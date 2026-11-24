# AGENTS.md — iplaypi.github.io 维护指南

本文件是本仓库（个人博客 `https://www.playpi.org`，Hexo 3.9 + NexT 主题）的协作与运维约定。
内容来自 2026-11 的一次完整改造（CI 迁移、标签大小写治理、本地环境修复），**修改构建、部署、标签相关内容前请先读完本文**。

---

## 1. 仓库与分支模型

| 分支 | 角色 | 是否可改 |
| --- | --- | --- |
| `source` | Hexo 源站：文章、主题、配置、构建脚本 | ✅ 唯一可编辑分支 |
| `master` | 纯部署产物（渲染后的纯静态站点） | ❌ 禁止本地修改/提交 |

- `master` 由 CI **每次构建后整体覆盖并强推**，提交信息固定为 `Auto Builder at YYYY-MM-DD HH:MM`。
- 因此：绝不手工编辑 `master`，绝不向 `master` 发起普通提交；要改内容只能改 `source`。
- 主站文件 `CNAME`、`LICENSE`、`README.md`、`index.php` 在构建时由 `source` 复制进 `master`，`public/` 里不会有它们。

---

## 2. 三条必须先知道的环境事实

1. **本项目的工具链是 2019 年的**：Hexo 3.9.0、`hexo-fs` 0.2.x、一批已废弃插件。不要「顺手升级」依赖，会连锁破坏主题渲染。
2. **Node 版本决定成败**：
   - Node 26（本机全局默认）→ `hexo` 直接崩溃（`TypeError: pangu.spacing is not a function`）；
   - Node 16 → `hexo server` 预览正常，但 `hexo generate` 会生成 **全站 0 字节文件**；
   - **Node 10.24.1 → 生成正常**（CI 使用该版本）。
3. **macOS 文件系统不区分大小写，而 `master` 的产物区分大小写**：`tags/Java/` 与 `tags/java/` 在本地只能存在一份，见第 6 节。

---

## 3. 本地环境

### 3.1 Node（fnm）

仓库根目录的 `.node-version` 固定为 `16`（只用于预览），进入该目录会自动切换。

`~/.zshrc` 中的 fnm 配置（**不要换成官方的 `fnm env --use-on-cd`，它有两个坑**）：

```zsh
eval "$(fnm env --shell zsh)"

_fnm_switch() {
  if [[ -f .node-version || -f .nvmrc ]]; then
    fnm use --silent-if-unchanged >/dev/null 2>&1
  else
    fnm use system >/dev/null 2>&1
  fi
  # zsh 会缓存命令路径，切换版本后必须重建哈希表，否则 node 仍指向旧版本
  rehash
}

autoload -U add-zsh-hook
add-zsh-hook -D chpwd _fnm_switch
add-zsh-hook chpwd _fnm_switch
_fnm_switch
```

两个坑：

- **必须有 `rehash`**：否则 `fnm current` 显示已切换，但 `node -v` 仍是旧版本（zsh 命令哈希缓存）。
- **离开项目目录要显式 `fnm use system`**：官方钩子只在「进入含版本文件的目录」时切换，`cd` 出去不会还原，会污染其他项目。

fnm 默认版本设为 `system`，保证其他项目继续使用系统 Node。

### 3.2 安装依赖

只用 `npm ci`，**不要用 `npm install`**（`npm install` 会重解析依赖，历史教训：`pangu` 会被升到 10.x 导致构建崩溃）。

```bash
npm ci --no-audit --no-fund
```

`package-lock.json` 的 `resolved` 已全部规范化为：

```
https://registry.npmjs.org/<包名>/-/<包名>-<版本>.tgz
```

**严禁**把 taobao 的地址写回去。taobao 的 URL 有两种不兼容形态，只换域名会 404：

```
taobao：https://registry.npm.taobao.org/hexo/download/hexo-3.9.0.tgz?cache=0&sync_timestamp=...
官方：  https://registry.npmjs.org/hexo/-/hexo-3.9.0.tgz
```

注意新版本 npm 会自动规范化脏 URL，所以**本地用 npm 8+ 测通不代表 CI（npm 6）能过**；验证依赖问题必须用 Node 10 + npm 6。

### 3.3 本地预览

```bash
cd ~/iplaypi/code/workspace/iplaypi.github.io
npx hexo server -p 4000
```

- 预览是内存渲染，不落盘，**不受大小写碰撞影响**，`/tags/Java/` 与 `/tags/java/`（若同时存在）都能正确显示。
- 本地**不要**依赖 `hexo generate` 的产物：Node 16 下会生成全站空文件。需要真实产物时用 Linux 容器或交给 CI。

---

## 4. 构建与部署（GitHub Actions）

配置文件：`.github/workflows/deploy.yml`，触发条件：`push` 到 `source`（也可 `workflow_dispatch` 手动触发）。

关键约束，改动时不要破坏：

| 配置 | 原因 |
| --- | --- |
| `runs-on: ubuntu-22.04` + `node-version: '10.24.1'` | 与历史可用环境一致；Node 16 生成空文件 |
| `npm ci` | 保证依赖版本与 lockfile 一致 |
| `test -s public/index.html` 守卫 | 产物为空直接失败，**绝不部署空白站** |
| 部署前清空 `master` 工作区 | 否则已删除的页面（如旧的大小写标签目录）会永久残留 |
| `git push --force origin HEAD:master` | 与历史部署方式一致，`master` 历史每次重置 |
| `concurrency: deploy-master` | 连续提交时取消上一次构建，避免并发强推 |

> 注：`master` 的每次构建都会整体变化（主题会在 HTML 里写入 build time 注释），所以「跳过部署」
> 分支基本不会走到，`master` 会稳定地一次 push 一个提交。

前置条件：仓库 **Settings → Actions → General → Workflow permissions** 必须是 **Read and write**，否则最后一步推送 403。

### 关于 Travis CI

- 原 `.travis.yml` **已失效**：最后一次成功构建是 `2021-06-09`，之后 `source` 上十余次提交均未触发构建。原因是 Travis 关停 `travis-ci.org` 并把开源项目改为额度制，与配置本身无关。
- 该文件仅作历史留存，**不要再改它**；所有 CI 改动都在 `.github/workflows/` 下。

---

## 5. 标签大小写规范（强制）

Hexo 用标签原文生成目录名，大小写不同会被当成两个标签，产生 `/tags/Java/` 与 `/tags/java/` 两个内容不同的页面（内容重复、SEO 分散、本地文件系统冲突）。

统一写法（**新增文章必须遵守**）：

| 标签 | 说明 |
| --- | --- |
| `Aria2` `Elasticsearch` `GitHub` `Hexo` `Maven` `Yarn` `Shadowsocks` | 官方产品名 |
| `Java` `JVM` `HTTP` `SSL` `VPS` | 技术缩写 |
| `MapReduce` `Markdown` | 官方拼写 |
| `Serializable` | Java 接口名 |

检查是否再次出现大小写重复（在 `source` 分支执行）：

```bash
grep -h -E '^tags:' source/_posts/*.md \
  | sed -E 's/^tags:[[:space:]]*//' | tr -d '[]' | tr ',' '\n' \
  | sed 's/^[[:space:]]*//; s/[[:space:]]*$//' | grep -v '^$' \
  | sort | uniq -c \
  | awk '{c=$1;$1="";sub(/^ /,"");k=tolower($0);n[k]=n[k]" | "$0}; END{for(k in n){split(n[k],a,"|");if(length(a)>2) print k": "n[k]}}'
```

输出为空即合规。同一条 `tags:` 数组内也不要重复同一标签。

---

## 6. macOS 大小写碰撞

### 现象

在本地 `checkout master` 会看到警告：

```
以下路径发生碰撞（如：在不区分大小写的文件系统上的区分大小写的路径）
  'tags/Java/index.html'
  'tags/java/index.html'
```

### 风险

碰撞组里只有一个文件能落地，另一个的内容被覆盖 → `git status` 出现「假修改」。
**此时任何 `git add -A` / `git commit -a` 都会把大写页面覆盖成小写内容，污染线上**。

### 处理原则

1. **本地不要 checkout `master`**，只在 `source` 上工作；需要看产物用 `git show master:tags/Java/index.html`。
2. 若必须检出 `master`（例如排查历史），检出后立刻做一次 `git status` 确认只有 `tags/` 下的假修改，并且**不要提交**。
3. 需要一份可用的本地 `master` 工作区时，用 sparse-checkout 排除碰撞文件（已验证可用）：

```bash
git sparse-checkout init --no-cone
{ echo '/*'
  for p in Aria2/aria2 ElasticSearch/Elasticsearch GitHub/Github Hexo/hexo Java/java \
           JVM/jvm MapReduce/mapreduce Markdown/markdown Maven/maven NexT/Next \
           Shadowsocks/shadowsocks SSL/ssl VPS/vps Yarn/yarn; do
    echo "!/tags/${p%%/*}/index.html"; echo "!/tags/${p##*/}/index.html"
  done
} > /tmp/sp.txt
git sparse-checkout set --no-cone --stdin < /tmp/sp.txt
```

（2026-11 已完成标签统一，此清单主要用于排查历史提交；如无碰撞可直接 `git sparse-checkout disable`。）

---

## 7. 网络与代理（国内环境）

GitHub 直连会被阻断（TCP 可建立但收不到数据）。Git 代理配置**只认 `http.<url>.proxy`**：

```bash
# 正确
git config --global 'http.https://github.com.proxy' 'socks5h://127.0.0.1:1080'

# 无效（Git 完全不读这个 section，等同于没配代理）
git config --global 'https.https://github.com.proxy' 'socks5://127.0.0.1:1080'
```

- 用 `socks5h`（DNS 也走代理），避免域名被污染解析。
- 加 URL 作用域，避免 GitLab 内网仓库误走代理。
- 排查顺序：`curl --socks5-hostname 127.0.0.1:1080 https://github.com`（通）→ `curl https://github.com`（不通）→ 说明代理正常、直连被阻断。
- Docker 拉取慢时用镜像：`docker.1ms.run/library/<image>`。

---

## 8. 故障速查

| 现象 | 原因 | 处理 |
| --- | --- | --- |
| `TypeError: pangu.spacing is not a function` | 默认 Node 26 跑 Hexo 3.9 | 切到 Node 16（预览）/ Node 10（生成） |
| `hexo generate` 全站 0 字节 | Node 16+ 与 `hexo-fs 0.2.x` 不兼容 | 用 Node 10，或交给 CI |
| `npm ci` 报 `E404 ... /<pkg>/download/...` | lockfile 里是 taobao 风格路径 | 改回 `/<pkg>/-/<pkg>-<ver>.tgz` |
| `npm ci` 报 `CERT_HAS_EXPIRED` | 旧 registry 域名证书过期 | 同上，统一 npmjs |
| `npm ci` 后构建报 `pangu` 相关错误 | 用了 `npm install` 重解析了依赖 | 改用 `npm ci` |
| Actions 最后一步 403 | Workflow permissions 是只读 | Settings → Actions → General 改为 Read and write |
| `git push` 要用户名密码 | 本机没有 GitHub 凭据 | 配 PAT（`credential.helper osxkeychain`）或 SSH key |
| 本地 `git status` 出现 `tags/` 假修改 | 检出 `master` 触发大小写碰撞 | 回到 `source`，或按第 6 节 sparse-checkout |

---

## 9. 提交与发布流程

```bash
git checkout source
git pull

# 改文章 / 配置 / 主题
git add -A
git commit -m "<type>: <说明>"
git push origin source        # 推送即触发构建
```

- 推送后 GitHub Actions 自动构建并强推 `master`，约 3~5 分钟。
- 构建失败时 `master` 不会被改动（守卫步骤会拦住）。
- 部署步骤里有一个「产物无变化则跳过」的判断，但**实际不会触发**：渲染出的页面内嵌了
  `<!-- build time:... -->` 注释，每次构建 592 个文件都会变，因此每次 push 都会在 `master`
  上新增一个提交。这是正常现象，不是配置错误。
- 提交信息使用 Conventional Commit 风格；不要直接向 `master` 推送。

---

## 10. 已知遗留

- `.travis.yml`：已失效，保留仅作历史。
- 原 Travis 中的「提交 URL 到百度站长」步骤未迁移（依赖 `BAIDU_TOKEN`）。
- 统一标签后 `/tags/aria2/`、`/tags/java/` 等旧 URL 返回 404，尚未加 301 重定向。
- Hexo 3.9 依赖链存在若干中危漏洞（Dependabot 提示），属历史包袱，升级需整体评估。

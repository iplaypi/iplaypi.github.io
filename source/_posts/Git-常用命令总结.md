---
title: Git 常用命令总结
id: 2019080701
date: 2019-08-07 23:39:06
updated: 2019-08-07 23:39:06
categories: 基础技术知识
tags: [Git,pull,push,commit]
keywords: Git,pull,push,commit
---


在软件工程师的工具列表中，`Git` 肯定是少不了的，作为分布式版本控制系统，`Git` 在目前非常流行，可以说，掌握 `Git` 的使用是工程师的基本功。而且，`Git` 也会为我们带来诸多的便利，根本离不开它。本文会记录一些常用的 `Git` 命令，不仅可以自查，也可以帮助读者。

另外，说明一下，关于远程仓库的选择，目前有多种多样，例如：`GitHub`、`GitLab`、`Gitee`【码云】、`coding` 等等，读者自行选择。其中，最流行的莫过于 `GitHub`，在全球非常受欢迎，被微软收购后也没有大家想象的那么可怕，反而更加开源了，现在都可以免费使用3个私有仓库了，可见微软还是愿意拥抱开源世界的。

本文中的远程仓库地址格式会以 `GitHub` 的 `HTTPS`  协议为准，即：

```
https://github.com/your_user_name/your_project_name.git
```

需要用户输入用户名、密码。

当然，还有一种格式是 `SSH` 协议的，即：

```
git@github.com:your_user_name/your_project_name.git
```

需要用户在本地生成秘钥，读者使用时可以自行选择。


<!-- more -->


# 下载安装


为了使用 `Git`，本地肯定要先安装好，在次不再赘述，请读者根据自己的操作系统类型选择合适的版本。`Git` 客户端下载官方网站：[git-scm](https://git-scm.com) 。

这里需要注意**回车换行符**的标准选择问题，需要先了解回车符【Carriage Return】、换行符【Line Feed】这两个概念，在计算机出现之前，为了解决打字机换行时的字符丢失问题，研发人员发明了这两个符号，回车符号告诉打字机把打印头定位在左边界，换行符号告诉打字机把纸向下移一行。

但是后来计算机出现后，科学家觉得用两个符号浪费存储空间【当时的存储硬件很昂贵】，保留一个符号就可以，这时候分歧出现了，也就导致现在的多种局面：在 `Mac` 系统里，每行结尾只有回车符 `CR`，即 `\\r`；在 `Unix` 系统里，每行结尾只有换行符 `LF`，即 `\\n`；在 `Windows` 系统里，每行结尾有回车换行两个符号 `CR LF`，即`\\r\\n` 。

这就会导致一个问题，在不同操作系统之间传输文本文件，打开后行会错乱，或者行尾多了不可见符号。

而通过 `Git` 管理项目时，一般都是代码文件、配置文件，远程仓库如果是 `Unix` 系统，那么文本文件的每行末尾都是换行符。而当我们本地开发时，用的是 `Windows` 系统或者 `Mac` 系统，而且伴随着代码更新、代码推送，多种符号会相互混在一起，就会显得很混乱。不过不用担心，在 `Git` 中可以设置回车换行符号的标准，在安装客户端时，选择当前操作系统对应的标准，那么每次在 `pull`、`push` 时，`Git` 会自动转换回车换行符号，保证一致性，这样在跨操作系统编辑文件时也不用担心这两个符号的问题。


# 初始化


对于新建的本地文件【以及文件夹】来说，需要初始化并关联到远程仓库【例如在 `GitHub` 新建了一个空白项目】，然后才能方便管理这个项目，可以按照如下流程操作：

```
# 进入项目目录
cd your_project_dir
# 初始化
git init
# 添加所有文件
git add .
# 提交到本地仓库
git commit -m "first commit"
# 关联到远程仓库
git remote add origin https://github.com/your_user_name/your_project_name.git
# 推送更新到远程仓库
git push -u origin master
```

如果本地的文件夹已经是一个标准 `Git` 项目，并且没有关联到任何远程分支，则直接关联即可，可以按照如下流程操作：

```
# 关联到远程仓库
git remote add origin https://github.com/your_user_name/your_project_name.git
# 推送更新到远程仓库
git push -u origin master
```

需要注意，如果远程仓库已经初始化【例如在 `GitHub` 上面新建一个包含 `README` 文件的项目】，本地仓库也已经初始化【执行 `init`】，此时关联后进行提交或者拉取更新会失败。`git pull` 返回错误 `fatal: refusing to merge unrelated histories`，提示仓库混乱【本地、远程是两个不同的仓库】，不能拉取；而 `git push` 则返回 `error: failed to push some refs to xx`，也不能提交。

此时不用担心，可以使用参数 `git pull origin master --allow-unrelated-histories` 来拉取远程仓库的内容，并合并所有内容，紧接着就可以提交本地的变更了。


# 检出仓库


如果本地目录是空白的，还没有任何项目，则需要从远程仓库克隆项目到本地，可以按照如下流程操作：

```
# 从远程仓库克隆项目,或者说是检出代码
git clone https://github.com/your_user_name/your_project_name.git
# 进入项目目录
cd your_project_dir
```


# 添加提交更新


如果更新了代码，或者新增了文件，需要提交更新，这样才能与别人合作开发项目，可以按照如下流程操作：

```
# 添加文件,对于新增的文件而言
git add your_file_name
# 点号表示添加本目录所有文件
git add .
# 提交变更到本地仓库,适当添加注释
git commit -m 'commit message'
# 当然，仅仅提交到本地仓库还不够,还需要推送到远程仓库
git push
# 在推送时可以指定分支,不指定则表示当前分支
git push origin master
```


# 拉取更新


如果在和别人合作开发的过程中，需要拉取别人的变更到本地，可以按照如下流程操作：

```
# 拉取更新(如果遇到代码冲突会麻烦,往下看)
git pull
# git pull其实相当于2个步骤
git fetch
git merge
# 如果merge遇到冲突,需要手动解决
# 1-改代码,把冲突文件改掉,可以使用git diff <source_branch> <target_branch>比较不同点
# 2-使用git add your_file标记改动完成
# 3-使用git commit -m "conflict fixed"提交冲突解决后的变更
```


# 管理分支


如果在开发过程中多人协作，肯定会有多个分支，此时涉及到管理分支的问题，可以按照如下流程操作：

```
# 新建分支并切换过去
git checkout -b your_branch_name
# 切换到指定的分支
git checkout your_branch_name
# 删除分支,切记不能删除当前分支,必须先切换到别的分支
git branch -d your_branch_name
# 将分支推送到远程仓库,不推送别人不可见
git push origin your_branch_name
# 当然,如果是处在当前分支,推送可以省略参数
git push
# 合并指定分支到当前分支
git merge your_branch_name
```

当然，此种情况有可能也会遇到代码冲突问题，参见**拉取更新**小节，需要手动解决冲突。


# 冲突解决


参见**拉取更新**小节，需要手动解决冲突。


# 更换关联远程分支


如果本地代码，已经关联了远程分支，但是想更换远程分支，例如想从 `GitHub` 切换到 `GitLab`，或者想在不同的项目之间切换。则需要先解除对远程分支的关联，再关联到新的远程分支，可以按照如下流程操作：

```
# 解除对远程仓库的关联
git remote remove origin
# 关联到新的远程仓库
git remote add origin https://github.com/your_user_name/your_project_name.git
# 接下来写代码、提交即可
```


# 强制更新覆盖本地修改


有些时候我们只想要 `Git` 远程仓库的代码，而对于本地的项目中修改不做任何理会【即本地的修改不提交，放弃不要了】，这时候就需要用到 `Git pull` 的强制覆盖，可以按照如下流程操作：

```
# 拉取远程最新的版本,或者使用git fetch origin也行
git fetch --all
# 或者直接使用git reset --hard HEAD也行
git reset --hard origin/master 
git pull
# 如果只想更改某个文件(不会影响新文件、已经commit的文件)
git checkout -- your_file_name
```


# 保存用户名密码


`Git` 可以将用户名、密码和仓库链接保存在硬盘中，而不用在每次 `git push` 的时候都输入密码。保存密码到硬盘只要一条命令就可以：

```
git config credential.helper store
```

当 `git push` 的时候输入一次用户名和密码后，就会被记录下来，以后不用再次输入。但是，这样保存的密码是明文的，保存在用户家目录的 `~/.git-credentials` 文件中，读者可以查看内容，使用：

```
cat ~/.git-credentials
```

由于这种方式密码是明文存储在文件中的，所以不安全，还是推荐大家使用 `SSH` 的方式。

此外，如果想手动设置用户名、邮箱，可以按照如下流程操作：

```
# 如果项目的环境众多,就不要带--global参数,否则全局的参数设置会影响到其它Git项目
git config --global user.name [username]
git config --global user.email [email]
```


# 管理标签


在软件开发的过程中，创建标签是很有必要的，可以跟踪当前的开发进度，出问题也能及时回退。可以按照如下流程操作：

```
# 创建标签,标签名字为1.0.1,commit_id是当次提交唯一标识
git tag 1.0.1 commit_id
# 当然,这里的commit_id会很长,不用全部写出来,一般6-10位足够了,只要保证它是唯一的就行
# 如果需要获取commit_id,可以使用log命令
git log
```


# 同步远程分支信息


有时候发现本地的分支信息与远程的不一致，例如远程的分支已经被删除，但是每次 `git pull` 的时候并不能同步到本地，在本地依然显示这些分支。

此时需要净化分支，使用命令：`git remote prune origin` 即可，或者也可以使用 `git remote update origin --prune`，效果一致。


# 代理设置


有时候遇到网络问题，或者被墙的问题，下载的速度非常慢，可以设置代理：

```
--global是全局的意思
设置代理
git config --global https.proxy http://127.0.0.1:1080
git config --global https.proxy https://127.0.0.1:1080
git config --global http.proxy 'socks5://127.0.0.1:1080'
git config --global https.proxy 'socks5://127.0.0.1:1080'

取消代理
git config --global --unset http.proxy
git config --global --unset https.proxy
```


# 查看日志


查看日志，可以看到变更的文件信息：

```
git log --stat
```


# 一些建议


在使用 `Git` 的时候，会有一些隐藏的小功能，可以增加使用体验，下面列出几个：

- 自带的图形化工具，使用 `gitk` 命令即可
- 设置彩色的内容输出，使用 `git config color.ui true` 设置
- 查看历史记录时，只显示一行注释信息，使用 `git config format.pretty oneline` 设置
- 添加文件时，如果想使用询问交互的模式，使用 `git add -i`，其实就是加了一个 `-i` 参数

此外，在使用 `Git` 相关的命令时，由于需要反复操作，时间久了会觉得很麻烦，因为每个命令都很长，由多个单词组成，每次都敲一遍还是很低效的。那么有没有什么好办法呢？其实可以合理利用 `Linux` 系统的别名特性，把自己常用的命令收集起来，分别给它们创建别名，这样在使用时只要简单敲几个字母就行。

我一般是在家目录下的 `.bashrc` 文件中指定别名，这样每次登录时会自动加载，可以直接在会话终端使用，关于 `Git` 的别名内容如下：

```
alias gp='git pull'
alias gb='git branch'
alias gc='git checkout'
alias gcs='git config credential.helper store'
alias gcfgn='git config --global user.name '
alias gcfge='git config --global user.email '
```

设置别名后，直接使用 `gp` 就相当于调用了 `git pull`，这就很方便了，其它命令也是类似的效果，读者可以根据自己的需要灵活设置。


# 资源推荐


下面列出一些常见的资源、网站、工具等信息，可能对读者有帮助：

- `git-tower` 工具，可视化管理，官网：[git-tower](https://www.git-tower.com)
- `sourcetree` 工具，可视化管理，官网：[sourcetreeapp](https://www.sourcetreeapp.com)
- `GitHub desktop` 工具，可视化管理，官网：[desktop](https://desktop.github.com)
- `Git` 社区参考书：[book.git-scm](https://book.git-scm.com)
- `GitHub` 帮助文档：[help.github](https://help.github.com)
- 像 `Git` 一样思考：[think-like-a-git](http://think-like-a-git.net)


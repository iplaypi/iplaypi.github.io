---
title: Hexo 博客集成 travis-ci 自动化测试发布
id: 2018100201
date: 2018-10-02 15:38:12
updated: 2019-05-11 15:38:12
categories: 建站
tags: [Hexo,travis-ci,GitHub]
keywords: Hexo,travis-ci,GitHub
---


我的博客一开始是搭建在阿里云上面的，购买了一台 VPS，然后在上面部署了 Git 仓库服务、Nginx 服务，同时也购买了一个域名。每次在本地写完博客，**generate** 后，直接使用 Hexo 自带的 **deploy** 命令把内容发布，同时在服务端的 Git 里面再设置一个 WebHook，触发自动拉取更新到 Nginx 项目目录的操作。这样，只要安心在本地写博客就行，写完就 **generate、deploy** 两下，看似很完美。

然而，使用了几个月就发现了各种麻烦事，例如：VPS 流量不够【恶意攻击或者爬虫】、VPS 服务不稳定【怀疑是被恶意攻击】、每次都要在本地生成【**generate** 命令】、两台电脑的环境配置不一致导致的兼容性问题、博客的整个管理还是略显繁琐。于是，我思考了好几天，并查看了别的成熟案例，最终决定使用 GitHub、travis-ci 搭配，完全的自动化测试部署，本地只负责写 Markdown 文档。这种方案才是真的简约、安全、方便。


<!-- more -->


# 前提


## 开源项目

首先说一下大前提，由于使用的所有工具、服务都是免费的，会暴露项目的信息、配置文件、日志信息，也就是说在 GitHub 中的项目类型要设置为 public 类型，使用 travis-ci 也要使用免费版本的【域名是 org 后缀的，不是 com 后缀的】。

把本地的项目提交到 GitHub 上面去，所以需要在 GitHub 上面新建一个空白项目，用来对接本地的项目。这里需要注意，为了使用 GitHub Pages 提供的独立子域名【https://username.github.io 】，需要把项目名称设置为 **username.github.io** 格式的。当然，任意项目名称命名的项目都可以作为 GitHub Pages，可以在 GitHub 的域名后面指定项目名称访问，但是不能使用独立子域名访问。

关于这个项目的分支管理，就比较独特了，因为源代码可以说只有配置文件、Markdown 文本文件，而经过 Hexo 编译生成文件基本全部是 HTML 文件。为了方便管理，这两种文件不要放在一起。所以可以用 **matser** 分支存放 Hexo 编译生成 HTML 文件，给 GitHub Pages 使用；而重新建立一个 **source** 分支【可以设置为孤儿分支，orphan】用来存放配置文件、Markdown 文本文件，用来更改、提交博客内容。这两个分支是完全没有关联的，不需要合并，他们存放的是完全不同类型的文件。

总结一下，对于 GitHub 中的项目，命名最好遵循 **username.github.io** 这样的格式，方便 GitHub Pages 分配独立的子域名，设置两个分支：master、source。其中，master 分支用来给 travis-ci 提交编译生成的 HTML 文件，可以通过 GitHub Pages 访问；source 分支用来本地提交写博客内容的 Markdown 文件，同时也给 travis-ci 监控，用来获取最新的博客并生成 HTML 文件提交到 master 分支。

为了直观起见，下面画一个流程图，清晰地表现出 GitHub 项目的设置：
![画一个流程图](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20190512001757.png "画一个流程图")

## 子模块管理

此外，还需要特别注意主题对应的项目，因为在 Hexo 项目中，主题是独立的项目，存放在 themes 文件夹内，例如默认的 **landscape** 主题。由于是独立的项目，而且是嵌套在 Hexo 中的，对于 Git 来说它属于子模块【submodule】，所以在对接 GitHub 时会遇到一些子模块的问题。具体如何解决我在这里不赘述，可以自行搜索解决方案，但是我要提出必要的思路：

一、由于主题子模块默认是在 GitHub 上 clone 下来的，而为了优化显示，我们一定会更改配置文件以及源代码，所以此时一定要解除主题与原来官方 GitHub 仓库的关系，转而把它连接到自己的 GitHub 仓库中。这样自己维护主题配置，避免更新时被官方的空白配置覆盖掉，当然，这样做就失去了与原来官方 GitHub 仓库的联系，导致不能及时获取更新【优化升级、bug 修复等】。

二、针对一中的情况，最好的做法是先在自己的仓库中 Fork 一份官方的主题源代码，然后在 Hexo 中的主题文件夹中使用自己 Fork 的主题源代码，这样既可以自己维护主题的配置，也能及时从官方拉取更新。此处会用到 **git submodule init**、**git submodule update** 等命令。

三、还有一种最简单但是不合理的做法，直接取消主题的 Git 项目属性，即把 Git 相关的配置删除，这样主题项目就不是 Hexo 的子模块了，只是一个普通的文件夹，可以随意更改，并且仅仅作为 Hexo 的一个子文件夹而已，永远不会更新。


# 持续集成


travis-ci 是一种持续集成的工具，持续集成【Continuous Integration】简称为 CI，当然类似的工具有好几种，例如：Jenkins、GitLab CI、Go CD 等，这里就不再赘述。这种工具可以提供一个持续集成功能的平台，在平台上面为你的项目配置好需要执行的操作，例如测试、编译、打包、部署等，这些配置都会有特定的方言规则，不同工具之间大同小异。此外，travis-ci 有两种版本，一种是收费的版本，网址为：[https://travis-ci.com](https://travis-ci.com) ，还有一种是免费的版本，网址为：[https://travis-ci.org](https://travis-ci.org) ，我使用的是免费的版本。

那么，使用这种持续集成的工具有什么好处呢？下面就会一一列举，当然，只是看解释说明可能无法感受，所以可以亲手测试一下各种场景，或者等完全部署完成之后再回头看它的好处。

## 优点一修改可以立即生效

例如你几天前发表了一篇博客，过了几天你发现里面竟然有错别字或者概念性的歧义，为了保证博客的质量，这个最好及时修复。如果自己的电脑在身边还可以操作，直接**修改文件、generate、deploy** 即可，但是如果只有一台普通的电脑，里面没有 Git、Hexo、Node.js 等环境，这个就很麻烦，恐怕装开发环境就要很久。

但是使用了 travis-ci 之后，这些和环境有关的操作都是它自动化完成的，你只要负责修改文件、提交更新到 GitHub 即可。你可以在本地只安装 Git 环境，clone 代码之后修改完再提交，当然更简单的是直接使用浏览器登录 GitHub 网站，在线直接修改文件提交。提交之后，会自动触发 travis-ci 的工作流程，编译、生成、部署等步骤全部由 travis-ci 自动完成，真的是解放了双手。

## 优点二自动部署到多个远程仓库

这个优点在 Hexo 自带的 deploy 功能中也有，可以把最新的代码同步到 GitHub 以外的远程仓库。有的人觉得在中国大陆 GitHub 的访问速度比较慢，就想着多部署几个站点，例如 Gitcafe、码云等，很简单，在 travis-ci 的脚本中多配置几行命令脚本即可，完全是自定义。

## 优点三部署快捷方便

当后期博客项目过大的时候，会需要一些自定义的优化点，例如搜索、字数统计、文件压缩等，这些特性都需要插件的支持，所以会安装很多插件，同时生成的静态文件也会越来越多。如果按照传统的手动管理方式，每次都需要提交大量的文件更新到远程仓库，耗时长而且没有必要，但是使用 travis-ci 之后，只需要提交 Markdown 文件的变更，其它的大量文件都交给 travis-ci 去生成，这样一来速度就很快了，时间消耗都转移到 travis-ci 上面去了。

## 优点四显示构建图标

对接 travis-ci 后，可以在 README 文件里显示持续集成工具构建结果的图标，是失败还是成功就很形象了。

## 其它优点

1、通过设置失败邮件提醒，在构建失败时会发送邮件通知。

2、如果设置了优点四中的构建图标，可以在 GitHub 的项目中，直接点击图标，然后会自动跳转到 travis-ci 的构建页面，可以查看构建日志、历史记录、项目配置等信息。

3、此外还可以配置自动化测试、构建成功才继续部署等选择项。


# 配置详解


## 登录持续集成帐号

打开官方网站：[https://travis-ci.org](https://travis-ci.org) ，登录帐号，注意不需要注册，一定要使用 GitHub 帐号授权的方式登录，只有这样 travis-ci 才能获取到 GitHub 上面的项目信息，进而进行管理。

## 开启项目管理权限

在 Settings、Repositories 中可以看到自己在 GitHub 上面的项目列表，但是 travis-ci 默认是不会管理任何一个项目的，需要手动开启。由于只需要监控我的博客项目，所以只是开启这一个，然后在开启按钮的右边点击设置按钮，进行下一步的设置。

开启管理权限
![开启管理权限](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20190512001740.png "开启管理权限")

进入到具体项目的设置页面，在这里，需要勾选 **General** 下面的 **Build pushed branches**、**Build pushed pull requests**，这两个选项的意思是当 GitHub 的项目有 **push** 操作时，则 travis-ci 会执行配置的流程。

设置 General
![设置 General](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20190512001733.png "设置 General")

再看下面的 **Auto Cancellation**，需要勾选 **Auto cacel branch builds**、**Auto cancel pull request builds**，这两个选项的意思是自动取消构建过程，主要用于当有连续多个 push、push pull request 发生时，可能先后间隔很短时间内触发了多次构建操作，这样显然浪费资源，没必要构建中间的 push，所以构建排队队列中的任务会自动取消，只保留最新的 push 触发的构建作业。当然，前提是必须等待正在运行的构建作业完成。

设置 Auto Cancellation
![设置 Auto Cancellation](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20190512001725.png "设置 Auto Cancellation")

## 按需设置环境变量

在设置中的 **Environment Variables** 里面，可以指定一些环境变量【其实就是全局变量】，这些变量可以在后面的构建脚本中直接使用。那么为什么要这么设置呢，有必要吗？

其实，一是为了安全，如果直接在构建脚本中使用字符串的形式暴露出来，势必会泄漏个人信息，例如在 GitHub 申请的 TOKEN、邮箱、用户名，这些信息肯定不能泄漏；二是为了方便，设置了全局变量，在构建脚本中直接引用，简化脚本内容，而且以后如果有更改，直接来到 travis-ci 更改环境变量即可，不需要更改构建脚本。因此，这些信息的设置是很有必要的。

当然，也不用在这里设置太多信息，有一些不重要的信息直接在构建脚本中使用字符串设置变量即可【构建方言规则里面有 env、global 可以设置只在脚本中有效的全局变量】。

我在这里设置了四个全局变量：REPO_TOKEN、GITHUB_URL、USER_EMAIL、USER_NAME，其中 REPO_TOKEN 是在 GitHub 中生成的访问验证信息，下面会讲怎么生成。

设置 Environment Variables
![设置 Environment Variables](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20190512001706.png "设置 Environment Variables")

切记，不要勾选 **Display value in build log**，否则这些信息还是会在 travis-ci 的构建日志中显示出来，也就是暴露了。

## 其它设置选项

还有一个名称为 **Cron Jobs** 的设置选项，这个设置就是开启定时任务，可以选择分支、周期、任务操作，如果你需要周期性地对 GitHub 项目进行操作就可以在这里配置。举个例子，如果你不要求你的博客的实时性，即不需要实时更新，可以不用设置上面的 **General**，直接在这里添加一个周期性任务，每天自动构建一次，这样你更新的博客内容要等一天才能更新到博客网站上面。

显然，如果为了保证实时性，这个选项是没有意义的，一般不需要开启。

至此，在 travis-ci 中的设置内容已经完成，travis-ci 已经在监控 GitHub 中的项目了，但是还有两件重要的事没做：生成验证信息、写自动构建脚本。

## 生成项目的访问验证信息

在设置环境变量的步骤中，用到了一个变量：REPO_TOKEN，这个是访问 GitHub 项目的验证信息，作用等同于用户名、密码，下面我们需要生成它。

在 GitHub 的个人设置中【不是单个项目的设置】，依次找到 **Settings**、**Developer settings**、**Personal access tokens**，这里面的内容就是开发者设置信息，可以生成一些隐私信息给开发者使用，方便程序直接调用接口，我也需要给 travis-ci 生成一个。

设置 Personal access tokens
![设置 Personal access tokens](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20190512001642.png "设置 Personal access tokens")

选择 **Generate new token** 按钮，为了安全，GitHub 还会要求验证一次密码，接着就进入到配置页面。在配置页面填写名称、权限即可，我这里只选择了 **repo** 权限，其它的目前没有必要。

注意，生成的 TOKEN 信息是一串字符串，GitHub 只会显示一次，所以要及时复制，刷新页面或者后续再回来查看是看不到的，只能重新申请。把这里生成的 TOKEN 作为设置环境变量步骤中的 **REPO_TOKEN** 的值即可，这样，在 travis-ci 构建脚本中就能访问 GitHub 从而进行 push 代码更新了。

生成 token 填写信息
![生成 token 填写信息](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20190512001556.png "生成 token 填写信息")

## 写自动构建脚本

在 GitHub 项目的 source 分支的根目录下，添加一个 **.travis.yml** 文件，这是 travis-ci 官方要求的，里面填写构建流程。

构建脚本内容的格式需要符合 travis-ci 的方言规范，里面也会用到上面设置的环境变量，获取环境变量的值使用 **${环境变量名称}** 格式，与使用 Linux 平台的环境变量格式一致，完整内容如下：

```
# 使用语言为 Node.js
language: node_js
# Node.js 版本,Node 11.0.0版本 yarn install 会报错不支持
# node_js: stable
node_js: 10.10.0
# 设置只监听哪个分支
branches:
  only:
  - source
# 缓存,可以节省集成的时间,这里用了 yarn,如果不用可以删除
cache:
  apt: true
  yarn: true
  directories:
    - node_modules
    - CNAME
# env
# 全局变量,为了安全,不要在这里设置,我这里设置只是示例,其实没有用到
env:
 global:
   - GITHUB_XXX_URL: github.com/iplaypi/iplaypi.github.io.git
# tarvis 生命周期执行顺序详见官网文档
before_install:
# 更改时区
- export TZ='Asia/Shanghai'
- git config --global user.name ${USER_NAME}
- git config --global user.email ${USER_EMAIL}
# 由于使用了 yarn,所以需要下载,不用 yarn 这两行可以删除
- curl -o- -L https://yarnpkg.com/install.sh | bash
- export PATH=$HOME/.yarn/bin:$PATH
# hexo 基础工具
- npm install -g hexo-cli
# 初始化所需模块,在 package.json 中配置的有,这样 node_modules 就不用提交到 GitHub 了
# 下次如果换电脑,安装完 Node.js,全局(-g参数)安装完 hexo-cli,直接在项目根目录初始化即可(在 package.json 配置的都会自动下载)
- npm install
# 本地搜索需要工具
- npm install hexo-generator-searchdb --save
# 字数统计,时长统计需要工具,Node 版本 7.6.0 之前,请安装 2.x 版本,npm install hexo-wordcount@2 --save
- npm install hexo-wordcount --save
# 站点地图,seo优化使用
- npm install hexo-generator-sitemap --save
- npm install hexo-generator-baidu-sitemap --save
# 中英文之间自动增加空格插件
# - npm install hexo-filter-auto-spacing --save(这个人用的少,不用了)
- npm install hexo-pangu-spacing --save
# rss订阅插件
- npm install hexo-generator-feed --save
# 三维卡通人物
- npm install --save hexo-helper-live2d
# 三维卡通人物-小猫咪模型下载(保险起见,把模型文件放到自己的文件夹里,不用每次下载)
# - npm install --save live2d-widget-model-hijiki
# 压缩文件
- npm install hexo-neat --save
install:
# 不用 yarn 的话这里改成 npm i 即可
- yarn
# script
# 以后把主题发布到 GitHub 中,先从官方 Fork 再更新自定义的,这里还需要更新子模块内容,示例:git submodule init,git submodule update
# 新建.gitmodules文件,内容
# [submodule "themes/next"]
#    path = themes/next
#    url = git://github.com/xin053/MyHexo_NexT_Theme
# 此外,还有那个评论系统的升级,Valine,思考怎么做
script:
- hexo clean
- hexo generate
# 成功之后才会提交,如果失败就会跳过并发送失败邮件通知
after_success:
# 获取 master 分支内容
- git clone https://${GITHUB_URL} .deploy_git
- cd .deploy_git
- git checkout master
- cp -rf ../public/* ./
# 必要配置文件
- cp -rf ../README.md ../.gitignore ../CNAME ../index.php ./
# 更改 .gitignore 内容,与 source 分支的不一样,直接置空,目前没有需要过滤的
- echo "" > ./.gitignore
- git add .
# 提交记录包含时间,跟上面更改时区配合
- git commit -m "Travis CI Auto Builder at `date +"%Y-%m-%d %H:%M"`"
# 推送到主分支
- git push --force --quiet "https://${REPO_TOKEN}@${GITHUB_URL}" master:master

# 邮件通知机制,我在这里设置了成功/失败都会通知
# configure notifications (email, IRC, campfire etc)
# please update this section to your needs!
# https://docs.travis-ci.com/user/notifications/
notifications:
  email:
    - ${USER_EMAIL}}
  on_success: always
  on_failure: always

```

我在构建脚本里面已经尽可能添加了注释说明，解释地很清晰了，那我在这里再说明一下构建脚本具体的思路：

- 指定环境、工具版本、监控的分支【只监控 source 分支】，开启缓存，设置全局变量
- 在 before_install 流程中进行环境的初始化
- 在 install 流程中安装基础环境【在这里 yarn 会使用缓存的内容，节约时间】
- 在 script 流程中生成 HTML 文件
- 在 after_success 流程中将最新代码推送到 master 分支【构建成功才会进行】
- 在 notifications 流程中执行通知邮箱与通知方式

这里要特别注意，我没有在构建脚本中使用 **hexo deploy**，所以在安装插件阶段也没有安装 **hexo-deployer-git**【对于我来说它不够灵活，只能发布 public 文件夹下面的内容】，因为我这里情况比较复杂，需要复制一些自定义的文件到 master 分支，而且我这里不再提交更新到 VPS 或者其它托管网站【这个我使用别的方式另外做了】。如果你的情况只是简单地自动部署，则在 **after_success** 流程中不需要那么多脚本，直接 **hexo deploy** 就行【当然别忘了在 Hexo 的配置文件 \_config.yml 中加上 deploy 相关配置】。

此外，我这里直接把主题的 Git 属性取消了，主题的文件夹被当作普通的文件夹提交到了 source 分支，这只是暂时的做法【而且显然不妥】，后面会把主题独立发布为一个项目，作为 Hexo 的一个 Git 子模块使用，敬请期待。我现在这么做虽然不妥，但是没有办法，因为我自己更改了太多的主题配置文件，而且版本过于陈旧，把这个主题项目单独整理出来需要消耗一些时间，以后会作为独立的博客发表一篇的，到时候构建脚本也会有小改动，敬请期待。

## 原理简述

travis-ci 为什么可以做到实时更新，只要有 push pull request 或者 push 就能被 travis-ci 监控到，然后去执行构建脚本。其实，背后使用的还是 GitHub 的 Webhooks 技术，由于给了 travis-ci 认证权限，travis-ci 就申请了 Webhooks 的发送请求，每当监控的项目有 push 或者 push request 请求时，GitHub 会发送项目的信息给 travis-ci，这样 travis-ci 就可以做出相应的动作，例如执行构建脚本。

这种做法我在另外一篇博客中也有实战经验，为了体验一下 VPS 上面的博客自动更新，也折腾了好几天，使用 PHP 自己搭建的服务脚本，有 GitHub 通知时自动拉取更新到本地指定的目录，有兴趣的可以参考一下：[使用 Github 的 WebHooks 实现代码自动更新](https://www.playpi.org/2019030601.html) 。

可以去项目的设置中【不是用户设置】，找到 **Settings**、**Webhooks**，可以看到有一条名称为 **https://notify.travis-ci.org **的 Webhooks 记录，它就是 GitHub 用来通知 travis-ci 的接口。
![Webhooks](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20190512003256.png "Webhooks")


# 效果预览


## 简化命令

完成了整个浩大的自动化部署工程后，以前需要使用的 Hexo 三部曲：

- hexo clean
- hexo generate
- hexo deploy

完全不需要了，取而代之的是 Git 三部曲：

- git add .
- git commit -am 'update message'
- git push

当然，在本地测试时还是要使用 Hexo 三部曲

- hexo clean
- hexo generate
- hexo sever

## 查看项目构建信息

在本地更新 source 分支的文本内容，提交到 GitHub 上面，然后去看 travis-ci 的构建结果。

构建基础信息，包含构建消耗时间、项目 Commit 的 id 值、分支名、构建流程消耗时间等等。
![构建基础信息](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20190512001610.png "构建基础信息")

接着往下看，有构建日志、构建脚本内容。
![构建日志](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20190512001421.png "构建日志")

查看一下构建历史列表，可以看到所有的构建信息，每一个都会有编号，从1开始增加。成功的构建是绿色的，失败的是红色的。
![构建历史列表](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20190512001344.png "构建历史列表")

## 给项目添加构建图标

在 travis-ci 的项目名称右边，可以看到有一个图标，点击，在弹出的对话框中选择分支与格式，我选择 source 分支，Markdown 格式，然后在下面的文本框中就会生成一个链接，直接复制粘贴到 GitHub 项目中的 README 文件中即可。

构建图标链接生成
![构建图标链接生成](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20190512001324.png "构建图标链接生成")

GitHub 项目的 README 文件填写
![GitHub 项目的 README 文件填写](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20190512001333.png "GitHub 项目的 README 文件填写")

GitHub 项目的构建图标查看
![GitHub 项目的构建图标查看](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20190512001033.png "GitHub 项目的构建图标查看")

点击这个图标，是可以直接跳转到 travis-ci 的构建页面，可以查看构建日志、历史记录、项目配置等信息。

至此，整个自动化部署方案完全实现，并验证通过，效果超级好，以后可以直接使用 Git 命令提交更新了。


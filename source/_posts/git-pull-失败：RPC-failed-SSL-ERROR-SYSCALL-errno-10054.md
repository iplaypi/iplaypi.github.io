---
title: git pull 失败：RPC failed;SSL_ERROR_SYSCALL errno 10054
id: 2019072301
date: 2019-07-23 23:06:33
updated: 2019-07-24 01:06:33
categories: 基础技术知识
tags: [Git,PRC,SSL]
keywords: Git,PRC,SSL
---


众所周知，`Git` 是一款非常流行的版本控制工具，现在的项目开发基本都离不开它，否则项目的协作开发将寸步难行，甚至会有专门的项目管理职位来规范项目的开发协作。如果不使用 `Git`，我的博客整理工作也会增加难度与复杂度，不得不说，我已经离不开它了。今天碰到一个关于 `Git` 的很奇怪的错误，本文记录解决的过程，整理完感觉经验技能又增长了。


<!-- more -->


# 问题出现


我换了一台电脑，把项目代码下载下来，正常的 `clone` 后，一直使用，过了几天，突然出现下面的问题。

在使用 `git pull` 命令同步最新代码时报错：

```
error: RPC failed; curl 56 OpenSSL SSL_read: SSL_ERROR_SYSCALL, errno 10054
fatal: The remote end hung up unexpectedly
fatal: early EOF
fatal: unpack-objects failed
```

![git pull报错信息](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20190724014935.png "git pull报错信息")

我仔细观察了整个过程，一开始还是正常的，百分比进度在变化，然后就卡在那里一直不再动，最后就报错，紧接着 `pull` 流程被终止。

初步看起来像是网络不好或者文件内容太大导致的网络连接超时失败。

按照可能是网络问题这个方向，我重试了多次，全部都是 `git pull` 失败，然后我换成其它项目再做相同的操作就正常，我陷入了沉思：应该和环境无关，只和项目有关，这个 `git pull` 失败的项目到底有什么特殊之处。

突然，我一拍脑门，想起来了，这个项目前一天晚上被我 `commit` 了很多张图片，应该有100张以上，总计 `200MB` 大小，看来这是问题所在。


# 问题分析解决


循着这个线索，使用报错关键词 `RPC failed; curl 56 OpenSSL SSL_read: SSL_ERROR_SYSCALL, errno 10054` 去 `stackoverflow` 搜索一下，发现很多人都遇到过这个问题。原因在于 `http` 通信缓存设置的值太小，恰好我的项目是使用 `http` 协议进行 `pull` 的，而没有使用 `ssh` 的方式。

这时候的解决方式就是设置一下缓存大小，参数名为：`http.postBuffer`，把它的值设置大一点【注意它的单位是 B，字节，进位是1024制的】：

```
# 500MB,如果配合使用 --global 参数可以全局生效
git config http.postBuffer 524288000
# 1GB
git config http.postBuffer 1048576000
```

根据官网对 `http.postBuffer` 这个参数的解释说明：

>Maximum size in bytes of the buffer used by smart HTTP transports when POSTing data to the remote system. For requests larger than this buffer size, HTTP/1.1 and Transfer-Encoding: chunked is used to avoid creating a massive pack file locally. Default is 1 MiB, which is sufficient for most requests.

附官网链接：[https://git-scm.com/docs/git-config](https://git-scm.com/docs/git-config) ，参见对参数 `http.postBuffer` 的解释。

![Git官网对于缓存参数的解释说明](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20190724015009.png "Git官网对于缓存参数的解释说明")

可以看到这个参数的默认值为：`1 MiB`，对大部分项目都是合理的，但是对于我这个一次疯狂 `commit` 很多张图片的项目就无能为力了。

配置完成后，也可以在项目的 `.git/config` 配置文件中查看这个参数的信息【如果设置了全局生效，则需要在家目录中寻找这个配置文件，即 `home` 目录】。

```
[core]
	repositoryformatversion = 0
	filemode = false
	bare = false
	logallrefupdates = true
	symlinks = false
	ignorecase = true
[remote "origin"]
	url = https://github.com/iplaypi/sources-playpi.git
	fetch = +refs/heads/*:refs/remotes/origin/*
[branch "master"]
	remote = origin
	merge = refs/heads/master
[gui]
	wmstate = normal
	geometry = 1061x563+30+30 233 255
[credential]
	helper = store
[user]
	name = iplaypi
	email = playpi@qq.com
[http]
	postBuffer = 524288000

```

![查看 Git 项目的配置信息](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20190724015105.png "查看 Git 项目的配置信息")

好，接下来再进行 `pull` 操作，可以看到，最终正常了，没有再出问题【一开始我设置的是500MB，还是不行，接着改为1GB就可以了】。由于网络速度问题或者中国大陆访问 `GitHub` 缓慢的原因，这次正常的 `pull` 使用了将近四十分钟才完成，等得我着急。

![pull正常同步更新](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20190724015342.png "pull正常同步更新")

可见，真的是我这个项目的内容太大了，同步的时候 `http` 通信缓存不足，导致出错。


#问题总结


1、此外，还有一个压缩参数：`core.compression`，可以用来设置压缩率，有11个取值。当然，如果把项目内容压缩了，由于压缩操作本身就会很耗时，会导致下载速度变慢，下载同步过程总的耗时也会随之增加。

官网说明：

>An integer -1..9, indicating a default compression level. -1 is the zlib default. 0 means no compression, and 1..9 are various speed/size tradeoffs, 9 being slowest. If set, this provides a default to other compression variables, such as core.looseCompression and pack.compression.

![Git官网对于压缩参数的解释说明](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20190724015140.png "Git官网对于压缩参数的解释说明")

2、我当前使用的是 `http` 方式，其实还有一种 `ssh` 方式，更方便，可以试试。


---
title: Git 客户端设置 Windows 下的字符编码
id: 2019031901
date: 2019-03-19 23:22:16
updated: 2019-03-19 23:22:16
categories: 基础技术知识
tags: [Git,Windows,中文乱码,gbk,utf-8]
keywords: Git,Windows,中文乱码,gbk,utf-8
---


在 Linux 以及大多数托管网站上，默认的字符编码均是 UTF-8，而 Windows 系统默认编码不是 UTF-8，一般是 GBK。如果在 Windows 平台使用 Git 客户端，不设置 Git 字符编码为 UTF-8，Git 客户端在处理中文内容时会出现乱码现象，很是烦人。但是，如果能正确设置字符编码，则可以有效解决处理中文和中文显示的问题。大多数技术从业者应该都遇到过各种各样的编码问题，后来渐渐习惯了使用英文，尽量避免中文，但是也有一些场景是必须使用中文的。本文就记录解决 Git 中文处理和中文显示的问题的过程，系统环境基于 Windows7 X64，Git 基于 v2.18.0。


<!-- more -->


# 乱码现象


Git 是一款非常好用的分布式版本控制系统，为了更好地使用它，一般都需要 Git 客户端的配合，下载使用参考：[https://git-scm.com/downloads](https://git-scm.com/downloads) 。

在 Windows 平台使用 Git 客户端的过程中，有一个问题你一定逃不掉，那就是乱码问题。这是因为 Windows 系统的编码是 GBK，而 Git 客户端的编码是 UTF-8，当两种不同的编码相遇，必然有一方会乱码。如果设置 Git 客户端的编码为 GBK，那么在使用 Git 客户端处理系统文件的时候可以正常显示，但是处理 Git 版本控制内容的时候，就会乱码，无法支持中文。如果反过来呢，把 Git 客户端的编码设置为 UTF-8，那么处理版本控制内容就可以有效支持中文，但是处理系统文件的时候又会乱码。

Git 客户端设置 UTF-8 编码，处理系统文件显示乱码
![ls命令中文乱码](https://ws1.sinaimg.cn/large/b7f2e3a3gy1g17blzgl2zj20l50cpjt9.jpg "ls命令中文乱码")


# 解决方式


这样看起来似乎没有解决方法，其实不是的，还是有很好的解决方法的。我这里为了完全支持版本管理系统，版本管理优先，肯定要统一设置为 UTF-8 编码，然后通过 Git 客户端的编码自动转换来支持系统的 GBK 编码。

这里先提前说明，在使用 Git 客户端的时候，Git 的安装目录【一般默认是 C:\Program Files\Git】，也就是 Git 的根目录。在使用 **ls** 等命令处理文件时，如果携带了 **/** 字符，其实就表示从 Git 的安装目录开始。例如在里面寻找 etc 目录，如果是使用 Git Bash 打开的，可以直接使用根目录的方式，**cd /etc/**。再例如 **vi /etc/git-completion.bash** 不是表示从系统的根目录开始寻找文件【Windows 系统也没有根目录的概念】，而是表示从 Git 的安装目录开始寻找文件。
![Git安装目录](https://ws1.sinaimg.cn/large/b7f2e3a3gy1g17bn7wtv0j20nd0dumyg.jpg "Git安装目录")

## 设置 Git 客户端

打开 Git 客户端的主页面，右键打开菜单栏【或者点击窗口的左上角也可以打开】，选择 **Options** 选项。
![Options选项](https://ws1.sinaimg.cn/large/b7f2e3a3gy1g17bmpt7mnj20l50cp0tw.jpg "Options选项")

接着选择 **Text** 参数配置，把编码方式由 GBK 改为 UTF-8【locale 也要设置为 zh_CN】。
![Text参数配置](https://ws1.sinaimg.cn/large/b7f2e3a3gy1g17bnna4xyj20l50cpacj.jpg "Text参数配置")

设置完成后，一定会导致一个现象，那就是使用 **ls** 查看系统文件时，带有中文的目录和带有中文的文件，一定是乱码的，根本看不清楚显示的是什么。不过不用担心，后面会通过设置让它恢复正常的。
![ls命令中文乱码](https://ws1.sinaimg.cn/large/b7f2e3a3gy1g17blzgl2zj20l50cpjt9.jpg "ls命令中文乱码")

接下来要解决的是显示的问题，目的是保证 Windows 的 GBK 编码可以在 Git 客户端正常显示。由于 Git 客户端被设置为了 UTF-8 编码，使用 **ls** 命令查看目录文件详情的时候，一定是乱码的，什么也看不出来【数字和英文不受影响】。那就需要设置 **ls** 命令的参数，让它按照 Git 客户端的编码来显示，不支持的字符也要显示，这样再使用 **ls** 命令的时候，就会自动把 GBK 编码转为 UTF-8 编码，那么带有中文的目录、带有中文的文件都能正常显示了。

最简单的做法，就是需要指定 **ls** 命令的附加参数【--show-control-chars】，为了方便，直接更改配置文件 **/etc/git-completion.bash** 【没有的话新建一个既可】，在行尾增加配置项 **alias ls="ls --show-control-chars --color"** 。其实就是通过新建别名这个技巧把 **ls** 命令的含义扩展了，让它可以根据 Git 客户端的编码转换系统的编码【在这里就是把 GBK 转为 UTF-8】。

```
vi /etc/git-completion.bash
alias ls="ls --show-control-chars --color"
```

更改完成后，可以看到能正常显示系统中的带有中文名称的文件了。
![ls可以正常显示中文](https://ws1.sinaimg.cn/large/b7f2e3a3gy1g17bo2mcrej20l50cpq4y.jpg "ls可以正常显示中文")

## 设置 Git

接下来就是设置 Git 进行版本控制时使用的编码方式，例如提交信息时支持输入中文日志、输出 log 可以正常显示中文。

设置 Git 有两种方式，一种是通过更改配置文件，另一种是通过 Git 自带的命令来配置参数。为了显得没有手动去破坏 Git 的原有配置文件，我就使用 Git 自带的命令来配置编码。当然，通过更改配置文件的方式也会一同描述出来。

1、通过命令行把 Git 的各种编码都设置为 UTF-8

```
git config --global core.quotepath false          # 显示 status 编码 
git config --global gui.encoding utf-8            # 图形界面编码 
git config --global i18n.commit.encoding utf-8    # 处理提交信息编码 
git config --global i18n.logoutputencoding utf-8  # 输出 log 编码 
export LESSCHARSET=utf-8                          # 因为 git log 默认使用 less 分页,所以需要 bash 对 less 命令处理时使用 utf-8 编码
```

2、如果通过配置文件的方式来更改，则需要编辑配置文件 **/etc/gitconfig** 【没有则新建一个】，在里面设置以下内容。

```
[core]
        quotepath = false 
[gui]
        encoding = utf-8 
[i18n]
        commitencoding = utf-8 
        logoutputencoding = utf-8
```

另外还需要在配置文件 **/etc/profile** 中新增

```
export LESSCHARSET=utf-8
```

3、特殊说明

**gui.encoding = utf-8** 是为了解决 git gui 和 gitk 中的中文乱码问题，如果发现代码中的注释显示乱码，可以在所属项目的根目录中 **.git/config** 文件中添加：

```
[gui]
        encoding = utf-8
```

**i18n.commitencoding = utf-8** 是为了设置 commit log 提交时使用 UTF-8 编码。
**i18n.logoutputencoding = utf-8** 是为了保证在 **git log** 时使用 UTF-8 编码。
**export LESSCHARSET=utf-8** 是为了保证 **git log** 翻页时使用 UTF-8 编码，这样就可以正常显示中文了【配合前面的 **i18n.logoutputencoding** 设置】。

## 验证

add 执行的时候 Git 输出的日志都是中文显示的，特别是带有中文名称的文件。
![add命令输出中文](https://ws1.sinaimg.cn/large/b7f2e3a3gy1g17bv0ph2yj20l50f20uh.jpg "add命令输出中文")

验证提交时填写日志信息，可以直接填写中文日志，另外 Git 的输出日志也是以中文来显示的，可以看到哪些文件变更了。
![验证提交时填写中文日志](https://ws1.sinaimg.cn/large/b7f2e3a3gy1g17boorhqyj20l50cpgn8.jpg "验证提交时填写中文日志")

验证使用 **git log** 查看历史日志时正常显示中文内容
![查看历史日志时正常显示中文内容1](https://ws1.sinaimg.cn/large/b7f2e3a3gy1g17bosnlsnj20l50cp0tt.jpg "查看历史日志时正常显示中文内容1")


![查看历史日志时正常显示中文内容2](https://ws1.sinaimg.cn/large/b7f2e3a3gy1g17box3cduj20l50cp3zx.jpg "查看历史日志时正常显示中文内容2")


# 注意事项


1、此外，Cygwin 在 Windows 平台上也有同样的问题，设置方式也是类似的。当然，如果只是查看目录文件，使用基本的命令，请尽量脱离带有中文的目录和带有中文的文件，避免踩坑，这样还可以把编码直接设置为 GBK 了，但是遇到特殊的情况还是脱离不了 UTF-8 编码。


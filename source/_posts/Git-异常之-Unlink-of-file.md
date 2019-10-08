---
title: Git 异常之 Unlink of file
id: 2019100801
date: 2019-10-08 20:48:39
updated: 2019-10-08 20:48:39
categories: 基础技术知识
tags: [Git]
keywords: Git
---


在使用 `Git` 的时候，出现错误：

```
Unlink of file '.git/objects/pack/pack-xx.idx' failed. Should I try again? (y/n)
```

连续出现几十次，看起来像是 `Git` 在操作索引文件时被拒绝了，可能是文件权限问题，或者文件被占用。

本文内容中涉及的 `Git` 版本为：`2.18.0.windows.1`，操作系统为：`Windows 7x64`。


<!-- more -->


# 问题出现


在对一个普通的 `Git` 项目进行 `git pull` 操作的时候，出现错误，显示如下的交互询问内容：

```
Unlink of file '.git/objects/pack/pack-61113bb66bb6a4dcc0893ee5e0b36bf30cf917e6.idx' failed. Should I try again? (y/n) 
Unlink of file '.git/objects/pack/pack-670222495fa872c140e7e231e36cb2701d76c86b.idx' failed. Should I try again? (y/n) 
Unlink of file '.git/objects/pack/pack-6acdf7d3bbb7394f39b68e0e40b47ca0116fbfa2.idx' failed. Should I try again? (y/n) 
Unlink of file '.git/objects/pack/pack-6ffde68d8af2eafb0803063b895291418ed5f465.idx' failed. Should I try again? (y/n) 
```

尝试手动输入 `y` 或者 `n`，并没有什么效果，输入 `y` 后同样的错误会继续出现，输入 `n` 会接着提示下一个类似的文件错误。

```
Unlink of file '.git/objects/pack/pack-61113bb66bb6a4dcc0893ee5e0b36bf30cf917e6.idx' iled. Should I try again? (y/n) y
Unlink of file '.git/objects/pack/pack-61113bb66bb6a4dcc0893ee5e0b36bf30cf917e6.idx' failed. Should I try again? (y/n) y
Unlink of file '.git/objects/pack/pack-61113bb66bb6a4dcc0893ee5e0b36bf30cf917e6.idx' failed. Should I try again? (y/n) y
Unlink of file '.git/objects/pack/pack-61113bb66bb6a4dcc0893ee5e0b36bf30cf917e6.idx' failed. Should I try again? (y/n) y
Unlink of file '.git/objects/pack/pack-61113bb66bb6a4dcc0893ee5e0b36bf30cf917e6.idx' failed. Should I try again? (y/n) y
Unlink of file '.git/objects/pack/pack-61113bb66bb6a4dcc0893ee5e0b36bf30cf917e6.idx' failed. Should I try again? (y/n) n
Unlink of file '.git/objects/pack/pack-670222495fa872c140e7e231e36cb2701d76c86b.idx' failed. Should I try again? (y/n) n
Unlink of file '.git/objects/pack/pack-6acdf7d3bbb7394f39b68e0e40b47ca0116fbfa2.idx' failed. Should I try again? (y/n) n
Unlink of file '.git/objects/pack/pack-6ffde68d8af2eafb0803063b895291418ed5f465.idx' failed. Should I try again? (y/n) y
Unlink of file '.git/objects/pack/pack-6ffde68d8af2eafb0803063b895291418ed5f465.idx' failed. Should I try again? (y/n) y
Unlink of file '.git/objects/pack/pack-6ffde68d8af2eafb0803063b895291418ed5f465.idx' failed. Should I try again? (y/n) y
Unlink of file '.git/objects/pack/pack-6ffde68d8af2eafb0803063b895291418ed5f465.idx' failed. Should I try again? (y/n) y
```

![Git 文件被占用](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20191008210804.png "Git 文件被占用")

可见是要把所有同类型的文件全部询问一次，看起来问题没那么简单。

如果有耐心的话，连续输入几十次 `n`，可能会把所有的文件都忽略掉，提示也就结束了，或者直接使用 `ctrl + c` 结束操作，强制退出，但是这样操作并没有从根本上解决这个问题。


# 分析解决


经过查询分析，这个问题的根本原因是 `Git` 项目的文件被其它程序占用，导致 `Git` 没有权限变更这些文件。这些文件是 `Git` 产生的临时文件，需要从 `Git` 的工作区移除。

上面提及的其它程序极有可能是 `IDEA`、`Eclipse`、`Visual Studio` 等常用的开发工具。

参考：[stackoverflow.com](https://stackoverflow.com/questions/4389833/unlink-of-file-failed-should-i-try-again) 。

解决方案也很简单，把占用文件的程序关闭就行。但是有时候找不到是哪个程序占用了文件，怎么办，可以利用微软的 `Process Explorer` 工具，具体介绍参考备注内容。


# 备注


1、`Process Explorer` 是一个任务管理器，目前由微软开发，仅用于 `Windows` 操作系统平台，可以查看系统的进程信息、资源占用信息、文件占用信息，官网地址：[Process Explorer](https://docs.microsoft.com/en-us/sysinternals/downloads/process-explorer) 。

同时，这个工具目前在 `GitHub` 上已经开源，并重新命名为：`sysinternals`，`GitHub` 的地址：[sysinternals](https://github.com/MicrosoftDocs/sysinternals/tree/live) 。

使用时无需安装，解压后直接可以运行，在主界面依次选择 `Find` -> `Find Handle or DLL`，在搜索框中输入程序的名字、文件的名字，点击搜索，就可以看到搜索结果了，例如正在运行的进程、文件的使用情况等。

![使用 Process Explorer 查看文件占用情况](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20191008210836.png "使用 Process Explorer 查看文件占用情况")

2、我留意到在上述的 `stackoverflow` 链接中，也有人建议先使用 `git gc` 来手动执行一下垃圾清理，把临时文件给清理掉，然才进行 `git pull` 操作。我没有测试过，但感觉也有道理，读者可以试试。


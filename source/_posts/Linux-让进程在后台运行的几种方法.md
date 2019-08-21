---
title: Linux 让进程在后台运行的几种方法
id: 2019051501
date: 2019-05-15 15:49:53
updated: 2019-06-08 15:49:53
categories: 大数据技术知识
tags: [Linux,nohup,setsid,disown,screen,daemon]
keywords: Linux,nohup,setsid,disown,screen,daemon
---


在 `Linux` 系统中，运行程序时经常需要把进程放在后台运行，并且退出终端等待，也可以说是守护进程，`daemon` 的概念，可能过几个小时或者十几个小时之后再去观察。此时，需要把进程放入后台运行，并且为了防止进程挂起，也需要设置进程忽略挂起信号【使用 `nohup` 命令】，这样就可以保证进程在我退出终端后仍旧能正常运行，无论我多久之后再来观察，仍可以看到进程的信息。本文记录关于进程后台运行【daemon】的几种方法，并给出实际操作示例。


<!-- more -->


# 回顾


在我刚开始步入工作的路途上，算是一个职场新手，很多东西都不会，一路上披荆斩棘，现在总算积累了一些经验。记得在刚开始工作时，经常碰到这样的问题，使用 `telnet` 或者 `ssh` 登录了远程的 `Linux` 服务器【很多工作需要在 `Linux` 上面完成】，在上面跑了几个 `Shell` 脚本，或者起了几个 `Java` 进程，而且这些脚本或者进程耗时都比较长，可能需要几个小时或者几天。我一开始的做法就是打开 `XShell` 工具的多个会话，分别跑脚本或者起进程，不仅不能关掉，而且还要担心网络问题导致会话断开，一切工作就白费了。

结果被其他同事看到了，说我这种做法太蠢了，可以使用后台挂起的命令【即 `nohup` 加上 `&`】，这样就可以让进程自由在在地运行，我也可以安心做其它事情了。我第一次受到了经验方面的冲击，觉得这种方式太酷了，一开始我为什么不多思考一下或者查询一下，我想这些实用的知识点肯定还有很多，从此以后我更加努力。

在后来的工作或者生活当中，我又接触到了很多类似的知识点或者说是小技巧，不仅提高了我的工作效率，还丰富了我的认知。其中，基于进程的后台运行这个需求，还有很多很好的工具可以使用，还有很多实际操作的小技巧可以使用，以下篇幅会一一介绍。继续阅读之前，可以先了解一下信号的概念，也可以直接参考我的另外一篇博文：[Linux 之 kill 命令入门实践](https://www.playpi.org/2019042101.html) 。


# 前言


在工程师或者运维人员的生涯中，肯定会碰到这样的场景：使用 `ssh` 或者 `telnet` 登录了远程服务器，然后在上面跑一些任务或者脚本。如果是临时任务或者几分钟就能搞定的任务，基本不会有什么问题，但是如果是耗时比较长的任务，就会因为网络不稳定或者手抖退出了会话，从而导致任务失败，还要从头再来，遇到这种问题所有人都是崩溃的。

那么我不禁思考，有没有什么办法可以让任务在提交后不受网络中断、会话退出的影响呢，可以一直保持在后台稳定运行，直到结束。肯定是有的，读者在工作中一定也见过周围的大神同事操作，下面列举一些常用的方式，读者可以参考，选择自己喜欢的方式使用。

内容中涉及到的 `SIGHUP` 信号，先来了解一下它的由来：

> 在 `Unix` 的早期版本中，每个终端都会通过 `modem` 和系统通讯，当用户 `logout` 时，`modem` 就会挂断（hang up）电话。同理，当 `modem` 断开连接时，就会给终端发送 `hangup` 信号来通知其关闭所有子进程。这里的子进程包含前台子进程、后台子进程，前台子进程是被直接关闭的（如果手动设置了 `nohup` 除外），后台子进程要根据操作系统的 `huponexit` 设置而定，不一定会被关闭。其中，这里的后台子进程包括正在运行的子进程（使用 `jobs` 工具查看 处于 `running` 状态）、暂停的子进程（使用 `jobs` 工具查看 处于 `stopped` 状态，无论有没有设置 `nohup` 都会被关闭）。

再看一下维基百科给它的定义：

> **nohup** is a POSIX command to ignore the HUP (hangup) signal. The HUP signal is, by convention, the way a terminal warns dependent processes of logout.
> Output that would normally go to the terminal goes to a file called nohup.out if it has not already been redirected.


# 直接忽略挂起信号


众所周知，当发生用户注销会话、网络断开等事件时，终端会收到 `SIGHUP` 信号从而关闭其所有的子进程，它是通过把 `SIGHUP` 信号发送给所有子进程实现。当然，**前台**子进程如果没有设置忽略 `SIGHUP` 信号直接会停掉，如果设置了会继续运行，但是**后台**子进程除了人为设置可能还会因为操作系统的设置而忽略 `SIGHUP` 信号【所以有些人会觉得莫名其妙，怎么退出了再登录进程还在】。到这里，我就能想到两种解决方案：一是让进程忽略掉 `SIGHUP` 信号，二是让进程脱离会话父进程的运行，附属于其它父进程，从而不会接收到当前终端对应的进程发出的 `SIGHUP` 信号，这两种方法都可以让进程不受外界因素影响，稳定地运行。

## nohup 方式

思路有了，首先能想到的就是 `nohup` 工具，顾名思义，`nohup` 这个工具的作用就是让进程忽略掉所有的 `SIGHUP` 信号。

先来看一下帮助文档信息，使用 `man nohup` 命令查看：

```
NOHUP(1)                         User Commands                        NOHUP(1)

NAME
       nohup - run a command immune to hangups, with output to a non-tty

SYNOPSIS
       nohup COMMAND [ARG]...
       nohup OPTION

DESCRIPTION
       Run COMMAND, ignoring hangup signals.

       --help display this help and exit

       --version
              output version information and exit

       If standard input is a terminal, redirect it from /dev/null.  If standard output is a terminal, append output to ‘nohup.out’ if possible, ‘$HOME/nohup.out’ otherwise.  If standard error is a terminal, redirect it to standard output.  To save output to FILE, use ‘nohup COMMAND > FILE’.

       NOTE: your shell may have its own version of nohup, which usually supersedes the version described here.  Please refer to your shell’s documentation for details about the options it supports.

AUTHOR
       Written by Jim Meyering.

REPORTING BUGS
       Report nohup bugs to bug-coreutils@gnu.org
       GNU coreutils home page: <http://www.gnu.org/software/coreutils/>
       General help using GNU software: <http://www.gnu.org/gethelp/>
       Report nohup translation bugs to <http://translationproject.org/team/>

COPYRIGHT
       Copyright © 2010 Free Software Foundation, Inc.  License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>.
       This is free software: you are free to change and redistribute it.  There is NO WARRANTY, to the extent permitted by law.

SEE ALSO
       The full documentation for nohup is maintained as a Texinfo manual.  If the info and nohup programs are properly installed at your site, the command

              info coreutils 'nohup invocation'

       should give you access to the complete manual.

GNU coreutils 8.4                December 2011                        NOHUP(1)
```

图。。

从中可以挑出重点信息：

```
nohup COMMAND [ARG]...
Run COMMAND, ignoring hangup signals.
If  standard  output is a terminal, append output to ‘nohup.out’ if possible,‘$HOME/nohup.out’ otherwise.
```

- 使用方式：在执行的命令前面加上 `nohup` 即可。
- 作用：可以让执行的进程忽略 `SIGHUP` 信号。
- 输出：在终端执行的进程，输出信息重定向到 `nohup.out` 文件。

可见，`nohup` 的使用时十分简单方便的，标准输出和标准错误默认会被重定向到 `nohup.out` 文件中，此文件生成于执行命令的目录。但是要注意，一般我会在命令结尾加上 `&` 来将命令放入后台运行，此外也可以使用 `>filename 2>&1` 来更改默认的重定向文件名。

下面举一个例子，来演示 `nohup` 的使用：

```
1、nohup tail -f xx.log &，提交一个后台进程
2、ps -ef |grep 'tail -f' |grep -v grep，查看进程的状态
3、kill -SIGHUP 245058，手动发送 SIGHUP 信号
4、同2再查看进程的状态
```

依次执行上述步骤，输出信息如下：

```
[pengfei@dev2 ~]$ nohup tail -f xx.log &
[1] 245058
[pengfei@dev2 ~]$ nohup: ignoring input and appending output to `nohup.out'

[pengfei@dev2 ~]$ 
[pengfei@dev2 ~]$ 
[pengfei@dev2 ~]$ ps -ef |grep 'tail -f' |grep -v grep
pengfei  245058 201491  0 01:36 pts/0    00:00:00 tail -f xx.log
[pengfei@dev2 ~]$ 
[pengfei@dev2 ~]$ 
[pengfei@dev2 ~]$ kill -SIGHUP 245058
[pengfei@dev2 ~]$ 
[pengfei@dev2 ~]$ ps -ef |grep 'tail -f' |grep -v grep
pengfei  245058 201491  0 01:36 pts/0    00:00:00 tail -f xx.log
```

图。。

可以看到，进程已经不受 `SIGHUP` 信号的影响了。

## setsid 方式

待整理。

## & 方式

待整理。


# 忽略挂起的后悔药


后台运行的例子，使用 `disown` 也可以达到效果。

使用 `Ctrl + z` 命令，把正在前台运行的进程暂停，并放在后台，程序并没有被杀死。其实这个组合快捷键是一种控制信号，编号为`19`，标识为 `SIGSTOP`，读者可以参考我的另外一篇博文：[Linux 之 kill 命令入门实践](https://playpi.org/2019042101.html) 。当然，如果使用终端工具，再开一个会话窗口，使用 `ps` 命令查询这个进程的 `pid` 编号，然后使用 `kill -19 pid` 命令发送一个 `SIGSTOP` 信号给进程也可以达到把程序暂停并放在后台的效果。


# 批量管理进程


前面的描述都是单个进程或者几个进程，管理起来也挺方便，但是如果遇到大量的进程需要管理，例如运维人员日常需要手动管理大量的进程，几百个几千个都是有可能的，那么怎么办呢。为了简化管理，并且保证进程能在后台稳定运行，此时就需要通过 `screen` 工具来操作，这是一个利器。

首先我们来看一下帮助文档信息，使用 `man screen` 命令输出：

```
xx
```

图。。


# 备注


## 关于挂起的测试

我使用 `XShell` 测试退出终端时，发现并不会挂起普通的后台进程【说明后台进程没有接收到 `SIGHUP` 信号，或者接收到但是忽略了】，反而把进程的父进程设置为了 `init`【进程号为1】，这样进程就不会退出，下次登录的时候还能查看。但是这个现象违反了前面的知识点：退出终端时所有子进程会收到 `SIGHUP` 信号，后来我发现，原来这个操作是针对**前台任务**而言的，如果是**后台任务**则不一定，要看系统的参数设置：`shopt | grep huponexit`，`huponexit` 这个参数决定了是否向后台任务发送 `SIGHUP` 信号。而在大多数 `Linux` 系统中，这个参数一般默认是关闭的，所以才出现了终端退出后台进程没有挂起的现象。

这里面还有两个有趣的现象。

### 前台任务

一是**前台任务**如果被人为设置了 `nohup`，则在会话关闭时会忽略掉 `SIGHUP` 信号，从而一直保持运行。下面演示一下。

```
1、tail -f xx.log
2、断开网络或者关闭会话窗口
3、nohup tail -f yy.log
4、断开网络或者关闭会话窗口
5、重新登录，使用 ps 工具查看进程：ps -ef |grep 'tail -f' |grep -v grep
```

输出信息如下：

```
[pengfei@dev2 ~]$ ps -ef |grep 'tail -f' |grep -v grep
pengfei  199496      1  0 01:16 ?        00:00:00 tail -f yy.log
```

图。。

使用上述步骤依次操作，可以发现 `nohup tail -f yy.log` 对应的进程还在，而 `tail -f xx.log` 对应的进程已经不在了，这就是因为前者在执行命令时手动添加了 `nohup`，从而可以保障不受因会话关闭发送的 `SIGHUP` 信号影响，而后者直接被杀死。

可能读者会怀疑这个没被杀死的进程是出于运行状态码，会不会处于暂停状态，这个很容易证明，直接使用 `pstack` 工具可以查看：`pstack pid`。例如我这里的进程号是199496 ，则使用 `pstack 199496` 查看。

```
[pengfei@dev2 ~]$ pstack 199496
#0  0x00000031fd8db7f0 in __read_nocancel () from /lib64/libc.so.6
#1  0x0000000000408df6 in ?? ()
#2  0x0000000000403b56 in ?? ()
#3  0x0000000000404ae0 in ?? ()
#4  0x00000031fd81ed20 in __libc_start_main () from /lib64/libc.so.6
#5  0x0000000000401959 in ?? ()
#6  0x00007ffdc74bdb48 in ?? ()
#7  0x000000000000001c in ?? ()
#8  0x0000000000000003 in ?? ()
#9  0x00007ffdc74be606 in ?? ()
#10 0x00007ffdc74be60b in ?? ()
#11 0x00007ffdc74be60e in ?? ()
#12 0x0000000000000000 in ?? ()
```

图。。

可以看到，进程仍旧在运行中，如果是暂停状态的进程，会显示 `stopped` 标记，下面的例子会演示这个，请读者继续往下看。

### 后台任务

【废弃】二是**后台任务**如果处于 `stopped` 状态，尽管会话关闭时不会导致进程被杀死，但是它仍旧处于 `stopped` 状态，等下次登录时它的父进程已经变为 `init` 进程，这就导致使用 `jobs` 工具无法查到，也无法使用 `fg` 工具激活任务。总之，这个任务永远处于 `stopped` 状态，对于我来说已经没有意义，只能等待操作系统把它停掉。下面演示一下。

二是**后台任务**如果处于 `stopped` 状态，无论有没有设置 `nohup`，在会话关闭或者网络断开时，进程会被杀死。而如果是处于 `ruuning` 状态，无论有没有设置 `nohup`，在会话关闭或者网络断开时，进程都不会被杀死。下面举两个例子演示一下。

```
1、tail -f xx.log &，这里只是简单后台运行，并没有设置 nohup，所以发送 SIGHUP 信号可以杀死进程
2、断开网络或者关闭会话窗口
3、nohup tail -f yy.log，然后使用 ctrl + z 暂停任务，状态处于 stopped，并置于后台
4、使用 jobs 工具查看进程状态
5、断开网络或者关闭会话窗口
6、重新登录，使用 ps 工具查看进程：ps -ef |grep 'tail -f' |grep -v grep
```

使用 `jobs` 工具查看进程状态输出信息如下，可见是 `stopped` 状态：

```
[pengfei@dev2 ~]$ nohup tail -f yy.log
nohup: ignoring input and appending output to `nohup.out'
^Z
[1]+  Stopped                 nohup tail -f yy.log
[pengfei@dev2 ~]$ 
[pengfei@dev2 ~]$ jobs
[1]+  Stopped                 nohup tail -f yy.log
```

图。。

再次使用上面的 `pstack` 工具查看：`pstack pid`，我这里的进程号是98537 ，则使用 `pstack 98537` 查看。

```
[pengfei@dev2 ~]$ pstack 98537
#0  0x00000031fd8db7f0 in __read_nocancel () from /lib64/libc.so.6
#1  0x0000000000408df6 in ?? ()
#2  0x0000000000403b56 in ?? ()
#3  0x0000000000404ae0 in ?? ()
#4  0x00000031fd81ed20 in __libc_start_main () from /lib64/libc.so.6
#5  0x0000000000401959 in ?? ()
#6  0x00007fff911d07e8 in ?? ()
#7  0x000000000000001c in ?? ()
#8  0x0000000000000003 in ?? ()
#9  0x00007fff911d1606 in ?? ()
#10 0x00007fff911d160b in ?? ()
#11 0x00007fff911d160e in ?? ()
#12 0x0000000000000000 in ?? ()

[1]+  Stopped                 nohup tail -f yy.log
```

图。。

也可以看到是 `stopped` 状态。

接着我在关闭会话时【我使用 XShell 的 ctrl + d 快捷键】，可以看到第一次提醒我有暂停的进程：`There are stopped jobs.`，第二次才真正退出。

图。。

接着重新登录使用 `ps` 工具查看进程输出信息如下：

```
[pengfei@dev2 ~]$ ps -ef |grep 'tail -f' |grep -v grep
pengfei   20331      1  0 01:45 ?        00:00:00 tail -f xx.log
```

图。。

使用上述步骤依次操作，可以发现 `nohup tail -f yy.log` 对应的进程已经不在了，尽管我手动给它设置了 `nohup`，也无济于事。而对于 `tail -f xx.log &` 对应的进程，我并没有手动设置 `nohup`，可以认定是操作系统的设置导致会话关闭时不会给后台进程发送 `SIGHUP` 信号，当前父进程已经是 `init`，这个可以理解。

【废弃】可以看到，进程仍旧处在 `stopped` 状态，而且根据上面 `ps` 工具查看的结果，父进程是 `init`【进程号是1】，所以使用 `jobs`、`fg`、`bg` 都是无效的，因此我也没有办法把它重新置于前台运行。

## 继续探索其它高效的工具

读者可以继续探索一下 `tmux` 工具的使用，这类工具可以更加高效、安全地帮助我们管理后台进程，从而让我们脱离手动管理后台程序的苦海。


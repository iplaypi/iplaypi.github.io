---
title: Linux 让进程在后台运行的几种方法
id: 2019051501
date: 2019-05-15 15:49:53
updated: 2019-06-08 15:49:53
categories: Linux 命令系列
tags: [Linux,nohup,setsid,disown,screen,daemon]
keywords: Linux,nohup,setsid,disown,screen,daemon
---


在 `Linux` 系统中，运行程序时经常需要把进程放在后台运行，并且退出终端等待，也可以说是守护进程，`daemon` 的概念，可能过几个小时或者十几个小时之后再去观察。此种场景，需要把进程放入后台运行，并且为了防止进程挂起，也需要设置进程忽略挂起信号【使用 `nohup` 命令】，这样就可以保证进程在我退出终端后仍旧能正常运行，无论我多久之后再来观察，仍可以看到进程的运行信息。本文记录关于进程后台运行【`daemon`】的几种方法，并给出实际的操作示例，属于入门级别。


<!-- more -->


# 回顾


在我刚刚开始步入社会时，算是一个职场新手，很多东西都不会，可以说是一张白纸。经过一路上走弯路、披荆斩棘，现在总算积累了一些经验。

记得在刚刚开始工作时，经常碰到这样的场景，使用 `telnet` 或者 `ssh` 登录了远程的 `Linux` 服务器【很多工作需要在 `Linux` 上面完成】，在上面跑了几个 `Shell` 脚本，或者起了几个 `Java` 进程，而且这些脚本或者进程耗时都比较长，可能需要几个小时或者几天。我一开始的做法就是打开 `XShell` 工具的多个会话窗口，分别跑脚本或者起进程，不仅不能关掉，而且还要时刻担心网络问题导致与 `Linux` 的会话断开，这样一切工作就白费了。

我在操作过程中被其他同事看到了，他们说我这种做法太蠢了，是在浪费生命。经过他们指点，其实可以使用后台挂起的命令【即 `nohup` 加上 `&`】，这样就可以让进程自由自在地在系统后台运行，我也可以安心地做其它事情了。

我第一次受到了经验方面的冲击，觉得这种方式太酷了，一开始我为什么不多思考一下、查询一下或者咨询一下同事。现在回想起来当时甚至都没有这方面的想法，只是知道埋头苦干，我想这些实用的知识点肯定还有很多，这也敦促了我从此以后我更加努力，多学多看多问。

在后来的工作或者生活当中，我又接触到了很多类似的知识点或者说是小技巧，不仅提高了我的工作效率，还丰富了我的认知。其中，基于进程的后台运行这个场景，还有很多很好的工具可以使用，而且还有很多实际操作的小技巧可以使用，以下的内容会一一介绍。

读者在继续阅读之前，最好先了解一下**信号**的概念，也可以直接参考我的另外一篇博文：[Linux 之 kill 命令入门实践](https://www.playpi.org/2019042101.html) ，里面会有一些入门级别的介绍。


# 前言


在工程师或者运维人员的职业生涯中，肯定会碰到这样的场景：使用 `ssh` 或者 `telnet` 登录了远程 `Linux` 服务器，然后在上面跑一些程序任务或者脚本。如果是临时任务或者几分钟就能搞定的任务，基本不会有什么问题，但是如果是耗时比较长的任务、需要在系统后台长期运行的任务，如果没有人为正确操作，就会因为网络不稳定或者手抖退出了连接会话，从而导致进程任务中断。最终还要从头再来，如果遇到这种问题，所有人都是崩溃的。

那么我不禁思考，有没有什么办法可以让进程任务在提交后不受网络中断、连接会话退出的影响呢，从而可以一直保持在后台稳定运行，直到结束。肯定是有的，读者在工作中一定也见过周围的技术大神同事操作，或者自己就是技术大神，下面列举一些常用的方式，读者可以参考，选择自己喜欢的方式使用。

内容中涉及到的 `SIGHUP` 信号，先来了解一下它的由来：

> 在 `Unix` 的早期版本中，每个终端都会通过 `modem` 和系统通信，当用户 `logout` 时，`modem` 就会挂断（hang up）电话。同理，当 `modem` 断开连接时，就会给终端发送 `hangup` 信号来通知其关闭所有子进程。这里的子进程包含前台子进程、后台子进程，前台子进程是被直接关闭的（如果被手动设置了 `nohup` 则除外），后台子进程要根据操作系统的 `huponexit` 设置而定，不一定会被关闭。其中，这里的后台子进程还会包括正在运行的子进程（使用 `jobs` 工具查看 处于 `running` 状态）、暂停的子进程（使用 `jobs` 工具查看 处于 `stopped` 状态，处于这个状态的子进程无论有没有被手动设置 `nohup` 都会被关闭）。

再看一下维基百科给它的定义：

> **nohup** is a POSIX command to ignore the HUP (hangup) signal. The HUP signal is, by convention, the way a terminal warns dependent processes of logout.
> Output that would normally go to the terminal goes to a file called nohup.out if it has not already been redirected.

下面简单总结一下终端会话退出时发生了什么：

- 当终端被挂断或伪终端程序被关掉，若终端的 `CLOCAL` 标志没有被设置，则 `SIGHUP` 信号会被发送到与该终端相关的控制进程【即会话首进程，通常为 `Shell`】
- 而 `SIGHUP` 的默认行为是终止程序的运行，当会话首进程终止，也会将 `SIGHUP` 信号发送给前台进程组中的每一个进程【根据 `Shell` 的具体实现，还可能会把 `SIGNHUP` 发送给后台进程组】


# 直接忽略挂起信号


众所周知，当发生用户注销会话、网络断开等事件时，终端会收到 `SIGHUP` 信号从而关闭其所有的子进程，它是通过把 `SIGHUP` 信号发送给所有子进程实现。当然，**前台**子进程如果没有设置忽略 `SIGHUP` 信号直接会停掉，如果设置了会继续运行【父进程会变化】。但是**后台**子进程除了人为设置可能还会因为操作系统的设置而忽略 `SIGHUP` 信号【所以有些人会觉得莫名其妙，怎么退出了再登录发现有些进程还在】，而且还要区分后台子进程的状态【使用 `jobs` 命令查看，处于 `running`、`stopped`等状态】。

梳理到这里，我就能想到两种解决方案：一是让进程忽略掉 `SIGHUP` 信号，二是让进程脱离会话父进程的运行，附属于其它父进程，从而不会接收到当前终端对应的进程发出的 `SIGHUP` 信号，这两种方法都可以让进程不受外界因素影响，稳定地运行。

下面逐一演示。

## nohup 方式

思路有了，我首先能想到的就是 `nohup` 工具，顾名思义，`nohup` 这个工具的作用就是让进程忽略掉所有的 `SIGHUP` 信号，不受它的影响。

`nohup` 的核心代码为：

```
signal (SIGHUP, SIG_IGN);

char **cmd = argv + optind;
execvp (*cmd, cmd);
```

让我们先来看一下帮助文档信息，使用 `man nohup` 命令查看：

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

![nohup 帮助文档信息](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20190831173014.png "nohup 帮助文档信息")

从中可以挑出重点信息查看：

```
nohup COMMAND [ARG]...
Run COMMAND, ignoring hangup signals.
If  standard  output is a terminal, append output to ‘nohup.out’ if possible,‘$HOME/nohup.out’ otherwise.
```

- 使用方式：在执行的任务命令前面加上 `nohup` 即可。
- 作用：可以让执行的进程忽略 `SIGHUP` 信号。也会关闭标准输入，该进程不能接收任何输入，即使运行在前台。
- 输出：在终端执行的进程，输出信息会重定向到 `nohup.out` 文件。

可见，`nohup` 的使用是十分简单方便的，标准输入被关闭，标准输出和标准错误默认会被重定向到 `nohup.out` 文件中，此文件会自动生成于执行命令的当前目录。

但是要注意，一般我会在命令结尾加上 `&` 来将任务进程放入后台运行【而且进程的 `stdin`、`stdout`、`stderr` 都脱离了终端会话，让它在前台运行似乎意义不大】，如果不加的话，进程会一直占用终端【其实就是标准输入一直等待终端的输入，一般等待30秒会释放】，这样就没法在当前会话窗口进行其它操作了。

这里需要注意一点，如果把进程放在后台运行，由于进程不再占用会话窗口，它的本质其实是不再从标准输入【`stdin`】读取输入参数指令，如果此时进程中有从标准输入读取指令的代码逻辑【只会得到 `EOF`】，会导致暂停【处于 `stopped` 状态】。因此，对于一些交互式的任务，肯定不适合放在后台运行，况且本来就是交互式任务【与前台用户交互】，还放在后台运行干什么。如果非要放在后台运行，可以在执行任务时加上输入重定向【注意不是输出重定向】：`nohup command < /dev/null &`，这样遇到读取输入的逻辑就不会暂停，但是可能会从 `/dev/null` 接收到一些奇怪的指令。

那么，为什么输出流没有这个问题呢，其实是 `nohup` 的功劳，它已经把标准输出、标准错误都重定向到 `nohup.out` 文件了。如果没有使用 `nohup`，而是直接执行 `command < /dev/null &`，同时退出了当前会话窗口【任务放在后台运行，退出会话不会影响任务继续运行】，则后台运行的任务已经失去了标准输出、标准错误这两个输出流。如果代码中有输出内容到标准输出或者标准错误的逻辑【例如打印日志】，会导致任务暂停【处于 `stopped` 状态】，但是当前会话窗口已经被关闭，进程找不到父进程，进而终止。所以，为了保证安全性，需要把输出信息输出到指定的文件，除了 `nohup` 默认的输出流，此时也可以使用 `command >filename 2>&1 &` 来更改默认的输出流，这样可以保证后台任务的正常运行，而且更方便观察每个进程的输出日志【全部输出到指定的文件】。

知识点绕的有点远了，言归正传，下面举一个例子，来演示 `nohup` 的使用：

```
1、nohup tail -f xx.log &，提交一个后台进程，忽略 SIGHUP 信号
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

![nohup 简单演示](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20190831173717.png "nohup 简单演示")

可以看到，进程已经不受 `SIGHUP` 信号的影响了，并没有被杀死，仍旧在运行中。因此，此时退出会话终端，对它也是没有影响的。

## setsid 方式

`nohup` 的秘密是什么，显而易见是通过忽略 `SIGHUP` 信号，使用户的进程避免被中断。这好像是具有很高权限的系统对进程说：你可以去死了，然而进程却不听，并捂住耳朵摇头：我不听！我不听！这种公然违抗系统指令的行为，使进程继续活下去，并可以自由自在地运行。

那其实不妨换一个角度思考，有没有可能不让系统发送 `SIGHUP` 信号，注意这里的含义是系统不会发送 `SIGHUP` 信号给进程，进程本身并没有忽略 `SIGHUP` 信号。

略加思考，我基本有了方案：让进程独立运行，不再属于当前会话的子进程，这样会话在关闭时不会再给这个进程发送 `SIGHUP` 信号【因为独立运行的进程不属于当前会话的子进程了，与当前会话无关】。

好，有一个工具可以帮到我，那就是 `setsid`，它的核心是 `setsid` 函数：

```
pid_t setsid(void);
```

先来看一下它的帮助信息，使用 `man setsid` 查看：

```
SETSID(1)                  Linux Programmer’s Manual                 SETSID(1)

NAME
       setsid - run a program in a new session

SYNOPSIS
       setsid program [arg...]

DESCRIPTION
       setsid runs a program in a new session.

SEE ALSO
       setsid(2)

AUTHOR
       Rick Sladkey <jrs@world.std.com>

AVAILABILITY
       The setsid command is part of the util-linux-ng package and is available from ftp://ftp.kernel.org/pub/linux/utils/util-linux-ng/.

Linux 0.99                     20 November 1993                      SETSID(1)
```

![setsid 帮助信息](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20190904010120.png "setsid 帮助信息")

可见，`setsid` 的作用就是在一个新的会话中启动进程，这样就可以保证启动的进程与当前会话无关。而且使用方法也很简单，只需要在命令前面加 `setsid` 即可，格式如：`setsid command` 。

执行示例：

```
1、setsid tail -f xx.log &> tail.log，提交进程，默认在后台运行
2、ps -ef |grep 'tail -f' |grep -v grep，查看进程的状态
3、退出当前会话
4、重新登录再查看进程的状态：ps -ef |grep 'tail -f' |grep -v grep
```

依次执行上述步骤，输出信息如下：

```
[pengfei@dev2 ~]$ setsid tail -f xx.log &> tail.log
[pengfei@dev2 ~]$ 
[pengfei@dev2 ~]$ ps -ef |grep 'tail -f' |grep -v grep
pengfei   53334      1  0 00:49 ?        00:00:00 tail -f xx.log
[pengfei@dev2 ~]$
...重新登录
[pengfei@dev2 ~]$ ps -ef |grep 'tail -f' |grep -v grep
pengfei   53334      1  0 00:49 ?        00:00:00 tail -f xx.log
[pengfei@dev2 ~]$
```

![setsid 示例演示](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20190904010155.png "setsid 示例演示")

可以看到，进程一直在运行，退出会话并没有影响到它。值得注意的是，这个进程的编号为53334，但是它的父进程编号却为1【即 `init` 进程】，并不是当前会话对应进程的编号，读者可以和上述的 `nohup` 作比较，可见 `setsid` 的作用就在此。

此时这个进程虽然在正常运行，退出当前会话也不会影响到它，但是它并没有忽略 `SIGHUP` 信号，所以还会受到 `SIGHUP` 信号的影响。不妨手动发送一个 `SIGHUP` 信号给它，再查看一下进程的状态。

```
kill -SIGHUP 53334，手动使用 kill 发送信号
ps -ef |grep 'tail -f' |grep -v grep，再查看进程的状态
```

依次执行上述步骤，输出信息如下：

```
[pengfei@dev2 ~]$ ps -ef |grep 'tail -f' |grep -v grep
pengfei   53334      1  0 00:49 ?        00:00:00 tail -f xx.log
[pengfei@dev2 ~]$ 
[pengfei@dev2 ~]$ 
[pengfei@dev2 ~]$ kill -SIGHUP 53334
[pengfei@dev2 ~]$ 
[pengfei@dev2 ~]$ ps -ef |grep 'tail -f' |grep -v grep
[pengfei@dev2 ~]$
```

![手动 kill 测试](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20190904010219.png "手动 kill 测试")

可见进程已经被杀死了，不复存在。

下面再简单介绍一下 `setsid` 的原理，核心在于 `pid_t setsid(void);` 函数。

首先需要了解一下两种调用场景。

如果调用 `setsid` 函数的进程不是一个进程组的组长，就会创建一个新会话，具体来说会经历下面三个流程：

- 该进程会变成新会话的会话首进程【会话首进程即创建该会话的进程】，此时新会话中只有该进程这么一个进程
- 该进程会变成一个新进程组的组长进程，新进程组 `PGID` 就是该进程的 `PID`
- 该进程与控制终端的联系被切断

如果调用 `setsid` 函数的进程本身就是一个进程组的组长，则该函数会返回出错。为了解决这种情况，通常函数需要先 `fork`，然后父进程退出，由子进程执行 `setsid`。由于子进程继承的是父进程的进程组 `PGID`，而其 `PID` 是新分配的 `ID`，因此这两者不可能相等，即子进程不可能是进程组的组长。在这种情况下，由于父进程先于子进程退出，因此子进程的父进程会由 `init` 进程【进程编号为1】接管。而这就是 `setsid` 命令的实现原理。

可以做一个简单的测试来观察一下 `setsid` 具体做了什么。首先编写一个测试程序，文件名为：`setsid_test.c`，源代码如下：

```
#include <unistd.h>
#include <stdio.h>

int main()
{
  pid_t sid=getsid(0);          /* 会话 id */
  pid_t pgrp=getpgrp();         /* 进程组id */
  pid_t ppid=getppid();         /* 父进程id */
  pid_t pid=getpid();           /* 进程ID */
  printf("会话id:%d\n进程组id:%d\n父进程id:%d\n进程id:%d\n",sid,pgrp,ppid,pid);
}
```

使用 `gcc` 编译器进行编译，执行 `gcc setsid_test.c -o setsid_test.out` 后，输出 `setsid_test.out` 可执行文件，然后运行可执行文件。

在 `Shell` 下直接运行【其实是通过 `bash` 进程来启动子进程】，使用：`./setsid_test.out`，输出内容如下【不妨再执行一次 `ps -f` 查看 `bash` 进程的信息】：

```
[pengfei@dev2 ~]$ ./setsid_test.out 
会话id:205689
进程组id:179572
父进程id:205689
进程id:179572
[pengfei@dev2 ~]$ 
[pengfei@dev2 ~]$ 
[pengfei@dev2 ~]$ ps -f
UID         PID   PPID  C STIME TTY          TIME CMD
pengfei  179660 205689  2 17:01 pts/2    00:00:00 ps -f
pengfei  205689 205681  0 15:10 pts/2    00:00:00 -bash
[pengfei@dev2 ~]$
```

![直接运行结果](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20190908172023.png "直接运行结果")

可以看到，启动的进程为179572，同时它也是这个进程组的组长，它的父进程是205689，从下面的输出可以看出205689进程即为 `bash` 进程。

接着在 `Shell` 下通过 `setsid` 运行，使用：`setsid ./setsid_test.out`，输出内容如下：

```
[pengfei@dev2 ~]$ setsid ./setsid_test.out 
[pengfei@dev2 ~]$ 会话id:198498
进程组id:198498
父进程id:1
进程id:198498
```

![通过 setsid 运行结果](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20190908172048.png "通过 setsid 运行结果")

对比这两个输出信息，读者会发现，`setsid` 新建了一个全新的会话，会话首进程是198498，而且其父进程变成了 `init` 进程【进程编号为1】。由于会话和父进程都与 `Shell` 无关，也就达到了不会接收到会话进程发送的 `SIGHUP` 信号的目的【当然，手动发送 SIGHUP 信号给进程，进程仍会正常接收】。

上文中涉及的 `c` 脚本已经被我上传至 `GitHub`，读者可以下载查看：[setsid_test](https://github.com/iplaypi/iplaypistudy/tree/master/iplaypistudy-normal/src/bin/20190515) ，脚本命名与上文中描述一致。

## & 方式

有些读者可能还知道有一个关于 `subshell` 的小技巧，将一个或多个命令包含在括号 `()` 中，就能让这些命令在子 `Shell` 中运行，从而扩展出很多有趣的功能，我在这里演示一下后台运行的功能。

将 `command &` 直接放入 `()` 中，读者就会发现提交的进程并不在作业列表中，也就是说，无法通过 `jobs` 来查看。这个现象背后的原因是什么呢，以及为什么这样就能躲过 `SIGHUP` 信号的影响呢？下面来演示一下。

先执行 `(tail -f xx.log &)` 命令启动进程，然后使用 `ps -ef |grep 'tail -f'` 查看进程的状态，输出信息如下：

```
[pengfei@dev2 ~]$ (tail -f xx.log &)
[pengfei@dev2 ~]$ 100

[pengfei@dev2 ~]$ ps -ef |grep 'tail -f'
pengfei   20009      1  0 17:35 pts/2    00:00:00 tail -f xx.log
pengfei   20742 205689  0 17:35 pts/2    00:00:00 grep tail -f
[pengfei@dev2 ~]$
```

![子 shell 演示结果](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20190908173857.png "子 shell 演示结果")

紧接着再使用 `jobs` 命令验证一下这个进程是否在当前会话终端进程的作业列表中【看不到任何进程的信息输出】：

```
[pengfei@dev2 ~]$ jobs
[pengfei@dev2 ~]$
```

![使用 jobs 查看](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20190908174319.png "使用 jobs 查看")

从上面的演示可以看出，新提交的进程的父进程为 `init` 进程，并不是当前会话终端进程，因此并不属于当前会话终端的子进程，从而也就不会收到当前会话终端的 `SIGHUP` 信号。

但是需要注意，使用 `(command &)` 的 `subshell` 方式，并不会改变子进程原本的输入流、输出流的状态，仍旧是继承自父进程，也就是会话终端，所以仍需要考虑进程与 `I/O` 的交互，避免出现问题。


# 忽略挂起的后悔药


通过前面的内容，读者已经知道，如果提交任务时，在命令前加上 `nohup` 或者 `setsid` 就可以避免 `SIGHUP` 信号的影响。但是如果我们未加任何处理就提交了命令，该如何补救才能让它避免 `SIGHUP` 信号的影响呢？

或者说，系统的 `Shell` 参数 `huponexit` 被设置为 `on`，此时会不会由此引发什么问题，需要我们注意呢？

以上这些考虑都是基于意外的情况，当然有时候读者可能也会遇到，下面给出解决的方法。

## 正常启动后台任务

有时候直接运行任务后，才发现没有手动设置忽略挂起【没有使用 `nohup`】，或者也没有使用 `setsid` 工具新建会话。已经运行了一段时间后，又不想停掉任务重新启动【如果参数 `huponexit` 设置为 `on`，会话进程在退出时就会给后台子进程发送 `SIGHUP` 信号，导致进程终止】，那么有没有可以事后弥补的方案呢？有，当然有。

以上情况重点在于忘记使用 `nohup`、`setsid` 等命令，由于这些命令与 `Shell` 无关【所以才需要在提交任务的命令前使用】，所以在提交任务后不可能再弥补，除非杀死进程重新启动。但是，我这里还有别的方案，这个工具就是 `bash` 的内置命令，它只能在 `bash` 下使用，它就是 `disown` 命令。

所以，此时可以通过 `disown` 工具来操作后台进程，先来看一下帮助文档，使用 `man disown` 命令查看：

```
disown [-ar] [-h] [jobspec ...]
              Without options, each jobspec is removed from the table of active jobs.  
              If jobspec is not present, and neither -a nor -r is supplied, the shell’s notion of the current job is used.  
              If the -h option is given, each jobspec is not removed  from  the table, but is marked so that SIGHUP is not sent to the job if the shell receives a SIGHUP.  
              If no jobspec is present, and neither the -a nor the -r option is supplied, the current job is used.  
              If no jobspec is supplied, the -a option means to remove or mark all jobs; the -r option without a jobspec argument restricts operation to running jobs. 
              The return value is 0 unless a jobspec does not specify a valid job.
```

![disown 帮助文档](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20190908220734.png "disown 帮助文档")

可以看出，我们可以用如下方式来达成我们的目的：

- 用 `disown -h jobspec` 将某个作业从 `jobs` 列表中移除
- 用 `disown -ah` 将所有的作业从 `jobs` 列表中移除
- 用 `disown -rh` 将正在运行的作业从 `jobs` 列表中移除

这样，当退出会话时，会话进程并不会将 `SIGHUP` 信号发送给被移除的进程【被移除的进程已经不在后台作业列表中】，因此这个被移除的进程可以一直在后台运行下去。

需要注意的是，当使用过 `disown` 之后，将把目标作业从 `jobs` 列表中移除，读者将不能再使用 `jobs` 命令来查看它，但是依然能够使用 `ps -ef` 查找到它。

然而，还要注意流的影响，使用 `disown` 并不会切断进程与会话终端的关联关系，这样当会话终端被关闭后，若进程尝试从 `stdin` 中读取或输出信息到 `stdout`、`stderr` 中，会导致异常退出，这点读者需要注意。

下面简单演示一下  `disown` 的使用，输入以及输出内容如下：

```
[pengfei@dev2 ~]$ tail -f xx.log &
[1] 141302
[pengfei@dev2 ~]$ 100

[pengfei@dev2 ~]$ jobs
[1]+  Running                 tail -f xx.log &
[pengfei@dev2 ~]$ 
[pengfei@dev2 ~]$ disown %1
[pengfei@dev2 ~]$ 
[pengfei@dev2 ~]$ jobs
[pengfei@dev2 ~]$
```

![disown 简单验证](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20190908221314.png "disown 简单验证")

可以看到，先启动一个后台任务，使用 `jobs` 还可以看到，接着使用 `disown` 将它移除，再使用 `jobs` 就看不到进程了。

如果退出会话，读者可能怀疑此时进程被杀死了吗，还是仍在运行，使用 `ps -ef |grep 'tail -f'` 查看便知，为了对比观察，在退出会话前后各查看一次。

```
退出会话前
[pengfei@dev2 ~]$ ps -ef |grep 'tail -f'
pengfei  141302 205689  0 22:11 pts/2    00:00:00 tail -f xx.log
pengfei  146581 205689  0 22:14 pts/2    00:00:00 grep tail -f
[pengfei@dev2 ~]$ 
[pengfei@dev2 ~]$ exit
logout
Connection closing...Socket close.

Connection closed by foreign host.

重新登录
[pengfei@dev2 ~]$ ps -ef |grep 'tail -f'
pengfei  141302      1  0 22:11 ?        00:00:00 tail -f xx.log
pengfei  153383 198673  0 22:17 pts/1    00:00:00 grep tail -f
[pengfei@dev2 ~]$
```

![退出会话前查看](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20190908222344.png "退出会话前查看")

![退出会话后查看](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20190908222353.png "退出会话后查看")

从上图可以看到，进程141302无论是在退出会话前还是在退出会话后，一直在运行，说明退出会话对进程没有影响，唯一的影响就是父进程变化了，退出会话后父进程由 `init` 进程接管。

## 直接启动前台任务

还有一种场景，如果在启动进程时没有使用 `&` 将进程放在后台运行，占用着当前的会话窗口，一不小心就会导致进程终止，那怎么办？其实也很简单。

使用 `Ctrl + z` 命令，把正在前台运行的进程暂停，并放在后台，程序并没有被杀死。其实这个组合快捷键是一种控制信号，编号为`19`，标识为 `SIGSTOP`，读者可以参考我的另外一篇博文：[Linux 之 kill 命令入门实践](https://playpi.org/2019042101.html) 。当然，如果使用终端工具，再开一个会话窗口，使用 `ps` 命令查询这个进程的 `pid` 编号，然后使用 `kill -19 pid` 命令发送一个 `SIGSTOP` 信号给进程也可以达到把程序暂停并放在后台的效果【不过肯定没有快捷键方便了】。

然后读者就可以使用 `jobs` 命令来查询它的作业编号，紧接着使用 `bg job_num` 就可以把这个进程放在后台运行了【由 `stopped` 状态变为 `running` 状态】。

但是需要注意的是，如果暂停进程会影响当前进程的运行结果，所以慎用此方法。

只要放在了后台运行，就可以继续使用 `disown` 命令将它从作业列表中移除了，下面简单演示一下，以下为输入与输出信息：

```
[pengfei@dev2 ~]$ tail -f xx.log
100
^Z
[1]+  Stopped                 tail -f xx.log
[pengfei@dev2 ~]$ 
[pengfei@dev2 ~]$ jobs
[1]+  Stopped                 tail -f xx.log
[pengfei@dev2 ~]$ 
[pengfei@dev2 ~]$ bg 1
[1]+ tail -f xx.log &
[pengfei@dev2 ~]$ 
[pengfei@dev2 ~]$ jobs
[1]+  Running                 tail -f xx.log &
[pengfei@dev2 ~]$ 
[pengfei@dev2 ~]$ disown %1
[pengfei@dev2 ~]$ 
[pengfei@dev2 ~]$ jobs
[pengfei@dev2 ~]$ 
[pengfei@dev2 ~]$ ps -ef |grep 'tail -f'
pengfei   29540 198673  0 23:20 pts/1    00:00:00 tail -f xx.log
pengfei   30418 198673  0 23:20 pts/1    00:00:00 grep tail -f
[pengfei@dev2 ~]$
```

![前台任务到后台任务演示](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20190908232405.png "前台任务到后台任务演示")

可见，启动进程时没有把它放在后台运行，先使用 `ctrl + z` 快捷键将它放在后台【处于 `stopped` 状态】，再使用 `bg` 使它运行【处于 `running` 状态】，紧接着就可以正常使用 `disown` 将它从 `jobs` 列表移除了。


# 批量管理进程


前面的描述都是单个进程或者几个进程，管理起来也挺方便，但是如果遇到大量的进程需要管理，例如运维人员日常需要手动管理大量的进程，几百个几千个都是有可能的，那么怎么办呢，如果每次都需要这么操作【使用 `nohup`、`setsid`等等】很麻烦。为了简化管理，并且保证进程能在后台稳定运行，此时就需要通过 `screen` 工具来操作，对于进程的后台运行，以及会话的模拟，这是一个利器。

## 功能使用

简单概括来说，`screen` 提供了 `ANSI/VT100` 的终端模拟器，使它能够在一个真实终端下运行多个全屏的伪终端【它的思路就是终端复用器，即 `terminal multiplexer`】。

它可以在当前 `session` 里面，新建另外一个 `session`，这样的话，当前 `session` 一旦结束，并不影响其它 `session`。而且，以后重新登录，还可以再连上早先新建的 `session`。

`screen` 的参数很多，具有很强大的功能，我在此仅介绍其常用的功能以及简要分析一下为什么使用 `screen` 能够避免 `SIGHUP` 信号的影响。

首先我们来看一下帮助文档信息，使用 `man screen` 命令输出：

```
SCREEN(1)                                                            SCREEN(1)

NAME
       screen - screen manager with VT100/ANSI terminal emulation

SYNOPSIS
       screen [ -options ] [ cmd [ args ] ]
       screen -r [[pid.]tty[.host]]
       screen -r sessionowner/[[pid.]tty[.host]]

DESCRIPTION
       Screen  is  a full-screen window manager that multiplexes a physical terminal between several processes (typically interactive shells).
       Each vir-tual terminal provides the functions of a DEC VT100 terminal and, in addition, several control functions from the ISO 6429 (ECMA 48,  ANSI  X3.64)
and  ISO  2022 standards (e.g. insert/delete line and support for multiple character sets).
There is a scrollback history buffer for each virtual terminal and a copy-and-paste mechanism that allows moving text regions between windows.
```

![screen 帮助文档](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20190911011009.png "screen 帮助文档")

由于信息比较多，只截取了其中一部分。总之，使用 `screen` 很方便，有以下几个常用选项：

- screen，建立一个会话，并登录【在此会话下可以不使用 nohup、setsid 等工具，退出会话后不影响进程的运行】
- screen -dm，建立一个处于断开模式下的会话【detached mode】
- screen -dmS session_name，建立一个处于断开模式下的会话【参数 S 用来指定其会话名】
- screen -list，列出所有的会话【或者参数也可以是 -ls，一样的效果】
- screen -r session_name，重新连接指定会话【指定会话名字，如果有重名的会话，需要同时带上pid_number前缀】
- screen -r pid_number，重新连接指定会话【指定会话编号】
- 快捷键 ctrl + a、ctrl + d，暂时退出当前会话【不影响会话的状态，会话并没有关闭，还可以重新登录】
- 快捷键 ctrl + c、ctrl + d，终止当前会话【会话不存在，里面的进程也就不存在了】

上面列出了一些常用的功能，下面就开始简单演示一下。

先新建一个名字为 `s1` 的会话，然后列出所有的会话，按照如下命令操作：

```
[pengfei@dev2 ~]$ screen -dmS s1
[pengfei@dev2 ~]$ 
[pengfei@dev2 ~]$ screen -ls
There is a screen on:
	17651.s1	(Detached)
1 Socket in /tmp/uscreens/S-pengfei.
[pengfei@dev2 ~]$
```

![screen 新建会话](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20190914023446.png "screen 新建会话")

可以看到，我新建了一个处于断开模式的会话 `s1`，如果我用 `-r` 参数连接到 `screen` 创建的 `s1` 会话后，我就可以在这个伪终端里面放心大胆地启动进程，再也不用担心 `SIGHUP` 信号会对我的进程造成影响，也不用给每个命令前都加上 `nohup` 或者 `setsid` 了。这是为什么呢？来看一下下面两个对比的例子吧。

1、在 `s1` 会话里面启动一个后台进程，并查看进程树，按照如下命令操作：

```
[pengfei@dev2 ~]$ screen -r s1
[pengfei@dev2 ~]$ tail -f xx.log &
[1] 45061
[pengfei@dev2 ~]$ 100

[pengfei@dev2 ~]$ pstree -H 45061 |grep 'tail\|screen\|init'
init-+-abrt-dump-oops
     |-screen-+-bash-+-grep
     |        |      `-tail
     |      |-sshd---sshd---bash---screen
[pengfei@dev2 ~]$
```

![使用 screen 会话启动进程](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20190914023453.png "使用 screen 会话启动进程")

可以看到，使用了 `screen` 后进程树有一些特殊，此时 `bash` 是 `screen` 的子进程，而 `screen` 是 `init`【进程号为1】的子进程。那么，当 `ssh` 断开会话连接时，`SIGHUP` 信号自然不会影响到 `screen` 下面的子进程。

2、在当前登录的会话里面启动一个后台进程，并查看进程树，按照如下命令操作：

```
[pengfei@dev2 ~]$ tail -f xx.log &
[1] 61916
[pengfei@dev2 ~]$ 100

[pengfei@dev2 ~]$ 
[pengfei@dev2 ~]$ pstree -H 61916 |grep 'tail\|screen\|init\|bash'
init-+-abrt-dump-oops
     |-bash---java---186*[{java}]
     |-sshd-+-sshd---sshd---bash
     |      |-sshd---sshd---bash-+-grep
     |      |                    `-tail
     |      `-sshd---sshd-+-2*[bash]
     |                    `-bash---java---37*[{java}]
[pengfei@dev2 ~]$
```

![在当前登录会话启动进程](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20190914023457.png "在当前登录会话启动进程")

可以看到，未使用 `screen` 而是直接在当前会话启动进程时，我所处的 `bash` 是 `sshd` 的子进程，当 `ssh` 断开连接时，`sshd` 进程关闭，`SIGHUP` 信号自然会影响到它下面的所有子进程【当然也包括我新建立的 `tail` 进程】。

通过对比这两种启动进程方式，读者可以发现，`screen` 的作用就在于新建会话，在 `screen` 会话中启动的进程与**当前登录会话**无关，这样无论什么时候，都不会影响 `screen` 会话中的进程，除非手动终止 `screen` 会话。而且，无论什么时候登录，还可以继续连接 `screen` 会话，并管理里面的进程，很方便。

## 关于安装

`screen` 的安装比较简单，如果是 `root` 用户，直接使用 `yum install screen` 即可一键安装完成【不同的操作系统类型使用的命令会不一样】，安装过程在此不需要赘述。但是如果是非 `root` 用户或者在网络无连接的情况下，则不能直接一键安装，需要使用源码编译安装的方式进行安装，过程比较繁琐，而且也容易出现各种各样的错误，主要是依赖环境不完整的问题。

下面列举常规的安装步骤：

1、下载 `screen` 源码包，地址在这里：[screen 源码包](http://ftp.gnu.org/gnu/screen) ，选择最新的版本。

2、解压、配置、编译、安装流程。

```
# 解压
tar -zxvf screen-4.6.2.tar.gz
# 配置,如果是非root用户需要自定义安装目录,即prefix参数
./configure --prefix=/home/pengfei/soft/screen
# 编译
make
# 安装
make install
```

注意在 `configure` 阶段可能会出错：`no tgetent - no screen`，错误原因就是缺少 `ncurses` 依赖环境，需要再次单独安装。

```
# 错误信息
configure: checking libncurses...
configure: checking libtinfo...
configure: error: !!! no tgetent - no screen
```

3、安装 `ncurses`，先去下载源码包，地址在这里：[ncurses 源码包](http://ftp.gnu.org/gnu/ncurses) ，选择最新的版本。

4、解压、配置、编译、安装流程。

```
# 解压
tar -zxvf ncurses-6.1.tar.gz
# 配置,如果是非root用户需要自定义安装目录,即prefix参数
# 指定安装目录时注意结尾不要带文件分隔符/,否则ncurses在创建文件目录时会创建一个错误的目录
# 例如bin目录:/home/pengfei/soft/ncurses//bin,它会自动在指定的目录后面追加/bin,从而导致/出现两次
# 这点在配置完成之后的日志输出中也可以看到
# 如果在输出日志中看到Include-directory is not in a standard location,这并不是一个错误,可以添加--enable-overwrite参数避免
./configure --prefix=/home/pengfei/soft/ncurses
# 编译
make
# 安装
# 安装如果出错,可以在配置时指定多个参数
# ./configure --prefix=/home/pengfei/soft/ncurses --with-shared --without-debug --without-ada --enable-overwrite
make install
```

5、回到 `screen` 解压目录，继续安装，这里需要注意设置两个全局变量。

```
# 编译器选项
# 链接相关选项,如果你有自定义的函数库(lib dir),即可以用-L<lib dir>指定
export LDFLAGS=-L/home/pengfei/soft/ncurses/lib
# 预编译器选项
# C/C++预处理器选项,如果你自定义的头文件,可以用-I<include dir>
export CPPFLAGS=-I/home/pengfei/soft/ncurses/include
```

6、安装完成后配置环境变量，全局可用，在家目录的 `.bashrc` 文件里设置 `screen` 执行路径：

```
export PATH=/home/pengfei/soft/screen/bin:$PATH
```

紧接着执行 `source ~/.bashrc` 更新 `PATH` 路径，以后在终端输入 `screen` 就能进入 `screen` 界面了。

7、我的安装总结，我在三台服务器上面尝试使用编译源码的方式安装，都出现各种各样的诡异错误，我也不是搞服务器端应用开发的，有些问题实在解决不了，折腾了一天最终放弃了，还是直接使用 `root` 用户一键安装比较快捷。

错误一，`screen` 配置过程报错，通过安装 `ncurces` 解决。

![screen 配置过程报错](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20190913221335.png "screen 配置过程报错")

错误二，`ncurses` 安装过程报错，通过添加配置的参数重新来过解决。

![ncurses 安装过程报错](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20190913221441.png "ncurses 安装过程报错")

错误三，`screen` 配置过程继续报错，已经和 `ncurces` 无关，找不到问题原因。

![screen 配置过程继续报错](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20190913221345.png "screen 配置过程继续报错")

错误四，`screen` 安装过程报错，找不到问题原因。

![screen 安装过程报错](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20190913221433.png "screen 安装过程报错")


# 简单总结


以上内容把几种方法已经介绍完毕，读者可以根据不同的场景来选择不同的方案。`nohup`、`setsid`、`&` 无疑是临时需要时最方便的方法，`disown` 能帮助我们来事后补救已经在运行的作业，而 `screen` 则是在大批量操作时不二的选择。


# 前台任务与后台任务


本文中涉及了这两个概念：**前台任务**【`foreground job`】、**后台任务**【`background job`】，并且很多示例演示也离不开这两个概念，读者如果不了解这两个概念，就会对很多内容看的云里雾里，所以有必要总结一下。

下面会对这两个概念做一些总结介绍，以加深读者的认识，达到知其然知其所以然的地步。

## 前台任务

如果直接启动一个进程或者脚本，例如 `sh example.sh`、`python example.py`、`java example.jar` 等，都可以提交一个**前台任务**。它会独自占用当前的会话窗口【输入流、输出流】，导致在当前会话窗口什么都不能做【要么开启其它会话窗口继续操作、要么暂停当前任务、要么终止当前任务】，只有等它运行完成或者被用户手动终止，用户才能继续在当前会话窗口进行各种操作。

## 后台任务

提交**后台任务**的方法很简单，在前台任务的提交命令末尾加上 `&` 符号，例如 `sh example.sh &`、`python example.py &`、`java example.jar &` 等，就表示把当前进程放在后台运行，变成后台任务，也可以说是守护进程【`daemon`】。这种类型的任务不会再占用当前会话窗口，用户可以继续进行其它操作【如果没有对输出做重定向的话，任务的输出信息仍旧会出现在窗口屏幕上，用户会时不时看到输出内容，不要觉得奇怪】。

后台任务有两个特点：

- 继承当前会话（session）的标准输出（stdout）、标准错误（stderr），因此，后台任务的所有输出仍然会同步地在当前会话窗口中显示（可见，如果关闭当前会话窗口，会引起任务暂停，但是由于父进程不存在，任务进而终止退出）。
- 不再继承当前会话（session）的标准输入（stdin），因此，用户无法再向这个任务输入参数指令了，如果任务试图去读取标准输入（可能代码中有这个逻辑），任务就会暂停执行（只是暂停，即 stopped 状态，不是终止）。

可以看到，**后台任务**与**前台任务**的本质区别只有一个，那就是是否继承当前会话【`session`】的标准输入。从这个区别不难理解，在执行后台任务时，会话窗口没有被占用，用户可以继续在当前会话窗口进行其它操作。而在执行前台任务时，会话窗口被占用，用户无法继续使用这个会话窗口。

## 状态互换

其实，**前台任务**和**后台任务**可以非常自如地切换，以满足用户的各种使用场景，否则就会显得难以使用。上文中已经非常详细地演示了几种方式，下面总结列举出来：

- 添加 `&` 方式，可以非常简单地把前台任务变为后台任务
- 针对后台任务，可以使用 `fg job_num` 调取出来，变为前台任务
- 使用 `setsid`，把任务变为另一个新会话进程的子进程，并且放在后台运行【但是使用 `jobs` 无法查看，也无法使用 `fg`、`bg` 等命令操作】
- 对于正在运行的前台任务，贸然地使用 `ctrl + c` 会导致任务终止，此时可以使用 `ctrl + z` 暂停任务【任务状态被置为 `stopped`】，然后使用 `bg job_num` 把任务放在后台运行【任务状态被置为 `running`】
- 对于当前进程下的子进程，即 `jobs` 列表，可以使用 `disown` 把子进程移除，变为 `init` 进程的子进程
- 使用 `(command &)` 的 `subshell` 方式把启动的进程变为 `init` 进程的子进程


# 总结 SIGHUP 信号的问题


关于后台任务在会话【`session`】退出后，再次登录，为什么有的人看到任务还在运行，有的人看到任务已经终止，这是玄学吗，根本原因是什么呢？要想了解根本原因，必须先了解 `SIGHUP` 信号的知识点，以及 `Linux` 系统关于给后台任务发送信号的规则设置。

看看 `Linux` 系统是怎么设计的：

- 用户准备退出会话【`session`】
- 用户退出会话，系统向该会话发送 `SIGHUP` 信号
- 会话把 `SIGHUP` 信号发送给所有子进程【包括前台子进程、后台子进程】
- 子进程收到 `SIGHUP` 信号后，自动退出

根据这个流程，首先可以明白为什么前台子进程会随着会话的关闭而终止，就是因为前台子进程收到了会话发送的 `SIGHUP` 信号，不得不终止。

那么后台子进程呢，看起来也会收到 `SIGHUP` 信号，为什么上文在演示时后台子进程不会被终止呢，有什么蹊跷吗？其实，会话在关闭前是否发送给子进程 `SIGHUP` 信号还会受到一个参数的限制，那就是 `Shell` 的 `huponexit` 参数，在 `Linux` 系统中可以使用 `shopt | grep huponexit` 命令查看。

![huponexit 参数查看](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20190901235345.png "huponexit 参数查看")

可以看到，在我的 `Linux` 系统中，这个参数的设置是 `off`，是关闭的，也就是会话在退出前不会把 `SIGHUP` 信号发送给后台子进程。

其实，在大多数 `Linux` 系统中，这个参数的值都是默认设置为 `off`，这样的话，在会话退出的时候，不会把 `SIGHUP` 信号发送给后台子进程，则后台子进程也就不会随着会话的退出而终止了【但是处于 `stopped` 状态的后台子进程仍旧会终止】。这也是读者在自己的操作系统测试时，可能会见到不同的现象的根本原因，所以觉得奇怪的读者可以查看自己的设置。


# 输入流输出流的问题


为了讲清楚让进程在后台运行的几种方法，上面的内容除了描述 `SIGHUP` 信号的问题，还夹杂着输入流、输出流的问题。其实，除了 `SIGHUP` 信号的影响，输入流、输出流也会影响着任务的运行状态，有时候虽然躲过了 `SIGHUP` 信号的攻击，但是却一不小心败给了输入流、输出流。

## 输入流

如果进程的代码逻辑中需要读取用户输入的指令，例如从键盘中读取指令，再执行对应的操作，这种询问应答的交互模式很常见。这里面就涉及了输入流的概念，进程需要一个输入流用来传输用户的指令，默认就是标准输入，即 `stdin` 。

## 输出流

如果进程的代码逻辑中需要输出信息，例如打印日志，输出报错信息，这里就涉及了输出流的概念，默认有两个，分别是：标准输出、标准错误，即 `stdout` 与 `stderr`。

## 总结

为了演示输入流、输出流的影响，在这里只考虑一种特殊的场景：用户退出会话【`session`】。此时，进程会受到 `SIGHUP` 信号的影响，前面已经详细说明并且演示，假设进程躲过了所有的 `SIGHUP` 信号并一直保持正常运行。

那么问题来了，如果这个正常运行的进程与 `标准 IO` 有交互的话，它还是会终止，可能不是立即终止，只有执行到与 `标准 IO` 进行交互的代码才会终止。读者是不是很惊讶，其实这与前台任务、后台任务的流继承有关，前面已经详细说明了，下面会举一个更具体的例子。

后台任务【使用 `&`】的输入流、输出流继承自当前会话进程，即分别为：`stdin`、`stdout`、`stderr`，如果使用其它工具操作，会改变流的状态，例如使用 `nohup`【关闭 `stdin`，重定向 `stdout`、`stderr`】、`disown`【不改变流的状态】、`setsid`【切断流与会话终端的联系】、`(command &)`【不改变流的状态】。

假如有一个任务，使用 `nohup command &` 执行，然后退出当前会话。我来分析一下：输出默认被重定向到 `nohup.out` 文件，忽略 `SIGHUP` 信号，任务放入后台运行，看起来是不是很完美。

但是如果任务与标准输入有交互，即需要从 `stdin` 读取指令，那么就完了。由于会话已经被关闭，`stdin` 已经不存在【况且 `nohup` 已经把进程的 `stdin` 关闭了】，任务会先进入 `stopped` 状态，紧接着退出。【即使用户不退出会话，任务也会永久处于 `stopped` 状态，无法再次激活正常运行】

如果任务与标准输出有交互，不需要多虑，因为 `nohup` 已经默默地把输出重定向到文件了。

如果在进程的代码中，就是存在与输入流、输出流的交互，有没有什么办法可以彻底解决问题，当然，就是重定向这个利器，除了把输出流重定向之外，也要把输入流重定向，使用形如 `command > stdout.txt 2> stderr.txt < /dev/null &` 这个格式的命令启动任务即可，不会再有问题。

如果启动任务使用的是 `setsid command &` 命令，需要特别考虑输入流、输出流这个问题，因为 `setsid` 在启动进程后，父进程变更为 `init` 进程，而且中间还有几步操作【子进程、新建会话、`init` 托管】。无论退出会话与否，输入流、输出流都已经被切断，进程无法与 `I/O` 交互。【但是我测试发现，脚本代码中如果有输入处理逻辑，进程会卡住；如果有输出处理逻辑，进程会正常把信息输出到当前会话窗口。如果关闭会话窗口则看不到输出，但是也不影响进程的正常运行，状态仍旧是 `running`，父进程变为 `init`。这说明输出流变更在关闭会话后才生效，如果没有关闭会话仍旧是 `stdout`，我没有找到相关资料，这个问题的根本原因暂时存疑。】

如果使用 `disown` 命令把后台的进程从 `jobs` 列表中移除，不会改变进程原本的输入流、输出流的状态，所以需要考虑进程与 `I/O` 的交互，避免出现问题。

如果使用 `(command &)` 的 `subshell` 方式，不会改变子进程原本的输入流、输出流的状态，继承自父进程，也就是会话终端，仍需要考虑进程与 `I/O` 的交互，避免出现问题。


# 备注


## 关于挂起的测试

我使用 `XShell` 测试退出终端时，发现并不会挂起普通的后台子进程【说明后台子进程没有接收到 `SIGHUP` 信号，或者接收到但是忽略了】，反而把进程的父进程设置为了 `init`【进程号为1】，这样进程就不会退出，下次登录的时候还能查看。但是这个现象违反了前面的知识点：退出终端会话时所有子进程会收到 `SIGHUP` 信号，后来我发现，原来这个操作是针对**前台任务**而言的，如果是**后台任务**则不一定，要看系统的参数设置：`shopt | grep huponexit`，`huponexit` 这个参数决定了是否向后台任务发送 `SIGHUP` 信号。而在大多数 `Linux` 系统中，这个参数一般默认是关闭的【取值为 `off`】，所以才出现了终端会话退出后后台子进程没有挂起的现象。

这里面还有两个有趣的现象。

### 前台任务

一是**前台任务**如果被人为设置了 `nohup`，则在会话关闭时会忽略掉 `SIGHUP` 信号，从而一直保持运行。下面演示一下。

```
1、tail -f xx.log &> tail.log【加输出重定向是为了排除输出流的影响】
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

![子进程仍旧存在](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20190902000501.png "子进程仍旧存在")

使用上述步骤依次操作，可以发现 `nohup tail -f yy.log` 对应的进程还在【父进程号已经变更为1，表示 `init` 进程】，而 `tail -f xx.log` 对应的进程已经不在了，这就是因为前者在执行命令时手动添加了 `nohup`，从而可以保障不受因会话关闭发送的 `SIGHUP` 信号影响，而后者直接被杀死。

读者可能会怀疑这个没被杀死的进程是处于运行状态吗【`running`】，会不会处于暂停状态【`stopped`】，这个很容易证明，直接使用 `pstack` 工具可以查看：`pstack pid`。例如我这里的进程号是199496 ，则使用 `pstack 199496` 查看。

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

![使用 pstack 验证进程状态](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20190902000522.png "使用 pstack 验证进程状态")

可以看到，进程仍旧在运行中，如果是暂停状态的进程，会显示 `stopped` 标记，下面的例子会演示这个，请读者继续往下看。

### 后台任务

二是**后台任务**如果处于 `stopped` 状态，无论有没有设置 `nohup`，在会话关闭或者网络断开时，进程会被杀死。而如果是处于 `ruuning` 状态，无论有没有设置 `nohup`，在会话关闭或者网络断开时，进程都不会被杀死。出现这个现象的原因是会话在退出时不会向子进程发送 `SIGHUP` 信号，则处于 `running` 的子进程仍旧运行，只不过父进程会变更为 `init`，而处于 `stopped` 状态的子进程因为父进程的退出而退出。下面举两个例子演示一下。

```
1、tail -f xx.log &> tail.log &，这里只是简单后台运行，并没有设置 nohup，所以发送 SIGHUP 信号可以杀死进程，加输出重定向是为了排除输出流的影响
2、断开网络或者关闭会话窗口
3、nohup tail -f yy.log，然后使用 ctrl + z 暂停任务，状态处于 stopped，并置于后台
4、使用 jobs 工具查看进程状态
5、断开网络或者关闭会话窗口
6、重新登录，使用 ps 工具查看进程：ps -ef |grep 'tail -f' |grep -v grep
```

在执行第二个任务时，可以在关闭会话前使用 `jobs` 工具查看进程状态，输出信息如下，可见是 `stopped` 状态：

```
[pengfei@dev2 ~]$ nohup tail -f yy.log
nohup: ignoring input and appending output to `nohup.out'
^Z
[1]+  Stopped                 nohup tail -f yy.log
[pengfei@dev2 ~]$ 
[pengfei@dev2 ~]$ jobs
[1]+  Stopped                 nohup tail -f yy.log
```

![使用 jobs 查看后台任务](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20190902001410.png "使用 jobs 查看后台任务")

或者再次使用上面的 `pstack` 工具查看：`pstack pid`，我这里的进程号是98537 ，则使用 `pstack 98537` 查看。

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

![使用 pstack 查看后台任务](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20190902001454.png "使用 pstack 查看后台任务")

也可以看到是 `stopped` 状态。

接着我在退出会话时【我使用 `XShell` 的 `ctrl + d` 快捷键，或者使用 `layout` 命令】，可以看到第一次退出时系统会提醒我有暂停的进程：`There are stopped jobs.`，继续再执行一次退出，第二次才真正退出。

![layout 两次的提示](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20190902001829.png "layout 两次的提示")

接着重新登录并使用 `ps` 工具查看进程输出信息如下：

```
[pengfei@dev2 ~]$ ps -ef |grep 'tail -f' |grep -v grep
pengfei   20331      1  0 01:45 ?        00:00:00 tail -f xx.log
```

![使用 ps 查看进程](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20190902001703.png "使用 ps 查看进程")

使用上述步骤依次操作，可以发现 `nohup tail -f yy.log` 对应的进程已经不在了，尽管我手动给它设置了 `nohup`，也无济于事。而对于 `tail -f xx.log &> tail.log &` 对应的进程，我并没有手动设置 `nohup`，进程仍旧在运行，这里可以认定是，操作系统的设置导致会话关闭时不会给后台子进程发送 `SIGHUP` 信号，当前父进程已经是 `init`，这个可以理解。

## 继续探索其它高效的工具

读者可以继续探索一下 `tmux` 工具的使用，这类工具可以更加高效、安全地帮助我们管理后台进程，从而让我们脱离手动管理后台进程的苦海。


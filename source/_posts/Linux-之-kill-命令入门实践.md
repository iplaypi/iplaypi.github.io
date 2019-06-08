---
title: Linux 之 kill 命令入门实践
id: 2019042101
date: 2019-04-21 22:35:27
updated: 2019-04-21 22:35:27
categories: Linux 命令系列
tags: [Linux,kill,jobs]
keywords: Linux,kill,jobs
---


最近在实际应用场景中，需要使用 Linux 系统的 **kill** 命令来控制程序的生命周期，例如 **ctrl + c**、**ctrl + z**、**kill -9 pid** 等，而这些命令在日常的工作当中也是非常常见的并且很好用。为了多了解一些 Linux 中信号常量的知识点，以及 kill 命令的基本原理，我整理了这一篇博客。

<!-- more -->


# 基础知识


## 信号

根据 kill 的实际使用来初步了解一下信号的概念。

首先要清楚一个基本知识点：kill 命令只是用来向进程发送信号的，而不是直接杀死进程的，实际操控进程生命的仍旧是系统内核以及信号常量的规范动作【进程本身注册的信号动作：默认、忽略、捕捉自定义】。

> kill 命令使用户能够向进程发送信号，信号是发送给进程以中断进程并使其作出反应的信息。如果进程被设计为对发送给它的该类型信号作出反应，则它将作出反应；否则，该进程将终止。

对于进程对信号做出正常反应的情况，例如对一个进程发送编号为9的信号，则该进程会终止。而对一个进程发送编号为19的信号【SIGSTOP】，则该进程会退到后台暂停，接着使用编号为18的信号【SIGCONT】可以激活进程继续运行【也可以直接使用 fg / bg 这一对命令】。

对于进程不能对信号做出反应而终止的情况，例如对一个进程发送编号为10的信号【SIGUSR1】，这个信号本来是给用户自定义的，而普通的进程没有被设计为对这个信号做出反应，因此进程将终止运行【另一方面，在 PHP 中，后台进程会对这个信号做出反应，是因为官方发布的程序实现了这个信号的指令，并为进程注册了这个信号】。

> 对于 Linux 来说，实际上信号是软中断，许多重要的程序都需要处理信号。信号，为 Linux 提供了一种处理异步事件的方法。

每个信号都有一个名字和编号，这些名字都以 **SIG** 开头，例如 **SIGINT**、**SIGKILL** 等等。信号定义在 **signal.h**【/usr/include/asm/signal.h】头文件中，信号编号都定义为正整数，从1开始。当然，也有编号为0的信号，但是它对于 kill 有特殊的应用。

使用 ** kill -l** 可以查看所有的信号常量列表，其中，前面32个是基本的，后面32个是扩展的【做底层驱动开发时能用到】。
![kill 命令查看信号常量](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20190518213523.png "kill 命令查看信号常量")

## 常用信号常量

以下列举一些常用的信号常量以及解释说明：

| 信号编号 | 信号名称 | 信号解释 |
| :------: | :------: | :------: |
| 1 | SIGHUP | 挂起信号【hang up】，终端断线，经常在退出系统前使用，会终止进程。但是，一般启动程序时为了让程序继续运行，会指定 nohup 就是为了不让程序接收挂起信号而终止，这样在退出系统时程序仍旧能正常运行 |
| 2 | SIGINT | 中断【与键盘快捷键 ctrl + c 对应】，表示与键盘中断 |
| 3 | SIGQUIT | 退出【与键盘快捷键 ctrl + \ 对应】 |
| 9 | SIGKILL | 强制终止，程序必须终止【无需清除】，只有进程属主或者超级用户发出该命令时才起作用 |
| 15 | SIGTERM | 停止，要求进程自己退出【需要先清除】，所以可能停止失败，只有进程属主或者超级用户发出该命令时才起作用 |
| 10 | SIGUSR1 | 用户自定义信号1 |
| 11 | SIGSEGV | 段错误信号，在操作内存、硬盘资源出错时会出现，例如硬盘空间不足、内存读取无权限时 |
| 12 | SIGUSR2 | 用户自定义信号2 |
| 18 | SIGCONT | 继续【与命令 fg/bg 对应，搭配 jobs 一起使用】 |
| 19 | SIGSTOP | 暂停【与键盘快捷键 ctrl + z 对应】，可以使用信号18来继续运行，或者使用 fg/bg 来调度到前/后台继续运行【搭配 jobs 一起使用】 |

也可以在 Linux 机器上面使用 **man 7 signal** 可以查看帮助文档，有更为详细的解释说明。
![man 7 signal 查看帮助文档](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20190518213623.png "man 7 signal 查看帮助文档")

在所有的信号中，只有编号为9的信号【SIGKILL】才可以**无条件终止**进程，编号为15的信号【SIGTERM】也可以**停止**进程，但是可能终止失败。对于编号为9的信号【SIGKILL】和编号为19的信号【SIGSTOP】，进程无法选择忽略，必须做出反应，而对于其它的信号，进程都有权利选择忽略。

## 信号处理动作详解

对于信号的处理有三种方式：忽略、捕捉、默认。

> 忽略信号，大多数信号可以使用这个方式来处理，但是有两种信号不能被忽略：9号【SIGKILL】、19号【SIGSTOP】。因为这两个信号向内核和超级用户提供了**终止**和**停止**的**可靠**方法，如果被忽略了，那么这个进程就变成了没人能管理的的进程，显然这是内核设计者不希望看到的场景。

> 捕捉信号，需要告诉内核，程序希望如何处理某一种信号，其实就是写一个信号处理函数，里面写上自定义的处理逻辑，然后将这个函数告诉内核【注册函数】。当该信号产生时，由内核来调用用户的自定义函数，以此来实现某种信号的自定义处理。说到底，就是进程捕捉信号，自定义处理，不使用内核默认的处理方式。

> 系统默认动作，对于每个信号来说，系统都对应有默认的处理动作。当发生了该信号，系统会自动执行。不过，对系统来说，大部分的处理方式都比较粗暴，就是直接杀死该进程。

## 信号的实际使用

以上把信号的基本概念了解清楚了，但是在实际中程序是怎么使用的呢？为了配合使用，必须有两方面程序：一是信号发送方【即负责发送信号的工具，例如 kill 就可以】，另一方是接收方【即能接收信号并且做出反应的程序，基本所有运行在 Linux 上的程序都可以】。

接下来就以 c 语言编程，写两个例子，模拟发送方【封装 kill】、接收方【信号处理函数注册】，来观察一下信号的实际应用。

### 信号处理函数注册

信号处理函数的注册，使用入门版的接口，signal 函数原型如下：

```c
#include <signal.h>
typedef void (*sighandler_t)(int);
sighandler_t signal(int signum, sighandler_t handler);
```

根据函数原型可以看出，由两部分组成，一个是真正处理信号的函数，另一个是注册函数。对于 **sighandler_t signal(int signum, sighandler_t handler)** 函数来说，signum 显然是信号的编号，handler 是处理函数的指针。同样地，在 **typedef void (\*sighandler_t)(int)** 这个处理函数的原型中，有一个参数是 int 类型，显然也是信号的编号，在实现函数时要根据信号的编号进行不同的操作。

只需要实现真正的处理信号的方法即可，以下是示例，信号处理只是打印，方便观察：

```c
#include<signal.h>
#include<stdio.h>
#include <unistd.h>

void handler(int signum) {
    // 处理函数只把接收到的信号编号打印出来
    if(signum == SIGIO)
        printf("SIGIO signal: %d\n", signum);
    else if(signum == SIGUSR1)
        printf("SIGUSR1 signal: %d\n", signum);
    else
        printf("error\n");
}

int main(void) {
    // 忽略 SIGINT,默认处理 SIGTERM,其它信号不注册都会导致程序退出
    signal(SIGIO, handler);
    signal(SIGUSR1, handler);
    signal(SIGINT, SIG_IGN);
    signal(SIGTERM, SIG_DFL);
    printf("SIGIO=%d,SIGUSR1=%d,SIGINT=%d,SIGTERM=%d\n", SIGIO, SIGUSR1, SIGINT, SIGTERM);
    // 以下是无限循环
    for(;;){
        sleep(10000);
    }
return 0;
}
```

使用 gcc 编译器编译【如果 Linux 环境不带需要自行安装】：gcc -o signal_test signal_test.c ，然后就可以执行了：./signal_test 。

接着使用 ctrl + c 快捷键【被进程忽略】，使用 kill 命令发送 29 号信号【被接收并打印出来编号】、10 号信号【被接收并打印出来编号】、2 号【被接收并忽略】、15 号【被接收并按照系统默认动作停止进程】，具体看下面的两张图片。

使用 kill 命令发送信号
![使用 kill 命令发送信号](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20190518222351.png "使用 kill 命令发送信号")

进程接收信号的处理方式
![进程接收信号的处理方式](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20190518222402.png "进程接收信号的处理方式")

接着演示 kill 发送一个程序没有注册的信号12号【SIGUSR2】，可以观察到程序直接退出。

kill 发送12号信号
![kill 发送12号信号](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20190518223015.png "kill 发送12号信号")

进程直接退出
![进程直接退出](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20190518223037.png "进程直接退出")


### 信号发送工具模拟

信号发送工具比较简易，其实就是模拟封装 kill，观察效果，先看一下 kill 函数的原型：

```c
#include <sys/types.h>
#include <signal.h>
int kill(pid_t pid, int sig);
```

可以看到函数原型很简单，有两个参数，pid 是信号接受者的 pid，sig 是信号编号，接着就实现一个简单的脚本，里面直接调用 kill 函数，内容如下：

```c
#include <sys/types.h>
#include <signal.h>
#include<stdio.h>
#include <unistd.h>

int main(int argc, char** argv) {
    // 接收的参数个数不足
    if(3 != argc){
        printf("[Arguments ERROR!]\n");
        printf("\tUsage:\n");
        printf("\t\t%s <Target_PID> <Signal_Number>\n", argv[0]);
        return -1;
    }
    int pid = atoi(argv[1]);
    int sig = atoi(argv[2]);
    // 这里增加一个对编号判断的逻辑
    if(pid > 0 && sig > 0){
        kill(pid, sig);
    }else{
        printf("Target_PID or Signal_Number MUST bigger than 0!\n");
    }
    return 0;
}
```

在此特殊说明一下，关于 pid 的取值范围，上述代码示例把 pid 限制在正整数，防止出错。其实 pid 的取值范围很广，各有特殊含义，请参考文末的备注。

使用 gcc 编译后【gcc -o signal_kill signal_kill.c】直接运行，观察能否把信号正常发送给运行的进程。

运行脚本发送信号
![运行脚本发送信号](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20190518224421.png "运行脚本发送信号")

运行的进程可以正常接收到信号
![运行的进程可以正常接收到信号](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20190518224412.png "运行的进程可以正常接收到信号")

经过观察，是可以的，至此信号函数的使用演示完成。


# 操作实践


详细认识信号的基本知识后，接下来进行实践会更加知其所以然，那就回归到正题，我来使用 kill 命令进行实践操作一下，演示一下常用的信号以及处理效果。

在日常工作中，一般会使用信号1、信号3、信号3、信号9、信号15，这五个比较常用，就不再演示，只是需要留意一下它们对应的键盘快捷键，信号2是 ctrl + c，信号3是 ctrl + \ 。

我想重点演示一下信号18、信号19以及 bg、fg、jobs 命令。

## 演示

开启三个进程，分别使用 ctrl + z 命令暂停它们的运行，在暂停时输出的日志中会有 Stopped 标记，并且会有进程的编号分配，在方括号中的就是【有时候暂停时还会有**核心已转储**、**core dumped**的提示】。
![开启三个进程分别暂停](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20190518231714.png "开启三个进程分别暂停")

使用 jobs 命令查看暂停的进程，此时每个进程会有编号，此时的三个进程分别是2、3、4。
![jobs 查看暂停的进程](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20190518231705.png "jobs 查看暂停的进程v")

使用 kill 发送18号信号给编号为4的暂停进程，然后再次使用 jobs 命令查看，发现这个进程的状态已经由 Stopped 变为了 Running，说明这个进程继续运行了【但是是后台运行，没有占用终端】。

发送18号信号
![发送18号信号](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20190518232545.png "发送18号信号")

编号为4的进程后台运行中
![编号为4的进程后台运行中](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20190518232554.png "编号为4的进程后台运行中")

接着使用 fg、bg 命令把编号为4的进程调到前台运行、返回后台运行。此时可以发现，fg、bg 命令和信号18的作用是等价的，而且更为丰富，可以把进程在前台【占用终端】、后台【不占用终端】之间调换。
![使用 fg、bg 命令](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20190518233026.png "使用 fg、bg 命令")

## 总结

总结一下：

对于正在运行的进程，并且等待终端的输入，此时如果使用 **ctrl + c** 就会导致进程退出，所以可以使用 **ctrl + z** 让进程暂停，并退到后台等待，此时终端被释放，可以继续输入命令。

接着可以使用 **jobs** 命令查看有哪些被暂停的进程【此时进程会有编号，从1开始】，可以使用 **bg num** 命令让第 num 个进程在后台运行，可以使用 **fg num** 让第 num 个进程在前台运行【继续占用终端】。当然，如果使用 bg、fg 时不加序号参数，则默认对最后一个进程操作。


# 备注


## 段错误

在某一次的实际场景中，想从本地上传文件到远程服务器，具体的操作是登录远程服务器后，在终端中使用 **lrz** 命令【环境为 CentOS 系统，需要自行安装这个工具】，然后在弹出的文件浏览器中选择本地的文件。

在上传的过程中，刚刚开始没多久就报错：**段错误 (core dumped)**【如果使用英文表示，为：Segmentation fault，后面括号里面的 core dumped 是核心已转储，在进程退出或者暂停时会出现】，紧接着上传进度中断，上传进程停止。

然后检查发现服务器上传文件指定目录的硬盘空间已经没有了，使用 **df -h** 命令查看，磁盘使用率 100%，所以无法再继续上传文件。

上面的错误： **段错误 (core dumped)**，我猜测可能是和信号 **SIGSEGV** 有关，下面就以 c 语言为基础写一个简单的例子，在代码中特意非法操作内存，让内核主动发送 **SIGSEGV** 信号给进程。

代码示例如下，已经写好注释：

```c
#include <stdio.h>

int main(){
    char *str = "hello";
    // 非法赋值,想改变字符串内存地址的字符串值,不被允许
    *str = 'h'; 
    printf("%s\n", str);
    // 新定义字符串就可以
    char *str2 = "world"; 
    printf("%s\n", str2);
    return 0;
}
```

使用 gcc 编译：**gcc -o seg_error seg_error.c**，然后运行：**./seg_error**，就可以发现报错：**Segmentation fault**。

Segmentation fault 报错截图
![Segmentation fault 报错截图](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20190521233505.png "Segmentation fault 报错截图")

如果不确定是哪几行代码出了问题，可以简单调试一下，重新编译时加上 **-g** 参数，再使用 gdb 调试器工具：**gdb seg_error**，开启调试模式，然后输入 **r** 运行，接着就可以看到具体的报错信息以及报错位置。

从下图中可以看到，程序在运行中接收到 **SIGSEGV** 信号而退出，并抛出 **Segmentation fault** 错误信息，异常代码在第6行：**\*str = 'h';**，这1行代码在非法操作内存【字符串是不可改变的量，被分配在内存区域的数据段，当向该只读数据区域进行写操作即为非法】，操作系统内核【kernel】会通过 kill 命令向进程发送编号为11的信号，即 SIGSEGV【段错误】信号，进程被内核终止。

![Segmentation 调试](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20190521234109.png "Segmentation 调试")

除了内核在检测到非法操作时发送这个信号给进程，如果我手动发送这个信号给进程会发生什么呢，不妨试一下。随便起动一个进程【我使用 tail -f seg_error.c 查看文件内容】，然后使用 kill 命令发送 SIGSEGV 信号给这个进程。

![手动发送 SIGSEGV 信号给进程](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20190521235126.png "手动发送 SIGSEGV 信号给进程")

可以从上图中看到，进程由于接收到 **SIGSEGV** 信号而退出。

## 进程号取值

在使用 kill 命令时，pid 参数就是系统给进程分配的编号，但是这个参数除了正常的正整数之外，其它的取值有各自特殊的含义。

- pid 大于0，将信号发送给进程 id 为 pid 的进程
- pid 等于0，将信号发送给与发送进程属于同一进程组的所有进程【即进程组 id 相等的进程】
- pid 等于-1，将该信号发送给系统内所有的进程【前提是有发送信号权限的，并且不包括系统进程集中的进程】
- pid 小于-1，将该信号发送给其进程组 id 等于 pid 绝对值的所有进程【针对进程组】

## 可靠信号与不可靠信号

以上内容在讨论信号的知识点与实际演示时，都没有考虑到信号的可靠性问题，默认都是能送达的。但是，信号是区分可靠信号、不可靠信号的。

- 不可靠信号，信号可能会丢失，而一旦信号丢失【多次信号不排队】，进程是无法接收这个信号的。Linux 的信号机制基本上是从 Unix 系统中继承过来的，早期 Unix 系统中的信号机制比较简单和原始，后来在实践中逐渐暴露出一些问题。因此，把那些建立在早期 Unix 信号机制上的信号叫做**不可靠信号**，信号值小于 SIGRTMIN【不同系统会有微小的差别，例如在 CentOS 中是34】的信号都是不可靠信号。
- 可靠信号，也称为阻塞信号，当发送了一个阻塞信号，并且该信号的动作是系统默认动作或捕捉该信号，则信号从发出以后会一直保持未决的状态，直到该进程对此信号解除了阻塞，或将对此信号的动作更改为忽略。随着时间的发展，实践证明了有必要对信号的原始机制加以改进和扩充。所以，后来出现的各种 Unix 版本分别在这方面进行了研究，力图实现**可靠信号**。由于原来定义的信号已有许多应用，不好再做改动，最终只好又新增加了一些信号，并在一开始就把它们定义为可靠信号，这些信号支持排队，不会丢失，信号值的范围在 SIGRTMIN 和 SIGRTMAX 之间。同时，信号的发送和安装也出现了新版本：信号发送函数 sigqueue() 以及信号的安装函数 sigaction() 。


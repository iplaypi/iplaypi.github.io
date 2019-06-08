---
title: IDEA 热部署配置方法总结
id: 2016120801
date: 2016-12-08 23:01:13
updated: 2019-06-08 23:01:13
categories: 基础技术知识
tags: [IDEA,Tomcat,deploy,JRebel]
keywords: IDEA,Tomcat,deploy,JRebel
---


前不久临时在搞一个 Java Web 项目，需要做一点点修改，由于对原有的代码不熟悉，所以附带需要大量的测试，搞清楚程序执行的流程。在一开始的操作过程中，我就是不断修改代码，然后关闭 Tomcat 服务器，再重启，操作了几次我就不想这么干了，太浪费时间了。大量的时间都用在了关闭重启服务上面，在最新更改的代码没有加载完成前，只能干等着，后面我就发现了有**热部署**这个技巧，可以节省大量的时间。本文就记录在 IDEA 中热部署的配置方式，操作系统环境基于 Windows7 X64，Web 容器基于 Tomcat 6.x。


<!-- more -->


# 大背景


在 Web 开发中，如果需要调试最新更新的代码，最先想到的思路就是重新启动 Web 容器，以加载最新的资源文件。但是显然，这种做法是很浪费时间的，而且当 Web 项目整体比较大的时候，重启一次需要很长的时间，更加凸显了这种做法的低效。

回头思考一下，有时候只是更改了某个方法的几行代码，却要重启整个服务，这动作太大了，肯定有更加方便快捷的方式来做这件事，例如**热部署**。

还有，有时候更新的不一定是 Java 类文件【或者其它编程语言的后台资源文件】，而是 HTML 静态文件、JavaScript 静态文件、项目配置文件【例如 Spring 的配置文件、日志配置文件】等，这时候是不是一定要重启 Web 服务呢，能不能也做到热部署，其实是可以的。


# 热部署配置


## 热部署基础配置


如果还没有为 Web 项目配置好 Tomcat 服务器，可以在 `Run` -> `Edit Configurations` 中先把 Web 服务器的基本信息【例如本地服务器安装目录、默认浏览器、服务端口、JRE 环境】配置好。
![先配置 Tomcat 服务器](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20190609025955.png "先配置 Tomcat 服务器")

具体配置可以参考下图：名字、本地安装的服务器、启动的浏览器、本地 JRE 环境、HTTP 服务端口。
![Tomcat 服务器具体配置信息](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20190609025912.png "Tomcat 服务器具体配置信息")

配置完成 Tomcat 服务器的基本信息，再接着配置部署优化信息，如图打开 Tomcat 的 `Edit Configurations`。如果刚刚执行完前面的 Tomcat 基础信息配置，可以不用关闭窗口，直接可以进入下一步骤进行配置，如果已经使用过 Tomcat 服务器，可以按照如图快捷方式打开配置窗口。
![打开 Tomcat 部署窗口](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20190609030044.png "打开 Tomcat 部署窗口")

打开 `Deployment` 选项卡，默认在启动项【startup】里面是没有任何东西的【面板中部也提示 `Nothing to deploy`】，需要手动添加，也就是为 Tomcat 服务器添加一个应用，这样在 Tomcat 启动时就会加载这个应用，也可以说是把这个应用部署到 Tomcat 服务器上面。点击右侧的绿色小加号，选择 `Artifact`。
![Deployment 选项卡配置应用](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20190609030125.png "Deployment 选项卡配置应用")

接着选择部署应用的类型，建议选择 `exploded` 的类型，不需要单纯的 `war` 包类型，这个相当于更改 Tomcat 的 `CATALINA_HOME`，效率比较高一点，选择后点击 `ok` 确认即可。
![添加 exploded 类型的应用](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20190609030158.png "添加 exploded 类型的应用")

配置完成 `Deployment` 信息后，如果有默认的 `Make` 操作记得删除【在 `Deployment` 选项卡的底部，有一个 `Before launch` 清单】，可以提高效率，只保留项目的 `exploded` 类型即可，选中后使用红色的减号来删除。
![删除 Make 提升效率](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20190609030231.png "删除 Make 提升效率")

接着返回 `Server` 选项卡，可以看到有两项重要的配置：`On 'Update' action`、`On frame deactivation`，如果在前面的 `Deployment` 选项卡中没有配置 `exploded` 类型的 war 包的话，这里是不会有 `On frame deactivation` 这个配置项的。接着把这两个重要的配置选项都设置为 `Update classes and resources`，否则类修改热部署不会生效，或者第三方模版框架例如 Freemarker 的热部署也不会生效。
![Server 选项卡配置](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20190609030252.png "Server 选项卡配置")

配置完成了以上信息，在 Debug 模式下，IDEA 失去焦点时【场景：开启 Debug 模式，更改完代码去浏览器操作测试】，则会自动加载更新从而达到热部署的效果。不难发现，这个过程还是有点缓慢，原因是什么呢，因为前面的配置效果都是基于 JVM 提供的热加载来实现的，仅支持方法块内代码的修改，并且只有 Debug 模式下，同时是在 IDEA 失去焦点时【`On frame deactivation` 配置产生的效果】才会触发热加载，相对来说整个流程的速度仍旧略显缓慢。

那么，怎么优化这个流程呢，继续往下面看。

## 热部署进阶配置

前面提到的热部署速度仍旧缓慢，必须在 Debug 模式下并且焦点离开 IDEA 时才会触发热加载，是因为还没有开启 IDEA 的自动编译功能。

众所周知，在 Eclipse 中是默认开启自动编译的特性的，也就说你只要更改了项目的文件，点击保存，Eclipse 就会立即执行编译操作，把文件编译一遍，虽然优点消耗资源，但是能在开发人员无感的情况下保证所有的执行文件都是最新的，避免诡异的问题出现。

但是在 IDEA 中，自动编译这个特性默认是关闭的，也就是说如果你更改了文件，但是没有及时编译，等到运行时使用的仍旧是上次的可执行文件，这就会导致一些诡异的现象发生。例如刚刚改了代码然后运行，发现运行的代码逻辑和更改的不一致，这就是因为虽然原文件被改了【肉眼可以看到改变】，但是可执行文件仍旧是旧的【运行程序观察到的现象是没变】。举个具体的例子就是在 IDEA 中写 Maven 项目，尽管在每次 Run 的时候 IDEA 都会重新编译 Java 类文件，保证运行的 class 文件都是最新的，但是有时候不知道怎么回事运行的 class 文件并不是最新的，我一直认为这是 IDEA 的 bug，另一方面，如果变更的是 xml 配置文件，IDEA 也会漏掉，因此，此时运行前最好先执行一下 `mvn clean` 来清空一下项目的编译结果。

下面开始进入正题，记录开启 IDEA 自动编译的方法。

首先设置自动构建【包含编译】，在 **Settings** -> **Build，Execution，Deployment** -> **Compiler** 中，勾选 `Build project automatically`，这个配置项表示自动构建项目，但是仅在项目没有运行或者 Debug 的状态下才会有效。那这样肯定不行，因为热部署就是表示项目一直在运行中，热加载更改代码后自动编译的文件，这个设置在运行状态下不会自动编译，别急，还有下一个步骤的设置。
![设置自动构建](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20190609030350.png "设置自动构建")

设置允许运行中的程序自动编译，先使用 `Ctrl + Shift + a` 调出搜索 Action 的对话框【这个快捷方式是基于 Windows 平台的 Eclipse 快捷方式，也可以在主界面根据 **Help** -> **Find Action** 进入】，在里面搜索 **Registry**，选择结果中的 **Registry...**，接着就会进入详细设置页面。
![在Action 搜索对话框中搜索 Registry](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20190609030409.png "在Action 搜索对话框中搜索 Registry")

在详细设置页面继续搜索 **compiler.automake.allow.when.app.running**，直接输入即可，不需要搜索框，或者输入关键词 **app.running**，会在左上角显示搜索内容：`Search for: app.running`，下面也会实时展示搜索结果。
![搜索 app.running](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20190609030445.png "搜索 app.running")

看到我想要的结果了，直接勾选 `compiler.automake.allow.when.app.running`，这就表示允许在程序运行时自动编译，但是还要留意一点，看到最上面的红色字体的提示：`Changing these values may cause unwanted behavior of IntelliJ IDEA.Please do not change these unless you have been asked`，其实就是在警告你不要随意更改这里面的配置，可能会对 IDEA 造成影响，除非你完全了解你更改的内容。关于这个选项的含义，可以直接看最下面的 `Description` 里面的描述：`Allow auto-make to start even if developed application is currently running. Note that automatically started make may eventually delete some classes that are required by the application.`。
![勾选需要的选项](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20190609030509.png "勾选需要的选项")

## 配置效果总结

如此一来，每当我的 Web 项目里面的 Java 文件、JavaScript 文件等资源更新时【例如更改了代码，重新配置了参数等】，Tomcat 服务会重新载入这些原始文件对应的编译文件，从而达到热部署的效果，这样我就可以不用在每次更改了一点东西，想测试一下效果，还需要关闭重启，浪费时间。

Tomcat 热部署时重新载入资源给出的提示信息
![Tomcat 热部署给出的提示信息](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20190609030529.png "Tomcat 热部署给出的提示信息")

还要注意一点，在 Debug 时，为了验证刚刚更改的代码有没有被热加载，可以添加一个断点，看看断点的状态有没有生效，即在红色的断点标记处有一个对勾标识【√】，如果没有对勾也没有叉【×】，而是一个单独的红圆圈，说明更改的代码没有生效。
![断点标记查看](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20190609030537.png "断点标记查看")


# 备注


1、如果需要方便地调试 JavaScript 代码【需要在 `Server` 配置中勾选 `with JavaScript debugger`】，还可以借助 IDEA 的官方浏览器插件：[JetBrains IDE Support](https://chrome.google.com/webstore/detail/jetbrains-ide-support/hmhgeddbohgjknpmjagkdomcpobmllji) ，可以很方便地对静态资源进行调试。

2、另外关于热部署还有一款超级好用的工具：[JRebel](https://jrebel.com) ，可以使用 Tomcat 参数配置的方式或者 IDEA 插件的方式，这款工具不是免费的，可以免费试用一段时间，请大家支持正版。


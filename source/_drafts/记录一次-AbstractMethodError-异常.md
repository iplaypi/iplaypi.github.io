---
title: 记录一次 AbstractMethodError 异常
id: 2019070401
date: 2019-07-04 23:19:13
updated: 2019-07-04 23:19:13
categories: 踩坑记录
tags: [AbstractMethodError,Java,Spark,netty]
keywords: AbstractMethodError,Java,Spark,netty
---


场景描述：在某一天我觉得我的 Java 项目的依赖太冗余了，决定删除一些无用的依赖，让整个项目瘦身，以后打包发布的时候也更快速、节省时间。

接着我按照自己的经验，把大部分依赖全部删除，此时编译会报一些错误，这是必然的，但是我不担心，根据报错信息把缺失的依赖再一个一个添加进来即可。忙活了一阵，终于解决了所有的报错，编译、打包一气呵成，不再有错误，看了一下打包后的文件大小，足足比原先小了30%，我略感满意。

但是此时我仍旧悬着一颗心，因为编译、打包成功不代表什么，后面的运行才是大问题，运行时往往会暴露一些隐藏的问题。而且项目里面有好几个功能，只要有一个功能运行失败那就说明依赖还是有问题，改造不成功。【千万不要以为编译、打包成功就万事大吉了，运行时的异常才是大问题，一定要有未雨绸缪的准备】

果然，刚启动第一个功能就出现了我想象中的异常信息：`java.lang.AbstractMethodError`。


<!-- more -->


# 问题出现


异常突然出现，我差点就蒙了，昨天还好好的，今天怎么就这样了，程序又不是女朋女，不可能说变就变。此时，我又想起了一个段子，程序员：运行失败了，这 TM 怎么可能会失败呢？运行成功了，这 TM 怎么就成功了呢？

作为一名资深的工程师，我还是决定试试，看看能不能走个狗屎运，于是我分别在本机、测试环境、正式环境分别做了测试，发现都是报一样的错误，接着我就意识到问题的严重行，不能心存侥幸，要拿我真实的技术来说话了。

前面的处理方式就像重启系统一样，只不过是碰运气的方式，我连报错信息都没有仔细看，接下来就要认真处理了。

既然报错了，那就耐心查看，办法总比困难多。下面列出完整的错误信息：

```
2019-07-04_20:05:26 [main] INFO yarn.Client:58: Application report for application_1561431414509_0020 (state: ACCEPTED)
2019-07-04_20:05:26 [shuffle-server-2] ERROR server.TransportRequestHandler:191: Error sending result RpcResponse{requestId=5206989806485258134, body=NioManagedBuffer{buf=java.nio.HeapByteBuffer[pos=0 lim=47 cap=47]}} to dev6/172.18.5.206:55124; closing connection
java.lang.AbstractMethodError
	at io.netty.util.ReferenceCountUtil.touch(ReferenceCountUtil.java:73)
	at io.netty.channel.DefaultChannelPipeline.touch(DefaultChannelPipeline.java:107)
	at io.netty.channel.AbstractChannelHandlerContext.write(AbstractChannelHandlerContext.java:810)
	at io.netty.channel.AbstractChannelHandlerContext.write(AbstractChannelHandlerContext.java:723)
	at io.netty.handler.codec.MessageToMessageEncoder.write(MessageToMessageEncoder.java:111)
	at io.netty.channel.AbstractChannelHandlerContext.invokeWrite0(AbstractChannelHandlerContext.java:738)
	at io.netty.channel.AbstractChannelHandlerContext.invokeWrite(AbstractChannelHandlerContext.java:730)
	at io.netty.channel.AbstractChannelHandlerContext.write(AbstractChannelHandlerContext.java:816)
	at io.netty.channel.AbstractChannelHandlerContext.write(AbstractChannelHandlerContext.java:723)
	at io.netty.handler.timeout.IdleStateHandler.write(IdleStateHandler.java:302)
	at io.netty.channel.AbstractChannelHandlerContext.invokeWrite0(AbstractChannelHandlerContext.java:738)
	at io.netty.channel.AbstractChannelHandlerContext.invokeWrite(AbstractChannelHandlerContext.java:730)
	at io.netty.channel.AbstractChannelHandlerContext.access$1900(AbstractChannelHandlerContext.java:38)
	at io.netty.channel.AbstractChannelHandlerContext$AbstractWriteTask.write(AbstractChannelHandlerContext.java:1089)
	at io.netty.channel.AbstractChannelHandlerContext$WriteAndFlushTask.write(AbstractChannelHandlerContext.java:1136)
	at io.netty.channel.AbstractChannelHandlerContext$AbstractWriteTask.run(AbstractChannelHandlerContext.java:1078)
	at io.netty.util.concurrent.AbstractEventExecutor.safeExecute(AbstractEventExecutor.java:163)
	at io.netty.util.concurrent.SingleThreadEventExecutor.runAllTasks(SingleThreadEventExecutor.java:403)
	at io.netty.channel.nio.NioEventLoop.run(NioEventLoop.java:462)
	at io.netty.util.concurrent.SingleThreadEventExecutor$5.run(SingleThreadEventExecutor.java:858)
	at java.lang.Thread.run(Thread.java:748)
```

![报错日志](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20190704232421.png "报错日志")

其中，重点只需要看这几行内容：

```
2019-07-04_20:05:26 [shuffle-server-2] ERROR server.TransportRequestHandler:191: Error sending result RpcResponse{requestId=5206989806485258134, body=NioManagedBuffer{buf=java.nio.HeapByteBuffer[pos=0 lim=47 cap=47]}} to dev6/172.18.5.206:55124; closing connection
java.lang.AbstractMethodError
	at io.netty.util.ReferenceCountUtil.touch(ReferenceCountUtil.java:73)
	at io.netty.channel.DefaultChannelPipeline.touch(DefaultChannelPipeline.java:107)
```

我定睛一瞧，`AbstractMethodError` 这种异常类型我还没见过，这怎么行，抓紧去查了 Java 的官方文档，查过之后，才明白这个异常的含义。
![AbstractMethodError 文档](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20190704232219.png "AbstractMethodError 文档")

官方定义内容如下：

> Thrown when an application tries to call an abstract method. Normally, this error is caught by the compiler; this error can only occur at run time if the definition of some class has incompatibly changed since the currently executing method was last compiled.

大概意思就是说在运行时发现方法的定义与编译时的不一致，也就是冲突了，至于为何造成冲突，还需要进一步检查。

我又回过头去仔细看一下这个功能的前后逻辑，很简单，只是使用 Spark 处理 HDFS 里面的数据，然后把处理结果再写回到 HDFS，实际运行时处理的数据量也不大，看起来不会有功能性的问题。而且，前不久这个功能还运行地好好的，只在我更改后才起不来的，原因基本可以定位在依赖方面：冲突、缺失。


# 问题解决


顺着依赖冲突这个突破点看下去，可能是因为我在清理依赖时把某个依赖清除掉了，然后又自己添加一个不同版本的，导致与原先的依赖版本不匹配。而且看到异常信息里面都是和 `netty` 有关的，可以猜测可能是 `netty` 的相关依赖出问题了。

接着再多看一点点异常信息，还有一些额外的有效信息：

```
2019-07-04_20:05:23 [main] INFO spark.SecurityManager:58: SecurityManager: authentication disabled; ui acls disabled; users with view permissions: Set(Administrator, dota); users with modify permissions: Set(Administrator, dota)
2019-07-04_20:05:23 [main] INFO yarn.Client:58: Submitting application 20 to ResourceManager
2019-07-04_20:05:23 [main] INFO impl.YarnClientImpl:274: Submitted application application_1561431414509_0020
2019-07-04_20:05:24 [main] INFO yarn.Client:58: Application report for application_1561431414509_0020 (state: ACCEPTED)
2019-07-04_20:05:24 [main] INFO yarn.Client:58: 
	 client token: N/A
	 diagnostics: N/A
	 ApplicationMaster host: N/A
	 ApplicationMaster RPC port: -1
	 queue: default
	 start time: 1562241921232
	 final status: UNDEFINED
	 tracking URL: http://dev6:8088/proxy/application_1561431414509_0020/
	 user: dota
2019-07-04_20:05:29 [main] INFO yarn.Client:58: Application report for application_1561431414509_0020 (state: ACCEPTED)
2019-07-04_20:05:30 [main] INFO yarn.Client:58: Application report for application_1561431414509_0020 (state: ACCEPTED)
2019-07-04_20:05:31 [main] INFO yarn.Client:58: Application report for application_1561431414509_0020 (state: ACCEPTED)
2019-07-04_20:05:32 [main] INFO yarn.Client:58: Application report for application_1561431414509_0020 (state: FAILED)
2019-07-04_20:05:32 [main] INFO yarn.Client:58: 
	 client token: N/A
	 diagnostics: Application application_1561431414509_0020 failed 2 times due to AM Container for appattempt_1561431414509_0020_000002 exited with  exitCode: 10
For more detailed output, check application tracking page:http://dev6:8088/cluster/app/application_1561431414509_0020Then, click on links to logs of each attempt.
Diagnostics: Exception from container-launch.
Container id: container_e19_1561431414509_0020_02_000001
Exit code: 10
Stack trace: ExitCodeException exitCode=10: 
	at org.apache.hadoop.util.Shell.runCommand(Shell.java:576)
	at org.apache.hadoop.util.Shell.run(Shell.java:487)
	at org.apache.hadoop.util.Shell$ShellCommandExecutor.execute(Shell.java:753)
	at org.apache.hadoop.yarn.server.nodemanager.DefaultContainerExecutor.launchContainer(DefaultContainerExecutor.java:212)
	at org.apache.hadoop.yarn.server.nodemanager.containermanager.launcher.ContainerLaunch.call(ContainerLaunch.java:303)
	at org.apache.hadoop.yarn.server.nodemanager.containermanager.launcher.ContainerLaunch.call(ContainerLaunch.java:82)
	at java.util.concurrent.FutureTask.run(FutureTask.java:266)
	at java.util.concurrent.ThreadPoolExecutor.runWorker(ThreadPoolExecutor.java:1149)
	at java.util.concurrent.ThreadPoolExecutor$Worker.run(ThreadPoolExecutor.java:624)
	at java.lang.Thread.run(Thread.java:748)
```

从上文的日志信息来看，程序的 Driver 端已经提交了 Spark 任务到 Yarn 集群，然后 Yarn 集群分配了资源，但是在后续的通信过程中，不知道哪里出问题了，导致通信中断，进而导致 Spark 任务失败。

结合上面我猜测的和 `netty` 依赖有关，那就从这里入手吧，先把项目的依赖树梳理出来，使用 `mvn dependency:tree > tree.txt`，把依赖树的信息保存在文件 `tree.txt` 中，然后在依赖树信息中搜索 `netty`。
![搜索 netty 关键字](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20190704232242.png "搜索 netty 关键字")

可以看到关于 `netty` 依赖的信息。

再全局搜索一下项目中的类【在 Windows 下使用 Eclipse 的快捷键 `Ctrl + Shift + t`】，异常信息对应的那个类：`ReferenceCountUtil`，可以看到存在两个同名的类：类名称一致【都是 ReferenceCountUtil】，包名称一致【都是 io.netty.util】，只不过对应的 jar 包依赖不一致，一个是 `io.netty:netty-common:4.1.13.Final.jar`，另一个是 `io.netty:netty-all:4.0.29.Final.jar`，这两个类肯定会冲突的。
![搜索 ReferenceCountUtil 类](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20190704232137.png "搜索 ReferenceCountUtil 类")

解决办法很简单，直接去除多余的依赖即可，但是要注意去除后会不会引发其它的依赖缺失问题。我在我的项目里面移除了所有的 `io.netty:netty-all` 依赖。

如果项目本身的依赖非常混乱，并且有大量的重复，可能去除一个还有一个，会造成大量重复的工作，所以在查看依赖树时可以使用 `-Dverbose` 参数，完整的命令：`mvn dependency:tree -Dverbose > tree.txt`，把原始的所有传递依赖全部列出来，这样就可以对症操作，一次性把所有依赖移除。

当然，会有人觉得这样操作也是很麻烦，能不能来个插件，直接配置一下即可，至于去除的操作过程我也不关心，只要能帮我去除就行。当然，这对于想偷懒的技术人员来说值必备的，这个东西就是插件 `maven-shade-plugin`，描述配置方法。


# 问题总结


总结一下问题，就是同名的类存在了不同版本的 jar 包中，等到运行的时候，虚拟机发现异常，便抛出异常信息，停止运行程序。

此外，在没有十足的把握或者时间人力不充足的情况下，千万不要想着重构代码，后果你不一定能承担，带来的好处可能大于带来的灾难，这也叫好心办坏事。


---
title: 记录一次 AbstractMethodError 异常
id: 2019070401
date: 2019-07-04 23:19:13
updated: 2019-07-04 23:19:13
categories: 踩坑记录
tags: AbstractMethodError,Java,Spark, netty
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

从上文的日志信息来看，程序的 `Driver` 端已经提交了 `Spark` 任务到 `Yarn` 集群，然后 `Yarn` 集群分配了资源，但是在后续的通信过程中，不知道哪里出问题了，导致通信中断，进而导致 `Spark` 任务失败。

结合上面我猜测的和 `netty` 依赖有关，那就从这里入手吧，先把项目的依赖树梳理出来，使用 `mvn dependency:tree > tree.txt`，把依赖树的信息保存在文件 `tree.txt` 中，然后在依赖树信息中搜索 `netty`。
![搜索 netty 关键字](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20190704232242.png "搜索 netty 关键字")

可以看到关于 `netty` 依赖的信息。

再全局搜索一下项目中的类【在 Windows 下使用 Eclipse 的快捷键 `Ctrl + Shift + t`】，异常信息对应的那个类：`ReferenceCountUtil`，可以看到存在两个同名的类：类名称一致【都是 ReferenceCountUtil】，包名称一致【都是 io.netty.util】，只不过对应的 jar 包依赖不一致，一个是 `io.netty:netty-common:4.1.13.Final.jar`【这个是我的 org.elasticsearch.client:transport:5.6.8 传递依赖过来的】，另一个是 `io.netty:netty-all:4.0.29.Final.jar`【这个是 Spark 自带的，只不过我重新指定了版本】，这两个类肯定会冲突的。
![搜索 ReferenceCountUtil 类](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20190704232137.png "搜索 ReferenceCountUtil 类")

解决办法很简单，直接去除多余的依赖即可，但是要注意去除后会不会引发其它的依赖缺失问题。我在我的项目里面移除了所有的 `io.netty:netty-*` 依赖，这些依赖也是传递过来的，版本都为 `v4.1.13`，如下图：

如果不全部移除而是选择只移除 `netty-common`，还会有问题，因为这些依赖之间也互相依赖，看 `common` 这个命名就知道了，这就是：**一荣俱荣，一损俱损**。

![移除所有的 netty 传递依赖](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20190718231720.png "移除所有的 netty 传递依赖")

我把这些依赖移除后，`netty` 相关的依赖冲突就没有问题了，但是又遇到了一个小问题：

```
java.lang.ClassNotFoundException: org.elasticsearch.spark.rdd.EsPartition
```

Spark 任务正常启动后，运行过程中出现了上述错误，导致 `Spark` 任务失败，乍一看是类缺失。但是如果在项目中搜索的话，也能搜索到这个类，是不是觉得很奇怪。

![搜索缺失的 ESPartition 类](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20190718233540.png "搜索缺失的 ESPartition 类")

其实不要多想，这个是典型的 `Yarn/Spark` 集群环境问题，项目中使用的 jar 包【特定版本的，我这里是：org.elasticsearch.client:transport:jar:5.5.0】在集群环境中没有，如果切换一个集群环境中存在版本就可以了【例如 v5.6.8】。或者一定要使用这个版本的话，就把这个 jar 包复制到 `Yarn/Spark` 集群环境每台机器的 `lib` 库中去。但是一般情况下，公司的环境是统一的，会避免使用多版本的依赖，以免引起一连串的未知冲突问题，浪费大家的时间。

在实际生产环境中，可能还会遇到一个更加糟糕的问题，即项目本身的依赖非常混乱，并且有大量的重复，可能去除一个还有一个，会造成大量重复的工作，所以在查看依赖树时可以使用 `-Dverbose` 参数，完整的命令：`mvn dependency:tree -Dverbose > tree.txt`，把原始的所有传递依赖全部列出来，这样就可以对症操作，一次性把所有依赖移除。

当然，会有人觉得这样操作也是很麻烦，能不能来个插件，直接配置一下即可，至于去除的操作过程我也不关心，只要能帮我去除就行。当然，这对于想偷懒的技术人员来说值必备的，这个东西就是插件 `maven-shade-plugin`。

在 `configuration` 里面配置 `artifactSet -> excludes -> exclude -> jar 包坐标` 即可。

但是要注意，插件要使用高版本的：`v3.1.0`，我一开始使用的是 `v2.4.3`，怎么配置都无效，搞了半天发现低版本不支持。此外，还要注意 JDK 的版本也要 `v1.8+`，这样才能保证使用其它的特性，例如打包压缩：`<minimizeJar>true</minimizeJar>`。使用这个参数可以自动把无用的依赖 jar 排除掉，给代码瘦身，同时也节约打包时间，非常好用。我的 jar 在使用打包压缩参数后，由原本的 313MB被压缩到了191MB，压缩率超过30%，我觉得非常好用。

此外，`maven-shade-plugin` 插件是一款非常优秀的插件，最常用的莫过于**影子别名**功能，对于复杂的依赖冲突解决有奇效。例如对于上面的依赖冲突问题，可以不用找原因一点一点解决，直接使用**影子别名**功能把传递依赖的 `netty` jar 包改个名字即可，这样它们就可以共存了，简单粗暴却有奇效。推荐大家使用，这里不再赘述。


# 问题总结


总结一下问题，就是同名的类存在了不同版本的 jar 包中，等到运行的时候，虚拟机发现异常，便抛出异常信息，停止运行程序。

此外，在没有十足的把握或者时间人力不充足的情况下，千万不要想着重构代码，后果你不一定能承担，带来的好处可能大于带来的灾难，这也叫好心办坏事。

再回顾一下，我这个问题是 `Spark` 任务运行在 `Yarn` 集群上面才发现的，如果使用 `local` 模式运行 `Spark` 任务是不会有问题的。所以当时出问题后我也是疑惑，反复测试了好几次才敢确认，主要是因为使用 `Yarn` 模式时，同时也会使用集群中提供的 jar 包依赖，如果项目本身打包时又打进了相同的 jar 包，就极有可能引发冲突【版本不一致，而且 `netty` 包的冲突本身就是一个大坑】。


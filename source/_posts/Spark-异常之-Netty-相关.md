---
title: Spark 异常之 Netty 相关
id: 2019011401
date: 2019-01-14 01:27:53
updated: 2019-01-14 01:27:53
categories: 基础技术知识
tags: [Spark,netty,nio]
keywords: Spark,netty,nio
---


在做项目的时候，需要新引入一个外部依赖，于是很自然地在项目的 pom.xml 文件中加入了依赖坐标，然后进行编译、打包、运行，没想到直接抛出了异常：

````java
2019-01-13_17:18:52 [sparkDriverActorSystem-akka.actor.default-dispatcher-5] ERROR actor.ActorSystemImpl:66: Uncaught fatal error from thread [sparkDriverActorSystem-akka.remote.default-remote-dispatcher-7] shutting down ActorSystem [sparkDriverActorSystem]
java.lang.VerifyError: (class: org/jboss/netty/channel/socket/nio/NioWorkerPool, method: createWorker signature: (Ljava/util/concurrent/Executor;)Lorg/jboss/netty/channel/socket/nio/AbstractNioWorker;) Wrong return type in function
````

任务运行失败，仔细看日志觉得很莫名奇妙，是一个 java.lang.VerifyError 错误，以前从来没见过类似的。本文记录这个错误的解决过程。

<!-- more -->


# 问题出现


在上述错误抛出之后，可以看到 SparkContext 初始化失败，然后进程就终止了；

完整日志如下：
````java
2019-01-13_17:18:52 [sparkDriverActorSystem-akka.actor.default-dispatcher-5] ERROR actor.ActorSystemImpl:66: Uncaught fatal error from thread [sparkDriverActorSystem-akka.remote.default-remote-dispatcher-7] shutting down ActorSystem [sparkDriverActorSystem]
java.lang.VerifyError: (class: org/jboss/netty/channel/socket/nio/NioWorkerPool, method: createWorker signature: (Ljava/util/concurrent/Executor;)Lorg/jboss/netty/channel/socket/nio/AbstractNioWorker;) Wrong return type in function
	at akka.remote.transport.netty.NettyTransport.(NettyTransport.scala:283)
	at akka.remote.transport.netty.NettyTransport.(NettyTransport.scala:240)
	at sun.reflect.NativeConstructorAccessorImpl.newInstance0(Native Method)
	at sun.reflect.NativeConstructorAccessorImpl.newInstance(NativeConstructorAccessorImpl.java:62)
	at sun.reflect.DelegatingConstructorAccessorImpl.newInstance(DelegatingConstructorAccessorImpl.java:45)
	at java.lang.reflect.Constructor.newInstance(Constructor.java:423)
	at akka.actor.ReflectiveDynamicAccess$$anonfun$createInstanceFor$2.apply(DynamicAccess.scala:78)
	at scala.util.Try$.apply(Try.scala:161)
	at akka.actor.ReflectiveDynamicAccess.createInstanceFor(DynamicAccess.scala:73)
	at akka.actor.ReflectiveDynamicAccess$$anonfun$createInstanceFor$3.apply(DynamicAccess.scala:84)
	at akka.actor.ReflectiveDynamicAccess$$anonfun$createInstanceFor$3.apply(DynamicAccess.scala:84)
	at scala.util.Success.flatMap(Try.scala:200)
	at akka.actor.ReflectiveDynamicAccess.createInstanceFor(DynamicAccess.scala:84)
	at akka.remote.EndpointManager$$anonfun$9.apply(Remoting.scala:711)
	at akka.remote.EndpointManager$$anonfun$9.apply(Remoting.scala:703)
	at scala.collection.TraversableLike$WithFilter$$anonfun$map$2.apply(TraversableLike.scala:722)
	at scala.collection.Iterator$class.foreach(Iterator.scala:727)
	at scala.collection.AbstractIterator.foreach(Iterator.scala:1157)
	at scala.collection.IterableLike$class.foreach(IterableLike.scala:72)
	at scala.collection.AbstractIterable.foreach(Iterable.scala:54)
	at scala.collection.TraversableLike$WithFilter.map(TraversableLike.scala:721)
	at akka.remote.EndpointManager.akka$remote$EndpointManager$$listens(Remoting.scala:703)
	at akka.remote.EndpointManager$$anonfun$receive$2.applyOrElse(Remoting.scala:491)
	at akka.actor.Actor$class.aroundReceive(Actor.scala:467)
	at akka.remote.EndpointManager.aroundReceive(Remoting.scala:394)
	at akka.actor.ActorCell.receiveMessage(ActorCell.scala:516)
	at akka.actor.ActorCell.invoke(ActorCell.scala:487)
	at akka.dispatch.Mailbox.processMailbox(Mailbox.scala:238)
	at akka.dispatch.Mailbox.run(Mailbox.scala:220)
	at akka.dispatch.ForkJoinExecutorConfigurator$AkkaForkJoinTask.exec(AbstractDispatcher.scala:397)
	at scala.concurrent.forkjoin.ForkJoinTask.doExec(ForkJoinTask.java:260)
	at scala.concurrent.forkjoin.ForkJoinPool$WorkQueue.runTask(ForkJoinPool.java:1339)
	at scala.concurrent.forkjoin.ForkJoinPool.runWorker(ForkJoinPool.java:1979)
	at scala.concurrent.forkjoin.ForkJoinWorkerThread.run(ForkJoinWorkerThread.java:107)
2019-01-13_17:18:52 [sparkDriverActorSystem-akka.actor.default-dispatcher-6] INFO remote.RemoteActorRefProvider$RemotingTerminator:74: Shutting down remote daemon.
2019-01-13_17:18:52 [sparkDriverActorSystem-akka.actor.default-dispatcher-6] INFO remote.RemoteActorRefProvider$RemotingTerminator:74: Remote daemon shut down; proceeding with flushing remote transports.
2019-01-13_17:18:52 [sparkDriverActorSystem-akka.actor.default-dispatcher-6] ERROR Remoting:65: Remoting system has been terminated abrubtly. Attempting to shut down transports
2019-01-13_17:18:52 [sparkDriverActorSystem-akka.actor.default-dispatcher-6] INFO remote.RemoteActorRefProvider$RemotingTerminator:74: Remoting shut down.
2019-01-13_17:19:02 [main] ERROR spark.SparkContext:95: Error initializing SparkContext.
java.util.concurrent.TimeoutException: Futures timed out after [10000 milliseconds]
	at scala.concurrent.impl.Promise$DefaultPromise.ready(Promise.scala:219)
	at scala.concurrent.impl.Promise$DefaultPromise.result(Promise.scala:223)
	at scala.concurrent.Await$$anonfun$result$1.apply(package.scala:107)
	at scala.concurrent.BlockContext$DefaultBlockContext$.blockOn(BlockContext.scala:53)
	at scala.concurrent.Await$.result(package.scala:107)
	at akka.remote.Remoting.start(Remoting.scala:179)
	at akka.remote.RemoteActorRefProvider.init(RemoteActorRefProvider.scala:184)
	at akka.actor.ActorSystemImpl.liftedTree2$1(ActorSystem.scala:620)
	at akka.actor.ActorSystemImpl._start$lzycompute(ActorSystem.scala:617)
	at akka.actor.ActorSystemImpl._start(ActorSystem.scala:617)
	at akka.actor.ActorSystemImpl.start(ActorSystem.scala:634)
	at akka.actor.ActorSystem$.apply(ActorSystem.scala:142)
	at akka.actor.ActorSystem$.apply(ActorSystem.scala:119)
	at org.apache.spark.util.AkkaUtils$.org$apache$spark$util$AkkaUtils$$doCreateActorSystem(AkkaUtils.scala:121)
	at org.apache.spark.util.AkkaUtils$$anonfun$1.apply(AkkaUtils.scala:53)
	at org.apache.spark.util.AkkaUtils$$anonfun$1.apply(AkkaUtils.scala:52)
	at org.apache.spark.util.Utils$$anonfun$startServiceOnPort$1.apply$mcVI$sp(Utils.scala:2024)
	at scala.collection.immutable.Range.foreach$mVc$sp(Range.scala:141)
	at org.apache.spark.util.Utils$.startServiceOnPort(Utils.scala:2015)
	at org.apache.spark.util.AkkaUtils$.createActorSystem(AkkaUtils.scala:55)
	at org.apache.spark.SparkEnv$.create(SparkEnv.scala:266)
	at org.apache.spark.SparkEnv$.createDriverEnv(SparkEnv.scala:193)
	at org.apache.spark.SparkContext.createSparkEnv(SparkContext.scala:288)
	at org.apache.spark.SparkContext.(SparkContext.scala:457)
	at org.apache.spark.api.java.JavaSparkContext.(JavaSparkContext.scala:59)
	at com.ds.octopus.job.utils.SparkContextUtil.refresh(SparkContextUtil.java:77)
	at com.ds.octopus.job.utils.SparkContextUtil.getJsc(SparkContextUtil.java:34)
	at com.ds.octopus.job.executors.impl.WeiboZPZExporter.action(WeiboZPZExporter.java:95)
	at com.ds.octopus.job.executors.impl.WeiboZPZExporter.action(WeiboZPZExporter.java:41)
	at com.ds.octopus.job.executors.SimpleExecutor.execute(SimpleExecutor.java:40)
	at com.ds.octopus.job.client.OctopusClient.run(OctopusClient.java:162)
	at com.yeezhao.commons.buffalo.job.AbstractBUTaskWorker.runTask(AbstractBUTaskWorker.java:63)
	at com.ds.octopus.job.client.TaskLocalRunnerCli.start(TaskLocalRunnerCli.java:109)
	at com.yeezhao.commons.util.AdvCli.initRunner(AdvCli.java:191)
	at com.ds.octopus.job.client.TaskLocalRunnerCli.main(TaskLocalRunnerCli.java:41)
2019-01-13_17:19:02 [main] INFO spark.SparkContext:58: Successfully stopped SparkContext
````

错误日志截图：
![错误日志局部](https://ws1.sinaimg.cn/large/b7f2e3a3gy1fz5j8uvmnrj219y0kqdil.jpg "错误日志局部")

根据日志没有看出有关 Java 层面的什么问题，只能根据 JNI 字段描述符：
````java
class: org/jboss/netty/channel/socket/nio/NioWorkerPool
````
猜测是某一个类的问题，根据：
````java
method: createWorker signature: (Ljava/util/concurrent/Executor;)Lorg/jboss/netty/channel/socket/nio/AbstractNioWorker;) Wrong return type in function
````
猜测是某个方法的问题，方法的返回类型错误。

然后在项目中使用 ctrl+shift+t 快捷键（全局搜索 Java 类，每个人的开发工具设置的可能不一样）搜索类：NioWorkerPool，发现这个类的来源不是新引入的依赖包，而是原本就有的 netty 相关包，所以此时就可以断定这个莫名其妙的错误的原因就在于这个类的 createWorker 方法返回类型上面了。

搜索类 NioWorkerPool
![搜索NioWorkerPool](https://ws1.sinaimg.cn/large/b7f2e3a3gy1fz5j9dcym1j216q0aztai.jpg "搜索NioWorkerPool")

日志的 JNI 字段描述符显示返回类型是 AbstractNioWorker，但是这个一看就是抽象类，不是我们要找的，去类里面看源码，发现 createWorker 方法返回类型是 NioWorker：

类 NioWorkerPool 源码
![NioWorkerPool源码](https://ws1.sinaimg.cn/large/b7f2e3a3gy1fz5j9wfx1mj20wu0et3z8.jpg "NioWorkerPool源码")

继续搜索类 NioWorker
![搜索NioWorker](https://ws1.sinaimg.cn/large/b7f2e3a3gy1fz5jagdz1qj216t09wwg0.jpg "搜索NioWorker")

好，此时发现问题了，这个类有2个，居然存在两个相同的包名，但是依赖坐标不一样，所以这个隐藏的原因在于类冲突，但是并不能算是依赖冲突引起的。也就是说，NioWorker 这个类重复了，但是依赖包坐标不一样，类的包路径却是一模一样的，不会引起版本冲突问题，而在实际运行任务的时候会抛出运行时异常，所以我觉得找问题的过程很艰辛。

使用依赖树查看依赖关系，是看不到版本冲突问题的，2个依赖都存在：
io.netty 依赖
![io.netty依赖](https://ws1.sinaimg.cn/large/b7f2e3a3gy1fz5jaxljmvj20mb05fglv.jpg "io.netty 依赖")

org.jboss.netty 依赖
![org.jboss.netty 依赖](https://ws1.sinaimg.cn/large/b7f2e3a3gy1fz5jb7z4o0j20la031t8r.jpg "org.jboss.netty 依赖")

于是又在网上搜索了一下，发现果然是 netty 的问题，也就是新引入的依赖包导致的，但是根本原因令人哭笑：netty 的组织结构变化，发布的依赖坐标名称变化，但是所有的类的包名称并没有变化，导致了这个错误。


# 问题解决


问题找到了，解决方法就简单了，移除传递依赖即可，同时也要注意以后再添加新的依赖一定要慎重，不然找问题的过程很是令人崩溃。

移除依赖
![移除依赖](https://ws1.sinaimg.cn/large/b7f2e3a3gy1fz5jbj046wj20g907amxa.jpg "移除依赖")

移除配置示例
````xml
<!-- 移除引发冲突的jar包 -->
<exclusions>
  <exclusion>
    <groupId>org.jboss.netty</groupId>
    <artifactId>netty</artifactId>
  </exclusion>
</exclusions>
````


# 问题总结


1、参考：[https://stackoverflow.com/questions/33573587/apache-spark-wrong-akka-remote-netty-version](https://stackoverflow.com/questions/33573587/apache-spark-wrong-akka-remote-netty-version) ；

2、netty 的组织结构（影响发布的 jar 包坐标名称）变化了，但是所有的类的包名称仍然是一致的，很奇怪，导致我找问题也觉得莫名其妙，因为这不会引发版本冲突问题（但是本质上又是2个一模一样的类被同时使用，引发类冲突）；

3、这个错误信息挺有意思的，解决过程也很好玩，边找边学习；

4、对于这种重名的类【类的包路径名、类名】，竟然对应的 jar 包不一样，这种极其特殊的情况也可以使用插件检测出来：

```
<groupId>org.apache.maven.plugins</groupId>
<artifactId>maven-enforcer-plugin</artifactId>
```

使用 **enforcer:enforce** 命令即可。

当然，这个插件还可以用来校验很多地方，例如代码中引用了 **@Deprecated** 的方法，也会给出提示信息，可以按照需求给插件配置需要校验的方面。


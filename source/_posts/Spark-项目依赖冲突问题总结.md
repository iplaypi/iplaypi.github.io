---
title: Spark 项目依赖冲突问题总结
id: 2019112901
date: 2019-11-29 20:05:46
updated: 2019-11-29 20:05:46
categories: 踩坑系列
tags: [Spark,Maven,shade]
keywords: Spark,Maven,shade
---


今天遇到一个常见的依赖冲突问题，在一个 `Spark` 项目中，引用了多个其它项目的公共包【例如公共 `elt` 模块、算法模块】，在提交运行 `Spark` 任务时，由于依赖冲突而失败，高低版本无法兼容。

本文记录问题解决过程以及经验总结，重要开发环境说明：`Spark v1.6`、`es-hadoop v5.6.8`、`kafka v0.9.x` 。


<!-- more -->


# 问题出现


在一个 `SparkStreaming` 项目中，由于业务需要而新增加了算法模块的依赖【公司开放的公共 `jar` 包】，结果无法正常运行，根本原因在于依赖包冲突，版本无法完全匹配。

下面简单描述一下各种现象，这当然是为了给读者参考才这么做的，在实际开发过程中如果也这么尝试是很浪费时间的【当然对于初学者还是很有必要的，实际踩坑才知道痛苦】。

在一开始，添加算法模块的依赖后，使用本地 `local` 模式试运行程序正常，相关算法接口可用，但是当提交任务到 `Spark` 集群后【`standalone` 模式】，提交任务失败，出现 `kryo` 序列化异常：

````
2019-11-26_18:00:32 [task-result-getter-0] WARN scheduler.TaskSetManager:70: Lost task 0.0 in stage 0.0 (TID 0, dev4): java.io.EOFException
	at org.apache.spark.serializer.KryoDeserializationStream.readObject(KryoSerializer.scala:232)
	at org.apache.spark.broadcast.TorrentBroadcast$.unBlockifyObject(TorrentBroadcast.scala:217)
	at org.apache.spark.broadcast.TorrentBroadcast$$anonfun$readBroadcastBlock$1.apply(TorrentBroadcast.scala:178)
	at org.apache.spark.util.Utils$.tryOrIOException(Utils.scala:1205)
	at org.apache.spark.broadcast.TorrentBroadcast.readBroadcastBlock(TorrentBroadcast.scala:165)
	at org.apache.spark.broadcast.TorrentBroadcast._value$lzycompute(TorrentBroadcast.scala:64)
	at org.apache.spark.broadcast.TorrentBroadcast._value(TorrentBroadcast.scala:64)
	at org.apache.spark.broadcast.TorrentBroadcast.getValue(TorrentBroadcast.scala:88)
	at org.apache.spark.broadcast.Broadcast.value(Broadcast.scala:70)
	at org.apache.spark.scheduler.ResultTask.runTask(ResultTask.scala:62)
	at org.apache.spark.scheduler.Task.run(Task.scala:89)
	at org.apache.spark.executor.Executor$TaskRunner.run(Executor.scala:227)
	at java.util.concurrent.ThreadPoolExecutor.runWorker(ThreadPoolExecutor.java:1149)
	at java.util.concurrent.ThreadPoolExecutor$Worker.run(ThreadPoolExecutor.java:624)
	at java.lang.Thread.run(Thread.java:748)
````

![启动 Spark 任务失败](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2018/20191201000221.png "启动 Spark 任务失败")

经过简单排查，上述错误的原因在于 `Spark` 需要依赖 `kryo v2.21`，而算法模块里面依赖了 `kryo v4.0.1`，在多版本同时存在的情况下，`Java` 类加载器加载到了高版本的 `kryo`【当然先加载到哪个类不确定，但是由前面的现象可以判定先加载了高版本的 `jar` 包】，导致 `Spark` 不兼容。

进一步想到可以将算法模块中的高版本 `kryo` 排除【当然此时没有考虑这样做对算法接口的影响】，我还就这么做了，又试了一次，结果出现以下异常【敏感包名使用 `xxx.yyy` 替换】：

````
java.lang.reflect.InvocationTargetException
	at org.apache.dubbo.common.bytecode.Wrapper0.invokeMethod(Wrapper0.java)
	at com.xxx.yyy.consumer.proxy.JavassistProxyFactory$1.doInvoke(JavassistProxyFactory.java:28)
	at com.xxx.yyy.consumer.proxy.AbstractProxyInvoker.doInvoke(AbstractProxyInvoker.java:57)
	at com.xxx.yyy.consumer.metric.ThanosConsumerMetric.makeMetric(ThanosConsumerMetric.java:90)
	at com.xxx.yyy.consumer.proxy.AbstractProxyInvoker.invoke(AbstractProxyInvoker.java:53)
	at com.xxx.yyy.consumer.proxy.InvokerInvocationHandler.invoke(InvokerInvocationHandler.java:36)
	at org.apache.dubbo.common.bytecode.proxy1.classify(proxy1.java)
	at com.xxx.zzz.analyz.rpc.ThanosRpcAlgorithmAnalyzer.classify(ThanosRpcAlgorithmAnalyzer.java:50)
	at com.xxx.zzz.analyz.rpc.ThanosRpcAlgorithmAnalyzer.classify(ThanosRpcAlgorithmAnalyzer.java:55)
	at com.xxx.zzz.analyz.rpc.ThanosRpcAlgorithmAnalyzer.main(ThanosRpcAlgorithmAnalyzer.java:70)
Caused by: org.apache.dubbo.rpc.RpcException: Failed to invoke the method classify in the service com.xxx.yyy.service.Classifier. Tried 3 times of the providers [172.18.5.66:31142, 172.18.5.145:31142] (2/2) from the registry dev3:2181 on the consumer 172.18.7.203 using the dubbo version 2.7.3. Last error is: Failed to invoke remote method: classify, provider: dubbo://172.18.5.145:31142/com.xxx.yyy.service.Classifier?application=xxx-rpc-consumer&check=false&cluster=backpressure&deprecated=false&dubbo=2.0.2&interface=com.xxx.yyy.service.Classifier&lazy=false&loadbalance=leastactive&pid=10388&qos.enable=false&reference.filter=requestid,activelimit&register.ip=172.18.7.203&release=2.7.3&remote.application=xxx-rpc-provider&retries=2&revision=0.1-20191122.093730-4&serialization=kryo&side=consumer&sticky=false&timeout=2147483647&timestamp=1574327320883&weight=16, cause: org.apache.dubbo.remoting.RemotingException: io.netty.handler.codec.EncoderException: java.lang.NoClassDefFoundError: com/esotericsoftware/kryo/pool/KryoFactory
io.netty.handler.codec.EncoderException: java.lang.NoClassDefFoundError: com/esotericsoftware/kryo/pool/KryoFactory
	at io.netty.handler.codec.MessageToByteEncoder.write(MessageToByteEncoder.java:125)
	at io.netty.channel.AbstractChannelHandlerContext.invokeWrite(AbstractChannelHandlerContext.java:658)
	at io.netty.channel.AbstractChannelHandlerContext.write(AbstractChannelHandlerContext.java:716)
	at io.netty.channel.AbstractChannelHandlerContext.write(AbstractChannelHandlerContext.java:651)
	at io.netty.handler.timeout.IdleStateHandler.write(IdleStateHandler.java:266)
	at io.netty.channel.AbstractChannelHandlerContext.invokeWrite(AbstractChannelHandlerContext.java:658)
	at io.netty.channel.AbstractChannelHandlerContext.write(AbstractChannelHandlerContext.java:716)
	at io.netty.channel.AbstractChannelHandlerContext.write(AbstractChannelHandlerContext.java:651)
	at io.netty.channel.ChannelDuplexHandler.write(ChannelDuplexHandler.java:106)
	at org.apache.dubbo.remoting.transport.netty4.NettyClientHandler.write(NettyClientHandler.java:87)
	at io.netty.channel.AbstractChannelHandlerContext.invokeWrite(AbstractChannelHandlerContext.java:658)
	at io.netty.channel.AbstractChannelHandlerContext.access$2000(AbstractChannelHandlerContext.java:32)
	at io.netty.channel.AbstractChannelHandlerContext$AbstractWriteTask.write(AbstractChannelHandlerContext.java:939)
	at io.netty.channel.AbstractChannelHandlerContext$WriteAndFlushTask.write(AbstractChannelHandlerContext.java:991)
	at io.netty.channel.AbstractChannelHandlerContext$AbstractWriteTask.run(AbstractChannelHandlerContext.java:924)
	at io.netty.util.concurrent.SingleThreadEventExecutor.runAllTasks(SingleThreadEventExecutor.java:380)
	at io.netty.channel.nio.NioEventLoop.run(NioEventLoop.java:357)
	at io.netty.util.concurrent.SingleThreadEventExecutor$2.run(SingleThreadEventExecutor.java:116)
	at io.netty.util.concurrent.DefaultThreadFactory$DefaultRunnableDecorator.run(DefaultThreadFactory.java:137)
	at java.lang.Thread.run(Thread.java:748)
Caused by: java.lang.NoClassDefFoundError: com/esotericsoftware/kryo/pool/KryoFactory
	at java.lang.ClassLoader.defineClass1(Native Method)
	at java.lang.ClassLoader.defineClass(ClassLoader.java:763)
	at java.security.SecureClassLoader.defineClass(SecureClassLoader.java:142)
	at java.net.URLClassLoader.defineClass(URLClassLoader.java:467)
	at java.net.URLClassLoader.access$100(URLClassLoader.java:73)
	at java.net.URLClassLoader$1.run(URLClassLoader.java:368)
	at java.net.URLClassLoader$1.run(URLClassLoader.java:362)
	at java.security.AccessController.doPrivileged(Native Method)
	at java.net.URLClassLoader.findClass(URLClassLoader.java:361)
	at java.lang.ClassLoader.loadClass(ClassLoader.java:424)
	at sun.misc.Launcher$AppClassLoader.loadClass(Launcher.java:349)
	at java.lang.ClassLoader.loadClass(ClassLoader.java:357)
	at org.apache.dubbo.common.serialize.kryo.KryoObjectOutput.<init>(KryoObjectOutput.java:39)
	at org.apache.dubbo.common.serialize.kryo.KryoSerialization.serialize(KryoSerialization.java:51)
	at org.apache.dubbo.remoting.exchange.codec.ExchangeCodec.encodeRequest(ExchangeCodec.java:234)
	at org.apache.dubbo.remoting.exchange.codec.ExchangeCodec.encode(ExchangeCodec.java:69)
	at org.apache.dubbo.rpc.protocol.dubbo.DubboCountCodec.encode(DubboCountCodec.java:40)
	at org.apache.dubbo.remoting.transport.netty4.NettyCodecAdapter$InternalEncoder.encode(NettyCodecAdapter.java:70)
	at io.netty.handler.codec.MessageToByteEncoder.write(MessageToByteEncoder.java:107)
	... 19 more
````

![算法接口抛异常](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2018/20191201001332.png "算法接口抛异常")

这里可以明确得出的是，由于擅自排除了算法模块需要的高版本 `kryo`，现在算法接口无法提供服务了，缺失 `KryoFactory` 类。

没办法，只好对算法模块中的 `kryo` 做了影子复制，把包名 `com.esotericsoftware.kryo` 变更了一下，这样既不会影响到算法接口的使用，也不会影响到 `Spark` 任务提交。

好，`kryo` 的冲突问题解决了，但是紧接着又出现了 `netty` 冲突问题，现象类似，异常信息如下：

````
2019-11-29_18:23:32 [appclient-register-master-threadpool-0] INFO client.AppClient$ClientEndpoint:58: Connecting to master spark://dev4:7077...
2019-11-29_18:23:32 [shuffle-client-0] ERROR client.TransportClient:235: Failed to send RPC 8750922883607188033 to dev4/172.18.5.204:7077: java.lang.AbstractMethodError: org.apache.spark.network.protocol.MessageWithHeader.touch(Ljava/l
ang/Object;)Lio/netty/util/ReferenceCounted;
java.lang.AbstractMethodError: org.apache.spark.network.protocol.MessageWithHeader.touch(Ljava/lang/Object;)Lio/netty/util/ReferenceCounted;
	at io.netty.util.ReferenceCountUtil.touch(ReferenceCountUtil.java:77)
	at io.netty.channel.DefaultChannelPipeline.touch(DefaultChannelPipeline.java:116)
	at io.netty.channel.AbstractChannelHandlerContext.write(AbstractChannelHandlerContext.java:785)
	at io.netty.channel.AbstractChannelHandlerContext.write(AbstractChannelHandlerContext.java:701)
	at io.netty.handler.codec.MessageToMessageEncoder.write(MessageToMessageEncoder.java:112)
	at io.netty.channel.AbstractChannelHandlerContext.invokeWrite0(AbstractChannelHandlerContext.java:716)
	at io.netty.channel.AbstractChannelHandlerContext.invokeWrite(AbstractChannelHandlerContext.java:708)
	at io.netty.channel.AbstractChannelHandlerContext.write(AbstractChannelHandlerContext.java:791)
	at io.netty.channel.AbstractChannelHandlerContext.write(AbstractChannelHandlerContext.java:701)
	at io.netty.handler.timeout.IdleStateHandler.write(IdleStateHandler.java:303)
	at io.netty.channel.AbstractChannelHandlerContext.invokeWrite0(AbstractChannelHandlerContext.java:716)
	at io.netty.channel.AbstractChannelHandlerContext.invokeWrite(AbstractChannelHandlerContext.java:708)
	at io.netty.channel.AbstractChannelHandlerContext.access$1700(AbstractChannelHandlerContext.java:56)
	at io.netty.channel.AbstractChannelHandlerContext$AbstractWriteTask.write(AbstractChannelHandlerContext.java:1102)
	at io.netty.channel.AbstractChannelHandlerContext$WriteAndFlushTask.write(AbstractChannelHandlerContext.java:1149)
	at io.netty.channel.AbstractChannelHandlerContext$AbstractWriteTask.run(AbstractChannelHandlerContext.java:1073)
	at io.netty.util.concurrent.AbstractEventExecutor.safeExecute(AbstractEventExecutor.java:163)
	at io.netty.util.concurrent.SingleThreadEventExecutor.runAllTasks(SingleThreadEventExecutor.java:510)
	at io.netty.channel.nio.NioEventLoop.run(NioEventLoop.java:518)
	at io.netty.util.concurrent.SingleThreadEventExecutor$6.run(SingleThreadEventExecutor.java:1044)
	at io.netty.util.internal.ThreadExecutorMap$2.run(ThreadExecutorMap.java:74)
	at java.lang.Thread.run(Thread.java:748)
2019-11-29_18:23:32 [appclient-register-master-threadpool-0] WARN client.AppClient$ClientEndpoint:91: Failed to connect to master dev4:7077
java.io.IOException: Failed to send RPC 8750922883607188033 to dev4/172.18.5.204:7077: java.lang.AbstractMethodError: org.apache.spark.network.protocol.MessageWithHeader.touch(Ljava/lang/Object;)Lio/netty/util/ReferenceCounted;
	at org.apache.spark.network.client.TransportClient$3.operationComplete(TransportClient.java:239)
	at org.apache.spark.network.client.TransportClient$3.operationComplete(TransportClient.java:226)
	at io.netty.util.concurrent.DefaultPromise.notifyListener0(DefaultPromise.java:577)
	at io.netty.util.concurrent.DefaultPromise.notifyListenersNow(DefaultPromise.java:551)
	at io.netty.util.concurrent.DefaultPromise.notifyListeners(DefaultPromise.java:490)
	at io.netty.util.concurrent.DefaultPromise.setValue0(DefaultPromise.java:615)
	at io.netty.util.concurrent.DefaultPromise.setFailure0(DefaultPromise.java:608)
	at io.netty.util.concurrent.DefaultPromise.tryFailure(DefaultPromise.java:117)
	at io.netty.util.internal.PromiseNotificationUtil.tryFailure(PromiseNotificationUtil.java:64)
	at io.netty.channel.AbstractChannelHandlerContext.notifyOutboundHandlerException(AbstractChannelHandlerContext.java:818)
	at io.netty.channel.AbstractChannelHandlerContext.invokeWrite0(AbstractChannelHandlerContext.java:718)
	at io.netty.channel.AbstractChannelHandlerContext.invokeWrite(AbstractChannelHandlerContext.java:708)
	at io.netty.channel.AbstractChannelHandlerContext.write(AbstractChannelHandlerContext.java:791)
	at io.netty.channel.AbstractChannelHandlerContext.write(AbstractChannelHandlerContext.java:701)
	at io.netty.handler.timeout.IdleStateHandler.write(IdleStateHandler.java:303)
	at io.netty.channel.AbstractChannelHandlerContext.invokeWrite0(AbstractChannelHandlerContext.java:716)
	at io.netty.channel.AbstractChannelHandlerContext.invokeWrite(AbstractChannelHandlerContext.java:708)
	at io.netty.channel.AbstractChannelHandlerContext.access$1700(AbstractChannelHandlerContext.java:56)
	at io.netty.channel.AbstractChannelHandlerContext$AbstractWriteTask.write(AbstractChannelHandlerContext.java:1102)

````

![netty 异常](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2018/20191201001713.png "netty 异常")

这个问题我见过很多次，通过简单排查发现 `Spark` 需要的是 `netty-all v4.0.29`，而算法模块需要的是 `v4.1.25`，我在本地看到实际加载的是 `v4.0.29`，这里 `Spark` 任务为什么提交失败我有疑惑【我只能怀疑服务器加载类的顺序和我本机的不一致，导致服务器上面实际加载的并不是 `Spark` 需要的版本】。

接着按照我的怀疑把高版本 `netty-all` 排除了，恢复正常【这里不需要复制影子，因为版本差别不大，算法模块可以兼容低版本 `netty-all` 依赖】。

但是，接着又出现 `org.apache.curator:curator-recipes` 依赖的问题，这是 `Spark` 任务读取 `kafka` 需要的依赖，而在算法模块中也需要。

异常信息如下：

````
Exception in thread "main" java.lang.NoSuchMethodError: org.apache.curator.framework.api.CreateBuilder.creatingParentsIfNeeded()Lorg/apache/curator/framework/api/ProtectACLCreateModePathAndBytesable;
````

![curator 异常](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2018/20191201001855.png "curator 异常")

其中，在 `Spark` 中需要的版本是 `v2.4.0`，而在算法模块中需要的是 `v4.0.1`，我看到实际加载的是 `v4.0.1`，所以 `Spark` 任务又失败了。

再按照这个节奏进行下去，读者是不是要疯掉了！好，我们到此为止，准备使用万能优雅的 `maven-shade-plugin` 插件解决这类让人抓狂的问题【只需要找到冲突的 `jar` 包替换包名，不需要排除】。


# 问题分析解决


## 简单分析解决

在上面的流程中，我会想到变更 `jar` 包依赖版本，或者移除多余的依赖，尝试让合适的版本出现，从而兼容代码中所有的调用。但是，遇到稍微复杂的情况这种做法显然是徒劳的。

诚然，这种方式针对单线程或者本地 `local` 模式运行的程序是可以生效的，但是对于集群模式的【`standalone`、`yarn` 等】`Spark` 任务，就无能为力了，很难恰好找到匹配的版本，毕竟公共包本身使用的依赖不是你能控制的，也不会为了你而做兼容【公共包面向大众发布，一般都会使用最新版本的依赖】。

接着详细来解释一下我这个典型场景，`Spark` 使用了一个低版本的 `kryo`，而算法模块使用了另外高版本的 `kyro`，但是诡异的是它们的依赖坐标不一致【算法模块是 `com.esotericsoftware:kryo`、`Spark` 是 `com.esotericsoftware.kryo:kryo`】，而实际类的包名却是一致的【都是 `com.esotericsoftware.kryo`】，这就导致类冲突无法兼容【在人们的经验中，`jar` 包坐标不同，类的包名也应该不同才对】。当然，`kryo` 高低版本之间的类不同也是无法兼容的原因之一。

如果选择移除算法模块的 `kryo`，调用算法接口时会报找不到类异常，如果移除 `Spark` 的 `kryo`，提交 `Spark` 任务时会报无法反序列化异常。

而且，比较让人崩溃的是，真的无法找到兼容两者的版本，那就只能利用 `maven-shade-plugin` 插件了。

我这里的项目本身使用的 `maven-shade-plugin` 插件是为了把所有的依赖都打包在一起，形成 `uber jar`，需要启动 `Spark` 任务时一起提交到集群。这样做主要是因为 `Spark` 集群的 `libs` 中没有存放任何公共依赖包，比较纯净，所以需要提交任务的客户端自己打包携带，这样也可以避免很多业务方共同使用同一个 `Spark` 集群产生依赖冲突问题。

无奈，最终只好决定使用 `maven-shade-plugin` 插件的高级功能：影子别名，直接变更类名，就不怕再冲突了。

使用 `maven-shade-plugin` 插件制作影子的相关类配置【把类的包名替换掉，避免冲突，根据项目的实际冲突情况而配置，这里仅供参考】：

````
<configuration>
    <relocations>
        <relocation>
            <pattern>com.google</pattern>
            <shadedPattern>iplaypi.com.google</shadedPattern>
        </relocation>
        <relocation>
            <pattern>io.netty</pattern>
            <shadedPattern>iplaypi.io.netty</shadedPattern>
        </relocation>
        <relocation>
            <pattern>org.apache.curator</pattern>
            <shadedPattern>iplaypi.org.apache.curator</shadedPattern>
        </relocation>
        <relocation>
            <pattern>com.esotericsoftware</pattern>
            <shadedPattern>iplaypi.com.esotericsoftware</shadedPattern>
        </relocation>
        <relocation>
            <pattern>de.javakaffee</pattern>
            <shadedPattern>iplaypi.de.javakaffee</shadedPattern>
        </relocation>
    </relocations>
</configuration>
````

我这里把 `guava`、`netty`、`curator`、`kryo` 全部制作影子了，仅供参考。

## 抽象简化问题

下面就用模型简化一下我遇到的这类场景，使用 `guava` 包冲突做示例。

`Maven` 项目中有 `a`、`b`、`c` 三个模块【分散为三个模块读者更容易理解，解决问题思路也更清晰】，`a` 同时依赖了 `b`、`c`。其中，`b` 依赖了低版本 `guava` 并调用了一个低版本独有的方法，`c` 依赖了高版本 `guava` 并调用了高版本独有的方法【当然引用特有的类也行】。

它们之间的关系如下图：

![项目依赖关系](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20200209000340.png "项目依赖关系")

在这个 `Maven` 项目中，发生 `jar` 包冲突很明显是因为，项目中依赖了同一个 `jar` 包的多个版本，而且分别调用了高低版本特有的方法，或者引用了高低版本特有的类。面对此类问题，一般的解决思路是只保留一个版本，排除掉不需要的版本，但是上面这种情况太特殊了，排除 `jar` 包不能解决问题。

可以试想一下，排除掉低版本 `guava` 的话 `b` 会报错，排掉高版本 `guava` 的话 `c` 会报错，所以希望在项目中同时使用低版本 `guava` 和高版本 `guava`。

那就只能使用 `maven-shade-plugin` 插件来构建影子 `jar` 包，替换类路径，制作影子的效果如下图【思路就是构建 `c` 时替换掉 `guava` 的包名】：

![shade 插件替换类路径](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20200209000438.png "shade 插件替换类路径")

这样就可以非常优雅地解决问题，但是会导致打包的 `jar` 比以前大一点。如果 `Maven` 项目本身没有那么多模块，只有一个大模块，建议拆分，至少把有冲突的部分单独拆出来构建影子模块。

这个方案的详细说明以及代码演示读者可以参考我的另外一篇博文：[解决 jar 包冲突的神器：maven-shade-plugin](https://www.playpi.org/2019120101.html) 。


# 问题总结


在制作影子时，`Maven` 的子模块是必不可少的帮手，否则还需要下载源码自己重新打包，麻烦而且做法不合适。

`Java` 项目拆分为子模块的好处之一，遇到依赖冲突时，可以很方便地使用 `maven-shade-plugin` 插件，分分钟就可以制作影子。例如上面的抽象简化例子，如果 `a`、`b`、`c` 没有拆分，一直是一个模块，遇到这种依赖冲突就没办法解决，怎么排除都是不行的，只能单独构建一个子模块用来制作影子。

当然，如果上面的 `c` 本身就依赖了很多 `jar` 包，它们之间在 `c` 模块中就有冲突，也不好制作影子，还是单独新建一个纯净的子模块比较好【例如把类似 `guava` 冲突的 `jar` 包以及代码抽出来，单独创建 `c-sub-shade` 模块，在里面制作影子，这个模块给 `c` 引用】。

![shade 子模块](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20200209000650.png "shade 子模块")

注意，上图和我本文中遇到的例子有一点不同，我的 `jar` 包在 `c` 模块中并没有冲突，所以可以直接利用 `c` 制作影子模块 `c-shade`，当然不怕麻烦也可以制作 `c-sub-shade`。

此外，我在一年前也遇到过一种简单的场景：[Spark Kryo 异常](https://www.playpi.org/2018100801.html)，当时直接通过排除依赖就解决问题了，但是这次的场景太复杂，只能启用 `maven-shade-plugin` 插件了。


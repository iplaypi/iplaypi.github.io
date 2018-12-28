---
title: Spark 异常之 java.net.BindException:地址已在使用
id: 2018122801
date: 2018-12-28 23:49:01
updated: 2018-12-28 23:49:01
categories: 基础技术知识
tags: [Spark,BindException]
keywords: Spark,BindException
---


今天查看日志发现，所有的 Spark 程序提交时会抛出异常：

````java
java.net.BindException: 地址已在使用
````

而且不止一次，会连续有多个这种异常，但是 Spark 程序又能正常运行，不会影响到对应的功能。本文就记录发现问题、分析问题的过程。

<!-- more -->


# 问题出现


在 Driver 端查看日志，发现连续多次相同的异常（省略了业务相关类信息）：

异常截图

![异常截图](https://ws1.sinaimg.cn/large/b7f2e3a3gy1fymxb3zolsj210v0dzabe.jpg "异常截图")

````java
// 第一次异常
2018-12-28_12:50:56 [main] WARN component.AbstractLifeCycle:204: FAILED SelectChannelConnector@0.0.0.0:4040: java.net.BindException: 地址已在使用
java.net.BindException: 地址已在使用
	at sun.nio.ch.Net.bind0(Native Method)
	at sun.nio.ch.Net.bind(Net.java:433)
	at sun.nio.ch.Net.bind(Net.java:425)
	at sun.nio.ch.ServerSocketChannelImpl.bind(ServerSocketChannelImpl.java:223)
	at sun.nio.ch.ServerSocketAdaptor.bind(ServerSocketAdaptor.java:74)
	at org.spark-project.jetty.server.nio.SelectChannelConnector.open(SelectChannelConnector.java:187)
	at org.spark-project.jetty.server.AbstractConnector.doStart(AbstractConnector.java:316)
	at org.spark-project.jetty.server.nio.SelectChannelConnector.doStart(SelectChannelConnector.java:265)
	at org.spark-project.jetty.util.component.AbstractLifeCycle.start(AbstractLifeCycle.java:64)
	at org.spark-project.jetty.server.Server.doStart(Server.java:293)
	at org.spark-project.jetty.util.component.AbstractLifeCycle.start(AbstractLifeCycle.java:64)
	at org.apache.spark.ui.JettyUtils$.org$apache$spark$ui$JettyUtils$$connect$1(JettyUtils.scala:252)
	at org.apache.spark.ui.JettyUtils$$anonfun$5.apply(JettyUtils.scala:262)
	at org.apache.spark.ui.JettyUtils$$anonfun$5.apply(JettyUtils.scala:262)
	at org.apache.spark.util.Utils$$anonfun$startServiceOnPort$1.apply$mcVI$sp(Utils.scala:2024)
	at scala.collection.immutable.Range.foreach$mVc$sp(Range.scala:141)
	at org.apache.spark.util.Utils$.startServiceOnPort(Utils.scala:2015)
	at org.apache.spark.ui.JettyUtils$.startJettyServer(JettyUtils.scala:262)
	at org.apache.spark.ui.WebUI.bind(WebUI.scala:136)
	at org.apache.spark.SparkContext$$anonfun$13.apply(SparkContext.scala:481)
	at org.apache.spark.SparkContext$$anonfun$13.apply(SparkContext.scala:481)
	at scala.Option.foreach(Option.scala:236)
	at org.apache.spark.SparkContext.<init>(SparkContext.scala:481)
	at org.apache.spark.api.java.JavaSparkContext.<init>(JavaSparkContext.scala:59)
......
2018-12-28_12:50:56 [main] WARN component.AbstractLifeCycle:204: FAILED org.spark-project.jetty.server.Server@33e434c8: java.net.BindException: 地址已在使用
java.net.BindException: 地址已在使用
	at sun.nio.ch.Net.bind0(Native Method)
	at sun.nio.ch.Net.bind(Net.java:433)
	at sun.nio.ch.Net.bind(Net.java:425)
	at sun.nio.ch.ServerSocketChannelImpl.bind(ServerSocketChannelImpl.java:223)
	at sun.nio.ch.ServerSocketAdaptor.bind(ServerSocketAdaptor.java:74)
	at org.spark-project.jetty.server.nio.SelectChannelConnector.open(SelectChannelConnector.java:187)
	at org.spark-project.jetty.server.AbstractConnector.doStart(AbstractConnector.java:316)
	at org.spark-project.jetty.server.nio.SelectChannelConnector.doStart(SelectChannelConnector.java:265)
	at org.spark-project.jetty.util.component.AbstractLifeCycle.start(AbstractLifeCycle.java:64)
	at org.spark-project.jetty.server.Server.doStart(Server.java:293)
	at org.spark-project.jetty.util.component.AbstractLifeCycle.start(AbstractLifeCycle.java:64)
	at org.apache.spark.ui.JettyUtils$.org$apache$spark$ui$JettyUtils$$connect$1(JettyUtils.scala:252)
	at org.apache.spark.ui.JettyUtils$$anonfun$5.apply(JettyUtils.scala:262)
	at org.apache.spark.ui.JettyUtils$$anonfun$5.apply(JettyUtils.scala:262)
	at org.apache.spark.util.Utils$$anonfun$startServiceOnPort$1.apply$mcVI$sp(Utils.scala:2024)
	at scala.collection.immutable.Range.foreach$mVc$sp(Range.scala:141)
	at org.apache.spark.util.Utils$.startServiceOnPort(Utils.scala:2015)
	at org.apache.spark.ui.JettyUtils$.startJettyServer(JettyUtils.scala:262)
	at org.apache.spark.ui.WebUI.bind(WebUI.scala:136)
	at org.apache.spark.SparkContext$$anonfun$13.apply(SparkContext.scala:481)
	at org.apache.spark.SparkContext$$anonfun$13.apply(SparkContext.scala:481)
	at scala.Option.foreach(Option.scala:236)
	at org.apache.spark.SparkContext.<init>(SparkContext.scala:481)
	at org.apache.spark.api.java.JavaSparkContext.<init>(JavaSparkContext.scala:59)
......

// 第二次异常
2018-12-28_12:50:56 [main] WARN component.AbstractLifeCycle:204: FAILED SelectChannelConnector@0.0.0.0:4041: java.net.BindException: 地址已在使用
java.net.BindException: 地址已在使用
	at sun.nio.ch.Net.bind0(Native Method)
	at sun.nio.ch.Net.bind(Net.java:433)
	at sun.nio.ch.Net.bind(Net.java:425)
......其它信息都一样

// 第三次异常
2018-12-28_12:50:56 [main] WARN component.AbstractLifeCycle:204: FAILED SelectChannelConnector@0.0.0.0:4042: java.net.BindException: 地址已在使用
java.net.BindException: 地址已在使用
	at sun.nio.ch.Net.bind0(Native Method)
	at sun.nio.ch.Net.bind(Net.java:433)
	at sun.nio.ch.Net.bind(Net.java:425)
.......其它信息都一样

// 第一次异常
2018-12-28_12:50:56 [main] WARN component.AbstractLifeCycle:204: FAILED SelectChannelConnector@0.0.0.0:4043: java.net.BindException: 地址已在使用
java.net.BindException: 地址已在使用
	at sun.nio.ch.Net.bind0(Native Method)
	at sun.nio.ch.Net.bind(Net.java:433)
	at sun.nio.ch.Net.bind(Net.java:425)
.......其它信息都一样
````

可以轻易发现核心的地方在于：
````java
FAILED SelectChannelConnector@0.0.0.0:端口号: java.net.BindException: 地址已在使用
````

端口号在不断变化，从4040一直到4043，才停止了异常的抛出。


# 问题分析


在 Spark 创建 context 的时候，会使用 4040 端口作为默认的 SparkUI 端口，如果遇到4040端口被占用，则会抛出异常。接着会尝试下一个可用的端口，采用累加的方式，则使用4041端口，很不巧，这个端口也被占用了，也会抛出异常。接着就是重复上面的过程，直到找到空闲的端口。

这个异常其实没什么问题，是正常的，原因可能就是在一台机器上面有多个进程都在使用 Spark，创建 context，有的 Spark 任务正在运行着，占用了4040端口；或者就是单纯的端口被某些应用程序占用了而已。此时是不能简单地把这些进程杀掉的，会影响别人的业务。


# 问题解决


既然找到了问题，解决办法就很简单了：

1、这本来就不是问题，直接忽略即可，不会影响 Spark 任务的正常运行；

2、如果非要不想看到异常日志，那么可以检查机器的4040端口被什么进程占用了，看看能不能杀掉，当然这种方法不好了；

3、可以自己指定端口（使用 spark.ui.port 配置项），确保使用空闲的端口即可（不建议，因为要确认空闲的端口，如果端口不空闲，Spark 的 context 会创建失败，更麻烦，还不如让 Spark 自己去重试）。


参考：[hortonworks](https://community.hortonworks.com/questions/8257/how-can-i-resolve-it.html)

原文：

>When a spark context is created, it starts an application UI on port 4040 by default. When the UI starts, it checks to see if the port is in use, if so it should increment to 4041. Looks like you have something running on port 4040 there. The application should show you the warning, then try to start the UI on 4041.
This should not stop your application from running. If you really want to get around the WARNING, you can manually specify which port for the UI to start on, but I would strongly advise against doing so.
To manually specify the port, add this to your spark-submit:
--conf spark.ui.port=your_port


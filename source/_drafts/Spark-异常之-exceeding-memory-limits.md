---
title: Spark 异常之 exceeding memory limits
id: 2020-04-13 00:51:24
date: 2020-04-13 00:51:24
updated: 2020-04-13 00:51:24
categories:
tags:
keywords:
---


2018022501
Spark,elasticsearch-hadoop,yarn,Elasticsearch
大数据技术知识


业务上使用 `elasticsearch-hadoop` 框架来处理 `Elasticsearch` 里面的数据，流程就是读取、中间处理、写入，然后由于数据量级太大的【占用的内存也大】原因，出现异常：`Container killed by YARN for exceeding memory limits.`，这个异常其实很常见，做大数据开发的工程师基本都遇到过，稍微调整一下内存配置即可。

本文简单记录一下，给读者参考，开发环境基于 `Elasticsearch v1.7.5`、`Spark v1.6.2`、`elasticsearch-hadoop v2.1.0`。



<!-- more -->


# 问题出现


es-spark 处理数据时，读取大量数据到内存中，内存参数设置太小，报内存错误。

异常信息如下：

```
ExecutorLostFailure (executor 4 exited caused by one of the running tasks) Reason: Container killed by YARN for exceeding memory limits. 6.0 GB of 6 GB physical memory used. Consider boosting spark.yarn.executor.memoryOverhead.
FetchFailed(BlockManagerId(4, host18, 45026), shuffleId=0, mapId=3, reduceId=27, message=
org.apache.spark.shuffle.FetchFailedException: Failed to connect to host18/192.168.10.188:45026
    at org.apache.spark.storage.ShuffleBlockFetcherIterator.throwFetchFailedException(ShuffleBlockFetcherIterator.scala:323)
    at org.apache.spark.storage.ShuffleBlockFetcherIterator.next(ShuffleBlockFetcherIterator.scala:300)
    at org.apache.spark.storage.ShuffleBlockFetcherIterator.next(ShuffleBlockFetcherIterator.scala:51)
    at scala.collection.Iterator$$anon$11.next(Iterator.scala:328)
    at scala.collection.Iterator$$anon$13.hasNext(Iterator.scala:371)
    at scala.collection.Iterator$$anon$11.hasNext(Iterator.scala:327)
    at org.apache.spark.util.CompletionIterator.hasNext(CompletionIterator.scala:32)
    at org.apache.spark.InterruptibleIterator.hasNext(InterruptibleIterator.scala:39)
    at scala.collection.Iterator$$anon$13.hasNext(Iterator.scala:371)
    at scala.collection.Iterator$$anon$11.hasNext(Iterator.scala:327)
    at scala.collection.Iterator$$anon$11.hasNext(Iterator.scala:327)
    at scala.collection.Iterator$$anon$11.hasNext(Iterator.scala:327)
    at org.apache.spark.rdd.PairRDDFunctions$$anonfun$saveAsHadoopDataset$1$$anonfun$13$$anonfun$apply$7.apply$mcV$sp(PairRDDFunctions.scala:1195)
    at org.apache.spark.rdd.PairRDDFunctions$$anonfun$saveAsHadoopDataset$1$$anonfun$13$$anonfun$apply$7.apply(PairRDDFunctions.scala:1195)
    at org.apache.spark.rdd.PairRDDFunctions$$anonfun$saveAsHadoopDataset$1$$anonfun$13$$anonfun$apply$7.apply(PairRDDFunctions.scala:1195)
    at org.apache.spark.util.Utils$.tryWithSafeFinallyAndFailureCallbacks(Utils.scala:1277)
    at org.apache.spark.rdd.PairRDDFunctions$$anonfun$saveAsHadoopDataset$1$$anonfun$13.apply(PairRDDFunctions.scala:1203)
    at org.apache.spark.rdd.PairRDDFunctions$$anonfun$saveAsHadoopDataset$1$$anonfun$13.apply(PairRDDFunctions.scala:1183)
    at org.apache.spark.scheduler.ResultTask.runTask(ResultTask.scala:66)
    at org.apache.spark.scheduler.Task.run(Task.scala:89)
    at org.apache.spark.executor.Executor$TaskRunner.run(Executor.scala:227)
    at java.util.concurrent.ThreadPoolExecutor.runWorker(ThreadPoolExecutor.java:1145)
    at java.util.concurrent.ThreadPoolExecutor$Worker.run(ThreadPoolExecutor.java:615)
    at java.lang.Thread.run(Thread.java:745)
Caused by: java.io.IOException: Failed to connect to host18/192.168.10.188:45026
    at org.apache.spark.network.client.TransportClientFactory.createClient(TransportClientFactory.java:216)
    at org.apache.spark.network.client.TransportClientFactory.createClient(TransportClientFactory.java:167)
    at org.apache.spark.network.netty.NettyBlockTransferService$$anon$1.createAndStart(NettyBlockTransferService.scala:90)
    at org.apache.spark.network.shuffle.RetryingBlockFetcher.fetchAllOutstanding(RetryingBlockFetcher.java:140)
    at org.apache.spark.network.shuffle.RetryingBlockFetcher.access$200(RetryingBlockFetcher.java:43)
    at org.apache.spark.network.shuffle.RetryingBlockFetcher$1.run(RetryingBlockFetcher.java:170)
    at java.util.concurrent.Executors$RunnableAdapter.call(Executors.java:471)
    at java.util.concurrent.FutureTask.run(FutureTask.java:262)
    ... 3 more
Caused by: java.net.ConnectException: Connection refused: host18/192.168.10.188:45026
    at sun.nio.ch.SocketChannelImpl.checkConnect(Native Method)
    at sun.nio.ch.SocketChannelImpl.finishConnect(SocketChannelImpl.java:739)
    at io.netty.channel.socket.nio.NioSocketChannel.doFinishConnect(NioSocketChannel.java:224)
    at io.netty.channel.nio.AbstractNioChannel$AbstractNioUnsafe.finishConnect(AbstractNioChannel.java:289)
    at io.netty.channel.nio.NioEventLoop.processSelectedKey(NioEventLoop.java:528)
    at io.netty.channel.nio.NioEventLoop.processSelectedKeysOptimized(NioEventLoop.java:468)
    at io.netty.channel.nio.NioEventLoop.processSelectedKeys(NioEventLoop.java:382)
    at io.netty.channel.nio.NioEventLoop.run(NioEventLoop.java:354)
    at io.netty.util.concurrent.SingleThreadEventExecutor$2.run(SingleThreadEventExecutor.java:111)
    ... 1 more

)
```

重点看开头的那部分：

```
ExecutorLostFailure (executor 4 exited caused by one of the running tasks) Reason: Container killed by YARN for exceeding memory limits. 6.0 GB of 6 GB physical memory used. Consider boosting spark.yarn.executor.memoryOverhead.
```


# 分析解决


参数设置太小，不够存储数据1.8KW，41G。

```
spark.yarn.executor.memoryOverhead=2048
setExecutorMemory("2g")
corenum=20
```

```
资源定义分几个：
1、executor memory：  进程内存大小
2、number of executor：  进程数
3、executor-cores  ：  进程的线程数，  spark on yarn模式下 ， 默认一个core(线程) 会对应占用yarn的一个vcore（ 除非改过类似resource calculator类）
```

解决办法当然很简单，增大内存配置即可，但是要注意不能盲目地增大，如果太消耗内存资源建议把数据分批处理。


# 备注

[elasticsearch-hadoop 官网参考](https://www.elastic.co/guide/en/elasticsearch/hadoop/2.1/configuration.html) 。


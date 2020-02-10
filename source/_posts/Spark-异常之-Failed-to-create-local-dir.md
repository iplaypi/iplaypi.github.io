---
title: Spark 异常之 Failed to create local dir
id: 2020010201
date: 2020-01-02 00:32:44
updated: 2020-02-11 00:32:44
categories: 大数据技术知识
tags: [Spark,Streaming,IOException]
keywords: Spark,Streaming,IOException
---


今天的 `Spark Streaming` 程序莫名出现异常【对于一个 `task` 来说，`Spark Streaming` 会重试4次，全部重试都失败后整个 `Stage` 才会失败】，紧接着 `task` 中的 `batch` 就会卡住不动【后来查到卡住是其它原因造成的】，使得整个 `Spark Streaming` 任务进程进入到等待状态，所有的 `batch` 都处于 `queued` 状态，数据流无法继续执行。本文内容基于 `Spark v1.6.2`。


<!-- more -->


# 问题出现


线上一个一直很稳定的 `Spark Streaming` 程序，突然出现异常：

```
Job aborted due to stage failure: Task 0 in stage 2174.0 failed 4 times, most recent failure: Lost task 0.3 in stage 2174.0 (TID 32656, host): java.io.IOException: Failed to create local dir in /cloud/data2/spark/local/spark-4fccb5c2-29f5-45f9-926e-1c6e33636884/executor-30fdf8f9-6459-43c0-bba5-3a406db7e700/blockmgr-7edadea3-1fa3-4f32-bef2-1cf81230042a/07.
	at org.apache.spark.storage.DiskBlockManager.getFile(DiskBlockManager.scala:73)
	at org.apache.spark.storage.DiskStore.contains(DiskStore.scala:161)
	at org.apache.spark.storage.BlockManager.org$apache$spark$storage$BlockManager$$getCurrentBlockStatus(BlockManager.scala:398)
	at org.apache.spark.storage.BlockManager.doPut(BlockManager.scala:827)
	at org.apache.spark.storage.BlockManager.putBytes(BlockManager.scala:700)
	at org.apache.spark.broadcast.TorrentBroadcast$$anonfun$org$apache$spark$broadcast$TorrentBroadcast$$readBlocks$1$$anonfun$org$apache$spark$broadcast$TorrentBroadcast$$anonfun$$getRemote$1$1.apply(TorrentBroadcast.scala:130)
	at org.apache.spark.broadcast.TorrentBroadcast$$anonfun$org$apache$spark$broadcast$TorrentBroadcast$$readBlocks$1$$anonfun$org$apache$spark$broadcast$TorrentBroadcast$$anonfun$$getRemote$1$1.apply(TorrentBroadcast.scala:127)
	at scala.Option.map(Option.scala:145)
	at org.apache.spark.broadcast.TorrentBroadcast$$anonfun$org$apache$spark$broadcast$TorrentBroadcast$$readBlocks$1.org$apache$spark$broadcast$TorrentBroadcast$$anonfun$$getRemote$1(TorrentBroadcast.scala:127)
	at org.apache.spark.broadcast.TorrentBroadcast$$anonfun$org$apache$spark$broadcast$TorrentBroadcast$$readBlocks$1$$anonfun$1.apply(TorrentBroadcast.scala:137)
	at org.apache.spark.broadcast.TorrentBroadcast$$anonfun$org$apache$spark$broadcast$TorrentBroadcast$$readBlocks$1$$anonfun$1.apply(TorrentBroadcast.scala:137)
	at scala.Option.orElse(Option.scala:257)
	at org.apache.spark.broadcast.TorrentBroadcast$$anonfun$org$apache$spark$broadcast$TorrentBroadcast$$readBlocks$1.apply$mcVI$sp(TorrentBroadcast.scala:137)
	at org.apache.spark.broadcast.TorrentBroadcast$$anonfun$org$apache$spark$broadcast$TorrentBroadcast$$readBlocks$1.apply(TorrentBroadcast.scala:120)
	at org.apache.spark.broadcast.TorrentBroadcast$$anonfun$org$apache$spark$broadcast$TorrentBroadcast$$readBlocks$1.apply(TorrentBroadcast.scala:120)
	at scala.collection.immutable.List.foreach(List.scala:318)
	at org.apache.spark.broadcast.TorrentBroadcast.org$apache$spark$broadcast$TorrentBroadcast$$readBlocks(TorrentBroadcast.scala:120)
	at org.apache.spark.broadcast.TorrentBroadcast$$anonfun$readBroadcastBlock$1.apply(TorrentBroadcast.scala:175)
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
Driver stacktrace:
```

![异常信息](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2020/20200211004947.png "异常信息")

重点内容在于 `java.io.IOException: Failed to create local dir`。

为了不影响业务逻辑，首先尝试重启，重启后短暂恢复正常，大概运行20-40分钟后，继续出现上述异常，非常诡异【重启5次左右仍旧出现】。

同时，伴随着部分 `Stage` 失败，`Spark Streaming` 任务出现了 `batch` 卡住的现象，有2个 `btach` 一直处于 `processing` 状态，极不正常。导致后面所有的 `batch` 都处于 `queued` 状态，数据流无法继续执行，最终整个 `Spark Streaming` 任务会卡住不动，类似于假死。

![batch 卡住](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2020/20200211010335.png "batch 卡住")


# 问题分析解决


查了一下文档，发现有两种情况会造成这个异常，一是没有权限写入磁盘，二是磁盘空间不足。

找运维人员协助查看了一下，服务器的磁盘没有问题，根据进程的用户判断权限也没有问题，而且有好几个其它类似的 `Spark Straming` 任务可以正常运行，一点问题没有。

于是回顾一下最近的代码变动，发现有问题的 `Spark Streaming` 任务都变更过一个第三方接口的调用，于是联系对应的开发人员。

经过沟通测试，发现了问题，第三方接口有一个异常没有捕捉，导致上述异常产生。同时，由此会导致资源不释放的 `bug`，进而影响了 `Spark Streaming` 任务的 `batch` 卡住。

以上这些问题都与 `Spark` 无关，后面紧急升级第三方接口，任务得以正常运行，后续又观察了三天，都没有问题。


# 深入探究


问题虽然解决了，但还是要关注一下这个异常的场景，通过查看源码，发现这个异常是在创建目录的时候产生的，如下图：

![查看源码](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2020/20200211011126.png "查看源码")

那这个场景就很简单了，如果进程没有写入磁盘的权限或者磁盘空间不足，都会产生这个异常。

进一步思考，为什么会创建这个目录，作用是什么呢？

原来，`Spark` 在 `shuffle` 时需要通过 `diskBlockManage` 将 `map` 结果写入本地，优先写入 `memory store`，在 `memore store` 空间不足时会创建临时文件。这是一个二级目录，如异常中的：

```
/cloud/data2/spark/local/spark-4fccb5c2-29f5-45f9-926e-1c6e33636884/executor-30fdf8f9-6459-43c0-bba5-3a406db7e700/blockmgr-7edadea3-1fa3-4f32-bef2-1cf81230042a/07
```

使用完成后会立即删除。

那 `shuffle` 又是咋回事呢？`Spark` 作为并行计算框架，同一个作业会被划分为多个任务在多个节点上执行，`reduce` 的输入可能存在于多个节点，因此需要 `shuffle` 将所有 `reduce` 的输入汇总起来。这一步比较消耗内存或者说是磁盘，视选择的缓存方式而定。

那上面的 `memory store` 的大小是多少，什么情况下会超出上限从而选择使用 `disk store`？其实，`memory store` 的大小取决于 `spark.excutor.memory` 的大小，默认为 `spark.excutor.memory * 0.6`。此外，官方是不建议更改0.6这个系数的【参数：`spark.storage.memoryFraction`】，参考：[configuration-1.6.2](https://spark.apache.org/docs/1.6.2/configuration.html) 。

那临时文件的目录，可以更改吗，例如磁盘空间不足后，新挂载了一块磁盘。是可以的，在 `spark.env` 中添加 `SPARK_LOCAL_DIRS` 变量即可【通过 `spark-env.sh` 脚本可以添加】，或者直接在程序中配置【`spark conf`，参数名是 `spark.local.dir`】，可配置多个路径，使用英文逗号分隔，这样可以增强 `IO` 效率。这个参数的官方说明如下，默认目录是 `/tmp`。

>Directory to use for "scratch" space in Spark, including map output files and RDDs that get stored on disk. This should be on a fast, local disk in your system. It can also be a comma-separated list of multiple directories on different disks. NOTE: In Spark 1.0 and later this will be overriden by SPARK_LOCAL_DIRS (Standalone, Mesos) or LOCAL_DIRS (YARN) environment variables set by the cluster manager.

综上所述，在生产环境中一定要确保磁盘空间充足和磁盘写权限，切记磁盘空间按需配置，不可乱用，运维侧也要加上磁盘相关的监控，有问题可以及时预警。


# 备注


异常参考：[stackoverflow](https://stackoverflow.com/questions/41238121/spark-java-ioexception-failed-to-create-local-dir-in-tmp-blockmgr) 。

官方文档参考：[configuration-1.6.2](https://spark.apache.org/docs/1.6.2/configuration.html) 。


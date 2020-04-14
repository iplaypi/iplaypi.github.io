---
title: 'HDFS 异常之 BlockReaderFactory: I/O error constructing remote block reader'
id: 2020-04-15 01:03:14
date: 2018-03-05 01:03:14
updated: 2020-04-15 01:03:14
categories:
tags:
keywords:
---


2018030501
Spark,HDFS
大数据技术知识


在 `Spark` 任务中，读取 `HDFS` 的数据，经过中间 `ETL` 处理后再写回 `HDFS`，平时定时执行都是正常的，前几天突然发生异常，`Spark` 任务卡住了将近40个小时。在4000多个 `task` 中，其中有一个 `task` 一直没有成功，但也没有失败，就是一直卡着，查看日志里面有警告信息：`18/03/02 01:15:16 WARN hdfs.BlockReaderFactory: I/O error constructing remote block reader.`。

刚好今天有时间排查总结一下，开发环境基于 `Spark v1.6.2`、`Hadoop HDFS v2.7.1`。


<!-- more -->


# 问题出现


本来应该正常完成的 `Spark` 任务，其中有一个 `task` 一直卡着，持续近10个小时【后续观察卡了将近40个小时才成功】，和别的 `task` 相比，它并没有什么特殊的地方，数据也没有倾斜。

图。。

查看 `task` 的警告日志：

```
18/03/02 01:15:16 WARN hdfs.BlockReaderFactory: I/O error constructing remote block reader.
java.net.SocketTimeoutException: 100000 millis timeout while waiting for channel to be ready for read. ch : java.nio.channels.SocketChannel[connected local=/192.168.10.201:54916 remote=/192.168.10.188:50010]
    at org.apache.hadoop.net.SocketIOWithTimeout.doIO(SocketIOWithTimeout.java:164)
    at org.apache.hadoop.net.SocketInputStream.read(SocketInputStream.java:161)
    at org.apache.hadoop.net.SocketInputStream.read(SocketInputStream.java:131)
    at org.apache.hadoop.net.SocketInputStream.read(SocketInputStream.java:118)
    at java.io.FilterInputStream.read(FilterInputStream.java:83)
    at org.apache.hadoop.hdfs.protocolPB.PBHelper.vintPrefixed(PBHelper.java:2201)
    at org.apache.hadoop.hdfs.RemoteBlockReader2.newBlockReader(RemoteBlockReader2.java:408)
    at org.apache.hadoop.hdfs.BlockReaderFactory.getRemoteBlockReader(BlockReaderFactory.java:796)
    at org.apache.hadoop.hdfs.BlockReaderFactory.getRemoteBlockReaderFromTcp(BlockReaderFactory.java:674)
    at org.apache.hadoop.hdfs.BlockReaderFactory.build(BlockReaderFactory.java:337)
    at org.apache.hadoop.hdfs.DFSInputStream.blockSeekTo(DFSInputStream.java:576)
    at org.apache.hadoop.hdfs.DFSInputStream.seekToBlockSource(DFSInputStream.java:1460)
    at org.apache.hadoop.hdfs.DFSInputStream.readBuffer(DFSInputStream.java:773)
    at org.apache.hadoop.hdfs.DFSInputStream.readWithStrategy(DFSInputStream.java:806)
    at org.apache.hadoop.hdfs.DFSInputStream.read(DFSInputStream.java:847)
    at java.io.DataInputStream.read(DataInputStream.java:100)
    at org.apache.hadoop.util.LineReader.fillBuffer(LineReader.java:180)
    at org.apache.hadoop.util.LineReader.readDefaultLine(LineReader.java:216)
    at org.apache.hadoop.util.LineReader.readLine(LineReader.java:174)
    at org.apache.hadoop.mapred.LineRecordReader.next(LineRecordReader.java:246)
    at org.apache.hadoop.mapred.LineRecordReader.next(LineRecordReader.java:47)
    at org.apache.spark.rdd.HadoopRDD$$anon$1.getNext(HadoopRDD.scala:246)
    at org.apache.spark.rdd.HadoopRDD$$anon$1.getNext(HadoopRDD.scala:208)
    at org.apache.spark.util.NextIterator.hasNext(NextIterator.scala:73)
    at org.apache.spark.InterruptibleIterator.hasNext(InterruptibleIterator.scala:39)
    at scala.collection.Iterator$$anon$11.hasNext(Iterator.scala:327)
    at scala.collection.Iterator$$anon$14.hasNext(Iterator.scala:388)
    at scala.collection.Iterator$$anon$14.hasNext(Iterator.scala:388)
    at scala.collection.Iterator$$anon$14.hasNext(Iterator.scala:388)
    at scala.collection.Iterator$$anon$11.hasNext(Iterator.scala:327)
    at scala.collection.Iterator$$anon$11.hasNext(Iterator.scala:327)
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
18/03/02 01:15:17 WARN hdfs.DFSClient: Failed to connect to /192.168.10.188:50010 for block, add to deadNodes and continue. java.net.SocketTimeoutException: 100000 millis timeout while waiting for channel to be ready for read. ch : java.nio.channels.SocketChannel[connected local=/192.168.10.201:54916 remote=/192.168.10.188:50010]
```

注意上面那个 `task` 不成功也没失败，从日志来看只是警告级别，并不算严重异常，结合里面的超时信息，可以猜测是等待重试，接下来分析一下。

当然，日志里面大部分都是正常的情况。

图。。。


# 问题分析解决


去 `HDFS` 中查看，大部分结果文件已经写入目标路径成功，只要这个 `task` 对应的缓存临时目录还没处理，目录如下：

```
xxxx表示 partition 编号
your_root_path/_temporary/0/task_201802281039_0000_m_00xxxx/part-xxxx
```

而接着查看了其它 `partition` 的数据【在业务逻辑中，5万条数据生成1个 `partition`】，全部都是正常的，只是都在临时缓存目录，等待 `Saprk` 任务完成后拷贝到最终的数据目录：`your_root_path/part-xxxx`。



由于紧急使用这批数据，先写了一个 `Shell` 脚本【`listfile.sh`】，先去把数据拉出来再说，剩下的那一个 `task` 对应的数据导致的误差可以容忍。

```
#!/bin/bash
#print the directory and file
#循环遍历，提取所需数据
tmpdir=/your_root_path/_temporary/0/task_201802281039_0000_m_00
tmpfile=/part-0
for i in {0000..3299}
#for i in {0000..0003}
do
  path=${tmpdir}${i}${tmpfile}${i}
  echo ${path}
  hdfs dfs -text ${path} >> ./data.txt
done
```


继续排查，发现问题所在，连接数过多，或者超时时间太短导致的。

可以配置。。。


# 备注


后来持续等待了40多个小时，那一个 `task` 成功了，数据也写回到 `HDFS` 指定目录了。此时处理的数据结果和直接去 `_tmporary` 目录取出的不一致，有微小差异。因为 `ETL` 中有过滤数据的逻辑，所以 `_temporary` 的结果比 `task` 成功后的结果偏多一点，有小部分应该过滤的数据被从 `_tmporary` 取出来了，不过这也是上面所说的误差，可以接受。

关于配置信息，参考 `Hadoop HDFS` 的官网文档：[yyy](xxx) 。


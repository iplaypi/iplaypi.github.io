---
title: HBase 异常：RpcRetryingCaller-Call exception
id: 2019091701
date: 2019-09-17 21:23:49
updated: 2019-09-17 22:23:49
categories: 大数据技术知识
tags: [HBase,RegionServer,RowCounter]
keywords: HBase,RegionServer,RowCounter
---


今天天气不错，我心情很好，但是在测试代码功能的时候遇到了一个问题，浪费了一些时间，感到惋惜。还好，最终解决了问题，只是集群环境的问题。


<!-- more -->


# 问题出现


我的本意是想写一个 `MapReduce` 程序来扫描 `HBase` 数据，统计一些信息，但是在测试的时候发现程序卡住了，等了几分钟之后开始出现连续的超时日志，我感觉是连接 `HBase` 超时，无法读取表的元信息。

`MapReduce` 扫描数据报错，报错信息如下：

```
18:06:43.022 [main] INFO  o.a.h.h.util.RegionSizeCalculator - Calculating region sizes for table "YOUR_TABLE_NAME".
18:07:52.298 [htable-pool2-t1] INFO  o.a.h.hbase.client.RpcRetryingCaller - Call exception, tries=10, retries=35, started=69237 ms ago, cancelled=false, msg=row 'YOUR_TABLE_NAME,,00000000000000' on table 'hbase:meta' at region=hbase:meta,,1.1588230740, hostname=dev6,16020,1565930591664, seqNum=0
18:08:12.336 [htable-pool2-t1] INFO  o.a.h.hbase.client.RpcRetryingCaller - Call exception, tries=11, retries=35, started=89279 ms ago, cancelled=false, msg=row 'YOUR_TABLE_NAME,,00000000000000' on table 'hbase:meta' at region=hbase:meta,,1.1588230740, hostname=dev6,16020,1565930591664, seqNum=0
18:08:32.358 [htable-pool2-t1] INFO  o.a.h.hbase.client.RpcRetryingCaller - Call exception, tries=12, retries=35, started=109301 ms ago, cancelled=false, msg=row 'YOUR_TABLE_NAME,,00000000000000' on table 'hbase:meta' at region=hbase:meta,,1.1588230740, hostname=dev6,16020,1565930591664, seqNum=0
18:08:52.522 [htable-pool2-t1] INFO  o.a.h.hbase.client.RpcRetryingCaller - Call exception, tries=13, retries=35, started=129465 ms ago, cancelled=false, msg=row 'YOUR_TABLE_NAME,,00000000000000' on table 'hbase:meta' at region=hbase:meta,,1.1588230740, hostname=dev6,16020,1565930591664, seqNum=0
18:09:12.560 [htable-pool2-t1] INFO  o.a.h.hbase.client.RpcRetryingCaller - Call exception, tries=14, retries=35, started=149503 ms ago, cancelled=false, msg=row 'YOUR_TABLE_NAME,,00000000000000' on table 'hbase:meta' at region=hbase:meta,,1.1588230740, hostname=dev6,16020,1565930591664, seqNum=0
```

![MapReduce 报错信息](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20190917203629.png "MapReduce 报错信息")

此时我又去检查正在运行的 `Spark` 程序写入数据有没有问题，发现也是在写入 `HBase` 时有同样的错误，报错日志如下：

```
19/09/17 18:22:49 INFO RpcRetryingCaller: Call exception, tries=10, retries=35, started=68431 ms ago, cancelled=false, msg=row 'YOUR_TABLE_NAME,14df3e2b1626e6e02fc1d772eb34f8ad,99999999999999' on table 'hbase:meta' at region=hbase:meta,,1.1588230740, hostname=dev6,16020,1565930591664, seqNum=0
19/09/17 18:23:09 INFO RpcRetryingCaller: Call exception, tries=11, retries=35, started=88446 ms ago, cancelled=false, msg=row 'YOUR_TABLE_NAME,14df3e2b1626e6e02fc1d772eb34f8ad,99999999999999' on table 'hbase:meta' at region=hbase:meta,,1.1588230740, hostname=dev6,16020,1565930591664, seqNum=0
19/09/17 18:23:29 INFO RpcRetryingCaller: Call exception, tries=12, retries=35, started=108564 ms ago, cancelled=false, msg=row 'YOUR_TABLE_NAME,14df3e2b1626e6e02fc1d772eb34f8ad,99999999999999' on table 'hbase:meta' at region=hbase:meta,,1.1588230740, hostname=dev6,16020,1565930591664, seqNum=0
19/09/17 18:23:49 INFO RpcRetryingCaller: Call exception, tries=13, retries=35, started=128578 ms ago, cancelled=false, msg=row 'YOUR_TABLE_NAME,14df3e2b1626e6e02fc1d772eb34f8ad,99999999999999' on table 'hbase:meta' at region=hbase:meta,,1.1588230740, hostname=dev6,16020,1565930591664, seqNum=0
19/09/17 18:24:09 INFO RpcRetryingCaller: Call exception, tries=14, retries=35, started=148657 ms ago, cancelled=false, msg=row
```

![Spark 报错信息](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20190917203619.png "Spark 报错信息")

接着我想使用 `HBase` 自带的 `RowCounter` 执行 `MapReduce` 任务扫描数据，测试一下，使用命令：`hbase org.apache.hadoop.hbase.mapreduce.RowCounter 'YOUR_TABLE_NAME'`。

结果也是超时报错，报错信息如下：

```
Exception in thread "main" org.apache.hadoop.hbase.client.RetriesExhaustedException: Failed after attempts=36, exceptions:
Tue Sep 17 18:10:02 CST 2019, null, java.net.SocketTimeoutException: callTimeout=60000, callDuration=68315: row 'YOUR_TABLE_NAME,,00000000000000' on table 'hbase:meta' at region=hbase:meta,,1.1588230740, hostname=dev6,16020,1565930591664, seqNum=0

	at org.apache.hadoop.hbase.client.RpcRetryingCallerWithReadReplicas.throwEnrichedException(RpcRetryingCallerWithReadReplicas.java:271)
	at org.apache.hadoop.hbase.client.ScannerCallableWithReplicas.call(ScannerCallableWithReplicas.java:203)
	at org.apache.hadoop.hbase.client.ScannerCallableWithReplicas.call(ScannerCallableWithReplicas.java:60)
	at org.apache.hadoop.hbase.client.RpcRetryingCaller.callWithoutRetries(RpcRetryingCaller.java:200)
	at org.apache.hadoop.hbase.client.ClientScanner.call(ClientScanner.java:320)
	at org.apache.hadoop.hbase.client.ClientScanner.nextScanner(ClientScanner.java:295)
	at org.apache.hadoop.hbase.client.ClientScanner.initializeScannerInConstruction(ClientScanner.java:160)
	at org.apache.hadoop.hbase.client.ClientScanner.<init>(ClientScanner.java:155)
	at org.apache.hadoop.hbase.client.HTable.getScanner(HTable.java:821)
	at org.apache.hadoop.hbase.client.MetaScanner.metaScan(MetaScanner.java:193)
	at org.apache.hadoop.hbase.client.MetaScanner.metaScan(MetaScanner.java:89)
	at org.apache.hadoop.hbase.client.MetaScanner.allTableRegions(MetaScanner.java:324)
	at org.apache.hadoop.hbase.client.HRegionLocator.getAllRegionLocations(HRegionLocator.java:88)
	at org.apache.hadoop.hbase.util.RegionSizeCalculator.init(RegionSizeCalculator.java:94)
	at org.apache.hadoop.hbase.util.RegionSizeCalculator.<init>(RegionSizeCalculator.java:81)
	at org.apache.hadoop.hbase.mapreduce.TableInputFormatBase.getSplits(TableInputFormatBase.java:256)
	at org.apache.hadoop.hbase.mapreduce.TableInputFormat.getSplits(TableInputFormat.java:237)
	at org.apache.hadoop.mapreduce.JobSubmitter.writeNewSplits(JobSubmitter.java:301)
	at org.apache.hadoop.mapreduce.JobSubmitter.writeSplits(JobSubmitter.java:318)
	at org.apache.hadoop.mapreduce.JobSubmitter.submitJobInternal(JobSubmitter.java:196)
	at org.apache.hadoop.mapreduce.Job$10.run(Job.java:1290)
	at org.apache.hadoop.mapreduce.Job$10.run(Job.java:1287)
	at java.security.AccessController.doPrivileged(Native Method)
	at javax.security.auth.Subject.doAs(Subject.java:422)
	at org.apache.hadoop.security.UserGroupInformation.doAs(UserGroupInformation.java:1709)
	at org.apache.hadoop.mapreduce.Job.submit(Job.java:1287)
	at org.apache.hadoop.mapreduce.Job.waitForCompletion(Job.java:1308)
	at org.apache.hadoop.hbase.mapreduce.RowCounter.main(RowCounter.java:210)
Caused by: java.net.SocketTimeoutException: callTimeout=60000, callDuration=68315: row 'YOUR_TABLE_NAME,,00000000000000' on table 'hbase:meta' at region=hbase:meta,,1.1588230740, hostname=dev6,16020,1565930591664, seqNum=0
	at org.apache.hadoop.hbase.client.RpcRetryingCaller.callWithRetries(RpcRetryingCaller.java:159)
	at org.apache.hadoop.hbase.client.ResultBoundedCompletionService$QueueingFuture.run(ResultBoundedCompletionService.java:65)
	at java.util.concurrent.ThreadPoolExecutor.runWorker(ThreadPoolExecutor.java:1149)
	at java.util.concurrent.ThreadPoolExecutor$Worker.run(ThreadPoolExecutor.java:624)
	at java.lang.Thread.run(Thread.java:748)
Caused by: java.net.ConnectException: Connection refused
```

![RowCounter 报错信息](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20190917203602.png "RowCounter 报错信息")

由此可以断定，`HBase` 集群有问题了。


# 问题分析解决


首先查看集群的服务是不是还正常，一看果然不正常，`RegionServer` 已经挂了，那就好办了，直接重启即可。

由于是在测试环境，平时不太关注，所以没有注意到服务已经挂了，让运维人员花了1分钟帮忙重启一下，确认后没有问题。

最后打开 `RegionServer` 管理界面，查看集群信息，恢复正常。

![RegionServer 状态正常](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20190917203513.png "RegionServer 状态正常")

我的 `MapReduce` 任务又欢快地跑起来了。

![MapReduce 正常执行](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20190917203533.png "MapReduce 正常执行")

再试了一下 `RowCounter` 任务，也可以正常执行。

![RowCounter 正常执行](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20190917203542.png "RowCounter 正常执行")

至此，这个小问题解决。


# 备注


在搜索资料的过程中，也有人说是以下原因，但是我这里不是这个原因，所以记录下来，仅供读者参考：

- 添加 `jar` 包，`com.yammer.metrics` -> `metrics-core`
- `hosts` 添加 `ip` 映射


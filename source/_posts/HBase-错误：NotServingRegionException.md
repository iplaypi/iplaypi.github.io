---
title: HBase 错误：NotServingRegionException
id: 2019101201
date: 2019-10-12 20:19:31
updated: 2019-10-12 20:19:31
categories: 大数据技术知识
tags: [SparkStreaming,HBase]
keywords: SparkStreaming,HBase
---


在使用 `SparkStreaming` 程序处理数据，结果写入 `HBase` 时，遇到异常 `NotServingRegionException`，只是突然出现一次，平时正常，怀疑是和开发环境有关，本文记录查找问题的过程。本文中涉及的开发环境为 `HBase v1.1.2`。


<!-- more -->


# 问题出现


`SparkStreaming` 程序处理数据，结果写入 `HBase`，出现异常，并且一直持续：

```
2019-10-13_16:40:31 [JobGenerator] INFO consumer.SimpleConsumer:68: Reconnect due to socket error: java.nio.channels.ClosedChannelException
2019-10-13_16:40:32 [JobGenerator] INFO scheduler.JobScheduler:58: Added jobs for time 1570869630000 ms
2019-10-13_16:40:33 [Executor task launch worker-0] INFO client.AsyncProcess:1656: #3, waiting for some tasks to finish. Expected max=0, tasksInProgress=29
2019-10-13_16:40:34 [htable-pool3-t1] INFO client.AsyncProcess:1174: #3, table=YOUR_TABLE, attempt=29/35 failed=64ops, last exception: org.apache.hadoop.hbase.NotServingRegionException: org.apache.hadoop.hbase.NotServingRegionException: Region YOUR_TABLE,f,1565318245911.a70001dfe6d9320600286510318bfeb6. is not online on dev6,16020,1570795214262
	at org.apache.hadoop.hbase.regionserver.HRegionServer.getRegionByEncodedName(HRegionServer.java:2898)
	at org.apache.hadoop.hbase.regionserver.RSRpcServices.getRegion(RSRpcServices.java:947)
	at org.apache.hadoop.hbase.regionserver.RSRpcServices.multi(RSRpcServices.java:1994)
	at org.apache.hadoop.hbase.protobuf.generated.ClientProtos$ClientService$2.callBlockingMethod(ClientProtos.java:32213)
	at org.apache.hadoop.hbase.ipc.RpcServer.call(RpcServer.java:2114)
	at org.apache.hadoop.hbase.ipc.CallRunner.run(CallRunner.java:101)
	at org.apache.hadoop.hbase.ipc.RpcExecutor.consumerLoop(RpcExecutor.java:130)
	at org.apache.hadoop.hbase.ipc.RpcExecutor$1.run(RpcExecutor.java:107)
	at java.lang.Thread.run(Thread.java:748)
 on dev6,16020,1569724523487, tracking started null, retrying after=20058ms, replay=64ops
2019-10-13_16:40:46 [scheduled-rate-update] INFO streaming.ScheduledRateController:136: MinRateCondition, rateLimit = -1, minRate = 400
2019-10-13_16:40:46 [stream-rate-update] INFO streaming.ScheduledRateController:155: MinRateCondition's execute, numOfBatches = 38 vs 80
2019-10-13_16:40:54 [Executor task launch worker-0] INFO client.AsyncProcess:1656: #3, waiting for some tasks to finish. Expected max=0, tasksInProgress=30
2019-10-13_16:40:54 [htable-pool3-t1] INFO client.AsyncProcess:1174: #3, table=YOUR_TABLE, attempt=30/35 failed=64ops, last exception: org.apache.hadoop.hbase.NotServingRegionException: org.apache.hadoop.hbase.NotServingRegionException: Region YOUR_TABLE,f,1565318245911.a70001dfe6d9320600286510318bfeb6. is not online on dev6,16020,1570795214262
	at org.apache.hadoop.hbase.regionserver.HRegionServer.getRegionByEncodedName(HRegionServer.java:2898)
	at org.apache.hadoop.hbase.regionserver.RSRpcServices.getRegion(RSRpcServices.java:947)
	at org.apache.hadoop.hbase.regionserver.RSRpcServices.multi(RSRpcServices.java:1994)
	at org.apache.hadoop.hbase.protobuf.generated.ClientProtos$ClientService$2.callBlockingMethod(ClientProtos.java:32213)
	at org.apache.hadoop.hbase.ipc.RpcServer.call(RpcServer.java:2114)
	at org.apache.hadoop.hbase.ipc.CallRunner.run(CallRunner.java:101)
	at org.apache.hadoop.hbase.ipc.RpcExecutor.consumerLoop(RpcExecutor.java:130)
	at org.apache.hadoop.hbase.ipc.RpcExecutor$1.run(RpcExecutor.java:107)
	at java.lang.Thread.run(Thread.java:748)
 on dev6,16020,1569724523487, tracking started null, retrying after=20050ms, replay=64ops
```

![HBase 错误日志](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20191012204453.png "HBase 错误日志")

留意重点信息：

```
NotServingRegionException
is not online on dev6,16020,1570795214262
```

通过初步排查，发现只有一个数据表有此问题，更换其它表数据就可以正常写入，看来是和环境有关。

通过 `phoenix` 进行查询，发现也无法查询出数据，报错超时：

```
java.lang.RuntimeException: org.apache.phoenix.exception.PhoenixIOException: org.apache.phoenix.exception.PhoenixIOException: Failed after attempts=36, exceptions:
Sat Oct 12 16:30:48 CST 2019, null, java.net.SocketTimeoutException: callTimeout=60000, callDuration=70197: row '0' on table 'YOUR_TABLE' at region=YOUR_TABLE,0,1565318245911.157723c2d47bbae2226f6286a56f0256., hostname=dev6,15020,1569724523487, seqNum=1627
```

![phoenix 查询超时](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20191012204535.png "phoenix 查询超时")

但是从这个超时异常中看不到有效的线索。

接着通过 `RegionServer` 查看 `Region` 的分布，尝试搜索日志中出现的 `Region YOUR_TABLE,f,1565318245911.a70001dfe6d9320600286510318bfeb6`，发现不存在，看来这个表的 `Region` 信息有异常。

通过搜索问题关键词，在 `stackoverflow` 上面找到一个例子，出现这种现象是因为这个表的 `Region` 损坏了，导致无法找到指定的 `Region`，但是可以手动修复。


# 问题解决


找问题原因，并且进一步得到了建议的解决方案，准备实施。

首先使用 `hbase hbck "YOUR_TABLE"` 检测数据表的状态，等待几十秒，会陆续打印出集群的状态以及表的状态：

```
2019-10-13 17:44:20,160 INFO  [main-SendThread(dev5:2181)] zookeeper.ClientCnxn: Opening socket connection to server dev5/172.18.5.205:2181. Will not attempt to authenticate using SASL (unknown error)
2019-10-13 17:44:20,247 INFO  [main-SendThread(dev5:2181)] zookeeper.ClientCnxn: Socket connection established to dev5/172.18.5.205:2181, initiating session
2019-10-13 17:44:20,359 INFO  [main-SendThread(dev5:2181)] zookeeper.ClientCnxn: Session establishment complete on server dev5/172.18.5.205:2181, sessionid = 0x26d539786987a13, negotiated timeout = 40000
Version: 1.1.2.2.4.2.0-258
Number of live region servers: 3
Number of dead region servers: 0
Master: dev6,16000,1563773138374
Number of backup masters: 1
Average load: 382.6666666666667
Number of requests: 0
Number of regions: 1148
Number of regions in transition: 30
2019-10-13 17:44:24,693 INFO  [main] util.HBaseFsck: Loading regionsinfo from the hbase:meta table

Number of empty REGIONINFO_QUALIFIER rows in hbase:meta: 0
2019-10-13 17:44:24,954 INFO  [main] util.HBaseFsck: getHTableDescriptors == tableNames => [YOUR_TABLE]
...
2019-10-13 17:44:26,621 INFO  [main] util.HBaseFsck: Checking and fixing region consistency
ERROR: Region { meta => YOUR_TABLE,6,1565318245911.60686e402d3b0e25edc210190f8290c6., hdfs => hdfs://dev-hdfs/apps/hbase/data/data/default/YOUR_TABLE/60686e402d3b0e25edc210190f8290c6, deployed => , replicaId => 0 } not deployed on any region server.
ERROR: Region { meta => YOUR_TABLE,9,1565318245911.3dab1e5fc8211112c46041544c8cf6a1., hdfs => hdfs://dev-hdfs/apps/hbase/data/data/default/YOUR_TABLE/3dab1e5fc8211112c46041544c8cf6a1, deployed => , replicaId => 0 } not deployed on any region server.
ERROR: Region { meta => YOUR_TABLE,0,1565318245911.157723c2d47bbae2226f6286a56f0256., hdfs => hdfs://dev-hdfs/apps/hbase/data/data/default/YOUR_TABLE/157723c2d47bbae2226f6286a56f0256, deployed => , replicaId => 0 } not deployed on any region server.
ERROR: Region { meta => YOUR_TABLE,3,1565318245911.8e6507c0aa0ba2f7864fb6adbab58cd4., hdfs => hdfs://dev-hdfs/apps/hbase/data/data/default/YOUR_TABLE/8e6507c0aa0ba2f7864fb6adbab58cd4, deployed => , replicaId => 0 } not deployed on any region server.
ERROR: Region { meta => YOUR_TABLE,f,1565318245911.a70001dfe6d9320600286510318bfeb6., hdfs => hdfs://dev-hdfs/apps/hbase/data/data/default/YOUR_TABLE/a70001dfe6d9320600286510318bfeb6, deployed => , replicaId => 0 } not deployed on any region server.
ERROR: Region { meta => YOUR_TABLE,c,1565318245911.e247e3f852573308fd554e07452fbe93., hdfs => hdfs://dev-hdfs/apps/hbase/data/data/default/YOUR_TABLE/e247e3f852573308fd554e07452fbe93, deployed => , replicaId => 0 } not deployed on any region server.
2019-10-13 17:44:26,732 INFO  [main] util.HBaseFsck: Handling overlap merges in parallel. set hbasefsck.overlap.merge.parallel to false to run serially.
ERROR: There is a hole in the region chain between 0 and 1.  You need to create a new .regioninfo and region dir in hdfs to plug the hole.
ERROR: There is a hole in the region chain between 3 and 4.  You need to create a new .regioninfo and region dir in hdfs to plug the hole.
ERROR: There is a hole in the region chain between 6 and 7.  You need to create a new .regioninfo and region dir in hdfs to plug the hole.
ERROR: There is a hole in the region chain between 9 and a.  You need to create a new .regioninfo and region dir in hdfs to plug the hole.
ERROR: There is a hole in the region chain between c and d.  You need to create a new .regioninfo and region dir in hdfs to plug the hole.
ERROR: Last region should end with an empty key. You need to create a new region and regioninfo in HDFS to plug the hole.
ERROR: Found inconsistency in table YOUR_TABLE
2019-10-13 17:44:26,747 INFO  [main] util.HBaseFsck: Computing mapping of all store files
...
2019-10-13 17:44:30,038 INFO  [main] util.HBaseFsck: Finishing hbck
Summary:
Table YOUR_TABLE is inconsistent.
    Number of regions: 11
    Deployed on:  dev4,16020,1570795191487 dev5,16020,1570795198827
Table hbase:meta is okay.
    Number of regions: 1
    Deployed on:  dev5,16020,1570795198827
12 inconsistencies detected.
Status: INCONSISTENT
```

![hbase hbck 查看输出日志-1](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20191012204717.png "hbase hbck 查看输出日志-1")

![hbase hbck 查看输出日志-2](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20191012204734.png "hbase hbck 查看输出日志-2")

![hbase hbck 查看输出日志-3](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20191012204747.png "hbase hbck 查看输出日志-3")

首先注意到前面那个不存在的 `Region` `a70001dfe6d9320600286510318bfeb6` 处于未部署状态，`RegionServer` 当然无法找到了。

可以看到最终的结论：`INCONSISTENT`，就是数据不一致。并且在输出日志里面还有说明出现了 `Region` 空洞【`Region hole`】。

那怎么解决呢，可以先尝试使用 `hbase hbck -fix "YOUR_TABLE"` 解决。

这里如果遇到操作 `HDFS` 无权限，记得切换用户 `export HADOOP_USER_NAME=hbase`，当然最好还是直接使用管理员权限操作：
`sudo -u hbase hbase hbck -fix "YOUR_TABLE"`。

在修复过程中，仍旧会不断输出日志，如果看到：
`util.HBaseFsck: Sleeping 10000ms before re-checking after fix...`
则说明修复完成，为了验证修复结果，`HBase` 还会自动检测一次。

再次检测后，如果看到如下信息，说明修复成功：

```
Summary:
Table YOUR_TABLE is okay.
    Number of regions: 17
2019-10-13 18:20:02,145 INFO  [main-EventThread] zookeeper.ClientCnxn: EventThread shut down
    Deployed on:  dev4,16020,1570795191487 dev5,16020,1570795198827
Table hbase:meta is okay.
    Number of regions: 1
    Deployed on:  dev5,16020,1570795198827
0 inconsistencies detected.
Status: OK
```

![hbase hbck fix 修复完成](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20191012204942.png "hbase hbck fix 修复完成")

接着就可以继续正常写入数据了。


# 备注


参考 `stackoverflow` 上面的例子：[notservingregionexception](https://stackoverflow.com/questions/37507878/hbase-fails-with-org-apache-hadoop-hbase-notservingregionexception-region-is-not) 。


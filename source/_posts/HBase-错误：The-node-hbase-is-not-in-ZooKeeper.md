---
title: HBase 错误：The node hbase is not in ZooKeeper
id: 2019101901
date: 2019-10-19 20:15:11
updated: 2019-10-19 20:15:11
categories: 踩坑系列
tags: [HBase,Phoenix,Zookeeper]
keywords: HBase,Phoenix,Zookeeper
---


使用 `phoenix` 向 `HBase` 中导入数据，使用的是 `phoenix` 自带的脚本 `psql.py`，结果报错：

```
19/10/18 11:47:29 ERROR client.ConnectionManager$HConnectionImplementation: The node /hbase is not in ZooKeeper. It should have been written by the master. Check the value configured in 'zookeeper.znode.parent'. There could be a mismatch with the one configured in the master.
```

看起来是 `ZooKeeper` 环境有问题，本文记录解决过程。

本文开发环境基于 `HBase v1.1.2`、`phoenix v4.2.0` 。


<!-- more -->


# 问题出现


使用 `phoenix` 自带的导数脚本 `psql.py`，执行导入操作：

```
psql.py -t YOUR_TABLE dev4:2181 ./content.csv
```

其中，`dev4:2191` 是 `Zookeeper` 集群节点，`./content.csv` 是数据文件，结果出现异常：

```
19/10/18 11:47:29 ERROR client.ConnectionManager$HConnectionImplementation: The node /hbase is not in ZooKeeper. It should have been written by the master. Check the value configured in 'zookeeper.znode.parent'. There could be a mismatch with the one configured in the master.
19/10/18 11:47:29 ERROR client.ConnectionManager$HConnectionImplementation: The node /hbase is not in ZooKeeper. It should have been written by the master. Check the value configured in 'zookeeper.znode.parent'. There could be a mismatch with the one configured in the master.
19/10/18 11:47:29 ERROR client.ConnectionManager$HConnectionImplementation: The node /hbase is not in ZooKeeper. It should have been written by the master. Check the value configured in 'zookeeper.znode.parent'. There could be a mismatch with the one configured in the master.
19/10/18 11:47:30 ERROR client.ConnectionManager$HConnectionImplementation: The node /hbase is not in ZooKeeper. It should have been written by the master. Check the value configured in 'zookeeper.znode.parent'. There could be a mismatch with the one configured in the master.
19/10/18 11:47:31 ERROR client.ConnectionManager$HConnectionImplementation: The node /hbase is not in ZooKeeper. It should have been written by the master. Check the value configured in 'zookeeper.znode.parent'. There could be a mismatch with the one configured in the master.
```

![导入数据异常](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20191019204203.png "导入数据异常")

看起来是 `Zookeeper` 中缺失 `/hbase` 节点目录。


# 问题解决


从 `stackoverflow` 上面查到一条类似的问题，见备注链接。

表面原因的确是 `Zookeeper` 中缺失 `/hbase` 节点目录，因为 `phoenix` 需要从这个节点获取 `HBase` 集群的信息，例如表结构，节点目录缺失则无法获取。

查看 `conf/hbase-site.xml` 文件，找到配置项：`zookeeper.znode.parent`，它就是表示 `HBase` 在 `ZooKeeper` 中的管理目录，里面存储着关于 `HBase` 集群的各项重要信息：

```
<property>
  <name>zookeeper.znode.parent</name>
  <value>/hbase-unsecure</value>
</property>
```

再去查看 `conf/hbase-env.sh` 里面的配置信息：`HBASE_MANAGES_ZK`，这个参数是告诉 `HBase` 是否使用自带的 `ZooKeeper` 管理 `HBase` 集群。如果为 `true`，则使用自带的 `ZooKeeper`；如果为 `false`，则使用外部的 `ZooKeeper`。

![查看 hbase-env.sh 文件](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20191019204433.png "查看 hbase-env.sh 文件")

可以看到我这里的参数设置的是 `false`，也就是使用外部的 `ZooKeeper` 集群。

在这里多说一下这个参数的不同值的使用场景：

- 默认值为 `true`，但是，自带的 `ZooKeeper` 只能为单机或伪分布模式下的 `HBase` 提供服务，一般用于学习场景或者测试环境，比较方便管理
- 如果设置为 `false`，则使用外部的 `ZooKeeper` 管理 `HBase`，此时 `HBase` 既可以是单机模式、伪分布式模式，也可以是分布式模式，重点只有一个，需要自己搭建一套 `ZooKeeper` 集群
- 如果设置为 `true`，并且 `HBase` 使用伪分布式模式，则在启动 `HBase` 时，`HBase` 将 `Zookeeper` 作为自身的一部分运行，进程变为 `HQuorumPeer`
- 一般建议使用 `false`，然后自己再单独搭建一套 `ZooKeeper`，这才是真生的分布式环境；当然，如果觉得复杂，只是自己学习、测试的时候使用，可以设置为 `true`

言归正传，既然使用的是外部的 `ZooKeeper`，也就是我这里指定的 `dev4:2181`，可见 `HBase` 集群已经设置了自己在 `Zookeeper` 中的元信息管理目录，而 `phoenix` 为什么要去另外一个目录 `/hbase` 获取呢。这里可能是 `phoenix` 的配置有问题。

不妨先去里面看一下是否存在 `/hbase` 节点即可，经过查看，没有这个节点。如果没有的话，也不妨先重新创建一个，使用：`create /hbase ""` 创建一个空内容节点，确保节点存在。

注意，这里只是创建了一个空节点，里面并没有任何信息，所以 `phoenix` 从里面是无法获取关于 `HBase` 集群的信息的。

测试了一下，果然，还是无法导入数据，抛出超时异常：

```
19/10/19 20:47:12 WARN impl.MetricsConfig: Cannot locate configuration: tried hadoop-metrics2-phoenix.properties,hadoop-metrics2.properties
org.apache.phoenix.exception.PhoenixIOException: callTimeout=600000, callDuration=1024368: 
	at org.apache.phoenix.util.ServerUtil.parseServerException(ServerUtil.java:108)
	at org.apache.phoenix.query.ConnectionQueryServicesImpl.ensureTableCreated(ConnectionQueryServicesImpl.java:840)
	at org.apache.phoenix.query.ConnectionQueryServicesImpl.createTable(ConnectionQueryServicesImpl.java:1134)
	at org.apache.phoenix.query.DelegateConnectionQueryServices.createTable(DelegateConnectionQueryServices.java:110)
	at org.apache.phoenix.schema.MetaDataClient.createTableInternal(MetaDataClient.java:1591)
	at org.apache.phoenix.schema.MetaDataClient.createTable(MetaDataClient.java:569)
	at org.apache.phoenix.compile.CreateTableCompiler$2.execute(CreateTableCompiler.java:175)
	at org.apache.phoenix.jdbc.PhoenixStatement$2.call(PhoenixStatement.java:271)
	at org.apache.phoenix.jdbc.PhoenixStatement$2.call(PhoenixStatement.java:263)
	at org.apache.phoenix.call.CallRunner.run(CallRunner.java:53)
	at org.apache.phoenix.jdbc.PhoenixStatement.executeMutation(PhoenixStatement.java:261)
	at org.apache.phoenix.jdbc.PhoenixStatement.executeUpdate(PhoenixStatement.java:1043)
	at org.apache.phoenix.query.ConnectionQueryServicesImpl$9.call(ConnectionQueryServicesImpl.java:1561)
	at org.apache.phoenix.query.ConnectionQueryServicesImpl$9.call(ConnectionQueryServicesImpl.java:1530)
	at org.apache.phoenix.util.PhoenixContextExecutor.call(PhoenixContextExecutor.java:77)
	at org.apache.phoenix.query.ConnectionQueryServicesImpl.init(ConnectionQueryServicesImpl.java:1530)
	at org.apache.phoenix.jdbc.PhoenixDriver.getConnectionQueryServices(PhoenixDriver.java:162)
	at org.apache.phoenix.jdbc.PhoenixEmbeddedDriver.connect(PhoenixEmbeddedDriver.java:126)
	at org.apache.phoenix.jdbc.PhoenixDriver.connect(PhoenixDriver.java:133)
	at java.sql.DriverManager.getConnection(DriverManager.java:664)
	at java.sql.DriverManager.getConnection(DriverManager.java:208)
	at org.apache.phoenix.util.PhoenixRuntime.main(PhoenixRuntime.java:182)
Caused by: java.net.SocketTimeoutException: callTimeout=600000, callDuration=1024368: 
	at org.apache.hadoop.hbase.client.RpcRetryingCaller.callWithRetries(RpcRetryingCaller.java:156)
	at org.apache.hadoop.hbase.client.HBaseAdmin.executeCallable(HBaseAdmin.java:3390)
	at org.apache.hadoop.hbase.client.HBaseAdmin.getTableDescriptor(HBaseAdmin.java:408)
	at org.apache.hadoop.hbase.client.HBaseAdmin.getTableDescriptor(HBaseAdmin.java:429)
	at org.apache.phoenix.query.ConnectionQueryServicesImpl.ensureTableCreated(ConnectionQueryServicesImpl.java:772)
	... 20 more
Caused by: org.apache.hadoop.hbase.MasterNotRunningException: java.io.IOException: Can't get master address from ZooKeeper; znode data == null
	at org.apache.hadoop.hbase.client.ConnectionManager$HConnectionImplementation$StubMaker.makeStub(ConnectionManager.java:1671)
	at org.apache.hadoop.hbase.client.ConnectionManager$HConnectionImplementation$MasterServiceStubMaker.makeStub(ConnectionManager.java:1697)
	at org.apache.hadoop.hbase.client.ConnectionManager$HConnectionImplementation.getKeepAliveMasterService(ConnectionManager.java:1914)
	at org.apache.hadoop.hbase.client.HBaseAdmin$MasterCallable.prepare(HBaseAdmin.java:3363)
	at org.apache.hadoop.hbase.client.RpcRetryingCaller.callWithRetries(RpcRetryingCaller.java:125)
	... 24 more
Caused by: java.io.IOException: Can't get master address from ZooKeeper; znode data == null
	at org.apache.hadoop.hbase.zookeeper.MasterAddressTracker.getMasterAddress(MasterAddressTracker.java:114)
	at org.apache.hadoop.hbase.client.ConnectionManager$HConnectionImplementation$StubMaker.makeStubNoRetries(ConnectionManager.java:1597)
	at org.apache.hadoop.hbase.client.ConnectionManager$HConnectionImplementation$StubMaker.makeStub(ConnectionManager.java:1643)
	... 28 more
```

![导入数据再次出现异常](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20191019211617.png "导入数据再次出现异常")

可以看到，里面有 `Can't get master address from ZooKeeper` 字样，也就是无法从 `Zookeeper` 指定的目录中获取关于 `HBase` 的主节点信息，可见，单纯在 `Zookeeper` 中创建一个 `/hbase` 目录是没用的。因此，源头应该在于 `phoenix` 为什么不去 `/hbase-unsecure` 目录中获取 `HBase` 集群信息【这才是 `HBase` 集群的信息所在地】，是哪里的配置出了问题。

经过排查，`phoenix` 脚本在加载 `hbase_conf_dir` 参数的时候，目录错误，因此没有获取到 `HBase` 相的配置文件，最终导致没有去 `Zookeeper` 的 `/hbase-unsecure` 目录读取数据。这里排查的是 `psql.py`、`phoenix_utils.py` 这两个文件，里面有关于加载 `HBase`、`Hadoop` 集群的配置目录的参数，如果赋值错误就会导致上述现象。

把 `hbase_conf_dir` 参数的加载过程梳理清楚，确保可以加载到 `HBASE_HOME/conf` 目录，接着就可以顺利导入数据了。

同时当然也需要 `HADOOP_HOME/conf`，但是我这里已经是正确的了，如果读者没有配置好，可能会遇到找不到 `hdfs` 的相关类，例如：

```
java.lang.RuntimeException: java.lang.ClassNotFoundException: Class org.apache.hadoop.hdfs.DistributedFileSystem not found
```

最后一点需要注意，上传的 `csv` 文件内容列数要确保和 `HBase` 表的列数一致，并且不需要表头，否则无法成功导入【表头也会被当做内容】，日志也会报错提醒的。当然，字段也是有顺序的，`csv` 文件中字段的顺序要和 `HBase` 表中定义的一致。

顺利导入数据，导入成功，耗时12秒，导入12000条数据，从输出日志中可以看到详情。

![数据导入成功](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20191021215944.png "数据导入成功")


# 备注


1、参考：[HBase](https://stackoverflow.com/questions/28605301/the-node-hbase-is-not-in-zookeeper) ，这是个相似的问题。

2、如果数据量比较大的话，就不建议使用这种脚本导入的方式，反而可以使用 `xxx-client.jar` 包里面自带的处理类来执行，并提前把数据文件上传至 `hdfs`，然后后台会提交 `MapReduce` 任务来大批量导入数据。

3、数据导入、数据导出还可以使用 `pig` 这个工具。


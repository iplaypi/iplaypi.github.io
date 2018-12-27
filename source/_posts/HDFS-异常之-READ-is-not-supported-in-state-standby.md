---
title: HDFS 异常之 READ is not supported in state standby
id: 2018122702
date: 2018-12-27 19:06:42
updated: 2018-12-27 19:06:42
categories: Hadoop 从零基础到入门系列
tags: [Hadoop,Spark,HDFS,nameNode,standby]
keywords: Hadoop,Spark,HDFS,nameNode,standby
---


今天查看日志发现，以前正常运行的 Spark 程序会不断抛出异常：
````java
org.apache.hadoop.ipc.RemoteException(org.apache.hadoop.ipc.StandbyException): Operation category READ is not supported in state standby
````

但是却没有影响到功能的正常运行，只不过是抛出了大量的上述异常，而且内容都一样，也都是操作 HDFS 产生的，所以猜测与 HDFS 集群（或者配置）有关系。本文就记录发现问题、解决问题的过程。


<!-- more -->


# 问题出现


按照日常操作，查看 Spark 任务的 Driver 端的日志，结果发现了大量的重复异常，又看了一下对功能的影响，结果发现没有影响，所有功能均正常运行，产生的结果也是期望的。

## 问题分析

详细来看一下 Driver 端的日志异常信息：

````java
2018-12-26_23:25:40 [main] INFO retry.RetryInvocationHandler:140: Exception while invoking getFileInfo of class ClientNamenodeProtocolTranslatorPB over hadoop1/192.168.10.162:8020. Trying to fail over immediately.
org.apache.hadoop.ipc.RemoteException(org.apache.hadoop.ipc.StandbyException): Operation category READ is not supported in state standby
	at org.apache.hadoop.hdfs.server.namenode.ha.StandbyState.checkOperation(StandbyState.java:87)
	at org.apache.hadoop.hdfs.server.namenode.NameNode$NameNodeHAContext.checkOperation(NameNode.java:1722)
	at org.apache.hadoop.hdfs.server.namenode.FSNamesystem.checkOperation(FSNamesystem.java:1362)
	at org.apache.hadoop.hdfs.server.namenode.FSNamesystem.getFileInfo(FSNamesystem.java:4414)
	at org.apache.hadoop.hdfs.server.namenode.NameNodeRpcServer.getFileInfo(NameNodeRpcServer.java:893)
	at org.apache.hadoop.hdfs.protocolPB.ClientNamenodeProtocolServerSideTranslatorPB.getFileInfo(ClientNamenodeProtocolServerSideTranslatorPB.java:835)
	at org.apache.hadoop.hdfs.protocol.proto.ClientNamenodeProtocolProtos$ClientNamenodeProtocol$2.callBlockingMethod(ClientNamenodeProtocolProtos.java)
	at org.apache.hadoop.ipc.ProtobufRpcEngine$Server$ProtoBufRpcInvoker.call(ProtobufRpcEngine.java:619)
	at org.apache.hadoop.ipc.RPC$Server.call(RPC.java:962)
	at org.apache.hadoop.ipc.Server$Handler$1.run(Server.java:2039)
	at org.apache.hadoop.ipc.Server$Handler$1.run(Server.java:2035)
	at java.security.AccessController.doPrivileged(Native Method)
	at javax.security.auth.Subject.doAs(Subject.java:422)
	at org.apache.hadoop.security.UserGroupInformation.doAs(UserGroupInformation.java:1628)
	at org.apache.hadoop.ipc.Server$Handler.run(Server.java:2033)
	at org.apache.hadoop.ipc.Client.call(Client.java:1468)
	at org.apache.hadoop.ipc.Client.call(Client.java:1399)
	at org.apache.hadoop.ipc.ProtobufRpcEngine$Invoker.invoke(ProtobufRpcEngine.java:232)
	at com.sun.proxy.$Proxy30.getFileInfo(Unknown Source)
	at org.apache.hadoop.hdfs.protocolPB.ClientNamenodeProtocolTranslatorPB.getFileInfo(ClientNamenodeProtocolTranslatorPB.java:768)
	at sun.reflect.GeneratedMethodAccessor34.invoke(Unknown Source)
	at sun.reflect.DelegatingMethodAccessorImpl.invoke(DelegatingMethodAccessorImpl.java:43)
	at java.lang.reflect.Method.invoke(Method.java:498)
	at org.apache.hadoop.io.retry.RetryInvocationHandler.invokeMethod(RetryInvocationHandler.java:187)
	at org.apache.hadoop.io.retry.RetryInvocationHandler.invoke(RetryInvocationHandler.java:102)
	at com.sun.proxy.$Proxy31.getFileInfo(Unknown Source)
	at org.apache.hadoop.hdfs.DFSClient.getFileInfo(DFSClient.java:2007)
	at org.apache.hadoop.hdfs.DistributedFileSystem$19.doCall(DistributedFileSystem.java:1136)
	at org.apache.hadoop.hdfs.DistributedFileSystem$19.doCall(DistributedFileSystem.java:1132)
	at org.apache.hadoop.fs.FileSystemLinkResolver.resolve(FileSystemLinkResolver.java:81)
	at org.apache.hadoop.hdfs.DistributedFileSystem.getFileStatus(DistributedFileSystem.java:1132)
	at org.apache.hadoop.fs.FileSystem.isFile(FileSystem.java:1426)
````

注意一下核心异常所在：
````java
Exception while invoking getFileInfo of class ClientNamenodeProtocolTranslatorPB over hadoop1/192.168.10.162:8020. Trying to fail over immediately.
org.apache.hadoop.ipc.RemoteException(org.apache.hadoop.ipc.StandbyException): Operation category READ is not supported in state standby
````

当去从 hadoop1/192.168.10.162:8020 这里 getFileInfo 的时候，抛出了异常，而且明确告诉我们这台机器处于 standby 状态，不支持读取操作。此时，可以想到，肯定是 hadoop1/192.168.10.162:8020 这台机器已经处于 standby 状态了，无法提供服务，所以抛出此异常。既然问题找到了，那么问题产生的原因是什么呢，以及为什么对功能没有影响，接下来一一分析。

首先查看 hdfs-site.xml 配置文件，看看 namenode 相关的配置项：

````xml
    <property>
      <name>dfs.nameservices</name>
      <value>r-cluster</value>
    </property>
    
    <property>
      <name>dfs.ha.namenodes.r-cluster</name>
      <value>nn1,nn2</value>
    </property>
    
    <property>
      <name>dfs.namenode.rpc-address.r-cluster.nn1</name>
      <value>hadoop1:8020</value>
    </property>
    
    <property>
      <name>dfs.namenode.rpc-address.r-cluster.nn2</name>
      <value>rocket15:8020</value>
    </property>
````

可以看到，namenode 相关配置有2台机器：nn1、nn2，而上述产生异常的信息表明连接 nn1 被拒绝，那么我去看一下 HDFS 集群的状态，发现 nn1 果然是 standby 状态的，而 nn2（rocket15） 才是 active 状态。

![nn2 的 active 状态](https://ws1.sinaimg.cn/large/b7f2e3a3gy1fyluqlzruwj20ln0b6mxq.jpg "nn2 的 active 状态")

再仔细查看日志，没有发现连接 nn2 的异常，那就说明是第一次连接 nn1 抛出异常，然后试图连接 nn2，成功连接，没有抛出异常，接下来程序就正常处理数据了，对功能没有任何影响。

到这里，我们已经分析出了整个过程，现象表明这个异常只是连接了 standby 状态的 namenode，是正常抛出的。然后会再次连接另外一台 active 状态的 namenode，连接成功。

## 抛异常的流程细节


1、客户端在连接 HDFS 的时候，会从配置文件 hdfs-site.xml 中，读取 nameservices 的配置，获取机器编号，我这里是 nn1 和 nn2，分别对应着2台 namenode 机器；

2、客户端会首先选择编号较小的 namenode（我这里是 nn1，对应着 hadoop1），试图连接；

3、如果这台 namenode 是 active 状态，则客户端可以正常处理请求；但是如果这台 namenode 是 standby 状态，则客户端抛出由服务端返回的异常：Operation category READ is not supported in state standby，同时打印 ip 信息，接着会尝试连接另外一台编号较大的 namenode（我这里是 nn2，即 rocket15）；

4、如果连接成功，则客户端可以正常处理请求；如果 nn2 仍然像 nn1 一样，客户端会抛出一样的异常，此时会继续反复重试 nn1 与 nn2（重试次数有配置项，间隔时间有配置项）；如果有成功的，则客户端可以正常处理请求，如果全部失败，则客户端无法正常处理请求，此时应该要关注解决 namenode 为什么全部都处在 standby 状态。

配置参数如下（参考[Hadoop 官方文档](https://hadoop.apache.org/docs/r2.6.0/hadoop-project-dist/hadoop-hdfs/hdfs-default.xml)）：

````xml
<!-- 客户端重试次数,默认15 -->
<property>
    <name>dfs.client.failover.max.attempts</name>
    <value>15</value>
</property>

<!-- 客户端2次重试间隔时间,默认500毫秒 -->
<property>
    <name>dfs.client.failover.sleep.base.millis</name>
    <value>500</value>
</property>

<!-- 客户端2次重试间隔时间,默认1500毫秒 -->
<property>
    <name>dfs.client.failover.sleep.max.millis</name>
    <value>1500</value>
</property>

<!-- 客户端1次连接中重试次数,默认0,在网络不稳定时建议加大此值 -->
<property>
    <name>dfs.client.failover.connection.retries</name>
    <value>0</value>
</property>

<!-- 客户端1次连接中超时重试次数，仅是指超时重试,默认0,在网络不稳定时建议加大此值 -->
<property>
    <name>dfs.client.failover.connection.retries.on.timeouts</name>
    <value>0</value>
</property>
````


# 问题解决


既然明确了问题，并且分析出了具体原因，解决起来就简单了，对于我这种情况，有2种方法：

1、不用解决，也无需关心，这个异常没有任何影响，会自动重连另外一台 active 状态的 namenode 机器的；

2、如果就是一心想把异常消除掉，那就更改 hdfs-site.xml 配置文件里面的 nameservices 配置项对应的机器，把编号最小的机器设置成状态为 active 的 namenode（例如我这里把 nn1、nn2 的对应的机器 ip 地址交换一下即可，确保 nn1 是 active 状态的），那么连接 HDFS 的时候第一次就会直接连接这台机器，就不会抛出异常了（但是要注意 namenode 以后可能是会挂的，挂了会自动切换，那么到那个时候还要更改这个配置项）。

````xml
    <property>
      <name>dfs.namenode.rpc-address.r-cluster.nn1</name>
      <value>rocket15:8020</value>
    </property>
    
    <property>
      <name>dfs.namenode.rpc-address.r-cluster.nn2</name>
      <value>hadoop1:8020</value>
    </property>
````


# 问题总结


1、参考：http://support-it.huawei.com/docs/zh-cn/fusioninsight-all/maintenance-guide/zh-cn_topic_0062904132.html

2、这个问题其实不是问题，只不过抛出了异常，我看到有点担心而已，但是如果连接所有的机器都抛出这种异常，并且重试了很多次就有影响了，说明所有的 namenode 都挂了，根本无法正常操作 HDFS 系统；

3、根据2进行总结：如果只是在操作 HDFS 的时候打印一次（每次操作都会打印一次），说明第一次连接到了 standby 状态的 namenode，是正常的，不用关心；但是，如果出现了大量的异常（比如连续10次，连续20次），说明 namenode 出问题了，此时应该关心 namenode 的状态，确保正常服务。


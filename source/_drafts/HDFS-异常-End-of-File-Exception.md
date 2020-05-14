---
title: HDFS 异常 End of File Exception
id: 2020-05-15 01:25:53
date: 2020-03-08 01:25:53
updated: 2020-05-15 01:25:53
categories:
tags:
keywords:
---


2018030801

大数据技术知识
HDFS,Hadoop



<!-- more -->


HDFS 命令 getmerge 数据文件

hdfs dfs -getmerge /path/to/file/ ./local/file，报错：

```
18/03/07 12:48:47 INFO retry.RetryInvocationHandler: Exception while invoking getFileInfo of class ClientNamenodeProtocolTranslatorPB over host15/192.168.2.15:8020 after 13 fail over attempts. Trying to fail over immediately.
java.io.EOFException: End of File Exception between local host is: "local3/192.168.1.3"; destination host is: "host15":8020; : java.io.EOFException; For more details see:  http://wiki.apache.org/hadoop/EOFException
    at sun.reflect.NativeConstructorAccessorImpl.newInstance0(Native Method)
    at sun.reflect.NativeConstructorAccessorImpl.newInstance(NativeConstructorAccessorImpl.java:57)
    at sun.reflect.DelegatingConstructorAccessorImpl.newInstance(DelegatingConstructorAccessorImpl.java:45)
    at java.lang.reflect.Constructor.newInstance(Constructor.java:526)
    at org.apache.hadoop.net.NetUtils.wrapWithMessage(NetUtils.java:791)
    at org.apache.hadoop.net.NetUtils.wrapException(NetUtils.java:764)
    at org.apache.hadoop.ipc.Client.call(Client.java:1473)
    at org.apache.hadoop.ipc.Client.call(Client.java:1400)
    at org.apache.hadoop.ipc.ProtobufRpcEngine$Invoker.invoke(ProtobufRpcEngine.java:232)
    at com.sun.proxy.$Proxy9.getFileInfo(Unknown Source)
    at org.apache.hadoop.hdfs.protocolPB.ClientNamenodeProtocolTranslatorPB.getFileInfo(ClientNamenodeProtocolTranslatorPB.java:768)
    at sun.reflect.NativeMethodAccessorImpl.invoke0(Native Method)
    at sun.reflect.NativeMethodAccessorImpl.invoke(NativeMethodAccessorImpl.java:57)
    at sun.reflect.DelegatingMethodAccessorImpl.invoke(DelegatingMethodAccessorImpl.java:43)
    at java.lang.reflect.Method.invoke(Method.java:606)
    at org.apache.hadoop.io.retry.RetryInvocationHandler.invokeMethod(RetryInvocationHandler.java:187)
    at org.apache.hadoop.io.retry.RetryInvocationHandler.invoke(RetryInvocationHandler.java:102)
    at com.sun.proxy.$Proxy10.getFileInfo(Unknown Source)
    at org.apache.hadoop.hdfs.DFSClient.getFileInfo(DFSClient.java:2007)
    at org.apache.hadoop.hdfs.DistributedFileSystem$19.doCall(DistributedFileSystem.java:1136)
    at org.apache.hadoop.hdfs.DistributedFileSystem$19.doCall(DistributedFileSystem.java:1132)
    at org.apache.hadoop.fs.FileSystemLinkResolver.resolve(FileSystemLinkResolver.java:81)
    at org.apache.hadoop.hdfs.DistributedFileSystem.getFileStatus(DistributedFileSystem.java:1132)
    at org.apache.hadoop.fs.Globber.getFileStatus(Globber.java:57)
    at org.apache.hadoop.fs.Globber.glob(Globber.java:252)
    at org.apache.hadoop.fs.FileSystem.globStatus(FileSystem.java:1648)
    at org.apache.hadoop.fs.shell.PathData.expandAsGlob(PathData.java:326)
    at org.apache.hadoop.fs.shell.Command.expandArgument(Command.java:224)
    at org.apache.hadoop.fs.shell.Command.expandArguments(Command.java:207)
    at org.apache.hadoop.fs.shell.Command.processRawArguments(Command.java:190)
    at org.apache.hadoop.fs.shell.Command.run(Command.java:154)
    at org.apache.hadoop.fs.FsShell.run(FsShell.java:287)
    at org.apache.hadoop.util.ToolRunner.run(ToolRunner.java:70)
    at org.apache.hadoop.util.ToolRunner.run(ToolRunner.java:84)
    at org.apache.hadoop.fs.FsShell.main(FsShell.java:340)
Caused by: java.io.EOFException
    at java.io.DataInputStream.readInt(DataInputStream.java:392)
    at org.apache.hadoop.ipc.Client$Connection.receiveRpcResponse(Client.java:1072)
    at org.apache.hadoop.ipc.Client$Connection.run(Client.java:967)
```


退出重新登录跳板机服务器，重新下载文件，可以了。

原因在于更改了 `HADOOP_USER_NAME` 环境变量，由于之前想手动删除 `HDFS` 的多余文件，手动设置了 `export HADOOP_USER_NAME=spark`，才有权限，删除完成后又设置为空 `export HADOOP_USER_NAME=`，然后就无法使用 `HDFS` 命令了。

此前有一次跑不了读取 `HDFS` 的 `Spark` 程序，也报类似的错误，可能也是这个原因。


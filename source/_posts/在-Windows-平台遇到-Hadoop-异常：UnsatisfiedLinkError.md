---
title: 在 Windows 平台遇到 Hadoop 异常：UnsatisfiedLinkError
id: 2017052101
date: 2017-05-21 20:03:14
updated: 2019-10-14 20:03:14
categories: 大数据技术知识
tags: [Spark,HBase,Hadoop]
keywords: Spark,HBase,Hadoop
---


在 `Windows` 平台运行 `Spark` 程序，`Spark` 任务的逻辑很简单，从 `HBase` 中获取数据，然后通过中间 `Spark` 算子做一些合并、过滤、去重等操作，最后写入 `HDFS`。

这个功能在真实线上环境一直运行稳定，由于业务逻辑需要做小部分修改升级，我修改完成后自己在电脑上测试【开发环境】，抛出异常：

```
java.lang.UnsatisfiedLinkError: org.apache.hadoop.util.NativeCrc32.nativeComputeChunkedSumsByteArray(II[BI[BIILjava/lang/String;JZ)V
```

并且数据写入 `HDFS` 失败，本文记录排查过程与解决方案。

本文开发环境基于 `Windows 10`、`HBase v1.1.2`、`Hadoop v2.7.1`、`Spark v1.6.2` 。


<!-- more -->


# 问题出现


在自己的电脑上使用 `IDEA` 调试 `Spark` 程序【开发环境】，使用 `local` 模式，从 `HBase` 中读取数据，处理后写入 `HDFS` 中，以前是运行正常的，但是今天就出现异常，异常信息如下：

```
20:00:34.116 [Executor task launch worker-0] ERROR org.apache.spark.executor.Executor - Exception in task 0.0 in stage 4.0 (TID 3)
java.lang.UnsatisfiedLinkError: org.apache.hadoop.util.NativeCrc32.nativeComputeChunkedSumsByteArray(II[BI[BIILjava/lang/String;JZ)V
	at org.apache.hadoop.util.NativeCrc32.nativeComputeChunkedSumsByteArray(Native Method)
	at org.apache.hadoop.util.NativeCrc32.calculateChunkedSumsByteArray(NativeCrc32.java:86)
	at org.apache.hadoop.util.DataChecksum.calculateChunkedSums(DataChecksum.java:430)
	at org.apache.hadoop.fs.FSOutputSummer.writeChecksumChunks(FSOutputSummer.java:202)
	at org.apache.hadoop.fs.FSOutputSummer.flushBuffer(FSOutputSummer.java:163)
	at org.apache.hadoop.fs.FSOutputSummer.flushBuffer(FSOutputSummer.java:144)
	at org.apache.hadoop.hdfs.DFSOutputStream.closeImpl(DFSOutputStream.java:2318)
	at org.apache.hadoop.hdfs.DFSOutputStream.close(DFSOutputStream.java:2300)
	at org.apache.hadoop.fs.FSDataOutputStream$PositionCache.close(FSDataOutputStream.java:72)
	at org.apache.hadoop.fs.FSDataOutputStream.close(FSDataOutputStream.java:106)
	at org.apache.hadoop.mapred.TextOutputFormat$LineRecordWriter.close(TextOutputFormat.java:108)
	at org.apache.spark.SparkHadoopWriter.close(SparkHadoopWriter.scala:103)
	at org.apache.spark.rdd.PairRDDFunctions$$anonfun$saveAsHadoopDataset$1$$anonfun$13$$anonfun$apply$8.apply$mcV$sp(PairRDDFunctions.scala:1203)
	at org.apache.spark.util.Utils$.tryWithSafeFinallyAndFailureCallbacks(Utils.scala:1295)
	at org.apache.spark.rdd.PairRDDFunctions$$anonfun$saveAsHadoopDataset$1$$anonfun$13.apply(PairRDDFunctions.scala:1203)
	at org.apache.spark.rdd.PairRDDFunctions$$anonfun$saveAsHadoopDataset$1$$anonfun$13.apply(PairRDDFunctions.scala:1183)
	at org.apache.spark.scheduler.ResultTask.runTask(ResultTask.scala:66)
	at org.apache.spark.scheduler.Task.run(Task.scala:89)
	at org.apache.spark.executor.Executor$TaskRunner.run(Executor.scala:227)
	at java.util.concurrent.ThreadPoolExecutor.runWorker(ThreadPoolExecutor.java:1149)
	at java.util.concurrent.ThreadPoolExecutor$Worker.run(ThreadPoolExecutor.java:624)
	at java.lang.Thread.run(Thread.java:748)
20:00:34.128 [Executor task launch worker-0] ERROR o.a.s.u.SparkUncaughtExceptionHandler - Uncaught exception in thread Thread[Executor task launch worker-0,5,main]
```

![Spark 错误日志](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2017/20191015212035.png "Spark 错误日志")

注意这个异常信息里面的类描述信息：

```
org.apache.hadoop.util.NativeCrc32.nativeComputeChunkedSumsByteArray(II[BI[BIILjava/lang/String;JZ)V
```

除了完整的包名、类名外，可以看到还有一个奇怪的信息，即末尾的：
`(II[BI[BIILjava/lang/String;JZ)V`，它其实是**JNI 字段描述符**，用简单的符号来表示 `Java` 的数据类型。

其中，括号里面的是参数类型，括号外面的 `V` 表示方法的返回类型是 `void`，`L` 表示 `Object` 类型，`[` 表示数组类型，更多内容请参考本文末尾的备注，这里不再赘述。

我查了 `Unsatisfied` 的含义，表示不满意，我想这里的意思应该是不匹配，也就是这个类有问题，至于是什么问题目前还不清楚。


# 问题解决


通过查询资料，找到这个问题的原因是本机的 `Hadoop` 版本不对【与服务器上比较、与项目的 `Hadoop` 依赖版本比较】，或者是本机开发环境缺失正确的 `hadoop.dll`、`winutils.exe` 文件。

我先查看了本机的 `Hadoop` 版本，并没有问题，并且 `HADOOP_HOME` 的配置也是正确的。

![HADOOP_HOME 设置](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2017/20191015211746.png "HADOOP_HOME 设置")

在 `Windows` 中，`dll` 文件表示动态链接库，全称：`Dynamic Link Library`，又称应用程序拓展，这种文件并不是一个完整的应用程序，他只是一个扩展库，可以给其它应用程序调用。

而这里的 `hadoop.dll` 就是专门给 `Hadoop` 平台准备的，因为官方发布的 `Hadoop` 包不能确保开发者开发的 `Spark`、`Mapreduce` 等应用在 `Windows` 平台上面直接运行，或者说不适配，需要加一些 `dll` 扩展库，才能保证 `Hadoop` 组件在 `Windows` 平台提供稳定的服务。

直接去下载一份对应版本的 `hadoop.dll`、`winutils.exe`，放在操作系统的 `C:\Windows\System32` 目录即可。

![dll 文件放入系统目录](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2017/20191015211930.png "dll 文件放入系统目录")

补齐文件后，再次运行，很顺利，问题解决。


# 备注


1、互联网上关于 `hadoop.dll` 的资源很多，但是需要下载时很不友好【积分、广告、过期】，所以推荐大家去 `GitHub` 上寻找，这里列举一个例子：[GitHub winutils](https://github.com/steveloughran/winutils) ，下载时注意版本的选择，也不是所有的版本都有。

2、关于上文中简单提到的**JNI 字段描述符**，更为完整的信息可以参考我的另外一篇博文：[JNI 字段描述符基础知识](https://www.playpi.org/2019041301.html) 。


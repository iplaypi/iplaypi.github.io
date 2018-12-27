---
title: HDFS 异常之 Filesystem closed
id: 2018122701
date: 2018-12-27 17:35:54
updated: 2018-12-27 17:35:54
categories: Hadoop 从零基础到入门系列
tags: [Hadoop,Spark,Filesystem,HDFS]
keywords: Hadoop,Spark,Filesystem,HDFS
---


今天通过 Hadoop 的 api 去操作 HDFS 里面的文件，读取文本内容，但是在代码里面总是抛出以下异常：

````java
Caused by: java.io.IOException: Filesystem closed
````

然而文本内容又是正常读取出来的，但是我隐隐觉得读取的文本内容可能不全，应该只是所有文本内容的一部分。本文就记录这个问题的原因、影响以及解决方法。


<!-- more -->


# 问题出现


通过查看日志发现，有大量的异常日志打印出来，全部都是操作 HDFS 的时候产生的，有的是使用 Spark 连接 HDFS 读取文本数据，有的是使用 Hadoop 的 Java api 通过文件流来读取数据，每次读取操作都会产生一个如下异常信息（会影响实际读取的内容，多个 DataNode 的内容会漏掉）：

````java
2018-12-26_23:25:46 [SparkListenerBus] ERROR scheduler.LiveListenerBus:95: Listener EventLoggingListener threw an exception
java.lang.reflect.InvocationTargetException
	at sun.reflect.GeneratedMethodAccessor33.invoke(Unknown Source)
	at sun.reflect.DelegatingMethodAccessorImpl.invoke(DelegatingMethodAccessorImpl.java:43)
	at java.lang.reflect.Method.invoke(Method.java:498)
	at org.apache.spark.scheduler.EventLoggingListener$$anonfun$logEvent$3.apply(EventLoggingListener.scala:150)
	at org.apache.spark.scheduler.EventLoggingListener$$anonfun$logEvent$3.apply(EventLoggingListener.scala:150)
	at scala.Option.foreach(Option.scala:236)
	at org.apache.spark.scheduler.EventLoggingListener.logEvent(EventLoggingListener.scala:150)
	at org.apache.spark.scheduler.EventLoggingListener.onJobStart(EventLoggingListener.scala:173)
	at org.apache.spark.scheduler.SparkListenerBus$class.onPostEvent(SparkListenerBus.scala:34)
	at org.apache.spark.scheduler.LiveListenerBus.onPostEvent(LiveListenerBus.scala:31)
	at org.apache.spark.scheduler.LiveListenerBus.onPostEvent(LiveListenerBus.scala:31)
	at org.apache.spark.util.ListenerBus$class.postToAll(ListenerBus.scala:55)
	at org.apache.spark.util.AsynchronousListenerBus.postToAll(AsynchronousListenerBus.scala:37)
	at org.apache.spark.util.AsynchronousListenerBus$$anon$1$$anonfun$run$1$$anonfun$apply$mcV$sp$1.apply$mcV$sp(AsynchronousListenerBus.scala:80)
	at org.apache.spark.util.AsynchronousListenerBus$$anon$1$$anonfun$run$1$$anonfun$apply$mcV$sp$1.apply(AsynchronousListenerBus.scala:65)
	at org.apache.spark.util.AsynchronousListenerBus$$anon$1$$anonfun$run$1$$anonfun$apply$mcV$sp$1.apply(AsynchronousListenerBus.scala:65)
	at scala.util.DynamicVariable.withValue(DynamicVariable.scala:57)
	at org.apache.spark.util.AsynchronousListenerBus$$anon$1$$anonfun$run$1.apply$mcV$sp(AsynchronousListenerBus.scala:64)
	at org.apache.spark.util.Utils$.tryOrStopSparkContext(Utils.scala:1181)
	at org.apache.spark.util.AsynchronousListenerBus$$anon$1.run(AsynchronousListenerBus.scala:63)
Caused by: java.io.IOException: Filesystem closed
	at org.apache.hadoop.hdfs.DFSClient.checkOpen(DFSClient.java:795)
	at org.apache.hadoop.hdfs.DFSOutputStream.flushOrSync(DFSOutputStream.java:1986)
	at org.apache.hadoop.hdfs.DFSOutputStream.hflush(DFSOutputStream.java:1947)
	at org.apache.hadoop.fs.FSDataOutputStream.hflush(FSDataOutputStream.java:130)
	... 20 more
````

最直接清晰的描述就是：

````java
Caused by: java.io.IOException: Filesystem closed
````

上述异常信息表明 HDFS 的 Filesystem 被关闭了，但是代码仍旧试图打开文件流读取内容。


# 问题解决


## 分析一下

根据上述信息，查看代码，每次操作 HDFS 都是独立的，会先根据统一的 conf 创建 Filesystem，然后根据文件路径创建 Path，打开输入流，读取内容，读取完成后关闭 Filesystem，没有什么异常的地方。

同时，根据异常信息可以发现，异常的抛出点并不是业务逻辑代码，更像是已经开始开启文件流读取文件，读着读着 Filesystem 就被关闭了，然后引发了异常，而业务逻辑中并没有突然关闭 Filesystem 的地方，也没有多线程操作 Filesystem 的地方。

````java
    /**
     * 获取文件内容
     * 纯文本,不做转换
     * 如果传入目录,返回空内容
     *
     * @param hdfsFile
     * @return
     */
    public static Set<String> getFileContent(String hdfsFile) {
        Set<String> dataResult = new HashSet<>();
        FileSystem fs = null;
        try {
            // 连接 hdfs
            fs = FileSystem.get(CONF);
            Path path = new Path(hdfsFile);
            if (fs.isFile(path)) {
                FSDataInputStream fsDataInputStream = fs.open(path);
                BufferedReader bufferedReader = new BufferedReader(new InputStreamReader(fsDataInputStream));
                String line = null;
                while (null != (line = bufferedReader.readLine())) {
                    dataResult.add(line);
                }
            } else {
                LOGGER.error("!!!!当前输入参数为目录,不读取内容:{}", hdfsFile);
            }
        } catch (Exception e) {
            LOGGER.error("!!!!处理hdfs出错: " + e.getMessage(), e);
        } finally {
            if (null != fs) {
                try {
                    fs.close();
                } catch (IOException e) {
                    LOGGER.error("!!!!关闭文件流出错: " + e.getMessage(), e);
                }
            }
        }
        return dataResult;
    }
````

通过查找文档发现，这个异常是 Filesystem 的缓存导致的。

当任务提交到集群上面以后，多个 datanode 在 getFileSystem 过程中，由于 Configuration 一样，会得到同一个 FileSystem。如果有一个 datanode 在使用完关闭连接，其它的 datanode 在访问时就会出现上述异常，导致数据缺失（如果数据恰好只存在一个 datanode 上面，可能没问题）。

## 找到方法

通过上面的分析，找到了原因所在，那么解决方法有2种：

1、可以在 HDFS 的 core-site.xml 配置文件里面把 fs.hdfs.impl.disable.cache 设置为 true，这样设置会全局生效，所有使用这个配置文件的连接都会使用这种方式，有时候可能不想这样更改，那就使用第2种方式；

````xml
<property>
    <name>fs.hdfs.impl.disable.cache</name>
    <value>true</value>
</property>
````

2、在 HDFS 提供的 Java api 里面更改配置信息，则会只针对使用当前 conf 的连接有效，相当于临时参数。

````java
// 缓存fs,避免多datanode异常:Caused by: java.io.IOException: Filesystem closed
CONF.setBoolean("fs.hdfs.impl.disable.cache", true);
````

上面2种方法的目的都是为了关闭缓存 Filesyetem 实例，这样每次获得的 Filesystem 实例都是独立的，不会产生上述的异常，但是缺点就是会增加网络的 I/O，频繁开启、关闭文件流。


# 问题总结


1、参考：[https://stackoverflow.com/questions/23779186/ioexception-filesystem-closed-exception-when-running-oozie-workflow](https://stackoverflow.com/questions/23779186/ioexception-filesystem-closed-exception-when-running-oozie-workflow) ；

2、保留日志，查看日志很重要；

3、FileSytem 类内部有一个 static CACHE，用来保存每种文件系统的实例集合，FileSystem 类中可以通过参数 fs.%s.impl.disable.cache 来指定是否禁用缓存 FileSystem 实例（其中 %s 替换为相应的scheme，比如 hdfs、local、s3、s3n等）。如果没禁用，一旦创建了相应的 FileSystem 实例，这个实例将会保存在缓存中，此后每次 get 都会获取同一个实例，但是如果被关闭了，则再次用到就会无法获取（多 datanode 读取数据的时候）；

4、源码分析放在以后，留坑。


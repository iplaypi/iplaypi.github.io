---
title: 记录一个 Kafka 错误：OffsetOutOfRangeException
id: 2017060101
date: 2017-06-01 02:21:19
updated: 2019-07-28 02:21:19
categories: 大数据技术知识
tags: [Kafka,OffsetOutOfRangeException,Spark,SparkStreaming,Zookeeper]
keywords: Kafka,OffsetOutOfRangeException,Spark,SparkStreaming,Zookeeper
---


在使用 `Kafka` 的过程中，某一天项目中莫名其妙出现了一个异常信息：
`kafka.common.OffsetOutOfRangeException`
项目的业务场景是使用 `SparkStreaming` 消费 `Kafka` 数据，进一步进行 **ETL 处理**，没有复杂的逻辑。平时一切正常运行，某一天我想在测试环境测试一下更新的逻辑代码，就出现了这个问题，导致整个进程任务失败。本文记录分析问题、解决问题的过程，运行环境基于 `Kafka v0.8.2.1`，`Spark v1.6.2`、`spark-streaming v2.10`，其它版本的内容会与这个版本存在部分不一致的地方，我会特殊说明。


<!-- more -->


# 问题出现


某一天我修改了项目的代码，在本地连接测试环境，开始测试，出现以下异常信息：

```
Caused by: kafka.common.OffsetOutOfRangeException
	at sun.reflect.NativeConstructorAccessorImpl.newInstance0(Native Method)
	at sun.reflect.NativeConstructorAccessorImpl.newInstance(NativeConstructorAccessorImpl.java:62)
	at sun.reflect.DelegatingConstructorAccessorImpl.newInstance(DelegatingConstructorAccessorImpl.java:45)
	at java.lang.reflect.Constructor.newInstance(Constructor.java:423)
	at java.lang.Class.newInstance(Class.java:442)
	at kafka.common.ErrorMapping$.exceptionFor(ErrorMapping.scala:86)
	at org.apache.spark.streaming.kafka.KafkaRDD$KafkaRDDIterator.handleFetchErr(KafkaRDD.scala:184)
	at org.apache.spark.streaming.kafka.KafkaRDD$KafkaRDDIterator.fetchBatch(KafkaRDD.scala:193)
	at org.apache.spark.streaming.kafka.KafkaRDD$KafkaRDDIterator.getNext(KafkaRDD.scala:208)
	at org.apache.spark.util.NextIterator.hasNext(NextIterator.scala:73)
	at scala.collection.convert.Wrappers$IteratorWrapper.hasNext(Wrappers.scala:29)
	at com.datastory.banyan.v3.consumer.BaseRhinoDirectConsumerV3$1.call(BaseRhinoDirectConsumerV3.java:81)
	at com.datastory.banyan.v3.consumer.BaseRhinoDirectConsumerV3$1.call(BaseRhinoDirectConsumerV3.java:72)
	at org.apache.spark.api.java.JavaRDDLike$$anonfun$foreachPartition$1.apply(JavaRDDLike.scala:225)
	at org.apache.spark.api.java.JavaRDDLike$$anonfun$foreachPartition$1.apply(JavaRDDLike.scala:225)
	at org.apache.spark.rdd.RDD$$anonfun$foreachPartition$1$$anonfun$apply$33.apply(RDD.scala:920)
	at org.apache.spark.rdd.RDD$$anonfun$foreachPartition$1$$anonfun$apply$33.apply(RDD.scala:920)
	at org.apache.spark.SparkContext$$anonfun$runJob$5.apply(SparkContext.scala:1858)
	at org.apache.spark.SparkContext$$anonfun$runJob$5.apply(SparkContext.scala:1858)
	at org.apache.spark.scheduler.ResultTask.runTask(ResultTask.scala:66)
	at org.apache.spark.scheduler.Task.run(Task.scala:89)
	at org.apache.spark.executor.Executor$TaskRunner.run(Executor.scala:227)
	... 3 more
```

项目中的异常信息本来有很多行，但是关键的就是这部分内容，关键异常信息截图如下。

![异常信息截图](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2017/20190728180827.png "异常信息截图")

重点就看 `Caused by: kafka.common.OffsetOutOfRangeException` 这一句即可，可以明显看出问题所在：**下标越界**，下一步开始分析问题、解决问题。


# 问题分析解决


## 分析

原因既然是**下标越界**，就要先搞清楚 `Kafka` 在什么场景下会出现这个异常。

通过查看源代码得知，这是 `Kafka topic` 的 `offset` 下标越界异常，对应我这个场景，就是 `Spark` 任务在消费 `Kafka topic` 的数据时，指定的下标不在**有效数据**范围之内。

有点看不明白？的确，此处有必要插入一些基本知识点。**消费者**客户端在消费处理 `Kafka topic` 的数据时，会有一个**偏移量**【取值是数字】记录已经消费数据的位置，也可以说是下标，称之为 `offset`，并同步更新到 `Zookeeper` 中。[^1] 如果**消费者**客户端在消费中途出问题而停止，等下一次消费时会从上一次中断的**偏移量**位置开始继续消费数据，[^2] 这样就可以避免重复消费数据，节约资源。

以上注解1、注解2：

[^1]: 注意，`Kafka v0.9.0.x` 以及之后的版本不再是这个策略，不再使用 `Zookeeper` 存储，改成存储到 `kafka` 的 `broker` 节点上面，更方便管理。

[^2]: 注意，这里的消费策略是通过参数 `auto.offset.reset` 设置的，从上一次中断的位置继续消费数据只是消费策略选择之一，取值 `smallest`。另外，`Kafka v0.7.x` 以及之前的版本这个参数曾经的名称为：`autooffset.reset`。这个参数的取值在 `v.0.9.0.x` 以及之后的版本也更名为：`earliest`、`latest`、`none`。

接着回到正题，如果发生**下标越界**现象，说明 `Zookeeper` 中保存**消费者**的 `offset` 的值小于 `topic` 中存在的最早的 `message` 的 `offset` 值，即 `zookeeper_offset < 最早_offset`。

这就导致**消费者**程序运行时需要消费的数据在 `Kafka topic` 中并不存在，进而引发异常的发生。表面上是因为消费的 `Zookeeper` 缓存信息不正确，实际上是因为 `Kafka` 的数据过期被清除了，下面我将使用 `Kafka` 自带的命令来一一验证。

## 验证

先查看**消费者**的消费进度信息，指定 `Zookeeper` 主机、消费 `group` 组名、`topic` 名称，使用命令：`bin/kafka-consumer-offset-checker.sh --zookeeper zkhost:2181 --group consumer_group_name --topic topic_name`。

查看消费进度，可以看到 `offset` 是0，表示从头开始消费，`logSize` 是10044740，表示 `Kafka topic` 已经生产了这么多数据。

![查看消费进度](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2017/20190728180912.png "查看消费进度")

从上图可以看出 `topic` 的**消费者**只有1个消费组分区，为了保险起见，再验证一下这个 `topic` 的分区数是怎样的，使用命令：`bin/kafka-topics.sh --describe --zookeeper zkhost:2181 --topic topic_name`。

查看分区数，可以看到只有1个分区，编号为0 。

![查看分区数](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2017/20190728180936.png "查看分区数")

综上截图，可以得出总结，**消费者**程序是从下标0开始消费数据，也就是从头开始，而 `topic` 的数据已经生产了1000多万。那么，读者就会怀疑，这种情况下怎么可能会**下标越界**呢，0就是开始的位置，还怎么越界。除非 `topic` 当前的数据量为0，而不是1000多万。

我思考了一下，上述的结论是基于 `Zookeeper` 的缓存信息得到的，如果 `Kafka topic` 里面真的有数据存在，的确不可能下标越界。但是，此处还会有另外一种情况，如果 `Kafka` 里面的数据已经过期了【`Kafka` 有相关的参数可以设置过期策略】，那就会找不到数据，则报错**下标越界**。

再结合我的业务场景，由于我的**消费者**程序给消费组重新定义了名字【使用 `group.id` 参数】，所以会从头消费【`offset` 为0】，但是测试环境的 `Kafka topic` 里面的数据极有可能是很久之前的，从创建 `topic` 开始到现在累积了1000多万数据，大量数据由于过期策略已经被清除了，现在肯定找不到。

接下来去查看 `Kafka broker` 服务的相关配置：过期策略、数据存储位置，在  `kafka broker` 的安装目录查看 `conf/server.properties` 配置文件，验证我的猜测。

首先查看名称为 `log.retention.*` 的相关参数，看看设置的值是什么：

![查看 Kafka 过期策略](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2017/20190728181003.png "查看 Kafka 过期策略")

可以看到，相关参数设置的值是 `log.retention.hours=48`，也就是说数据的有效期是48小时，过期会自动清理，而 `log.retention.bytes=-1` 表示不限制数据空间大小，即不会因为数据占用空间太大而删除。

那么，`Kafka topic` 里面的数据是不是真的不在了呢，让我一探究竟，继续从配置文件中查看数据存储目录，参数名称为：`log.dirs` 。

![查看 Kafka 数据存储位置](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2017/20190728181036.png "查看 Kafka 数据存储位置")

可以看到，数据与索引存储在 `/kafka-logs` 目录，进入目录，找到指定的 `topic`、`partition` 对应的目录，我这里是 `/kafka-logs/topic_name-partition_number`。

![查看 Kafka 数据文件](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2017/20190728181046.png "查看 Kafka 数据文件")

可以从上图看到目录里面有2个文件，分别是数据文件：`00000000000010044740.log`、索引文件：`00000000000010044740.index`。通过查看文件空间大小，发现数据文件的大小的是0B，什么意思呢，表示没有数据，看来数据已经全部过期而且都被清理掉了。

至此，验证了我全部的分析猜测，下面可以简单复现一下这个异常现象。

## 重现异常

1、修改配置文件，把过期时间设置为3分钟：`log.retention.minutes=3`，然后重启 `Kafka` 服务。
2、使用 `Kafka producer` 生产一批数据，100条，并等待3分钟，数据由于过期会被清理。
3、启动 `SparkStreaming` 消费程序处理数据，出现异常。
4、使用 `Kafka` 命令查看**消费者**消费进度信息，`offset` 是0，`logSize` 是100 。
5、去 `Zookeeper` 里面查看 `zk_offset` 的值，是0 。

复现异常，现象完全一致，至此问题原因找到。

总结一下：我这里的 `Kafka topic` 已经生产了1000多万的数据，但是旧数据由于过期被清理，而且全部被清理掉了。然而 `Zookeeper` 中的 `Kafka topic` 信息仍旧保留，**消费者**程序从头消费的时候，实际上已经获取不到 `Kafka topic` 的真实数据，所以一定会有异常。

## 解决

那怎么办呢，如果 `Kafka topic` 继续生产数据，我的**消费者**程序怎么才能消费到新数据呢？

其实还是有办法的，最简单的就是不要使用新的消费组名【`group.id` 参数指定】，如果能继续使用以前的消费组名，并且以前已经把数据消费处理完了，那么它的 `offset` 也就是最大的值。此时如果继续消费数据，是从最大的**偏移量**位置开始消费的，即只会消费最新生产的数据，不会有**下标越界**的异常出现。

但是，如果非要使用新的消费组名称，并且也想从最新生产的数据开始消费【从头再重复消费1000多万数据太浪费资源】，有没有办法呢。当然也有，可以手动在 `Zookeeper` 查询一下消费者的**偏移量**，主要查看当前消费组对某个 `Kafka topic` 的消费**偏移量**，然后根据实际情况重置即可。

先登录 `Zookeeper` 服务，在指定目录查看消费者的**偏移量**，需要指定消费组名称、`topic` 名称，使用命令：`get /consumers/consumer_group_name/offsets/topic_name/0` 。

![查看消费分区偏移量](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2017/20190728181432.png "查看消费分区偏移量")

可以看到当前取值是0，接着重置消费者的**偏移量**，使用命令：
`set /consumers/consumer_group_name/offsets/topic_name/0 10044740` 。

![重置消费分区偏移量](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2017/20190728181441.png "重置消费分区偏移量")

我把它重置为最大值，接下来再测试消费程序就会从最新生产的数据开始消费。

好了，接下来就成功运行了。


# 总结备注


## 不同版本之间的参数差异

本文是基于低版本的 `Kafka` 进行分析问题的：`v0.8.2.1`，关于里面的参数信息可以参考官网：
[Kafka-v0.8.2-configuration](https://kafka.apache.org/082/documentation.html#consumerconfigs) 。

其中，`auto.offset.reset` 这个参数【`v0.7.x` 之前参数名称为 `autooffset.reset`】的解释说明如图。

![低版本 auto.offset.reset 参数说明](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2017/20190729204654.png "低版本 auto.offset.reset 参数说明")

原文如下：

> What to do when there is no initial offset in ZooKeeper or if an offset is out of range:
> - `smallest` : automatically reset the offset to the smallest offset
> - `largest` : automatically reset the offset to the largest offset
> - `anything else`: throw exception to the consumer

参数含义的总结归纳：

- `smallest`：当各分区下有已提交的 `offset` 时，从提交的 `offset` 开始消费；无提交的 `offset` 时，从头开始消费
- `largest`：当各分区下有已提交的 `offset` 时，从提交的 `offset` 开始消费；无提交的 `offset` 时，从该分区下新产生的数据开始消费
- `anything else`：`topic` 各分区都存在已提交的 `offset` 时，从 `offset` 后开始消费；只要有一个分区不存在已提交的 `offset`，则抛出异常信息

关于 `v0.7.x` 版本的参数信息参考官网：
[Kafka-v0.7.x-configuration](https://kafka.apache.org/07/documentation/#configuration) 。

其中，`autooffset.reset` 这个参数名称和以后的都不一样，解释说明如图。

![低版本 autooffset.reset 参数说明](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2017/20190728181607.png "低版本 autooffset.reset 参数说明")

原文如下：

> - `smallest`: automatically reset the offset to the smallest offset available on the broker.
> - `largest` : automatically reset the offset to the largest offset available on the broker.
> - `anything else`: throw an exception to the consumer.

至于高版本的配置信息，也可以参考官网：
[Kafka-v0.9.0.x-configuration](https://kafka.apache.org/090/documentation.html#consumerconfigs) 。

其中，`auto.offset.reset` 这个参数的解释说明如图，自从 `v0.9.0.x` 版本之后，它的取值已经变化。

![高版本 auto.offset.reset 参数说明](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2017/20190728190054.png "高版本 auto.offset.reset 参数说明")

原文如下：

> What to do when there is no initial offset in Kafka or if the current offset does not exist any more on the server (e.g. because that data has been deleted):
> - `earliest`: automatically reset the offset to the earliest offset.
> - `latest`: automatically reset the offset to the latest offset.
> - `none`: throw exception to the consumer if no previous offset is found for the consumer's group.
> - `anything else`: throw exception to the consumer.

## 消费者信息存储位置

**消费者**信息存储位置的问题，新版本【v0.9.x 以及之后】不存储在 `Zookeeper` 了，转而存到 `Kafka` 的 `broker` 节点。如果有**消费者**启动，那么这个**消费者**的组名和它要消费的那个 `topic` 的 `offset` 信息就会被记录在 `broker` 节点上。

## 关于偏移量的另一个常见异常

关于偏移量 `offset` 的问题，还有一个常见异常：`numRecords must not be negative`，它主要是由删除 `Kafka topic` 后又新建同名的 `topic` 引起的。根本原因在于删除 `topic` 后没有把 `Zookeeper` 中的**消费者**的信息也一同删除，导致遗留的**消费者**的信息在新建同名后 `topic` 被作为当前 `topic` 的**消费者**的信息，如果此时启动一个消费程序，在计算 `numRecords` 的时候会出现负数的情况【0减去old_offset】，接着就会抛出这个异常。


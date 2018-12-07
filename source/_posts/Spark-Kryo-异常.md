---
title: Spark Kryo 异常
id: 2018100801
date: 2018-10-08 00:11:48
updated: 2018-12-08 00:11:48
categories: 基础技术知识
tags: [Spark,Kryo,序列化]
keywords: Spark异常,Spark,Kryo Spark,Spark 序列化
---

本文讲述使用 es-hadoop （版本 v5.6.8）组件，运行 Spark 任务遇到的异常：
```java
Caused by: java.io.EOFException
at org.apache.spark.serializer.KryoDeserializationStream.readObject(KryoSerializer.scala:232)
at org.apache.spark.broadcast.TorrentBroadcast$.unBlockifyObject(TorrentBroadcast.scala:217)
```
以及通过 Maven 依赖查找分析的解决方法。

<!-- more -->

# 遇到问题

由于最近的 elasticsearch 集群升级版本，到了 v5.6.8 版本，所用的功能为了兼容处理高版本的 elasticsearch 集群，需要升级 es-hadoop 相关依赖包到版本 v5.6.8，结果就遇到了问题：

![异常信息](https://ws1.sinaimg.cn/large/b7f2e3a3gy1fxyn2hnapxj21600cbdhd.jpg "异常信息")

代码逻辑就是通过 es-spark 直接读取 elasticsearch 里面的数据，生成 RDD，然后简单处理，直接写入 HDFS 里面。本机在测试平台测试一切正常，没有任何问题，但是在线上运行就会抛出异常。

# 解决方法

先分析一下这个问题产生的原因，在代码层面没有任何变动，只是更改了依赖的版本，所以问题在于更改版本之后是不是导致了传递依赖包的缺失，或者版本冲突，所以总体而言，肯定是Maven 依赖包的问题，这个思路没问题。

提前说明下面截图中出现的 Maven 中的常量：
```xml
<elasticsearch-hadoop.version>5.6.8</elasticsearch-hadoop.version>
<spark-core_2.10.version>1.6.2</spark-core_2.10.version>
```

1、local 模式
通过在本机连接测试平台，运行起来没有问题，但是部署到正式环境，运行不起来，直接抛出上图所示的异常信息。

首先去依赖树里面查看与 kryo 相关的依赖信息（使用 mvn dependency:tree 命令）：
![kryo 相关的依赖信息](https://ws1.sinaimg.cn/large/b7f2e3a3gy1fxynj70u3ij20ue0kz0uy.jpg "kryo 相关的依赖信息")

发现两个依赖包（es-hadoop v5.6.8，spark-core_2.10 v1.6.2）里面都有与之相关的传递依赖，而且版本（奇怪的是 groupId 也稍有不同，这导致了我后续判断失误）不一致，这必然导致依赖包的版本冲突，通过 exclusions 方式去除其中一个依赖（其实不是随意去除一个，要经过分析去除错误的那个，保留正确的那个），local 模式可以完美运行。

![移除 spark-core_2.10 的 kryo 依赖](https://ws1.sinaimg.cn/large/b7f2e3a3gy1fxyoie8f6wj20mt0dy0tb.jpg "移除 spark-core_2.10 的 kryo 依赖")
此图是 pom.xml 文件里面的移除信息，是我根据依赖树整理的，可以更加清楚地看到传递依赖的影响。

2、yarn-client 模式

通过步骤1解决了 local 模式运行的问题，但是当使用 yarn-client 模式向 yarn 集群提交 Spark 任务时，如果移除的是 spark-core_2.10里面的 kryo 依赖，异常信息仍然存在，无法正常运行。此时，我想到了前面所说的2个 kryo 依赖包的 groupId 有一点不一样，所以这2个依赖包虽然是同一种依赖包，但是可能由于版本不同的原因，导致名称有些不同。我认为使用的 es-hadoop 依赖的版本比较高，可能没有兼容低版本的 spark-core_2.10，所以需要保留 spark-core_2.10 里面的 kryo 依赖，而是把 es-hadoop 里面的 kryo 依赖移除。果然，再次完美运行。

![移除 es-hadoop 的 kryo 依赖](https://ws1.sinaimg.cn/large/b7f2e3a3gy1fxynyr4f4ej20me0h9aas.jpg "移除 es-hadoop 的 kryo 依赖")

# 总结说明

这次通过 Maven 依赖找到了问题，但是版本仅仅限定在我使用的版本，其它的版本之间会有什么冲突我无法得知，但是这种处理问题的思路是正确的，避免走冤枉路，浪费不必要的时间。

另外，提醒一下大家，更新 pom.xm 文件（包括新增依赖和更新依赖版本）一定要谨慎而行，并且对所要引入的依赖有一个全面的了解，知道要去除什么、保留什么，否则会浪费一些不必要的时间去查找依赖引发的一系列问题。

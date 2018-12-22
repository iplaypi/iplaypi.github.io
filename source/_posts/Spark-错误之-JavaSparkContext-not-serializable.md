---
title: Spark 错误之 JavaSparkContext not serializable
id: 2018122101
date: 2018-12-21 00:43:50
updated: 2018-12-21 00:43:50
categories: 基础技术知识
tags: [Spark,Spark序列化,serializable]
keywords: Spark,Spark序列化,JavaSparkContext not serializable,
---


今天更新代码，对 Spark 里面的 RDD 随便增加了一个 Function，结果遇到了序列化（Serializable）的问题，这个不是普通的自定义类不能序列化问题，而是 JavaSparkContext 的用法问题，由于小看了这个问题，多花了一点时间解决问题，本文就记录下这一过程。


<!-- more -->


# 问题出现


针对已有的项目改动了一点点，结果直接出现了这个错误：

![日志报错](https://ws1.sinaimg.cn/large/b7f2e3a3gy1fydoetmx57j21gx0hjgph.jpg "日志报错")

一开始疏忽大意了，以为像往常一样，是某些需要传递的对象对应的类没有序列化，由于对代码不敢改动太大，就想着用最简单的方法，把几个自定义类都序列化了，以为就应该可以了。结果，还是不行，此时虽然不会有自定义类的序列化问题了，但是却出现了终极错误：JavaSparkContext not serializable，这是什么意思呢，是说 JavaSparkContext 不能序列化，总不能把 JavaSparkContext 序列化吧，Spark 是不允许这么干的。

那么问题是什么呢？我首先猜测肯定是 Function 里面用到了 JavaSparkContext 对象，导致启动 Spark 任务的时候，需要序列化 Function 用到的所有对象（当然也需要序列化对象所属类里面的所有属性），而这些 Function 所用到的所有对象里面，就有 JavaSparkContext 对象。于是，我耐心看了一下代码，果然，在创建 Function 对象的时候，竟然把 JavaSparkContext 对象作为参数传进去了，还是因为 JavaSparkContext 不能乱用。

其实，报错日志里面都已经明显指向说明了，除了自定义的类，错误归结于
```java
at org.apache.spark.api.java.AbstractJavaRDDLike.mapPartitions(JavaRDDLike.scala:46)
```
而这里的代码，正是我增加的一部分，为了贪图简单方便，直接把 JavaSparkContext 对象传递给了 mapPartitions 对应的 Function。


# 解决问题


既然找到了问题，接下来就好办了。既然 JavaSparkContext 不能乱用，那就不用，把这个传递参数去掉，即可正常运行，但是这样做太简单粗暴，不是解决问题的思路。仔细分析一下，可以有2种解决办法（思路就是避免序列化）：

1、如果在 Function 里面非要用到 JavaSparkContext 对象，那就把 JavaSparkContext 对象设置为全局静态的 Java 属性（使用 static 关键字），那么在哪里都可以调用它了，而无需担心序列化的问题（静态属性可以避免从 Driver 端发送到 Executor 端，从而避免了序列化过程）；

2、对于 Function 不要使用内部匿名类，这样必然需要序列化 Function 对象，同时也必然需要序列化 Function 对象用到的 JavaSparkContext 对象，其实可以把 Function 类定义为内部静态类，就可以避免序列化了。


# 问题总结


1、出现这种错误，不要想当然地认为就是某种原因造成的，而要先看详细日志，否则会走弯路，浪费一些时间（虽然最终也能解决问题）；

2、有时候状态不好，晕乎乎的，找问题又慢又低效，此时应该休息一下，等头脑清醒了再继续找问题，否则可能事倍功半，而且影响心情。

参考：[https://stackoverflow.com/questions/27706813/javasparkcontext-not-serializable](https://stackoverflow.com/questions/27706813/javasparkcontext-not-serializable)


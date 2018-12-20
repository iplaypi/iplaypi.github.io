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

一开始疏忽大意了，以为像往常一样，是某些需要传递的对象对应的类没有序列化，由于对代码不敢改动太大，就想着用最简单的方法，把几个类都序列化了。结果，还是不行，虽然不会有自定义类的序列化问题了，但是却出现了终极错误：JavaSparkContext not serializable，这是什么意思呢，是说 JavaSparkContext 不能序列化，总不能把 JavaSparkContext 序列化吧，Spark 是不允许这么干的。

那么问题是什么呢？是因为 JavaSparkContext 不能乱用。

其实，报错日志里面都已经说明了，除了自定义的类，错误归结于
```java
at org.apache.spark.api.java.AbstractJavaRDDLike.mapPartitions(JavaRDDLike.scala:46)
```
而这里的代码，正是我增加的一部分。

参考：[https://stackoverflow.com/questions/27706813/javasparkcontext-not-serializable](https://stackoverflow.com/questions/27706813/javasparkcontext-not-serializable)

---
title: 多个 SparkContext 实例共存
id: 2020-05-15 01:19:02
date: 2018-03-07 01:19:02
updated: 2020-05-15 01:19:02
categories:
tags:
keywords:
---


2018030701
Spark,SparkContext
大数据技术知识

简单记录


<!-- more -->

Spark 提交任务

基于 Spark v1.6.2；

在同一个入口类中，先后提交 2 个 Spark 任务，第 1 个跑完提交第 2 个，报错：

```
org.apache.spark.SparkException: Only one SparkContext may be running in this JVM (see SPARK-2243). To ignore this error, set spark.driver.allowMultipleContexts = true. The currently running SparkContext was created at: xxx(提交第 2 个任务的代码栈追踪)
```

原因：第 1 个 Spark 任务跑完没有关闭 SparkContext

```
// 关闭jsc
if (null != jsc) {
    jsc.stop();    
    jsc.close();
}
```

第二个 SparkContext 在启动时冲突了，即两个 SparkContext 实例共同存在于同一个 JVM 中。


同样的代码以前跑没问题，说明 Spark 的参数有变化

```
spark.driver.allowMultipleContexts=true
```

设置这个参数后，使用第二个jsc前记得把前一个jsc先stop一下【不是close】，这样2个实例就可以共存。


当然，对于Spark v2.x以上的版本，已经天然支持多个jsc存在，不会再有这个异常出现。



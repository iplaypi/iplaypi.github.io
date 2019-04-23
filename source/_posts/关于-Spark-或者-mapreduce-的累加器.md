---
title: 关于 Spark 或者 mapreduce 的累加器
id: 2017043001
date: 2017-04-30 23:34:26
updated: 2019-04-23 23:34:26
categories: 基础技术知识
tags: [Spark,mapreduce,Accumulator]
keywords: Spark,mapreduce,Accumulator
---


在 Spark 和 mapreduce 中都有累加器的概念，使用方式也是大同小异，但是还是有一点点不同的地方。


<!-- more -->


# 累加器基础概念


mr程序的累加器不用单独打印出来最终结果，在运行日志中可以看到统计值，但是在 yarn 中却看不到。而 spark 程序可以在 yarn 中查看累加器。


# 累加器的使用


1、Spark 中的使用


注意版本的影响，使用方式不一致。

在程序中对累加器只能增加，不能取值，在 driver 端等待任务结束时才能取值。

2、mapreduce 中的使用

在 driver 端会自动打印出自定义的累加器取值。

参考：
https://www.cnblogs.com/cc11001100/p/9901606.html 
https://www.jianshu.com/p/9d6111fc6303 


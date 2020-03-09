---
title: 关于 Hadoop Reduce 阶段遍历 Iterable 的坑
id: 2017022401
date: 2017-02-24 23:31:39
updated: 2019-07-11 23:31:39
categories:
tags:
keywords:
---


发表在早期的时间点上。
2017022401
Hadoop,MapReduce,Iterable,Java
大数据技术知识

<!-- more -->


待整理。

HBase 读写的 mr 问题，在 reducer 中使用 iterable 可以，转为 list 再使用就会被去重，保留的数据条数为 reduceNum 的2倍。【实际上对于一个集合来说，只有第一个元素、最后一个元素被处理了，所以会造成这种奇怪的现象】

这是 mapreduce 的 reduce 的坑，**对象复用**，整理一篇博客，包括本地调试 mr 代码




# 备注



hadoop传递参数到mapreduce中，可以通过conf完成，然后在setup里面初始化。

或者直接把数据放在hdfs上面，在setup中直接读取。



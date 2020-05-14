---
title: Spark 读取 HDFS 设置分区数
id: 2020-05-15 01:35:11
date: 2018-04-25 01:35:11
updated: 2020-05-15 01:35:11
categories:
tags:
keywords:
---


2018042501
大数据技术知识
Spark,HDFS,Hadoop

简单整理


<!-- more -->


Spark 读取 HDFS 问题

textFile(path, partitions);

指定的 partitions 如果比 block 数量少，是不生效的，实际 task 个数取 block 个数与partitions 中较大者



参考：https://blog.csdn.net/u011564172/article/details/53611109 


---
title: 'Spark 异常之 IllegalArgumentException: Size exceeds'
id: 2020-05-15 02:06:33
date: 2018-11-26 02:06:33
updated: 2020-05-15 02:06:33
categories:
tags:
keywords:
---


2018112601
大数据基础知识
Spark,RDD


Saprk 报错java.lang.IllegalArgumentException: Size exceeds Integer.MAX_VALUE


读取 ES 数据，报错；

搜索资料，发现是 partition 数据量太小，导致 rdd 处理数据每个分区偏大，超过2g，Spark 无法处理。

处理 ES 数据，如果数据来自聚合，控制数据量每5万一个分区是足够保险的；

另外，还要注意内存问题，如果数据量多达2千万（假设占用空间40G），设置100个 partition 也是没用的，因为内存不够用，如果 Spark 任务按照分配4个 core 来说，每个core 5个并发，则同时可以跑20个task，共计需要内存8G，需要设置executor.memory在2G以上才行，否则会报内存溢出；

Integer.MAX_VALUE=2的31次方-1，最大能表示2147483647B，也就是2*1024*1024*1024-1，最大也就是2GB

参考：


https://blog.csdn.net/dehu_zhou/article/details/77587570

https://stackoverflow.com/questions/42247630/sql-query-in-spark-scala-size-exceeds-integer-max-value


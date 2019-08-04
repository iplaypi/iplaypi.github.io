---
title: Hadoop 入门系列0--初识 Hadoop
id: 2017040101
date: 2017-04-01 15:58:54
updated: 2018-11-21 15:58:54
categories: Hadoop 从零基础到入门系列
tags: [Hadoop,Zookeeper,HDFS,MapReduce]
keywords: Hadoop,Zokkeeper,入门到精通,Hadoop 入门,HDFS,MapReduce
---


待开始整理


<!-- more -->


# 开始


今天是愚人节。

`HDFS` 设置副本数是在 `hdfs-site.xml` 配置文件中，默认为3，在一般场景下都是可以保证数据安全的。如果觉得浪费资源可以设置为2，但是磁盘的价格是不贵的，多一份可以保障数据更加安全。

```
<property>
  <name>dfs.replication</name>
  <value>3</value>
</property>
```

注意，HDFS 中的副本参数的概念不是中文语境下的复制次数，而是总的数量，例如把 **dfs.replication** 设置为3，虽然翻译为副本数为3，其实表示的总共有3份数据【主本1份 + 副本2份】。

注意，如果按照中文语境下的含义来解释，副本数应该是2，加上主本一共有3份数据，这看起来有歧义，也会令人疑惑。它不像在 `Elastisearch` 中设置副本的参数 **number_of_replicas**，表示的就是副本数，如果想保存总共3份数据，需要把 **number_of_replicas** 设置为2 。下图中此参数的值设置为1，即副本为1，表示总共保存2份数据。

es设置图。。


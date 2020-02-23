---
title: es-hadoop 版本不匹配导致 discoverNodes 异常
id: 2020-02-24 01:04:14
date: 2018-05-29 01:04:14
updated: 2020-02-24 01:04:14
categories:
tags:
keywords:
---


2018052901
踩坑系列
Elasticsearch,elasticsearch-hadoop,Spark,Hadoop


<!-- more -->



待重新整理一下。

另外还有一种 `elasticsearch-spark` 依赖，不知道用处，我在项目中也同时依赖了，看起来没什么用处，因为没用到，暂时先不关心。

```
<dependency> 
  <groupId>org.elasticsearch</groupId>  
  <artifactId>elasticsearch-spark_2.10</artifactId>  
  <version>2.1.0</version> 
</dependency>
```

![es-spark 依赖](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2018/20200224011208.png "es-spark 依赖")

看官网说明是为了支持 `spark SQL` 的，链接：[Supported Spark SQL versions](https://www.elastic.co/guide/en/elasticsearch/hadoop/master/spark.html) 。

> Spark SQL while becoming a mature component, is still going through significant changes between releases. Spark SQL became a stable component in version 1.3, however it is not backwards compatible with the previous releases. Further more Spark 2.0 introduced significant changed which broke backwards compatibility, through the Dataset API. elasticsearch-hadoop supports both version Spark SQL 1.3-1.6 and Spark SQL 2.0 through two different jars: elasticsearch-spark-1.x-\<version>.jar and elasticsearch-hadoop-\<version>.jar support Spark SQL 1.3-1.6 (or higher) while elasticsearch-spark-2.0-\<version>.jar supports Spark SQL 2.0. In other words, unless you are using Spark 2.0, use elasticsearch-spark-1.x-\<version>.jar


# 备注


最好还是升级 `elasticsearch-hadoop` 版本与 `Elasticsearch` 保持一致，例如升级到 `v2.4.5`【与 `Elasticsearch` 版本保持一致】。

但是，`v2.4.5` 版本的 `elasticsearch-hadoop` 自有它的坑【是很严重的 `bug`】，那就是它在处理数据时，会过滤掉中文的字段，导致读取中文字段丢失，影响中间的 `ETL` 处理逻辑。而如果数据处理完成后，再写回去原来的 `Elasticsearch` 索引就悲剧了，采用 `index` 方式会覆盖数据，导致中文字段全部丢失；采用 `update` 方式不会导致数据覆盖。

中文字段丢失问题，只针对某些版本，关于此问题的踩坑记录可以参考我的另外一篇博客：[es-hadoop 读取中文字段丢失问题](https://www.playpi.org/2017102301.html) 。


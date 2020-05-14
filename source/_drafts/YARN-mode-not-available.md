---
title: YARN mode not available
id: 2020-05-15 01:51:54
date: 2018-05-17 01:51:54
updated: 2020-05-15 01:51:54
categories:
tags:
keywords:
---


2018051701
Spark,Maven


简单说明



<!-- more -->



mvn 依赖冲突问题

YarnScheduler 类与 spark-core 包里面的冲突，报错 org.apache.spark.SparkException: YARN mode not available ?


```
<dependency>
<groupId>com.yeezhao.commons</groupId>
<artifactId>yz-commons-hadoop</artifactId>
<exclusions>
<exclusion>
<artifactId>hadoop-core</artifactId>
<groupId>org.apache.hadoop</groupId>
</exclusion>
<exclusion>
<artifactId>hbase</artifactId>
<groupId>org.apache.hbase</groupId>
</exclusion>
<exclusion>
<artifactId>protobuf-java</artifactId>
<groupId>com.google.protobuf</groupId>
</exclusion>
</exclusions>
</dependency>
```


排除掉这些依赖即可。


---
title: es-hadoop 读取中文字段丢失问题
id: 2020-02-15 19:30:07
date: 2020-02-15 19:30:07
updated: 2020-02-15 19:30:07
categories:
tags:
keywords:
---



2017102301
踩坑系列
Hadoop,Elasticsearch,Spark


<!-- more -->




版本问题，导致丢失中文字段；

如果是使用 `index` 方式把数据写回原始索引，那么这些字段就彻底丢失了。


使用 jdk 版本问题，需要适配；


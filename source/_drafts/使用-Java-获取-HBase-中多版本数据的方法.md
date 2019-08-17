---
title: 使用 Java 获取 HBase 中多版本数据的方法
id: 2019071101
date: 2019-07-11 23:35:05
updated: 2019-07-11 23:35:05
categories: 大数据技术知识
tags: [Java,HBase,version]
keywords: Java,HBase,version
---
最近工作比较繁忙，在处理需求、写代码的过程中踩到了一些坑，不过问题都被我一个一个解决了，所以最近三周都没有更新博客内容。不过，我是整理了提纲、打了草稿的，近期会陆续整理出来。今天就先整理出来一个简单的知识点：使用 `Java API` 从 `HBase` 中获取多版本【Version 的概念】数据的方法，开发环境基于 `JDK v1.8`、`HBase v1.1.2`、`Zookeeper v3.4.6`，在演示过程中还会使用原生的 `HBase Shell` 进行配合，加深理解。


<!-- more -->


id: 2019071101
categories: 大数据技术知识
tags: [Java,HBase,version]
keywords: Java,HBase,version


# 入门概念


先列举一些关于 `HBase` 的基础概念，有助于继续阅读下文：

- 列式分布式数据库，基于 `BigTable` 论文开发，适合海量的数据存储
- Rowkey、Column Family、Qualifier、Timestamp、Cell、Version 的概念
- HBase Shell、Java API、Phoenix


# 示例代码


下面的演示会以 `HBase Shell`、`Java API` 这两种方式分别进行，便于读者理解。

## 建表造数据




## 命令行查看




## 代码示例



# 备注


1、在使用 `Java API` 时注意低版本、高版本之间的差异，必要时及时升级，就像上文代码中的 `Result.getColumn`、`KeyValue.getValue()`、`Cell.getValue()` 这几个方法。

2、`Phoenix` 是一款基于 `HBase` 的工具，在 `HBase` 之上提供了 `OLTP` 相关的功能，例如完全的 `ACID` 支持、`SQL`、二级索引等，此外 `Phoenix` 还提供了标准的 `JDBC` 的 `API`。在使用 `Phoenix` 时，可以很方便地像操作 `SQL` 那样操作 `HBase`。

3、本示例的代码放在 `GirHub`，详见：[TestHBase.java](https://github.com/iplaypi/iplaypistudy/tree/master/iplaypistudy-hbase/src/main/java/org/playpi/study/test) ，搜索类名 `TestHBase` 即可。参考 `GitHub` 的代码时，注意在 `iplaypistudy-common-config` 模块中增加自己的配置文件，如果开发环境的版本不匹配，也要升级版本，在 `pom.xml` 更改即可。


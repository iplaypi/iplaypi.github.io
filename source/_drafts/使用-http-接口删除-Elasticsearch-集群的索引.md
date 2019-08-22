---
title: 使用 http 接口删除 Elasticsearch 集群的索引
id: 2019-08-22 23:00:47
date: 2019-08-22 23:00:47
updated: 2019-08-22 23:00:47
categories:
tags:
keywords:
---
在工作中遇到需要定期关闭、删除 `Elasticsearch` 集群索引的需求，关闭或者删除是一个很简单的操作，直接向 `Elasticsearch` 集群发送一个请求即可。而且，为了批量删除，可以一次性发送多个索引名称，使用逗号分隔即可，甚至可以使用通配符【需要 `Elasticsearch` 集群设置开启】，直接删掉满足条件的索引。

本文基于最简单的场景：单个索引的关闭、删除，使用 `Java` 编程语言、`HTTP` 接口，尝试关闭、删除 `Elasticsearch` 集群的索引，属于入门级别，开发环境基于 `Elasticsearch v1.7.5`，是一个很旧的版本，`JDK v1.8`。


<!-- more -->
使用 http 接口删除 Elasticsearch 的索引
2019082101
大数据技术知识
Elasticsearch,Java,HTTP,curl

在 v6.x 及以上版本取消了 type 的概念，在那个场景下可以随便删除索引，而不用再考虑单个索引下面存在的多个 type，没有误删除的风险。

演示使用 curl 命令的方式，与 java 代码发送 http 请求的效果一样。


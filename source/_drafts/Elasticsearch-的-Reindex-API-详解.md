---
title: Elasticsearch 的 Reindex API 详解
id: 2020-01-16 20:15:12
date: 2020-01-16 20:15:12
updated: 2020-01-16 20:15:12
categories:
tags:
keywords:
---

2020011601
Elasticsearch,HTTP
大数据技术知识

在业务中只要有使用到 `Elasticsearch` 的场景，那么有时候会遇到需要重构索引的情况，例如 `mapping` 被污染了、某个字段需要变更类型等。如果对 `reindex API` 不熟悉，那么在遇到重构的时候，必然事倍功半，效率低下。但是如果熟悉了，就可以方便地进行索引重构，省时省力。

本文演示内容基于 `Elasticsearch v5.6.8`。


<!-- more -->


目标索引如果不设置 `mapping`，则会使用默认的，对一些特殊的字段不会处理，则会引发字段类型错误的结果。

参考官网：[docs-reindex](https://www.elastic.co/guide/en/elasticsearch/reference/5.6/docs-reindex.html) 。


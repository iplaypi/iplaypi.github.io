---
title: 给 Elasticsearch 使用者的 N 条建议
id: 2020-03-08 19:57:22
date: 2020-03-08 19:57:22
updated: 2020-03-08 19:57:22
categories:
tags:
keywords:
---


给 Elasticsearch 使用者的 N 条建议

2020030801
大数据技术知识
Elasticsearch


本人接触 `Elasticsearch` 已经两年多了，从一开始的陌生，到后来的熟悉，开发者的角色也从使用者逐渐变为维护者，并可以提供一些建议。本文记录汇总一些使用 `Elasticsearch` 过程中踩过的坑，以及注意事项，不仅提醒自己，也能给读者带去思考。

本人使用过的 `Elasticsearch` 版本有 `v1.7.5`、`v.2.3.x`、`v2.4.x`、`v5.6.8` 等等，对于特定版本存在的坑会特殊说明。那为什么本文的标题中带有 `N 条` 字样呢，其实我想表达很多条，并且随着时间的流逝，以后会不断更新修正，毕竟技术之路学无止境。


<!-- more -->


ES的update操作会覆盖no source的数据（例如 content），这是因为字段没有store【可以参考es44个建议里面的】


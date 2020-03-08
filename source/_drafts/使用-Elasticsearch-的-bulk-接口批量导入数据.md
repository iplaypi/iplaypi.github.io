---
title: 使用 Elasticsearch 的 bulk 接口批量导入数据
id: 2020-03-09 00:55:02
date: 2019-10-17 00:55:02
updated: 2019-10-17 00:55:02
categories:
tags:
keywords:
---


大数据技术知识
2019101701
Elasticsearch,bulk,HTTP,HBase



<!-- more -->


`bulk` 批量接口

注意，使用 `http` 请求写入数据时，
使用 post 请求，`_id` 是自动生成的，与数据中的 id 字段无关；
以 `my-index-post` 为例；




bulk 别名异常问题

bulk 接口会自动生成 `_id`，表示文档的唯一标识，不等于文档里面的 id 字段；
有没有参数可以指定呢？待查明；


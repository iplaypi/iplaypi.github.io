---
title: Elasticsearch 常用 HTTP 接口
id: 2020-01-15 02:16:56
date: 2020-01-15 02:16:56
updated: 2020-01-15 02:16:56
categories:
tags:
keywords:
---

2018051401
Elasticsearch,HTTP,RESTful

本文记录工作中常用的关于 `Elasticsearch` 的 `HTTP` 接口，以作备用，读者也可以参考。开发环境基于 `Elasticsearch v5.6.8`。


<!-- more -->


待整理，最好先分大类，以后还需要添加

集群状态、分片分布

集群配置信息

热点进程

查看不同分词器的分词结果

创建索引、添加 `type` 索引

添加别名、删除别名

导入数据

查询数据



## 删除数据

根据查询条件删除数据：

```
POST my-index-user/user/_delete_by_query/
{
  "query": {
    "terms": {
      "id": [
        "1",
        "2"
      ]
    }
  }
}
```

打开索引、关闭索引

迁移数据、查看迁移任务、取消迁移任务

关闭 `rebalance`，移动分片


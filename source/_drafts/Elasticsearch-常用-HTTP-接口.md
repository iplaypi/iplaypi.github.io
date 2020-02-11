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



# 删除数据

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

当然，如果是低版本的 `Elasticsearch`，在 `1.x` 的版本中还可以使用发送 `DELETE` 请求的方式删除数据，容易引发一些操作失误，不建议使用。

更多内容参考：[Elasticsearch 根据查询条件删除数据的 API](https://www.playpi.org/2018022401.html) 。


# 索引关闭开启


主要有两个接口：

- 开启索引，`curl -XPOST http://localhost:9200/your_index/_open`
- 关闭索引，`curl -XPOST http://localhost:9200/your_index/_close`

参考这篇博客的部分内容：[使用 http 接口删除 Elasticsearch 集群的索引](https://www.playpi.org/2019082101.html) 。


# 迁移数据


参考：[Elasticsearch 的 Reindex API 详解](https://www.playpi.org/2020011601.html) ，里面包含了常见的参数使用方式，以及查看迁移任务进度、取消迁移任务的方式。


关闭 `rebalance`，移动分片


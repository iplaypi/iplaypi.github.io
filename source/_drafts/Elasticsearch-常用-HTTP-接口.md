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

索引数据复制迁移。。。

待整理，最好先分大类，以后还需要添加



集群状态、分片分布



集群配置信息



热点进程


查看不同分词器的分词结果


下面举出例子，其它内容参考另外一篇博客：xxx。


# 创建索引


创建带 `mapping` 的索引：

```
PUT /my-index-post/
{
  "settings": {
    "index.number_of_shards": 3,
    "index.number_of_replicas": 1,
    "index.refresh_interval": "30s",
    "index.routing.allocation.total_shards_per_node": 3
  },
  "mappings": {
    "post": {
      "_all": {
        "enabled": false
      },
      "dynamic_templates": [
        {
          "title1": {
            "match": "title",
            "match_mapping_type": "*",
            "mapping": {
              "type": "text",
              "analyzer": "wordsEN"
            }
          }
        }
      ]
    }
  }
}
```

创建带 `mapping` 的 `type`【在索引已经存在的情况下】：

```
PUT /my-index-post/_mapping/post/
{
    "_all": {
        "enabled": false
    },
    "dynamic_templates": [
        {
            "title1": {
                "mapping": {
                    "analyzer": "wordsEN",
                    "type": "text"
                },
                "match": "title"
            }
        },
        {
            "title2": {
                "mapping": {
                    "analyzer": "wordsEN",
                    "type": "text"
                },
                "match": "*_title"
            }
        }
    ],
    "properties": {
        "avatar_url": {
            "type": "keyword"
        }
    }
}
```


# 添加别名、删除别名


给索引增加别名：

```
POST /_aliases
{
  "actions": [
    {
      "add": {
        "index": "my-index-post",
        "alias": "my-index-post-all"
      }
    }
  ]
}
```

移除索引的别名：

```
POST /_aliases
{
  "actions": [
    {
      "remove": {
        "index": "my-index-post",
        "alias": "my-index-post-all"
      }
    }
  ]
}
```


# 导入数据


`bulk` 接口，详情参考另外一篇博客：xx。


# 查询数据


多种查询方式。


# 删除数据


根据查询条件删除数据：

```
POST my-index-post/post/_delete_by_query/
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


迁移一个索引的数据到另外一个索引，切记需要提前创建好索引，包含 `mapping`，避免字段类型出问题：

```
POST _reindex
{
  "source": {
    "index": "my-index-post",
    "type": "post"
  },
  "dest": {
    "index": "my-index-post-bak",
    "type": "post"
  }
}

查看任务状态，取消任务

GET _tasks?detailed=true&actions=*reindex

POST _tasks/task_id:1/_cancel
```

此外，参考：[Elasticsearch 的 Reindex API 详解](https://www.playpi.org/2020011601.html) ，里面包含了常见的参数使用方式，以及查看迁移任务进度、取消迁移任务的方式。


# 移动分片


需要先关闭 `rebalance`，再手动移动分片。


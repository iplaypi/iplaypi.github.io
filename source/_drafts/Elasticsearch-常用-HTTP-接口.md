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

本文记录工作中常用的关于 `Elasticsearch` 的 `HTTP` 接口，以作备用，读者也可以参考，会持续补充更新。开发环境基于 `Elasticsearch v5.6.8`。


<!-- more -->

wiki同步完，待补充。


# 集群状态cc


## 空间使用

查询每个节点的空间使用情况，预估数据大小：

```
http://localhost:9200//_cat/allocation?v
```

## 分片分布



## 集群配置信息



## 热点线程

查看热点线程，可以判断热点线程是 `search`，`bulk`，还是 `merge` 类型，从而进一步分析是查询还是写入导致 `CPU` 负载过高。

```
http://localhost:9200/_nodes/node0/hot_threads

http://localhost:9200/_nodes/hot_threads
```

## 请求队列

查看请求队列情况，可以看到每种类型请求的积压情况：

```
http://localhost:9200/_cat/thread_pool?v
```


# 分词器


可以查看不同分词器的分词结果，或者基于某个索引的某个字段查看分词结果。下面列举一些例子，其它更多的内容请读者参考另外一篇博客：[Elasticsearch 分词器使用入门指南](https://www.playpi.org/2017082001.html) 。

查看集群安装的各种分词器效果，指定文本内容、分词器即可：

```
POST _analyze
{
  "text":"行完成，是否成功请查看ccc",
  "analyzer":"wordsEN"
}
 
POST _analyze
{
  "text":"行完成，是否成功请查看ccc",
  "analyzer":"standard"
}
 
POST _analyze
{
  "text":"行完成，是否成功请查看ccc",
  "analyzer":"english"
}
```

查看某个索引的某个字段的分词器效果【索引已经指定分词器，可以通过 `mapping` 查看】，指定索引名称、文本内容、字段名称，不要指定索引的 `type`，否则请求变为了新建文档：

```
POST my-index-post/_analyze
{
  "text":"行完成，是否成功请查看ccc",
  "field":"content"
}
```

查询时也可以指定分词器【不同分词器会影响返回的结果，例如 `standard` 分词器会过滤掉标点符号，所以查不到数据】，特别指定分词器即可。另外只能使用 `match`，不能使用 `match_phrase`。

```
POST my-index-post/post/_search
{
  "query": {
    "match": {
      "content":{
        "query": "，",
        "analyzer": "standard"
      }
    }
  }
}
```


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


# 添加删除别名


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


# 导入数据cc


`bulk` 接口，详情参考另外一篇博客：xx。


# 查询数据


## 脚本查询

`Elasticsearch` 提供了脚本的支持，可以通过 `Groovy` 外置脚本【已经过时，`v6.x` 以及之后的版本，不建议使用】、内置 `painless` 脚本实现各种复杂的操作【类似于写逻辑代码，对数据进行 `ETL` 操作，需要集群配置开启】。

以下是关于 `v2.x` 的说明：

>默认的脚本语言是 Groovy，一种快速表达的脚本语言，在语法上与 JavaScript 类似。它在 Elasticsearch v1.3.0 版本首次引入并运行在沙盒中，然而 Groovy 脚本引擎存在漏洞，允许攻击者通过构建 Groovy 脚本，在 Elasticsearch Java VM 运行时脱离沙盒并执行 shell 命令。
>因此，在版本 v1.3.8、1.4.3 和 v1.5.0 及更高的版本中，它已经被默认禁用。此外，您可以通过设置集群中的所有节点的 config/elasticsearch.yml 文件来禁用动态 Groovy 脚本：script.groovy.sandbox.enabled: false，这将关闭 Groovy 沙盒，从而防止动态 Groovy 脚本作为请求的一部分被接受。

```
Groovy脚本
{
  "query": {
    "bool": {
      "filter": {
        "script": {
          "script": "doc['keywords'].values.length == 2"
        }
      }
    }
  }
}

painless脚本
{
  "query": {
    "bool": {
      "filter": {
        "script": {
          "script": {
            "source": "doc['keywords'].values.length == 2",
            "lang": "painless"
          }
        }
      }
    }
  }
}
```

## 日期桶聚合

对日期格式的字段做桶聚合，可以使用 `interval` 设置桶间隔，使用 `extended_bounds` 设置桶边界，其它还可以设置时区、`doc` 过滤等。

```
"aggs": {
    "by_month": {
      "date_histogram": {
        "field": "publish_timestamp",
        "interval": "day",
        "time_zone": "+08:00",
        "format": "yyyy-MM-dd",
        "min_doc_count": 100000,
        "extended_bounds": {
          "min": "2019-08-30",
          "max": "2019-09-24"
        }
      }
    }
  }
```

对于聚合结果不准的问题，可以增加参数，适当提高准确性。`size` 参数规定了最后返回的 `term` 个数【默认是10个】，`shard_size` 参数规定了每个分片上返回的个数【默认是 `size * 1.5 + 10`】，如果 `shard_size` 小于 `size`，那么分片也会按照 `size` 指定的个数计算。

聚合的字段可能存在一些频率很低的词条，如果这些词条数目比例很大，那么就会造成很多不必要的计算。因此可以通过设置 `min_doc_count` 和 `shard_min_doc_count` 来规定最小的文档数目，只有满足这个参数要求的个数的词条才会被记录返回。`min_doc_count`：规定了最终结果的筛选，`shard_min_doc_count`：规定了分片中计算返回时的筛选。

```
  "aggs": {
    "aggs_sentiment":{
      "terms": {
        "field": "sentiment",
        "size": 10,
        "shard_size": 30,
        "min_doc_count": 10000,
        "shard_min_doc_count": 50
      }
    }
  }
```

## 更新文档

指定部分字段进行更新，不影响其它字段【但是要注意，如果字段只是索引 `index` 而没有存储 `_source`，更新后会无法查询这个字段】。

```
POST /my-index-user/user/0f42d65be1f5287e1c9c26e3728814aa/_update
{
   "doc" : {
      "friends" : [ "98681482902","63639783663","59956667929" ]
   }
}
```

## 自动缓存相关

`terms lookup` 查询：

```
自动缓存
POST my-index-post/_search
{
  "query": {
    "terms": {
      "user_item_id":{
          "index": "my-index-user",
          "type": "user",
          "id": "0f42d65be1f5287e1c9c26e3728814aa",
          "path": "friends"
        }
      }
  }
}
```

操作缓存的接口：

```
关闭缓存
curl -XPOST 'localhost:9200/_cache/clear?filter_path=your_cache_key'
```


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


# 移动分片cc


需要先关闭 `rebalance`，再手动移动分片。


---
title: Elasticsearch 常用 HTTP 接口
id: 2018051401
date: 2018-05-14 02:16:56
updated: 2020-01-15 02:16:56
categories: 大数据技术知识
tags: [Elasticsearch,HTTP,RESTful]
keywords: Elasticsearch,HTTP,RESTful
---


本文记录工作中常用的关于 `Elasticsearch` 的 `HTTP` 接口，以作备用，读者也可以参考，会持续补充更新。开发环境基于 `Elasticsearch v5.6.8`、`v1.7.5`、`v2.x`。


<!-- more -->


# 集群状态

## 集群信息

```
http://localhost:9200/_cluster/stats?pretty
http://localhost:9200/_cat/nodes
http://localhost:9200/_cat/indices
http://localhost:9200/_cluster/state
http://localhost:9200/_cat/aliases
```

可以看到整个集群的索引数、分片数、文档数、内存使用等等信息。

## 健康状况

```
http://localhost:9200/_cat/health?v
```

可以看到分片数量，状态【红、黄、绿】。

## 空间使用

查询每个节点的空间使用情况，预估数据大小：

```
http://localhost:9200/_cat/allocation?v
```

## 分片分布

```
http://localhost:9200/_cat/shards
```

## 索引状态

可以看到索引的数据条数、磁盘大小、分片个数【可以使用别名】。

各项指标解释说明参考：[indices-stats](https://www.elastic.co/guide/en/elasticsearch/reference/5.6/indices-stats.html) 。

```
http://localhost:9200/your_index/_stats
```

## 集群配置信息

```
http://localhost:9200/_cluster/settings?pretty
```

对于一些可以设置的参数，临时生效，对于集群的管理很有帮助。

例如节点黑名单：`cluster.routing.allocation.exclude._ip`，临时下线节点，类似于黑名单，分片不会往指定的主机移动，同时会把分片从指定的节点全部移除，最终可以下线该节点，可通过 `put transient` 设置临时生效。

```
curl -XPUT 127.0.0.1:9200/_cluster/settings -d '{
    "transient" :{
        "cluster.routing.allocation.exclude._ip" : "192.168.0.1"
    }
}'
```

例如临时关闭分片重分配【开启时设置值为 `all`】。

```
curl -XPUT 127.0.0.1:9200/_cluster/settings -d '{
    "transient": {
        "cluster.routing.allocation.enable": "none"
    }
}'

PUT /_cluster/settings/
{
    "transient": {
        "cluster.routing.allocation.enable": "none"
    }
}
```

设置整个集群每个节点可以分配的分片数，主要是为了数据分布均匀。

```
GET _cluster/settings

PUT /_cluster/settings/
{
    "transient": {
        "cluster.routing.allocation.total_shards_per_node": "50"
    }
}
```

设置慢索引阈值，指定索引进行操作，可以使用通配符：

```
curl -XPUT 127.0.0.1:9200/your_index_*/_settings -d '{
  "index.indexing.slowlog.threshold.index.info": "10s"
}''
```

设置慢查询阈值方式类似：

```
curl -XPUT 127.0.0.1:9200/your_index_*/_settings -d '{
  "index.indexing.slowlog.threshold.search.info": "10s"
}'
```

推迟索引分片的重新分配时间平【适用于 `Elasticsearch` 节点短时间离线再加入集群，提前设置好这个参数，避免从分片的复制移动，降低网络 `IO`】。

```
PUT /your_index/_settings
{
  "settings": {
    "index.unassigned.node_left.delayed_timeout": "5m"
  }
}
```

可以使用索引别名、通配符设置，这样就可以一次性设置多个索引，甚至全部的索引。

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

# 添加参数可以查看各个指标
http://localhost:9200/_cat/thread_pool/search?v&h=node_name,ip,name,active,queue,rejected,completed,type,queue_size
```

## 节点配置信息

可以查看节点的 `JVM` 配置、插件信息、队列配置等等。

```
http://localhost:9200/_nodes/node_id
http://localhost:9200/_nodes?pretty=true
http://localhost:9200/_nodes/stats/thread_pool?pretty=true
```

注意，`thread_pool` 线程池相关参数自从 `v5.x` 以后不支持动态设置【即通过 `put` 接口】，只能通过更改节点的配置文件并重启节点来操作，这也说明了这个参数是对于节点生效，不同配置的节点可以设置不同的值。

## 使用堆内存大小

使用

```
http://localhost:9200/_cat/fielddata
```

查看当前集群中每个数据节点上被 `fielddata` 所使用的堆内存大小。

此外还可以指定字段

```
http://localhost:9200/_cat/fielddata?v&fields=uid&pretty
http://localhost:9200/_cat/fielddata/uid?v&pretty
```

按照节点、索引来查询：

```
按照索引、分片
http://localhost:9200/_stats/fielddata?fields=*

按照节点
http://localhost:9200/_nodes/stats/indices/fielddata?fields=*

按照节点、索引分片
http://localhost:9200/_nodes/stats/indices/fielddata?level=indices&fields=*
http://localhost:9200/_nodes/stats/indices/fielddata?level=indices&fields=_uid
```

## 清理缓存

```
curl localhost:9200/index/_cache/clear?pretty&filter=false&field_data=true&fields=_uid,site_name

关于 `&bloom=false` 参数的问题，要看当前 `Elasticsearch` 版本是否支持，`v5.6.x` 是不支持了。
```

## 推迟索引分片的重新分配时间

适用于节点短时间离线再加入集群，提前设置好，避免从分片的复制移动。

```
PUT your_index/_settings
{
  "settings": {
    "index.unassigned.node_left.delayed_timeout": "5m"
  }
}
```

## 排除掉节点

不让索引的分片分配在上面，想取消设置为 `null` 即可。

```
# 索引级别的
PUT your_index/_settings
{
  "index.routing.allocation.exclude._ip": "ip1,ip2"
}

# 集群级别的，等价于下线节点，滚动重启时需要
PUT /_cluster/settings/
{
    "transient": {
        "cluster.routing.allocation.exclude._ip": "ip1,ip2"
    }
}
```

## 基于负载的智能路由查询

`v6.2` 以及以上版本，`search` 智能路由设置，`v7.0` 以及以上版本默认开启。

```
PUT /_cluster/settings
{
    "transient": {
        "cluster.routing.use_adaptive_replica_selection": true
    }
}
```

## 查询全局超时时间

`search` 全局超时时间，避免某些耗时的查询把集群拖垮。

```
search.default_search_timeout

示例：5m
```

## 查询时指定分片主机等

```
preference=_shards:8,12
preference=_only_nodes:1
preference=_primary
preference=_replica
 
POST your_index/_search?preference=_shards:12
{
  "query": {
    "match_phrase": {
      "content": "查证"
    }
  }
}
```

## 分片迁移的并发数带宽流量大小等等

```
# 并发数
PUT _cluster/settings
{
  "transient": {
    "cluster.routing.allocation.node_concurrent_outgoing_recoveries": "3",
    "cluster.routing.allocation.node_concurrent_incoming_recoveries": "3",
    "cluster.routing.allocation.node_concurrent_recoveries": 3
  }
}

# 带宽
PUT _cluster/settings
{
    "transient": {
        "indices.recovery.max_bytes_per_sec": "20mb" 
    }
}
```


# 分析器


可以查看不同分析器的分词结果，或者基于某个索引的某个字段查看分词结果。下面列举一些例子，其它更多的内容请读者参考另外一篇博客：[Elasticsearch 分析器使用入门指南](https://www.playpi.org/2017082001.html) 。

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

更新索引的 `mapping`【在索引、类型都已经存在的情况下】：

```
PUT /my-index-post/_mapping/post
{
  "post": {
    "properties": {
      "title": {
        "type": "text",
        "analyzer": "english",
        "search_analyzer": "standard" 
      }
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


# 导入数据


```
把文件中的数据导入索引，批量的形式
由于数据中可能存在一些特殊符号，所以使用文件的形式，in为文件路径
文件内容格式，1条数据需要包含2行内容，index表示索引数据
{"index":{}}
JSON原始数据

curl -XPOST 'http://localhost:9200/my-index-post/post/_bulk' --data-binary @"$in"
```

`bulk` 接口，详情参考另外一篇博客：[使用 Elasticsearch 的 bulk 接口批量导入数据](https://www.playpi.org/2019101701.html) 。


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

## 多层嵌套反转桶聚合

多层聚合查询，关于嵌套、反转，参考：[nested-aggregation](https://www.elastic.co/guide/cn/elasticsearch/guide/current/nested-aggregation.html) 。

```
POST combine-paas-1003-index/2723-data/_search
{
    "aggs": {
        "x": {
            "aggs": {
                "xx": {
                    "aggs": {
                        "xxx": {
                            "aggs": {
                                "xxxx_interaction_cnt": {
                                    "sum": {
                                        "field": "2723_interaction_cnt"
                                    }
                                }
                            },
                            "reverse_nested": {}
                        }
                    },
                    "terms": {
                        "field": "Titan_sports.yundongerji",
                        "size": 100
                    }
                }
            },
            "nested": {
                "path": "Titan_sports"
            }
        }
    },
    "query": {
        "bool": {
            "must": [
                {
                    "term": {
                        "2723_is_noise": {
                            "value": "否"
                        }
                    }
                }
            ]
        }
    },
    "size": 1
}
```

## 统计个数聚合

对于多篇文章，统计每个站点下面的作者个数：

```
-- 多层嵌套以及特殊的聚合，每个 site_name 下面的作者个数统计
{
    "aggs": {
        "s": {
            "aggs": {
                "a": {
                    "cardinality": {
                        "field": "author"
                    }
                }
            },
            "terms": {
                "field": "site_name",
                "size": 0
            }
        }
    },
    "query": {},
    "size": 0
}
```

## 存在查询

`exists`、`missing` 这两类查询在不同的版本之间使用方式不一致。

```
-- 存在、不存在判断条件，1.7.5 版本和 2.3.4 版本的方式不一样
-- 2.3.4：使用 exists、missing 关键字即可
{
    "query": {
        "exists": {
            "field": "gender"
        }
    }
}

{
    "query": {
        "missing": {
            "field": "gender"
        }
    }
}
 
 
-- 更高版本【v5.x以及以上】的 ES 关键字 missing 已经被废弃，改为 must_not 和 exists 组合查询,以下有示例
{
    "query": {
        "bool": {
            "must_not": {
                "exists": {
                    "field": "user"
                }
            }
        }
    }
}
 
-- 1.7.5：使用 filter 后再使用对应关键词，本质是一种过滤器
{
  "query": {
    "filtered": {
      "filter": {
        "exists": {
          "field": "data_type"
        }
      }
    }
  }
}

-- 此外，不同版本连接 ES 的 client 方式也不一样【tcp 连接，如果是 http 连接就不会有问题】，代码不能兼容，所以只能使用其中1种方式【在本博客中可以搜索到相关总结】
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

size参数在最外层表示随机抽取n条测试；
size参数在source里面表示batch大小，默认1000；
 
参数 wait_for_completion=false 可以让任务在后台一直运行到完成，否则当数据量大的时候，执行时间过长，会超时退出。

查看任务状态，取消任务

GET _tasks?detailed=true&actions=*reindex

POST _tasks/task_id:1/_cancel

POST _tasks/_cancel?nodes=nodexx&actions=*search*
```

此外，参考：[Elasticsearch 的 Reindex API 详解](https://www.playpi.org/2020011601.html) ，里面包含了常见的参数使用方式，以及查看迁移任务进度、取消迁移任务的方式。


# 移动分片


需要先关闭 `rebalance`，再手动移动分片，否则由于手动迁移分片造成集群进行分片的重新分配，进而消耗 `IO`、`CPU` 资源。手动迁移分片完成之后，再打开 `rebalance`，让集群自行进行重新分配管理。

临时参数设置：

```
关闭
curl -XPUT 'localhost:9200/_cluster/settings' -d
'{
  "transient": {
    "cluster.routing.allocation.enable": "none"
  }
}'

打开
curl -XPUT 'localhost:9200/_cluster/settings' -d
'{
  "transient": {
    "cluster.routing.allocation.enable": "all"
  }
}'
```

分片的迁移使用：

```
move：移动分片
cancel：取消分片
allocate：重新分配分片

curl -XPOST 'localhost:9200/_cluster/reroute' -d '{
    "commands" : [ {
        "move" :
            {
              "index" : "test", "shard" : 0,
              "from_node" : "node1", "to_node" : "node2"
            }
        },
       "cancel" :
            {
              "index" : "test", "shard" : 0, "node" : "node1"
            }
        },
        {
          "allocate" : {
              "index" : "test", "shard" : 1, "node" : "node3"
          }
        }
    ]
}'

将分配失败的分片重新分配
curl -XGET 'localhost:9200/_cluster/reroute?retry_failed=true'

用命令手动分配分片，接受丢数据（ES集群升级前关闭了your_index索引，升级后，把副本数设置为0，打开有20个分片无法分配，集群保持红色。关闭也无效，只好接受丢数据恢复空分片）。
{
  "commands": [
    {
      "allocate_empty_primary": {
        "index": "your_index",
        "shard": 17,
        "node": "nodexx",
        "accept_data_loss": true
      }
    }
  ]
}
```

注意，`allocate` 命令还有一个参数，`"allow_primary" : true`，即允许该分片做主分片，但是这样可能会造成数据丢失【在不断写入数据的时候】，因此要慎用【如果数据在分配过程中是静态的则可以考虑使用】。

当然，手动操作需要在熟悉集群的 `API` 使用的情况下，例如需要获取节点、索引、分片的信息，不然的话不知道参数怎么填写、分片怎么迁移。此时可以使用 `Head`、`kopf`、`Cerebro` 等可视化工具进行查看，比较适合运维人员，而且，分片的迁移指挥工作也可以交给这些工具，只要通过鼠标点击就可以完成分片的迁移，很方便。


# 验证


检验查询语句的合法性，不仅仅是满足 `JSON` 格式那么简单：

```
POST /my-index-post/_validate/query?explain
{
  "query": {
    "match": {
      "content":{
        "query": "，",
        "analyzer": "wordsEN"
      }
    }
  }
}
```

检查分片分配的相关信息：

```
不带任何参数执行该命令，会输出当前所有未分配分片的失败原因
curl -XGET 'localhost:9200/_cluster/allocation/explain

该命令可查看指定分片当前所在节点以及分配到该节点的理由，和未分配到其他节点的原因
curl -XPOST 'localhost:9200/_cluster/reroute' -d '{
    "index": <索引名>,
    "shard": <分片号>,
    "primary": true/false
}'
```


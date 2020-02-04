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

本文演示内容基于 `Elasticsearch v5.6.8`，在以后会不断补充完善。


<!-- more -->


# 常用方式


提前声明，在开始演示具体的 `API` 的时候，有一点读者必须知道，`reindex` 不会尝试自动设置目标索引，它也不会复制源索引的设置。读者应该在运行 `reindex` 操作之前设置好目标索引的参数，包括映射、分片数、副本数等等。目标索引如果不设置 `mapping`，则会使用默认的配置，例如对一些特殊的字段不会处理，则会引发字段类型错误的结果。

当然，关于设置索引，最常见的做法不是手动设置索引信息，而是使用索引模版【使用动态模版：`dynamic_templates`】，只要索引模版的匹配形式可以匹配上源索引和目标索引，我们不需要去考虑索引配置的问题，模版会为我们解决对应的问题。当然，关于的索引的分片数、副本数，还是需要考虑的。

最后，关于版本的说明，以下内容只针对 `v5.x` 以及之后的版本，更多的版本使用方式读者可以参考文末的备注信息。

## 迁移数据简单示例

涉及到 `_reindex` 关键字，示例如下：

```
POST _reindex
{
  "source": {
    "index": "my-index-user"
  },
  "dest": {
    "index": "my-index-user-v2"
  }
}
```

```
{
  "took": 9991,
  "timed_out": false,
  "total": 12505,
  "updated": 12505,
  "created": 0,
  "deleted": 0,
  "batches": 13,
  "version_conflicts": 0,
  "noops": 0,
  "retries": {
    "bulk": 0,
    "search": 0
  },
  "throttled_millis": 0,
  "requests_per_second": -1,
  "throttled_until_millis": 0,
  "failures": []
}
```

![演示结果](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2020/20200203234351.png "演示结果")

演示结果迁移了12505条数据，耗时9991毫秒。

以上只是一个非常基础的示例，还有一些可以优化的参数没有指定，全部使用的是默认值，例如看到 `batches`、`total` 对应的数值，就可以算出一批的数据大小默认为1000，12505条数据需要13批次才能迁移完成。再看到 `updated` 的数值，就可以猜测是更新了目标索引的数据，而不是创建数据，说明目标索引本来就有数据，被重新覆盖了。而这些内容在后续的演示中都会逐一解释，并再次演示。

注意一点，如果 `Elasticsearch` 是 `v6.x` 以及以下的版本，会涉及到索引的 `type`，如果源索引只有一个 `type`，则可以省略 `type` 这个参数，即不需要指定【数据会迁移到目标索引的同名 `type` 里面】。但是，如果涉及到多个 `type` 的数据迁移，肯定是要指定的【例如把多个 `type` 的数据迁移到同一个 `type` 中，或者把某个 `type` 的数据迁移到另外一个 `type` 中】。因此，为了准确无误，最好还是指定 `type`【当然再高的版本就没有 `type` 的概念了，无需指定】。

如果根据上面的示例，再添加 `type` 参数：

```
POST _reindex
{
  "source": {
    "index": "my-index-user",
    "type": "user"
  },
  "dest": {
    "index": "my-index-user-v2",
    "type": "user"
  }
}
```

## version_type 参数

就像 `_update_by_query` 里面的逻辑一样，`_reindex` 会生成源索引的快照【`snapshot`】，但是它的目标索引必须是一个不同的索引【另外创建一个】，以便避免版本冲突问题。同时，针对 `dest index` 可以像 `index API`【索引数据】 一样进行配置，以乐观锁控制并发写入【并发写入相同的数据，通过 `version` 来控制，有冲突时会写入失败，可以重试】。

像上面那样最简单的方式，不设置 `version_type` 参数【默认为 `internal`】或显式设置它为 `internal`，效果都一样。此时，`Elasticsearch` 将会直接将文档转储到 `dest index` 中，直接覆盖任何具有相同类型和 `id` 的 `document`，不会产生冲突问题。

```
POST _reindex
{
  "source": {
    "index": "my-index-user"
  },
  "dest": {
    "index": "my-index-user-v2",
    "version_type": "internal"
  }
}
```

如果把 `version_type` 设置为 `external`，则 `Elasticsearch` 会从 `source` 读取 `version` 字段，当遇到具有相同类型和 `id` 的 `document` 时，只会保留 `newer verion`，即最新的 `version` 对应的数据。

```
POST _reindex
{
  "source": {
    "index": "my-index-user"
  },
  "dest": {
    "index": "my-index-user-v2",
    "version_type": "external"
  }
}
```

上面的说法看起来似乎有点不好理解，再简单直观点来说，就是在 `redinex` 的时候，我们的 `dest index` 可以不是一个新创建的不包含数据的 `index`，而是已经包含有数据的。如果我们的 `source index` 和 `dest index` 里面有相同类型和 `id` 的 `document`【一模一样的数据】，对于使用 `internal` 来说，就是直接覆盖，而使用 `external` 的话，只有当 `source index` 的数据的 `version` 比 `dest index` 数据的 `version` 更加新的时候，才会去更新【即保留最新的 `version` 对应的数据】。

再说明一下，`internal` 可以理解为使用内部版本号，即 `Elasticsearch` 不会单独比较版本号，对于 `dest index` 来说，无论是索引数据还是更新数据，写入时都按部就班把版本号累加，所以也就不会有冲突问题【从 `source index` 出来的数据是不携带版本信息的】。

另一方面，`external` 表示外部版本号，即 `Elasticsearch` 会单独比较版本号再决定写入的流程，对于 `dest index` 来说，无论是索引数据还是更新数据，写入时会先比较版本号，只保留版本号最大的数据【如果是来自不同索引的数据，版本号会不一致；如果是来自不同集群的数据，版本号规则可能也不一致】。

## op_type 参数

`op_type` 参数控制着写入数据的冲突处理方式，如果把 `op_type` 设置为 `create`，在 `_reindex API` 中，表示写入时只在 `dest index` 中添加不存在的 `doucment`，如果相同的 `document` 已经存在，则会报 `version confilct` 的错误，那么索引操作就会失败。【这种方式与使用 `_create API` 时效果一致】

```
POST _reindex
{
  "source": {
    "index": "my-index-user"
  },
  "dest": {
    "index": "my-index-user-v2",
    "op_type": "create"
  }
}
```

如果这样设置了，也就不存在更新数据的场景了【冲突数据无法写入】，则 `version_type` 参数的设置也就无所谓了。

## conflicts 配置

默认情况下，当发生 `version conflict` 的时候，`_reindex` 会被 `abort`，任务终止【此时数据还没有 `reindex` 完成】，在返回体中的 `failures` 指标中会包含冲突的数据【有时候数据会非常多】，除非把 `conflicts` 设置为 `proceed`。

关于 `abort` 的说明，如果产生了 `abort`，已经执行的数据【例如更新写入的】仍然存在于目标索引，此时任务终止，还会有数据没有被执行，也就是漏数了。换句话说，该执行过程不会回滚，只会终止。如果设置了 `proceed`，任务在检测到数据冲突的情况下，不会终止，会跳过冲突数据继续执行，直到所有数据执行完成，此时不会漏掉正常的数据，只漏掉有冲突的数据。

```
POST _reindex
{
  "source": {
    "index": "my-index-user"
  },
  "dest": {
    "index": "my-index-user-v2",
    "op_type": "create"
  },
  "conflicts": "proceed"
}
```

故意把 `op_type` 设置为 `create`，人为制造数据冲突的场景，测试时更容易观察到冲突现象。

## query 配置

迁移数据的时候，肯定有只是复制源索引中部分数据的场景，此时就需要配置查询条件【使用 `query` 参数】，只复制命中条件的部分数据，而不是全部，这和查询 `Elasticsearch` 数据的逻辑一致。

如下示例，通过 `query` 参数，把需要 `_reindex` 的 `document` 限定在一定的范围，我这里是限定更新时间 `update_timestamp` 在1546272000000【20190101000000】之后。

```
POST _reindex
{
  "source": {
    "index": "my-index-user",
    "query": {
      "bool": {
        "must": [
          {
            "range": {
              "update_timestamp": {
                "gte": 1546272000000
              }
            }
          }
        ]
      }
    }
  },
  "dest": {
    "index": "my-index-user-v2"
  }
}
```

## 批次大小配置

如果在 `query` 参数的同一层次【即 `source` 参数中】再添加 `size` 参数，并不是表示随机获取部分数据，而是表示 `scroll size` 的大小【会影响批次的次数，进而影响整体的速度】，这个有点迷惑人。另外，直接在`query` 中添加 `size` 参数是不被允许的。

如果不显式设置，默认是一批1000条数据，在一开始的简单示例中也看到了。

如下，设置 `scroll size` 为100：

```
POST _reindex
{
  "source": {
    "index": "my-index-user",
    "query": {
      "bool": {
        "must": [
          {
            "range": {
              "update_timestamp": {
                "gte": 1546272000000
              }
            }
          }
        ]
      }
    },
    "size": 100
  },
  "dest": {
    "index": "my-index-user-v2"
  }
}
```

![返回结果](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2020/20200205001736.png "返回结果")

根据返回结果可以看到，实际迁移12505条数据，`batches` 为126【可以算出每次 `batch` 为1000条数据】，耗时为31868毫秒，是前面简单示例耗时的3倍【前面简单示例的耗时是10秒左右】。

注意，千万不要用错 `size` 参数的位置，可以继续参考下面的**随机 size 配置**小节。

## 多对一迁移

如果需要把多个索引的数据或者多个 `type` 的数据共同迁移到同一个目标索引中，则需要在 `source` 参数中指定多个索引。

把同一个索引中的不同 `type` 的数据共同迁移到同一个索引中，例如把 `my-index-user` 下的 `user`、`user2` 数据共同迁移到 `my-index-user-v2` 中：

```
POST _reindex
{
  "source": {
    "index": [
      "my-index-user",
      "my-index-user"
    ],
    "type": [
      "user",
      "user2"
    ]
  },
  "dest": {
    "index": "my-index-user-v2"
  }
}
```

把不同索引中的数据共同迁移到同一个索引中，例如把 `my-index-user` 下的 `user`、`my-index-user-v2` 下的 `user2` 数据共同迁移到 `my-index-user-v3` 中：

```
POST _reindex
{
  "source": {
    "index": [
      "my-index-user",
      "my-index-user-v2"
    ],
    "type": [
      "user",
      "user2"
    ]
  },
  "dest": {
    "index": "my-index-user-v3"
  }
}
```

这里要注意的是，对于上面的第二个示例，如果 `my-index-user` 和 `my-index-user-v2` 中有 `document` 的 `id` 是一样的，则无法保证最终出现在 `my-index-user-v3` 里面的 `document` 是哪个，因为迭代是随机的。按照默认的配置【即前面的 `version_type`、`opt_type` 等参数】，最后一条数据会覆盖前一条数据。

当然，对于第一个示例也会有这个问题。

另外，不要想着一对多迁移、多对多迁移等操作，不支持，因为写入时必须指定唯一确定的索引，否则 `Elasticsearch` 不知道数据要往哪个索引里面写入。

## 随机 size 配置

有时候想提前测试一下迁移结果是否准确，或者使用少量数据做一下性能测试，则需要随机取数的配置，可以使用 `size` 参数。注意，`size` 参数的位置是与 `source`、`dest` 在同一层级的，即在最外层。

例如随机取数100条，示例如下：

```
POST _reindex
{
  "source": {
    "index": "my-index-user"
  },
  "dest": {
    "index": "my-index-user-v2"
  },
  "size": 100
}
```

![随机100条数据结果](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2020/20200205004107.png "随机100条数据结果")

可以看到，随机迁移了100条数据，耗时223毫秒。

注意这里，千万不要用错 `size` 参数的位置，一个是表示 `scroll size` 的大小【如上面的**query 配置**中，配置在与 `query` 同一个层级，在 `source` 里面】，一个是表示随机抽取多少条【本小节示例，配置在最外层】。

我曾经就把 `size` 设置错误，放在与 `query` 同一层级，也就是误把 `scroll size` 设置为10了【本来是想先迁移10条数据看看结果】，导致 `reindex` 速度非常慢，30分钟才20万数据量【我还在疑惑为什么设置的随机10条不生效，把全部数据都迁移了】。

后来发现了，把任务取消，重新提交 `reindex` 任务，准确地把随机 `size` 设置为10万，把 `scroll size` 设置为2000。测试后才正式开始迁移数据，速度达到了30分钟500万，和前面的误操作比较明显提升了很多。

## 排序配置

好，上面有了随机数据条数的设置，但是如果我们想根据某个字段进行排序，获取 `top 100`，有没有办法呢？有，当然有，可以使用排序的功能，关键字为 `sort`，使用方式和查询 `Elasticsearch` 时一致。

例如按照更新时间 `update_timestamp` 的降序排列，获取前100条数据：

```
POST _reindex
{
  "source": {
    "index": "my-index-user",
    "sort": {
      "update_timestamp": "desc"
    }
  },
  "dest": {
    "index": "my-index-user-v2"
  },
  "size": 100
}
```

![返回结果](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2020/20200205005139.png "返回结果")

## 指定字段配置

指定字段。

还有一点需要注意，如果 `Elasticsearch` 的索引设置中，使用 `_source、excludes` 排除了部分字段的存储【为了节省磁盘空间】，则不可以直接迁移，会丢失这些字段。

## 使用脚本配置

## 使用 Ingest Node 配置

## 迁移远程集群数据到当前环境

## 返回体

正常情况下，返回的结果格式如下：

```
{
  "took": 9675,
  "timed_out": false,
  "total": 12505,
  "updated": 12505,
  "created": 0,
  "deleted": 0,
  "batches": 13,
  "version_conflicts": 0,
  "noops": 0,
  "retries": {
    "bulk": 0,
    "search": 0
  },
  "throttled_millis": 0,
  "requests_per_second": -1,
  "throttled_until_millis": 0,
  "failures": []
}
```

图。。

这里需要注意的是 `failures` 信息，如果里面的信息不为空，则表示本次 `_reindex` 是失败的，是被中途 `abort`，一般都是因为发生了 `conflicts`。前面已经描述过如何合理设置【场景可接受的方式，例如把 `conflicts` 设置为 `proceed`】，可以确保在发生 `conflict` 的时候还能继续运行。但是，这样设置后任务不会被 `abort`，可以正常执行完成，则最终也就不会返回 `failures` 信息了。

## 查看任务进度已经取消任务




# 备注


参考官网：[docs-reindex](https://www.elastic.co/guide/en/elasticsearch/reference/5.6/docs-reindex.html) 。


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



上面的说法看起来似乎有点不好理解，再简单直观点来说，就是在 `redinex` 的时候，我们的 `dest index` 可以不是一个新创建的不包含数据的 `index`，而是包含有数据的。如果我们的 `source index` 和 `dest index` 里面有相同类型和 `id` 的 `document`【一模一样的数据】，对于使用 `internal` 来说，就是直接覆盖，而使用 `external` 的话，只有当 `source index` 的数据的 `version` 比 `dest index` 数据的 `version` 更加新的时候，才会去更新【即保留最新的 `version` 对应的数据】。

## op_type 参数


## conflicts 配置


## query 配置



注意这里，千万不要用错 `size` 参数的位置，参考下面的**随机 size 配置**小节。

## 多对一迁移

不能保证顺序。

## 随机 size 配置


注意这里，千万不要用错 `size` 参数的位置，一个是表示 `scroll size` 的大小【如上面的**query 配置**中，配置在 `query` 里面】，一个是表示随机抽取多少条【本小节示例】。

我曾经就把 `size` 设置错误，放在了 `query` 中，也就是误把 `scroll size` 设置为10了【本来是想先迁移10条数据看看结果】，导致 `reindex` 速度非常慢，30分钟才20万数据量【我还在疑惑为什么设置的随机10条不生效，把全部数据都迁移了】。

后来发现了，把任务取消，重新提交 `reindex` 任务，准确地把随机 `size` 设置为10万，把 `scroll size` 设置为2000，测试后才正式迁移数据，速度达到了30分钟500万，和前面的误操作比较明显提升了很多。

## 排序配置


## 指定字段配置

指定字段。

还有一点需要注意，如果 `Elasticsearch` 的索引设置中，使用 `_source、excludes` 排除了部分字段的存储【为了节省磁盘空间】，则不可以直接迁移，会丢失这些字段。

## 使用脚本配置

## 使用 Ingest Node 配置

## 迁移远程集群数据到当前环境

## 返回体

## 查看任务进度已经取消任务


# 备注


参考官网：[docs-reindex](https://www.elastic.co/guide/en/elasticsearch/reference/5.6/docs-reindex.html) 。


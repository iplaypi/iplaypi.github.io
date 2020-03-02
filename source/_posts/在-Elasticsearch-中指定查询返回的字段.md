---
title: 在 Elasticsearch 中指定查询返回的字段
id: 2020030201
date: 2020-03-02 20:03:44
updated: 2020-03-02 20:03:44
categories: 大数据基础知识
tags: [Elasticsearch,fields,source,stored_fields]
keywords: Elasticsearch,fields,source,stored_fields
---


在 `Elasticsearch` 中，有参数可以指定查询结果返回的字段，这样可以使查询结果更简约，看起来更清晰。如果是大批量 `scroll` 取数，还可以减少数据在网络中的传输，从而降低网络 `IO`。本文使用简单的查询来举例，演示环境基于 `Elasticsearch v5.6.8`。


<!-- more -->


# 演示


我的演示环境里面有一个索引 `my-index-user`，里面是用户的信息，字段有姓名、年龄、性别、城市等。

现在我根据用户 `id` 查询数据，使用 `_source` 参数指定返回4个字段：`item_id`、`gender`、`city`、`birthday`。

查询条件：

```
POST my-index-user/_search
{
  "query": {
    "terms": {
      "item_id": [
        "63639783663",
        "59956667929"
      ]
    }
  },
  "_source": [
    "item_id",
    "gender",
    "city",
    "birthday"
  ]
}
```

查询结果：

```
{
  "took": 2,
  "timed_out": false,
  "_shards": {
    "total": 3,
    "successful": 3,
    "skipped": 0,
    "failed": 0
  },
  "hits": {
    "total": 2,
    "max_score": 7.937136,
    "hits": [
      {
        "_index": "my-index-user",
        "_type": "user",
        "_id": "23c659fde1a2c02b3618eaa92fcd7106",
        "_score": 7.937136,
        "_source": {
          "birthday": "1994-01-01",
          "city": "成都",
          "item_id": "63639783663"
        }
      },
      {
        "_index": "my-index-user",
        "_type": "user",
        "_id": "75e3db1f4ab288d38de3ab80bfba8ecd",
        "_score": 7.937136,
        "_source": {
          "birthday": "1982-01-01",
          "gender": "1",
          "city": "渭南",
          "item_id": "59956667929"
        }
      }
    ]
  }
}
```

![查询结果指定字段](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2020/20200302205417.png "查询结果指定字段")

可以看到，查到的数据只返回了4个字段。


# 备注


除了 `_source` 参数外，还有其它的参数也可以达到同样的效果，在 `v2.4` 以及之前的版本，可以使用 `fields` 参数：

```
POST my-index-user/_search
{
  "query": {
    "terms": {
      "item_id": [
        "63639783663",
        "59956667929"
      ]
    }
  },
  "fields": [
    "user_name",
    "item_id",
    "gender",
    "city",
    "birthday"
  ]
}
```

下图是我找了一个低版本 `Elasticsearch` 集群测试了一下：

![fields 参数过滤字段](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2020/20200302205758.png "fields 参数过滤字段")

不过在 `v5.x` 以及之后的版本不再支持这个参数：

![不支持 fields 参数](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2020/20200302205500.png "不支持 fields 参数")

异常信息：

```
The field [fields] is no longer supported, please use [stored_fields] to retrieve stored fields or _source filtering if the field is not stored
```

注意这里提及的 `stored_fields` 参数用处有点鸡肋，还是需要 `_source` 参数配合。


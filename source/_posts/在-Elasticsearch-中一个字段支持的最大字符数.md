---
title: 在 Elasticsearch 中一个字段支持的最大字符数
id: 2017061401
date: 2017-06-14 21:29:31
updated: 2017-06-14 21:29:31
categories: 大数据技术知识
tags: [Elasticsearch,bulk,keyword,ignore_above]
keywords: Elasticsearch,bulk,keyword,ignore_above
---


最近在项目中遇到一个异常，写入数据到 `Elasticsearch` 中，报错：`max_bytes_length_exceeded_exception`。这个其实和 `Elasticsearch` 的字段长度限制有关，本文就回顾一下在 `Elasticsearch` 中一个字段支持的最大字符数。

本文涉及的开发环境：`Elasticsearch v5.6.8`，读者需要注意**字符数**、**字节数**这两个基本概念的区别。


<!-- more -->


# 问题出现


在业务中发现漏数，查看后台的任务日志，发现异常：

```
ERROR ESBulkProcessor: {"index":"your_index","type":"your_type","id":"b20ddaf126908506024aed6698b50214","cause":{"type":"exception","reason":"Elasticsearch exception [type=illegal_argument_exception, reason=Document contains at least one immense term in field=\"author.raw\" (whose UTF8 encoding is longer than the max length 32766), all of which were skipped.  Please correct the analyzer to not produce such terms.  The prefix of the first immense term is: '[-24, -87, -71, -25, -74, -83, -24, -128, -107, -17, -68, -113, -27, -113, -80, -27, -116, -105, -27, -96, -79, -27, -80, -114, 32, -27, -120, -111, -28, -70]...', original message: bytes can be at most 32766 in length; got 98345]","caused_by":{"type":"exception","reason":"Elasticsearch exception [type=max_bytes_length_exceeded_exception, reason=max_bytes_length_exceeded_exception: bytes can be at most 32766 in length; got 98345]"}},"status":400}
17/06/14 18:07:04 ERROR ESBulkProcessor: bulk [76 : 1560506824519] 527 request - 526 response
17/06/14 19:05:36 ERROR ESBulkProcessor: {"index":"your_index","type":"your_type","id":"cc36f925a9281389cb50b194cf590108","cause":{"type":"exception","reason":"Elasticsearch exception [type=illegal_argument_exception, reason=Document contains at least one immense term in field=\"author.raw\" (whose UTF8 encoding is longer than the max length 32766), all of which were skipped.  Please correct the analyzer to not produce such terms.  The prefix of the first immense term is: '[-27, -112, -77, -25, -112, -115, -27, -112, -101, -26, -114, -95, -24, -88, -86, -27, -96, -79, -27, -80, -114, 35, 34, 44, 34, 112, 117, 98, 116, 105]...', original message: bytes can be at most 32766 in length; got 94724]","caused_by":{"type":"exception","reason":"Elasticsearch exception [type=max_bytes_length_exceeded_exception, reason=max_bytes_length_exceeded_exception: bytes can be at most 32766 in length; got 94724]"}},"status":400}
```


可以看到，使用 `bulk` 方式，在数据写入 `Elasticsearch` 时遇到异常，如果一个字段的类型是 `keyword`，而实际写入数据时指定了一个非常长的文本值，会报错：`illegal_argument_exception`、`max_bytes_length_exceeded_exception`，整个文档写入失败并返回异常【注意，会过滤掉当前整个文档，即整条数据不能被写入，而如果字段的字节长度小于等于32766，文档是可以被写入的，但是这个字段可能不会被索引，参考下面的 `ignore_above` 参数】。

更详细的信息：

```
whose UTF8 encoding is longer than the max length 32766
```

`author.raw` 取值的字节数超过了32766，无法写入，综合上述异常信息，表明 `author.raw` 字段定义为 `keyword`，而实际写入数据时文本长度过大，字节数达到94724【大概率是脏数据】。

注意，这里的无法写入是针对整个文档，即整条数据无法成功写入 `Elasticsearch`。


# 问题分析


对于这种超长的值，如果简单的把字段设置为 `keyword` 类型肯定是不行的。

解决方法就是对这种长文本的字段不能定义为 `keyword`，而应该定义为分析类型，即 `text`，并指定必要的分析器。

那如果这个字段本身就应该定义为 `keyword` 类型，而实际中存在少量的脏数据，这种超长的内容是可以忽略的，那就给这个字段指定一个最长字符数，例如200字符，在写入前判断一下长度，超过则移除或者截断，不要让这种超长的文本进入写 `Elasticsearch` 的流程。毕竟这种超长文本写入到一个 `keyword` 类型的字段中，对于 `Elasticsearch` 是不友好的，底层的 `Lucene` 也无法支持，而且哪怕写入了，对于使用者来说也没有意义【要进行全文检索才是有意义的】。

## 禁止索引

当然，对于长度不超过32766字节的 `keyword` 类型字段值，如果太长也没有意义，例如几百几千个字符【对应的字节数可能是几千几万】，而 `Elasticsearch` 原生也支持对 `keyword` 类型的字段设置禁止索引的长度上限，超过一定的字符数【前提是不超过32766字节】则当前字段不能被索引，但是字段的数据还是能写入的，它就是 `ignore_above` 参数，下面举例说明。

设置 `name_ignore` 字段为 `keyword` 类型，并指定 `ignore_above` 为8，表示最大可以索引8个字符的长度。同理，设置 `name` 字段为 `keyword` 类型，并指定 `ignore_above` 为32，表示最大可以索引32个字符的长度。

注意，`ignore_above` 参数限制的是字符数，具体字节数要根据实际内容转换，如果内容中都是字母、数字，则字符数就是字节数，但是当内容中大多数是中文、韩文，则字节数等于字符数乘以4。

```
PUT /my-index-post/_mapping/post
{
    "properties": {
      "name_ignore": {
        "type": "keyword",
        "ignore_above": 8
      }
  }
}

PUT /my-index-post/_mapping/post
{
    "properties": {
      "name": {
        "type": "keyword",
        "ignore_above": 32
      }
  }
}

```

写入2条数据：

```
POST my-index-post/post/1
{
  "name": "名称过长会被过滤名称过长会被过滤",
  "name_ignore": "名称过长会被过滤名称过长会被过滤"
}

POST my-index-post/post/2
{
  "name": "名称过长会被过滤名称过长会被过滤",
  "name_ignore": "名称过长会被过滤名称过长会被过滤"
}
```

可以看一下数据，2条数据都成功写入 `Elasticsearch` 中：

```
POST my-index-post/_search
{
  "query": {
    "bool": {
      "must": [
        {
          "terms": {
            "_id": [
              "1",
              "2"
            ]
          }
        }
      ]
    }
  }
}
```

![查看2条数据](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2017/20200305213903.png "查看2条数据")

可以看到字段信息都完整，那设置了 `name_ignore` 参数的用处是什么呢，在于是否**索引**，我们加上精确匹配来查询一下：

```
# 查不到数据
POST my-index-post/_search
{
  "query": {
    "bool": {
      "must": [
        {
          "terms": {
            "_id": [
              "1",
              "2"
            ]
          }
        },
        {
          "terms": {
            "name_ignore": [
              "名称过长会被过滤名称过长会被过滤"
            ]
          }
        }
      ]
    }
  }
}

# 可以查到数据
POST my-index-post/_search
{
  "query": {
    "bool": {
      "must": [
        {
          "terms": {
            "_id": [
              "1",
              "2"
            ]
          }
        },
        {
          "terms": {
            "name": [
              "名称过长会被过滤名称过长会被过滤"
            ]
          }
        }
      ]
    }
  }
}
```

![查不到数据](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2017/20200305213928.png "查不到数据")

![可以查到数据](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2017/20200305213935.png "可以查到数据")

可以发现，使用 `name_ignore` 字段做精确匹配时查不到数据，而使用 `name` 字段却可以，说明 `Elasticsearch` 在写入 `name_ignore` 字段的值时没有对超过8个字符的做索引，只是简单的存储，也就无法查询。

官方说明：

>Strings longer than the ignore_above setting will not be indexed or stored.


# 总结


1、一个字段被设置为 `keyword` 类型，遇到很长的大段内容写入后【超过32766个字节】，抛出字节数过大异常，整条数据无法写入。

2、搜索超过 `ignore_above` 设定长度的字段，无法命中数据【因为在写入时没有做索引，但是字段的值仍旧保留】。

3、写入数据时，内容的字符数超过 `ignore_above` 的限制，整条数据仍旧可以入库【包含当前字段】，只是内容不会被索引，在查询命中这条数据时字段对应的值仍旧可以返回。

4、如果不设置 `ignore_above` 的值，默认为256个字符，但是记住这个值首先受限于 `keyword` 类型的限制，并不能无限大。

## 引申说明

1、由于 `keyword` 的长度限制，`keyword` 类型的最大支持的长度为32766个字节，注意如果是 `UTF-8` 类型的字符【占用1-4个字节】，也就能支持8000个左右【如果都是数字、字母则会长一点】，也就是说 `term` 精确匹配的最大支持长度为8000个 `UTF-8` 个字符【而实际上这么长在应用中是没有意义的】。

2、两种类型的区别：

- `text` 类型：没有最大长度限制，支持分词、全文检索，不支持聚合、排序，因此适合大字段存储，例如文章详情
- `keyword` 类型：最大字节数为32766，如果使用 `UTF-8` 编码，最大字符数粗略估计可以使用最大字节数除以4，支持精确匹配，支持聚合、排序，适合精确字段匹配，例如：`url`、姓名、性别

官方说明：

>This option is also useful for protecting against Lucene’s term byte-length limit of 32766.
>The value for ignore_above is the character count, but Lucene counts bytes. If you use UTF-8 text with many non-ASCII characters, you may want to set the limit to 32766 / 4 = 8191 since UTF-8 characters may occupy at most 4 bytes.


# 备注


1、官方文档：[ignore-above](https://www.elastic.co/guide/en/elasticsearch/reference/5.6/ignore-above.html) 。

2、字段的 `ignore_above` 可以变更，类型不会变更，不会影响已经存储的内容【使用 `put` 接口，参考官方文档：[indices-put-mapping](https://www.elastic.co/guide/en/elasticsearch/reference/5.6/indices-put-mapping.html)】，只会影响以后写入的内容，因为字段类型并没有变化，只是限制了写入长度。

3、设置时取值为数值，例如6、16等，注意它表示的是字符数，不是字节数，所以如果数据都是字母、数字最大就可以设置为32766，但是当数据是中文、韩文时最大只能设置为8000了。

4、如果需要同一个字段存在多种类型，可以使用 `multi-fields` 特性，参考：[multi-fields](https://www.elastic.co/guide/en/elasticsearch/reference/5.6/multi-fields.html) 。


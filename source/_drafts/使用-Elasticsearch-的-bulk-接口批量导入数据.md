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

使用 `Elasticsearch` 时，有时候需要导入一些数据，例如一份 `JSON` 格式的文本文件。此时除了写 `Java`、`Python` 代码，还可以利用 `Elasticsearch` 提供的 `API` 接口快速执行导入操作。本文简单做一个介绍，开发环境基于 `Elasticsearch v5.6.8`。


<!-- more -->


# 导入示例



```
把文件中的数据导入索引，批量的形式
由于数据中可能存在一些特殊符号，所以使用文件的形式，in为文件路径
文件内容格式，1条数据需要包含2行内容，index表示索引数据
{"index":{}}
JSON原始数据


sed '1,600000 i{"index":{}}' -i post_es.txt
curl -XPOST 'http://dev4:9200/my-index-post/post/_bulk' --data-binary @"$out"


HBase的操作，注意字段的对齐
/usr/hdp/current/phoenix-client/bin/psql.py -t MY_INDEX_POST dev4:2181 ./post_hbase.csv
```


注意，使用 `http` 请求写入数据时，
使用 post 请求，`_id` 是自动生成的，与数据中的 id 字段无关；
以 `my-index-post` 为例；


bulk 接口会自动生成 `_id`，表示文档的唯一标识，不等于文档里面的 id 字段；

有没有参数可以指定呢？待查明；【有参数可以指定，不指定则会随机生成】


# 知识延伸


还有其它接口可以用

https://www.jianshu.com/p/1c8ba834e15c

https://www.elastic.co/guide/cn/elasticsearch/guide/current/bulk.html



## HBase 导入导出数据


也包括hbase的接口

数据文件不需要表头，字段顺序要对齐。

导出使用记录命令：

```
开启记录
输出文件
正常查询
退出查看文件
```

使用 `phoenix` 往 `HBase` 表里面导数，遇到过一个小问题，参考：[HBase 错误：The node hbase is not in ZooKeeper](https://www.playpi.org/2019101901.html) 。


# 一些异常


`bulk` 别名异常问题，必须使用真实索引名称

```
{"error":{"root_cause":[{"type":"illegal_argument_exception","reason":"Alias [my-index-post-all] has more than one indices associated with it [[my-index-post-1, my-index-post-2]], can't execute a single index op"}],"type":"illegal_argument_exception","reason":"Alias [my-index-post-all] has more than one indices associated with it [[my-index-post-1, my-index-post-2]], can't execute a single index op"},"status":400}

```


# 备注


官网链接：[docs-bulk](https://www.elastic.co/guide/en/elasticsearch/reference/5.6/docs-bulk.html) 。


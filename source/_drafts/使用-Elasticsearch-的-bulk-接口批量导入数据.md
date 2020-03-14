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



<!-- more -->


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


`bulk` 批量接口

注意，使用 `http` 请求写入数据时，
使用 post 请求，`_id` 是自动生成的，与数据中的 id 字段无关；
以 `my-index-post` 为例；




bulk 别名异常问题

bulk 接口会自动生成 `_id`，表示文档的唯一标识，不等于文档里面的 id 字段；
有没有参数可以指定呢？待查明；



https://www.jianshu.com/p/1c8ba834e15c


# 备注

各种坑

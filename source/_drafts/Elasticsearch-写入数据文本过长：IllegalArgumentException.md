---
title: Elasticsearch 写入数据文本过长：IllegalArgumentException
id: 2020-03-23 01:11:04
date: 2018-05-30 01:11:04
updated: 2018-05-30 01:11:04
categories:
tags:
keywords:
---


2018053001
Elasticsearch,Hadoop
踩坑系列


在使用 `elasticsearch-hadoop` 处理数据时，写入数据报错：`IllegalArgumentException`，具体原因显示字符过长，也就是写入的文本太长了，`Elasticsearch` 自身无法支持。

开发环境基于 `elasticsearch-hadoop v2.1.0`、`Elasticsearch v1.7.5` 。


<!-- more -->



# 问题出现


处理数据后写回 `Elasticsearch` 时有异常：

```
org.elasticsearch.hadoop.rest.EsHadoopInvalidRequest: Found unrecoverable error [192.168.10.170:9202] returned Internal Server Error(500) - [IllegalArgumentException[Document contains at least one immense term in field="content_seg" (whose UTF8 encoding is longer than the max length 32766)
```

图。。。

业务逻辑是把 `content` 分词取 `top5` 放入 `content_seg` 字段里面，字段 `content_seg` 是存放一个分词结果的数组。

此外还有提示：

```
Please correct the analyzer to not produce such terms.  The prefix of the first immense term is: '[-17, -69, -65, -17, -69, -65, -17, -69, -65, -17, -69, -65
```

建议正确设置字段的类型，分词字段比较合适。




# 问题分析


本质就是文本过长。

更为详细的信息参考我的另外一篇博客：[在 Elasticsearch 中一个字段支持的最大字符数](https://www.playpi.org/2017061401.html) 。


# 问题解决



解决办法有两种，都是基于业务逻辑考虑的，在技术上并没有什么方案。

## 思路一

一种方案是过滤掉无意义的分词结果，保证分词结果的长度在固定数值之内，例如100，大于100的默认为无意义分析结果。

可以通过过滤逻辑把分词后的词筛选，长度大于100的当作废词，舍弃，比如下面这样的就不要了。

图。。

这种一看就是无意义的分词结果，前面的异常也就表明了这些分词结果是很长的字符串，导致写回 `Elasticsearch` 时超过最大长度，报错。

代码如下。

图。。


当然也可以更换效果更好的分词器，不让它产生这种无意义的分词结果。

上面使用的是 `ansj_seg` 分词器，版本是 `v5.0.3`。

```
<dependency>
    <groupId>org.ansj</groupId>
    <artifactId>ansj_seg</artifactId>
    <version>5.0.3</version>
</dependency>
```

图。。

## 思路二

另一种方案是不分词了，设置合适的分词器，直接使用 `Elasticsearch` 的全文检索功能进行搜索。当然，如果想统计分词的分布式不可行了。



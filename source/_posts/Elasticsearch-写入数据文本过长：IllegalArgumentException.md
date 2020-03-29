---
title: Elasticsearch 写入数据文本过长：IllegalArgumentException
id: 2018053002
date: 2018-05-30 01:11:04
updated: 2018-05-30 01:11:04
categories: 踩坑系列
tags: [Elasticsearch,Hadoop]
keywords: Elasticsearch,Hadoop
---


在使用 `elasticsearch-hadoop` 处理数据时，写入数据报错：`IllegalArgumentException`，具体原因显示字符过长，也就是写入的文本太长了，`Elasticsearch` 自身无法支持【本质还是底层的 `Lucene` 无法支持】。

开发环境基于 `elasticsearch-hadoop v2.1.0`、`Elasticsearch v1.7.5` 。


<!-- more -->


# 问题出现


处理数据后写回 `Elasticsearch` 时出现异常：

```
org.elasticsearch.hadoop.rest.EsHadoopInvalidRequest: Found unrecoverable error [192.168.10.170:9202] returned Internal Server Error(500) - [IllegalArgumentException[Document contains at least one immense term in field="content_seg" (whose UTF8 encoding is longer than the max length 32766)
```

![写入异常](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2018/20200329200432.png "写入异常")

在代码中，业务逻辑是把 `content` 分词取 `top5` 放入 `content_seg` 字段里面，字段 `content_seg` 是存放一个分词结果的数组。

此外还有提示：

```
Please correct the analyzer to not produce such terms.  The prefix of the first immense term is: '[-17, -69, -65, -17, -69, -65, -17, -69, -65, -17, -69, -65
```

建议正确设置字段的类型，分词字段比较合适。


# 问题分析


由上面的异常信息以及提示信息可见，分词的结果文本过长，无法写入一个 `string term` 类型的字段，本质就是文本过长【和字段类型不匹配】。

更为详细的信息参考我的另外一篇博客：[在 Elasticsearch 中一个字段支持的最大字符数](https://www.playpi.org/2017061401.html) 。


# 问题解决


解决办法有两种，都是基于业务逻辑考虑的，在技术上并没有什么方案【底层的 `Lucene` 无法支持】。

## 思路一

一种方案是过滤掉无意义的分词结果，保证分词结果的长度在固定数值之内，例如100，大于100的默认为无意义分析结果，可以舍弃。

可以通过过滤逻辑把分词后的词筛选，长度大于100的当作废词，舍弃，比如下面这样的就不要了。

![无意义的可舍弃的词](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2018/20200329200845.png "无意义的可舍弃的词")

这种一看就是无意义的分词结果，前面的异常也就表明了这些分词结果是很长的字符串，导致写回 `Elasticsearch` 时超过最大长度，报错。

代码如下。

![过滤代码](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2018/20200329200539.png "过滤代码")

当然也可以更换效果更好的分词器，或者添加黑名单，不让它产生这种无意义的分词结果。

上面使用的是 `ansj_seg` 分词器，版本是 `v5.0.3`。

```
<dependency>
    <groupId>org.ansj</groupId>
    <artifactId>ansj_seg</artifactId>
    <version>5.0.3</version>
</dependency>
```

![分词器依赖](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2018/20200329200416.png "分词器依赖")

## 思路二

另一种方案是不对文本分词了，而是给 `content` 本身设置合适的分词器，直接使用 `Elasticsearch` 的全文检索功能进行搜索。当然，如果想统计分词的分布是不可行了。


---
title: Elasticsearch 分析器使用入门指南
id: 2017-08-20 00:56:10
date: 2020-02-19 00:56:10
updated: 2020-02-19 00:56:10
categories:
tags:
keywords:
---


2017082001
Elasticsearch,analyzer,wordsEN,standard,english
大数据技术知识

`ElasticSearch` 是一个基于 `Lucene` 构建的开源、分布式、`RESTful` 搜索引擎，能够达到实时搜索，并且稳定、可靠、快速。而其中最常用的全文检索【`match` 匹配】功能，在很多场景都应用，其中离不开分析器【`Analyzer`】的功劳，本文简单总结一下相关内容，入门级别。开发环境基于 `v5.6.8`。


<!-- more -->


# 初识分析器


首先需要先了解一下分析器的概念，以及与此相关的几个术语。

做全文检索前就需要对文档分析、建索引，其中从文档中提取词元【`Token`】的算法称为分词器【`Tokenizer`】，在分词前预处理的算法称为字符过滤器【`Character Filter`】，进一步处理词元的算法称为词元过滤器【`Token Filter`】，最后得到词元【`Term`，最小单元，决定着搜索时能否命中】。而这整个分析算法称为分析器【`Analyzer`】，我们对文档的某个字段可以指定分析器，以达到我们全文检索的需求。

这里注意，我们在日常口语中会把 `Analyzer` 称为分词器，例如给某个字段指定一个分词器，这其实是有误导的【因为分词器只是分析器中的一个重要的步骤】。

文档包含词的数量称为词频【`Frequency`】，搜索引擎会建立词与文档的索引，称为**倒排索引**【`Inverted Index`】，这是 `ElasticSearch` 中的基本概念。

下面使用一张图片来简单描述一下分析器的分析流程，更加直观：

图。。

`Analyzer` 按顺序做三件事：

1. 使用 `CharacterFilter` 过滤字符，可以添加、删除或更改字符来转换字符流，一个分析器可以有多个字符过滤器；
2. 使用 `Tokenizer` 分词，接收字符流，将其分解成单独的词元，并输出词元流，一个分析器只能有一个分词器；
3. 使用 `TokenFilter` 过滤词元，接收词元流，并可以添加、删除或修改词元，不允许更改每个词元的位置或字符偏移量，一个分析器可有多个 `TokenFilter` 过滤器，并按顺序应用。

关于词元【`Term`】，我们也会简称为词，为了避免歧义，本文统一称之为词元。

`Elasticsearch` 默认提供了多种 `CharacterFilter`、`Tokenizer`、`TokenFilter`、`Analyzer`【可以直接使用的分析器】，当然，我们也可以下载第三方的 `Analyzer` 组件，或者根据业务场景开发自定义的组件。

官网链接如下：

- [CharacterFilter](https://www.elastic.co/guide/en/elasticsearch/reference/current/analysis-charfilters.html)
- [Tokenizer](https://www.elastic.co/guide/en/elasticsearch/reference/current/analysis-tokenizers.html)
- [TokenFilter](https://www.elastic.co/guide/en/elasticsearch/reference/current/analysis-tokenfilters.html)
- [Analyzer](https://www.elastic.co/guide/en/elasticsearch/reference/current/analysis-analyzers.html)

`Elasticsearch` 中的 `Analyzer` 一般会提供一些配置，我们按照需要使用，如 `standard Analyzer` 提供了 `stop_words` 停用词过滤配置，这样我们就可以提供一些噪音词【例如特定行业数据中可能有歧义的词，不想被分析器输出为词元】，用于分析时剔除。

官方介绍：

>The standard analyzer divides text into terms on word boundaries, as defined by the Unicode Text Segmentation algorithm. It removes most punctuation, lowercases terms, and supports removing stop words.

下面列举一个简单示例，为 `standard Analyzer` 添加 `stop_words`：

```
PUT /my-index-post/_settings
{
  "index": {
    "analysis": {
      "analyzer": {
        "standard": {
          "type": "standard",
          "stop_words": [ "is", "a", "哈", "吁"]
        }
      }
    }
  }
}
```

以上我们就构造了名为 `standard` 的 `standard Analyzer` 类型的带停用词列表的分析器。

还有其它更多的分析器请读者参考上面的官方文档，例如 `Whitespace Analyzer`，即空格分析器，遇到任何空格字符时都会将文本分为多个项目，并且不会把词元转换为小写字母【区分大小写】。


# 自定义分析器


通过上面的讲解，我们发现也可以通过 `Setting API` 来构造组合自定义的 `Analyzer`，此时需要我们指定 `Character Filter`、`Tokenizer`、`Token Filter` 等基础规则组件。读者可以参考官网示例：[analysis-custom-analyzer](https://www.elastic.co/guide/en/elasticsearch/reference/current/analysis-custom-analyzer.html) 。

请看以下例子：

```
PUT my-index-post/_settings

{
  "index": {
    "analysis": {
      "analyzer": {
        "custom_analyzer": {
          "type": "custom",
          "char_filter": [ "html_strip" ],
          "tokenizer": "standard",
          "filter": [ "lowercase", "stop" ]
        }
      }
    }
  }
}
```

我们构造了一个名称为 `custom_analyzer` 的分析器，其中 `type` 用来告诉 `Elasticsearch` 我们要自定义一个分析器，`char_filter` 指定了 `Character Filter`，`tokenizer` 指定了 `Tokenizer`，`filter` 指定了 `Token Filter`。

根据我们的设置，它会完成以下流程：

1. 使用 `html_strip` 字符过滤器，移除 `html` 标签；
2. 使用 `standard` 分词器，进行分词；
3. 使用 `lowercase` 词元过滤器，把大写字母转为小写字母；
4. 使用 `stop` 词元过滤器，过滤掉停用词。

这样我们的自定义分析器构造完成，可以根据名称使用它了。


# 实战演示


首先说明，在创建索引时，我们针对特殊的字段都会指定分析器，例如内容、标题这种长文本，需要全文检索。因此，我们在配置 `_mapping` 时，就可以指定分析器了，可以为单个字段指定，也可以使用动态模版指定【更加灵活】。




# 备注

在索引层面动态设置
或者使用索引模版

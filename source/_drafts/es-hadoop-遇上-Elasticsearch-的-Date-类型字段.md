---
title: es-hadoop 遇上 Elasticsearch 的 Date 类型字段
id: 2020-01-16 20:14:18
date: 2020-01-16 20:14:18
updated: 2020-01-16 20:14:18
categories:
tags:
keywords:
---


2018041801
Elasticsearch,Hadoop,Date
大数据技术知识


<!-- more -->



注意，es-hadoop版本如果很低，例如v2.1.0，还不支持高版本的es，例如v2.3.5，此时会导致异常，无法处理date字段；
另外，使用v2.4.5，有bug，会导致读取中文字段丢失，如果再写回去就悲剧了，中文字段全部丢失。【关于此问题的踩坑记录可以参考我的另外一篇博客，后续从tower整理出来，给出链接】

```
<!-- 2.4.5版本获取Node过程兼容了2.1.0版本,但是读取ES数据中文字段会丢失 -->

        <!-- es-spark,要指定es-hadoop新版本 -->
        <!-- 以下2个依赖包都需要 -->
        <dependency>
            <groupId>org.elasticsearch</groupId>
            <artifactId>elasticsearch-hadoop</artifactId>
            <version>${elasticsearch-hadoop.version}</version>
            <!-- 必须移除,与spark-core_2.10里面有冲突 -->
            <exclusions>
                <exclusion>
                    <groupId>com.esotericsoftware</groupId>
                    <artifactId>kryo</artifactId>
                </exclusion>
            </exclusions>
        </dependency>
        <dependency>
            <groupId>javax.servlet</groupId>
            <artifactId>javax.servlet-api</artifactId>
            <version>4.0.1</version>
        </dependency>
```


从es查看原始数据

```
{
  "took": 6,
  "timed_out": false,
  "_shards": {
    "total": 80,
    "successful": 80,
    "skipped": 0,
    "failed": 0
  },
  "hits": {
    "total": 1,
    "max_score": 11.363798,
    "hits": [
      {
        "_index": "ds-banyan-newsforum-post-year-2019-v3",
        "_type": "post",
        "_id": "ae75c92981148654195408f9f5260930",
        "_score": 11.363798,
        "_source": {
          "id": "ae75c92981148654195408f9f5260930",
          "url": "https://fxhh.jd.com/detail.html?id=226608850",
          "publish_timestamp": 1575129850000
        }
      }
    ]
  }
}
```



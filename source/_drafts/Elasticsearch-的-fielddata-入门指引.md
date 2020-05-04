---
title: Elasticsearch 的 fielddata 入门指引
id: 2020-05-04 17:06:06
date: 2020-05-01 17:06:06
updated: 2020-05-04 17:06:06
categories:
tags:
keywords:
---



2020050101
大数据技术知识
Elasticsearch,fielddata,aggregations,JVM

昨天查看 `Elasticsearch` 集群监控，发现有几个 `Elasticsearch` 节点的 `JVM Heap` 异常，上下波动非常频繁，进一步查看 `GC`，发现 `Full GC` 非常频繁，每分钟达到5-10次，而累加耗时有10-20秒，也就是说有17%-33%的时间都在做 `Full GC`，这显然是不健康的。

进一步查看 `CPU` 使用情况，发现 `CPU` 使用率由正常的20%左右，达到现在的50%-70%，这也是不正常的。

排查方向是看是否有大量的 `aggregations` 请求或者排序 `sort` 操作，这种情况才会造成大量的内存占用【`fielddata` 类型的字段】，当然其它情况也有可能，但概率低【例如大查询，`query` 语句复杂，数据量大】，具体情况需要具体对待。排查的过程就不说了，由此做引子，先简单对 `fielddata` 做入门指引。


<!-- more -->


# 问题引入


昨天将要迎来小长假，仔细看了一眼 `Elasticsearch` 集群的监控，发现某几个 `Elasticsearch` 节点的 `CPU` 使用率、`JVM` 内存的指标都有异常，初步排查下来和 `aggregations` 请求有关，而根本原因和 `fielddata` 字段有关。

异常的监控

图。。

图。。

观察服务端集群的日志，发现有频繁的 `Full GC` 流程：

```
[2020-05-01T17:01:03,243][WARN ][o.e.i.b.fielddata        ] [fielddata] New used memory 12778206644 [11.9gb] for data of [_uid] would be larger than configured breaker: 12759701913 [11.8gb], breaking
[2020-05-01T17:01:03,296][WARN ][o.e.i.b.fielddata        ] [fielddata] New used memory 12778952590 [11.9gb] for data of [_uid] would be larger than configured breaker: 12759701913 [11.8gb], breaking
[2020-05-01T17:01:03,333][WARN ][o.e.i.b.fielddata        ] [fielddata] New used memory 12778206644 [11.9gb] for data of [_uid] would be larger than configured breaker: 12759701913 [11.8gb], breaking
[2020-05-01T17:01:03,373][WARN ][o.e.i.b.fielddata        ] [fielddata] New used memory 12778442411 [11.9gb] for data of [_uid] would be larger than configured breaker: 12759701913 [11.8gb], breaking
[2020-05-01T17:01:03,411][WARN ][o.e.i.b.fielddata        ] [fielddata] New used memory 12778206644 [11.9gb] for data of [_uid] would be larger than configured breaker: 12759701913 [11.8gb], breaking
[2020-05-01T17:01:03,526][WARN ][o.e.i.b.fielddata        ] [fielddata] New used memory 12778206644 [11.9gb] for data of [_uid] would be larger than configured breaker: 12759701913 [11.8gb], breaking
[2020-05-01T17:01:03,665][WARN ][o.e.i.b.fielddata        ] [fielddata] New used memory 12778206644 [11.9gb] for data of [_uid] would be larger than configured breaker: 12759701913 [11.8gb], breaking
[2020-05-01T17:01:03,963][WARN ][o.e.i.b.fielddata        ] [fielddata] New used memory 12778442411 [11.9gb] for data of [_uid] would be larger than configured breaker: 12759701913 [11.8gb], breaking
[2020-05-01T17:01:04,037][WARN ][o.e.i.b.fielddata        ] [fielddata] New used memory 12778206644 [11.9gb] for data of [_uid] would be larger than configured breaker: 12759701913 [11.8gb], breaking
[2020-05-01T17:01:04,518][WARN ][o.e.i.b.fielddata        ] [fielddata] New used memory 12778206644 [11.9gb] for data of [_uid] would be larger than configured breaker: 12759701913 [11.8gb], breaking
[2020-05-01T17:01:04,713][WARN ][o.e.i.b.fielddata        ] [fielddata] New used memory 12778372453 [11.9gb] for data of [_uid] would be larger than configured breaker: 12759701913 [11.8gb], breaking
[2020-05-01T17:01:04,715][WARN ][o.e.i.b.fielddata        ] [fielddata] New used memory 12777862273 [11.9gb] for data of [_uid] would be larger than configured breaker: 12759701913 [11.8gb], breaking
[2020-05-01T17:01:04,821][WARN ][o.e.i.b.fielddata        ] [fielddata] New used memory 12777862273 [11.9gb] for data of [_uid] would be larger than configured breaker: 12759701913 [11.8gb], breaking
[2020-05-01T17:01:05,059][WARN ][o.e.i.b.fielddata        ] [fielddata] New used memory 12777626506 [11.9gb] for data of [_uid] would be larger than configured breaker: 12759701913 [11.8gb], breaking
[2020-05-01T17:01:05,470][WARN ][o.e.i.b.fielddata        ] [fielddata] New used memory 12778206751 [11.9gb] for data of [_uid] would be larger than configured breaker: 12759701913 [11.8gb], breaking
[2020-05-01T17:01:05,530][WARN ][o.e.i.b.fielddata        ] [fielddata] New used memory 12778206751 [11.9gb] for data of [_uid] would be larger than configured breaker: 12759701913 [11.8gb], breaking
[2020-05-01T17:01:05,693][WARN ][o.e.i.b.fielddata        ] [fielddata] New used memory 12778442518 [11.9gb] for data of [_uid] would be larger than configured breaker: 12759701913 [11.8gb], breaking
[2020-05-01T17:01:09,173][WARN ][o.e.m.j.JvmGcMonitorService] [es1] [gc][1567372] overhead, spent [665ms] collecting in the last [1s]
[2020-05-01T17:01:12,000][WARN ][o.e.i.b.fielddata        ] [fielddata] New used memory 12778442518 [11.9gb] for data of [_uid] would be larger than configured breaker: 12759701913 [11.8gb], breaking
[2020-05-01T17:01:12,410][WARN ][o.e.i.b.fielddata        ] [fielddata] New used memory 12778206751 [11.9gb] for data of [_uid] would be larger than configured breaker: 12759701913 [11.8gb], breaking
[2020-05-01T17:01:12,652][WARN ][o.e.i.b.fielddata        ] [fielddata] New used memory 12778206751 [11.9gb] for data of [_uid] would be larger than configured breaker: 12759701913 [11.8gb], breaking
[2020-05-01T17:01:17,947][WARN ][o.e.m.j.JvmGcMonitorService] [es1] [gc][1567379] overhead, spent [2.4s] collecting in the last [2.7s]
[2020-05-01T17:01:20,295][WARN ][o.e.i.b.fielddata        ] [fielddata] New used memory 12778206751 [11.9gb] for data of [_uid] would be larger than configured breaker: 12759701913 [11.8gb], breaking
[2020-05-01T17:01:34,847][WARN ][o.e.m.j.JvmGcMonitorService] [es1] [gc][1567395] overhead, spent [1.6s] collecting in the last [1.8s]
[2020-05-01T17:01:41,989][WARN ][o.e.m.j.JvmGcMonitorService] [es1] [gc][1567402] overhead, spent [638ms] collecting in the last [1.1s]
[2020-05-01T17:01:51,991][WARN ][o.e.m.j.JvmGcMonitorService] [es1] [gc][1567412] overhead, spent [563ms] collecting in the last [1s]
[2020-05-01T17:02:04,601][WARN ][o.e.m.j.JvmGcMonitorService] [es1] [gc][1567422] overhead, spent [2.8s] collecting in the last [3.6s]
[2020-05-01T17:02:16,809][WARN ][o.e.m.j.JvmGcMonitorService] [es1] [gc][1567433] overhead, spent [1.7s] collecting in the last [2.2s]
```

图。。

日志中显示的 `breaking`，即熔断，和 `fielddata` 有关，而根源是 `_uid` 字段。

下面简单介绍 `fielddata` 的内容。


# 入门指引


`feilddata` 含义：。


Elasticsearch

相关配置：。


接口查看示例：。

配图。


# 备注


关于 `fielddata` 的官网链接：[fielddata](https://www.elastic.co/guide/en/elasticsearch/reference/5.6/fielddata.html) 。

如果执行的查询刚好遇到熔断，会返回到客户端异常：

```
{
    "error": "... CircuitBreakingException[[FIELDDATA] Data too large, data for [proccessDate] would be larger than limit of [12759701913/11.8gb]]; }]",
    "status": 500
}
```


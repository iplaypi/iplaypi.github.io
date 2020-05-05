---
title: Elasticsearch 的 fielddata 入门指引
id: 2020050101
date: 2020-05-01 17:06:06
updated: 2020-05-01 17:06:06
categories: 大数据技术知识
tags: [Elasticsearch,fielddata,aggregations,JVM]
keywords: Elasticsearch,fielddata,aggregations,JVM
---


昨天查看 `Elasticsearch` 集群监控，发现有几个 `Elasticsearch` 节点的 `JVM Heap` 异常，上下波动非常频繁，进一步查看 `GC`，发现 `Full GC` 非常频繁，每分钟达到5-10次，而累加耗时有10-20秒，也就是说有17%-33%的时间都在做 `Full GC`，这显然是不健康的。

进一步查看 `CPU` 使用情况，发现 `CPU` 使用率由正常的20%左右，达到现在的50%-70%，这也是不正常的。

排查方向是看是否有大量的 `aggregations` 请求或者排序 `sort` 操作，这种情况才会造成大量的内存占用【`fielddata` 缓存】。当然其它情况也有可能，但概率低【例如大查询，`query` 语句复杂，数据量大】，具体情况需要具体对待。排查的过程就不说了，由此做引子，先简单对 `fielddata` 缓存做入门指引。

首先声明，本文记录的内容是 `fielddata` 缓存数据、熔断器，不是 `text` 开启 `fielddata` 属性那种含义，给出3个链接：[modules-fielddata](https://www.elastic.co/guide/en/elasticsearch/reference/5.6/modules-fielddata.html)、[circuit-breaker](https://www.elastic.co/guide/en/elasticsearch/reference/5.6/circuit-breaker.html)、[cluster-nodes-stats](https://www.elastic.co/guide/en/elasticsearch/reference/5.6/cluster-nodes-stats.html) 。


<!-- more -->


# 问题引入


昨天将要迎来小长假，仔细看了一眼 `Elasticsearch` 集群的监控，发现某几个 `Elasticsearch` 节点的 `CPU` 使用率、`JVM` 内存的指标都有异常，初步排查下来和 `aggregations` 请求有关，而根本原因和 `fielddata` 缓存有关。

异常的监控

![CPU 使用率](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2020/20200506014112.png "CPU 使用率")

![Full GC 次数](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2020/20200506014105.png "Full GC 次数")

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

![频繁 Full GC](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2020/20200506014039.png "频繁 Full GC")

日志中显示的 `breaking`，即熔断，和 `fielddata` 缓存有关，而根源是 `_uid` 字段。

下面简单介绍 `fielddata` 缓存的内容。


# 入门指引


## 含义

`feilddata` 缓存的含义：`Elasticsearch` 节点在处理 `aggregations`、`sort`、自定义脚本等请求时，为了快速计算，需要把相关的值全部加载到 `JVM` 的内存中，而且一般情况下不会释放。

原文：

> The field data cache is used mainly when sorting on or computing aggregations on a field. It loads all the field values to memory in order to provide fast document based access to those values. The field data cache can be expensive to build for a field, so its recommended to have enough memory to allocate it, and to keep it loaded.

如果对一个多值的字段做此操作，必然需要很大的内存，例如极端一点的 `id` 字段【值唯一，多少条数据也就有多少个值】、时间戳字段【值的可能性很多】。

其实，这种数据就是正排索引，刚好与 `Elasticsearch` 的倒排索引相反，它不是为了快速检索，而是为了计算值的分布、排序。

## 相关配置

提示：这些配置大部分可以通过 `put` 的方式更新到 `Elasticsearch` 集群，立即生效。

1、`indices.fielddata.cache.size`，字段可以占用缓存的最大值，默认无边界。如果这里不手动设置，建议把熔断器设置好，否则集群在大量的 `aggregations` 请求下很容易挂掉。

官方解释：

> The max size of the field data cache, eg 30% of node heap space, or an absolute value, eg 12GB. Defaults to unbounded.

注意：这个是静态设置，必须在 `Elasticsearch` 群集中的每个数据节点上进行配置，所以无法实时更新。建议设置时取值比 `indices.breaker.fielddata.limit` 稍小，否则这个参数也就没有意义了【到达 `indices.breaker.fielddata.limit` 已经被熔断了】。

2、`indices.breaker.fielddata.limit`，`fielddata` 占用内存的熔断器，超过后出发垃圾回收机制，回收内存。

> Limit for fielddata breaker, defaults to 60% of JVM heap

`indices.breaker.fielddata.overhead`，一个系数【我也没搞明白，大概是内存占用估算时需要乘以它】。

> A constant that all field data estimations are multiplied with to determine a final estimation. Defaults to 1.03

3、`indices.breaker.total.limit`，总的内存限制，它可以保护所有的请求、处理过程。

> Starting limit for overall parent breaker, defaults to 70% of JVM heap.

4、其它几个相关参数。

- `indices.breaker.request.limit`，请求的内存占用限制
- `indices.breaker.request.overhead`，与上面那个参数相关的系数
- `network.breaker.inflight_requests.limit`，处理请求的内存占用限制
- `network.breaker.inflight_requests.overhead`，与上面那个参数相关的系数

## 接口查看示例

可以从不同的角度查看。

```
查看所有的
GET /_cat/fielddata
过滤字段的
GET /_cat/fielddata?v&fields=uid&pretty

# Fielddata summarised by node
GET /_nodes/stats/indices/fielddata?fields=field1,field2

# Fielddata summarised by node and index
GET /_nodes/stats/indices/fielddata?level=indices&fields=field1,field2

# Fielddata summarised by node, index, and shard
GET /_nodes/stats/indices/fielddata?level=shards&fields=field1,field2

# You can use wildcards for field names
GET /_nodes/stats/indices/fielddata?fields=field*
```

下面给出2种查询示例

![stats 查看](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2020/20200506013927.png "stats 查看")

![cat 查看](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2020/20200506013952.png "cat 查看")


# 备注


1、关于熔断的异常。

如果执行的查询刚好遇到熔断，会返回到客户端异常：

```
{
    "error": "... CircuitBreakingException[[FIELDDATA] Data too large, data for [proccessDate] would be larger than limit of [12759701913/11.8gb]]; }]",
    "status": 500
}
```

2、关于 `fielddata` 属性【不是本文描述的 `fielddata` 缓存】。

关于 `text` 类型字段的 `fielddata` 解释，官网链接：[fielddata](https://www.elastic.co/guide/en/elasticsearch/reference/5.6/fielddata.html) 。

如果对没有开启 `fielddata` 属性的 `text` 字段执行聚合、排序等操作，会抛出异常：

```
Fielddata is disabled on text fields by default. Set fielddata=true on [your_field_name] in order to load fielddata in memory by uninverting the inverted index. Note that this can however use significant memory.
```

类型有 `paged_bytes`【默认的】、`fst`、`doc_values` 等几种。


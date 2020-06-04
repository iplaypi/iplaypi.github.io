---
title: Elasticsearch 集群管理基础知识
id: 2020-06-01 00:24:04
date: 2020-06-01 00:24:04
updated: 2020-06-01 00:24:04
categories:
tags:
keywords:
---


2020053101
Elasticsearch
大数据技术知识


对于 `Elasticsearch` 集群的管理，首先需要的基础知识有：节点角色、集群规模、脑裂问题、索引分片个数、分片大小等等，本文记录一些相关建议。


<!-- more -->


# 节点角色


候选节点

`Master Eligible Node` 候选主节点。


设置成 `node.master=true` 都可能会被选举为主节点。


```
node.master: true
node.data: false
node.ingest: false
```

主节点


由候选主节点选举出来的，负责管理 `Elasticsearch` 集群，通过广播的机制与其它节点维持关系，负责集群中的 `DDL` 操作【创建、删除索引】，管理其他节点上的分片【`shard`】。


关于 `Master` 节点的脑裂问题，候选主节点之间出现了网络问题则可能会出现集群脑裂的情况，导致数据不一致或者数据丢失。我们可以通过设置 `discovery.zen.minimum_master_nodes` 参数为 `master_eligible_nodes / 2 + 1` 避免掉这个问题，弊端就是当候选主节点数由于宕机等不确定因素导致少于 `master_eligible_nodes / 2 + 1` 的话，集群将无法正常运作下去。


数据节点


`Data Node`，数据节点，这个很好理解，即存放数据的节点，负责数据的增删改查 `CRUD`。

```
node.master: false
node.data: true
node.ingest: false
```

提取节点


`Ingest Node`，提取节点，能执行预处理管道，有自己独立的任务要执行，类似于 `logstash` 的功能，不负责数据也不负责集群相关的事务。


```
node.master: false
node.data: false
node.ingest: true
```

协调节点

`Coordinating Node`，协调节点，每一个节点都是一个潜在的协调节点，且不能被禁用，协调节点最大的作用就是将各个分片里的数据汇集起来一并返回给客户端，因此 `Elasticsearch` 的节点需要有足够的 `CPU` 和内存去处理协调节点的 `gather` 阶段。

# 线程类型


写入、索引、查询、拉取


并发大小，队列长度



线程池的类型：

cached  无限制的线程池，为每个请求创建一个线程。这种线程池是为了防止请求被阻塞或者拒绝，其中的每个线程都有一个超时时间(`keep_alive`)，默认5分钟，一旦超时就会回收终止。

`v5.x` 之后被取消。

fixed  有着固定大小的线程池，大小由size属性指定，默认是`5*cores`数，允许你指定一个队列（使用`queue_size`属性指定，默认是-1，即无限制）用来保存请求，直到有一个空闲的线程来执行请求。如果Elasticsearch无法把请求放到队列中（队列满了），该请求将被拒绝。

scaling  可变大小的pool，大小根据负载在1到size间，同样`keep_alive`参数指定了闲置线程被回收的时间。


参考：[modules-threadpool](https://www.elastic.co/guide/en/elasticsearch/reference/5.6/modules-threadpool.html) 。


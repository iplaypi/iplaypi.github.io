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



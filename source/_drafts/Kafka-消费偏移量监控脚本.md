---
title: Kafka 消费偏移量监控脚本
id: 2020-05-08 00:45:30
date: 2020-05-07 00:45:30
updated: 2020-05-08 00:45:30
categories:
tags:
keywords:
---


2020050701
大数据基础知识
Kafka,Shell


利用 `Shell` 脚本，做一个简单的消费偏移量监控功能，当数据积压过多时，发送信息。


<!-- more -->


# 入门知识


待整理


# 脚本内容


有时候由于开发环境的原因【没有配置客户端脚本、无法直接连接 `Kafka`】，可能无法直接使用 `Kafka` 的 `Shell` 脚本：`kafka-consumer-offset-checker.sh`，此时迫不得已可以使用 `kafka-run-class.sh kafka.tools.ConsumerOffsetChecker`，直接运行 `Java` 类。

```
./bin/kafka-consumer-offset-checker.sh --zookeeper localhost:2181 --topic your_topic --group your_group
```

也是的：

```
kafka-run-class.sh kafka.tools.ConsumerOffsetChecker --zkconnect localhost:2181 --topic your_topic --group your_group
```

待整理


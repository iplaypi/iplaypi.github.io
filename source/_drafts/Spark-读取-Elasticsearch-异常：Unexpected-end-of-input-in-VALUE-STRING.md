---
title: Spark 读取 Elasticsearch 异常：Unexpected end-of-input in VALUE_STRING
id: 2020-01-15 01:59:18
date: 2020-01-15 01:59:18
updated: 2020-01-15 01:59:18
categories:
tags:
keywords:
---


2019102001
Spark,Elasticsearch,Hadoop
大数据技术知识


<!-- more -->


以前也遇到过，但是由于事情紧急，没有仔细排查，重跑成功之后就抛在了脑后。今天再次遇到这个问题，并且重跑了两次还是重复出现，直到重跑第三次才正常。

后来晚上有时间，接着重跑测试，发现偶尔可以复现，这就引起了我的兴趣，让我们共同来看一下源代码吧。


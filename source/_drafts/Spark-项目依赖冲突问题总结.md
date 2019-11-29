---
title: Spark 项目依赖冲突问题总结
id: 2019-11-29 20:05:46
date: 2019-11-29 20:05:46
updated: 2019-11-29 20:05:46
categories:
tags:
keywords:
---

2019112901
大数据基础知识
Spark,Maven,shade







我在一年前也遇到过一种简单的场景：[Spark Kryo 异常](https://www.playpi.org/2018100801.html)，直接通过排除依赖就解决问题了，但是这次的场景太复杂，只能启用 `maven-shade-plugin` 插件了。


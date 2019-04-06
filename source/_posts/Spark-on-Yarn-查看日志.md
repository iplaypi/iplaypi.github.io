---
title: Spark on Yarn 查看日志
id: 2018120702
date: 2018-12-07 02:06:20
updated: 2018-12-07 02:06:20
categories: 基础技术知识
tags: [Spark,Yarn,日志查看]
keywords: Spark on Yarn,日志查看,Spark log,Yarn log
---

一直一来都是直接在 Yarn 的 UI 界面上面查看 Spark 任务的日志的，感觉看少量的内容还勉强可以，但是如果内容很多，浏览器就没法看了，更没法分析。本文讲述如何使用 Yarn 自带的命令在终端查看 Spark 任务的日志，也可以拷贝出日志文件，便于分析。

<!-- more -->

1、查看某个 Spark 任务的日志，使用 logs 入口：
```bash
yarn logs -applicationId application_1542870632001_26426
```
如果日志非常多，直接看会导致刷屏，看不到有用的信息，所以可以重定向到文件中，再查看文件：
```bash
yarn logs -applicationId application_1542870632001_26426 > ./application.log
```

2、查看某个 Spark 任务的状态，使用 application 入口：
```bash
yarn application -status application_1542870632001_26426
```
同时也可以看到队列、任务类型、日志链接等详细信息
![查看状态](https://ws1.sinaimg.cn/large/b7f2e3a3gy1fxxloh9spej20uo0auaas.jpg "查看状态")

3、kill 掉某个 Spark 任务，有时候是直接在 Driver 端 kill 掉进程，然后 Yarn 的 Spark 任务也会随之失败，但是这种做法是不妥的。其实 kill 掉 Spark 任务有自己的命令：
```bash
yarn application -kill application_1542870632001_26426
```

4、需要注意的是，步骤1中去查看日志，要确保当前 HADOOP_USER_NAME 用户是提交 Spark 任务的用户，否则是看不到日志的，因为日志是放在 HDFS 对应的目录中的，其中路径中会有用户名。此外，步骤1中的日志要等 Spark 任务运行完了才能看到，否则日志文件不存在（还没收集到 HDFS 中）。

在 Linux 环境中可以使用 **export HADOOP_USER_NAME=xxx** 临时伪装用户。


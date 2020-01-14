---
title: 别再使用 SimpleDateFormat
id: 2020-01-06 01:13:43
date: 2020-01-06 01:13:43
updated: 2020-01-06 01:13:43
categories:
tags:
keywords:
---

2019022801
基础技术知识
SimpleDateFormat,Java,DateTimeFormatter,Thread

最近在一个项目中遇到了时间转换的异常现象，在做数据清洗的时候，把毫秒时间戳转换为格式化的字符串：`yyyy-MM-dd`，同时也抽取年份数字，例如：`1990,2000,2017`。结果发现有很多异常的取值，例如：`1、10、1900、1199`，但是查看它们对应的毫秒时间戳，是正常的，这就说明在转换过程中出现了问题。

进一步查看，我发现代码中使用的日期转换类是 `SimpleDateFormat`，而且是并发程序，我一下就明白了，这肯定是在多线程环境中 `SimpleDateFormat` 引发的问题，因为 `SimpleDateFormat` 根本就不能在多线程环境中使用，会引发 `bug`。

本文就使用代码示例演示在多线程环境下使用 `SimpleDateFormat` 会出现什么问题，读者看到后抓紧把项目中的 `SimpleDateFormat` 去掉吧，转换为 `Java 8` 的 `DateTimeFormatter`，如果实在不升级，就自己加锁吧，否则以后必定会引发问题【确定是单线程可以忽略】。


<!-- more -->


提前说明，下文中涉及的代码已经被我上传至 `GitHub`：[源代码](xx)，读者可以提前下载查看。


# 问题出现


时间转换问题

怀疑是多线程；

在处理美妆库字段缺失问题时，在Spark算子中获取时间戳（正常），转换获取年份，得到的有大量的错误时间；

获取日期字符串，yyyy-MM-dd；

使用 SIMPLE_DATE_FORMAT 转成 Date，再使用另一个 SIMPLE_DATE_FORMAT （yyyy）转成字符串，结果得到的结果多种多样，明显是一些错误的值，例如：1、10、1900、11990101 ；

最后先改为字符串截取，截取前4位；


# 代码演示


待定。


# 备注


抓紧使用 `Java 8` 的 `DateTimeFormatter`，不仅适合多线程，并且增加了很多接口，很好用。

关于 `DateTimeFormatter` 的简单使用，读者可以参考我的另外一篇博客：[DateTimeFormatter 简单使用示例](https://www.playpi.org/20200103.html) 。


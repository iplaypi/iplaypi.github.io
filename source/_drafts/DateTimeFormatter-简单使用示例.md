---
title: DateTimeFormatter 简单使用示例
id: 2020-01-06 00:53:34
date: 2020-01-06 00:53:34
updated: 2020-01-06 00:53:34
categories:
tags:
keywords:
---


2020010301
基础技术知识
Java,DateTimeFormatter,LocalDate,LocalDateTime

在 `Java 7` 以及以前的版本，实现日期格式化都是使用 `SimpleDateFormat` 类，但是这个类有多线程的问题，具体可以参考我以前的一篇博文：[多线程问题](xx.yy.zz)。而且，这个 `SimpleDateFormat` 类不好用，有很多接口都没有，还需要自己实现，很麻烦，这时候也可以使用第三方类库 `joda`，里面关于时间、日期的工具类很好用。

当然，如果升级到 `Java 8` 以及以上版本，就可以使用全新的 `Java` 官方类库：`java.time`，里面关于时间、日期的类很好用，类似于 `joda`，其实官方真的是邀请 `joda` 共同开发的。、

而我在使用其中的 `DateTimeFormatter` 类进行格式化转换时，最近遇到了一个小问题，通过查询文档解决了问题，我觉得很有意义，值得读者参考。

提前说明，下文中所使用的代码已经被我上传至 `GitHub`：[源代码](xx)，读者可以直接下载查看。


<!-- more -->


# 问题出现


出现转换异常。


# 问题解决


原来是格式化字符串声明不对，不能使用年代，要使用年份。


# 备注


`LocalDate`、`LocalDateTime` 之间的区别，不可乱用。

还有一些好用的接口，例如增加一天，减少一天。

简单描述关于时区的使用。


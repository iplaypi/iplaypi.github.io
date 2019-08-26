---
title: Elasticsearch 异常之 too many open files
id: 2019-08-26 21:15:08
date: 2018-07-09 21:15:08
updated: 2019-08-26 21:15:08
categories:
tags:
keywords:
---
目前在项目中使用 `Elasticsearch` 的 `Java API` 进行连接集群、发送请求、解析结果，某一次发生了异常，异常信息如下：

```
java.net.SocketException: Too many open files
  at java.net.Socket.createImpl(Socket.java:460)
  at java.net.Socket.connect(Socket.java 587)
  at sun.net.NetworkClient.doConnect(NetworkClient.java 175)
  at sun.net.www.http.HttpClient.openServer(HttpClient.java 463)
  at sun.net.www.http.HttpClient.openServer(HttpClient.java 558)
  at sun.net.www.http.HttpClient.<init>(HttpClient.java 242)
  at sun.net.www.http.HttpClient.New(HttpClient.java 339)
  at sun.net.www.http.HttpClient.New(HttpClient.java 357)
  at sun.net.www.protocol.http.HttpURLConnection.getNewHttpClient(HttpURLConnection.java 1220)
  sun.net.www.protocol.http.HttpURLConnection.plainConnect0(HttpURLConnection.java 1156)
  sun.net.www.protocol.http.HttpURLConnection.plainConnect(HttpURLConnection.java 1050)
  sun.net.www.protocol.http.HttpURLConnection.connect(HttpURLConnection.java 984)
  sun.net.www.protocol.http.HttpURLConnection.getOutputStream0(HttpURLConnection.java 1334)
  sun.net.www.protocol.http.HttpURLConnection.getOutputStream(HttpURLConnection.java 1309)
```

看异常信息里面的重点：`java.net.SocketException: Too many open files`，有时候在中文环境下会显示：`打开的文件过多`，其实是一个意思。本文介绍遇到此问题、分析解决的方法，开发环境基于 `Elasticsearch v1.7`【这是一个古老的版本】、`JDK v1.8`，其它的版本的报错详细信息可能会大同小异，但是主要异常信息是一致的。


<!-- more -->


# 问题出现


2018070901
大数据技术知识
Elasticsearch,Java


日志信息

图。。

这里看不到具体的出错位置，需要跟踪找到业务代码，发现是在创建 `TransportClient` 连接的时候，代码已经放在 `GitHub`，详见：(xx)[xx]，搜索 `xxUtil` 类即可，仅供参考。

可以看到，这里不是单例模式，会创建大量的链接，如果没有及时关闭，有潜在的危险。顺着这个思路继续找下去。的确，在业务中会创建大量的连接，然后请求 `Elasticsearch` 集群，更为奇葩的是，使用完成后也没有关闭 `TransportClient` 连接，而是不管不问，让它自生自灭。

这样怎么能行，肯定会有大量连接没有关闭，占用着 `Elasticsearch` 集群的资源。

`Elasticsearch` 的 `TransportClient` 对象使用完成后，要及时关闭，不能占用着连接不使用但是又不关闭，这样肯定是给 `Elasticsearch` 集群造成压力，等到连接数达到最大时，`Elasticsearch` 集群也就会一直报错：打开的文件过多。

加大系统的文件句柄配置不是根本解决办法，只是滋养了烂代码的生存空间，最终还是会重现问题。最好的方式当然是把生成 `TransportClient` 的方法改成单例模式，或者使用完成后及时关闭连接，简单正确，可以永久解决此问题。


---
title: 写入 Elasticsearch 异常：413 Request Entity Too Large
id: 2019122901
date: 2019-12-29 23:53:41
updated: 2019-12-29 23:53:41
categories: 大数据技术知识
tags: [Elasticsearch,HTTP,RestHighLevelClient]
keywords: Elasticsearch,HTTP,RestHighLevelClient
---


在一个非常简单的业务场景中，偶尔出现异常：`413 Request Entity Too Large`，业务场景是写入数据到 `Elasticsearch` 中，异常日志中还有 `Nginx` 字样。

本文记录排查过程，本文环境基于 `Elasticsearch v5.6.8`，使用的写入客户端是 `elasticsearch-rest-high-level-client-5.6.8.jar`。


<!-- more -->


# 问题出现


在后台日志中，发现异常信息：

```
19/12/29 23:06:41 ERROR ESBulkProcessor: bulk [2307 : 1577632001467] 1000 request - 0 response - Unable to parse response body
ElasticsearchStatusException[Unable to parse response body]; nested: ResponseException[POST http://your_ip_address:9200/_bulk?timeout=1m: HTTP/1.1 413 Request Entity Too Large
<html>
<head><title>413 Request Entity Too Large</title></head>
<body>
<center><h1>413 Request Entity Too Large</h1></center>
<hr><center>nginx/1.16.1</center>
</body>
</html>
];
	at org.elasticsearch.client.RestHighLevelClient.parseResponseException(RestHighLevelClient.java:506)
	at org.elasticsearch.client.RestHighLevelClient$1.onFailure(RestHighLevelClient.java:477)
	at org.elasticsearch.client.RestClient$FailureTrackingResponseListener.onDefinitiveFailure(RestClient.java:605)
	at org.elasticsearch.client.RestClient$1.completed(RestClient.java:362)
	at org.elasticsearch.client.RestClient$1.completed(RestClient.java:343)
	at org.apache.http.concurrent.BasicFuture.completed(BasicFuture.java:115)
	at org.apache.http.impl.nio.client.DefaultClientExchangeHandlerImpl.responseCompleted(DefaultClientExchangeHandlerImpl.java:173)
	at org.apache.http.nio.protocol.HttpAsyncRequestExecutor.processResponse(HttpAsyncRequestExecutor.java:355)
	at org.apache.http.nio.protocol.HttpAsyncRequestExecutor.inputReady(HttpAsyncRequestExecutor.java:242)
	at org.apache.http.impl.nio.client.LoggingAsyncRequestExecutor.inputReady(LoggingAsyncRequestExecutor.java:87)
	at org.apache.http.impl.nio.DefaultNHttpClientConnection.consumeInput(DefaultNHttpClientConnection.java:264)
	at org.apache.http.impl.nio.client.InternalIODispatch.onInputReady(InternalIODispatch.java:73)
	at org.apache.http.impl.nio.client.InternalIODispatch.onInputReady(InternalIODispatch.java:37)
	at org.apache.http.impl.nio.reactor.AbstractIODispatch.inputReady(AbstractIODispatch.java:113)
	at org.apache.http.impl.nio.reactor.BaseIOReactor.readable(BaseIOReactor.java:159)
	at org.apache.http.impl.nio.reactor.AbstractIOReactor.processEvent(AbstractIOReactor.java:338)
	at org.apache.http.impl.nio.reactor.AbstractIOReactor.processEvents(AbstractIOReactor.java:316)
	at org.apache.http.impl.nio.reactor.AbstractIOReactor.execute(AbstractIOReactor.java:277)
	at org.apache.http.impl.nio.reactor.BaseIOReactor.execute(BaseIOReactor.java:105)
	at org.apache.http.impl.nio.reactor.AbstractMultiworkerIOReactor$Worker.run(AbstractMultiworkerIOReactor.java:584)
	at java.lang.Thread.run(Thread.java:748)
	Suppressed: java.lang.IllegalStateException: Unsupported Content-Type: text/html
		at org.elasticsearch.client.RestHighLevelClient.parseEntity(RestHighLevelClient.java:523)
		at org.elasticsearch.client.RestHighLevelClient.parseResponseException(RestHighLevelClient.java:502)
		... 20 more
Caused by: org.elasticsearch.client.ResponseException: POST http://your_ip_address:9200/_bulk?timeout=1m: HTTP/1.1 413 Request Entity Too Large
<html>
<head><title>413 Request Entity Too Large</title></head>
<body>
<center><h1>413 Request Entity Too Large</h1></center>
<hr><center>nginx/1.16.1</center>
</body>
</html>

	at org.elasticsearch.client.RestClient$1.completed(RestClient.java:354)
	... 17 more
```

![异常信息](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20191230002704.jpg "异常信息")

留意重点内容：

```
<html>
<head><title>413 Request Entity Too Large</title></head>
<body>
<center><h1>413 Request Entity Too Large</h1></center>
<hr><center>nginx/1.16.1</center>
</body>
</html>
```

看起来是发送的 `HTTP` 请求的请求体【`body`】过大，超过了服务端 `Nginx` 的配置，导致返回异常。

这个请求体过大，本质上还是将要写入 `Elasticsearch` 的文档过大，可见是某个字段的取值过大【这种情况一般都是异常数据导致的，例如采集系统把整个网页的内容全部抓回来作为正文，或者把网站反扒的干扰长文本全部抓回来作为正文】。

但是我又不禁想，这个配置参数名是什么呢？限制的最大字节数是多少呢？


# 问题排查解决


在 `Elasticsearch` 官网查看相关配置项，发现有一个参数：`http.max_content_length`，表示一个 `HTTP` 请求的内容大小上限，默认为 `100MB`【对于 `v5.6` 来说】。

官网地址：[elasticsearch 关于 HTTP 的配置](https://www.elastic.co/guide/en/elasticsearch/reference/5.6/modules-http.html) ，以下为参数说明：

>The max content of an HTTP request. Defaults to 100mb. If set to greater than Integer.MAX_VALUE, it will be reset to 100mb.

![HTTP 相关配置](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20191230005435.jpg "HTTP 相关配置")

这个参数是配置在 `elasticsearch.yml` 配置文件中的，我查看了我使用的 `Elasticsearch` 集群中对应的配置，没有发现参数的设置，说明使用了默认配置。

其实，`100MB` 对于文本来说很大了，一般正常的文本也不过只有几 `KB` 大小，对于长一点的文本来说，例如几万个字符，也就是几百 `KB`。由于写入 `Elasticsearch` 是批量的，1000条数据一批，如果一批里面包含的全部是长文本，还是有可能超过 `100MB` 的，可见调整 `HTTP` 请求大小的上限是有必要的，或者是降低批次的数据量【会影响写入性能】。

此外，关于 `HTTP` 的另外两个参数也值得关注：`http.max_initial_line_length`、`http.max_header_size`。

前者表示 `HTTP` 请求链接的长度，默认为 `4KB`：

>The max length of an HTTP URL. Defaults to 4kB

后者表示 `HTTP` 请求头的大小上限，默认为 `8KB`：

>The max size of allowed headers. Defaults to 8kB


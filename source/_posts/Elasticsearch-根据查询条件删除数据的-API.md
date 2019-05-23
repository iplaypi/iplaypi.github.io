---
title: Elasticsearch 根据查询条件删除数据的 API
id: 2018022401
date: 2018-02-24 21:41:37
updated: 2019-05-22 21:41:37
categories: 大数据技术知识
tags: [Elasticsearch,API,delete]
keywords: Elasticsearch,API,delete
---


在使用 Elasticsearch 的时候，有时候免不了存入了一些脏数据，或者多余的数据，此时如果想把这部分数据删除，第一时间想到的就是删除接口，类似于关系型数据库中的 **delete** 操作。尽管**删除**这个操作在 IT 的世界里是大忌，甚至**从删库到跑路**这句话早已经成为了段子，但是只要控制好流程，经过多人审核，并做好备份，必要的时候删除这个操作还是要出场的。好，言归正传，本文记录 Elasticsearch 中的删除接口的使用，以及不同版本之间的差异。


<!-- more -->


# 网络接口


这里的网络接口其实就是指 HTTP 的 RESTful 接口，优点就是接口稳定，各版本不会有差别，兼容多种编程语言的调用，只要能发送 HTTP 请求即可，缺点就是返回的数据结果是原生的 Elasticsearch 数据，需要调用方自己解析处理。

好，关于接口的情况不再多做解释，直接进入正题，怎么删除数据。不得不再多解释一点，关于 Elasticsearch 的删除数据接口在不同版本之间有变化。

- 在 1.x 的版本中，可以直接使用 **DELETE** 请求加上 **\_query** 查询语句来删除数据
- 在 2.x 的版本中，此功能被从 core 中移除，单独作为插件使用，因为官方认为可能会引发一些错误，如果需要使用，安装插件即可：**bin/plugin install delete-by-query**，使用方式与上述一致
- 在 5.x 的版本中，此功能又回归到 core，无需安装插件，但是使用方式变化了，是使用 **POST** 请求加上 **\_delete\_by\_query** 查询语句来删除数据

下面直接举例说明：

1、在 1.x、2.x 的版本中，发送的是 **DELETE** 请求，并且使用 **\_query** 关键字。

```
DELETE 主机地址/删除数据的索引名/删除数据的索引type/_query
{
    "query": {
        "match_all": {}
    }
}
```

2、在 5.x 的版本中，发送的是 **POST** 请求，并且使用 **\_delete\_by\_query** 关键字。

```
POST 主机地址/删除数据的索引名/删除数据的索引type/_delete_by_query
{
    "query": {
        "match_all": {}
    }
}
```

我这里为了代码简洁，查询条件设置的为 **match_all**，会命中所有数据，因此会删除指定索引 type 下的所有数据。如果只是删除部分数据，只要指定自己的查询条件即可，例如删除用户索引下 uid 为特定值的数据【以 5.2 版本语法演示】。

```
POST 主机地址/用户的索引名/用户的索引type/_delete_by_query
{
    "query": {
        "terms": {
            "uid": [
                "uid1",
                "uid2",
                "uid2"
            ]
        }
    }
}
```

返回的数据格式如下，包含删除记录条数、消耗时间等信息：

```
{
  "took" : 147,
  "timed_out": false,
  "deleted": 119,
  "batches": 1,
  "version_conflicts": 0,
  "noops": 0,
  "retries": {
    "bulk": 0,
    "search": 0
  },
  "throttled_millis": 0,
  "requests_per_second": -1.0,
  "throttled_until_millis": 0,
  "total": 119,
  "failures" : [ ]
}
```


# 客户端接口


这里的客户端接口就是官方或者社区开发的适配各个编程语言的接口，它和 RESTful 接口相匹配，但是必须写代码实现查询或者取数的操作，例如：Java、Python、Go 等。这种接口的优点是不用担心使用出错【例如在 HTTP 中，参数构造错误导致请求失败】，只要按照接口写代码，请求的构造过程按照官方提供的接口来就行，而且，请求的数据结果是被封装为实体的，不需要额外解析数据结构，直接使用即可。但是，有时候优点也是缺点，由于接口过于死板，导致多版本之间不兼容，例如 1.x 和 2.x 之间的 TransportClient 生成方式就不兼容，导致一份代码只能请求一个版本的 Elasticsearch 集群，此时对于多版本 Elasticsearch 集群之间的请求则无能为力。

好，直接进入正题，给出删除数据的示例，直接使用 5.1.1 版本的示例，其它的请参考文末的官方文档【此外还可以根据 client 指定 id 进行单条删除，不属于根据查询条件删除的范畴，不再赘述】，这个操作如果耗时很长，还会有异步的问题，也可以参考官方文档。此处需要特别注意 5.1、5.6之间的使用方式也略有不同，具体以官方文档为准，我就被坑了，例如 BulkIndexByScrollResponse、BulkByScrollResponse。

```
BulkIndexByScrollResponse response =
                DeleteByQueryAction.INSTANCE.newRequestBuilder(client)
                        .filter(QueryBuilders.matchQuery("uid", "uid1"))
                        .filter(QueryBuilders.typeQuery("需要删除的索引类型"))
                        .source("需要删除的索引名称")
                        .get();
// 返回删除的行数
long deleted = response.getDeleted();
```

注意如果是 2.x 版本是不支持删除的，但是可以更新，如果更新还需要增加相关依赖：

```
<dependency>
    <groupId>org.elasticsearch.module</groupId>
    <artifactId>reindex</artifactId>
    <version>2.3.2</version>
</dependency>
```

上面的删除代码示例中用到了 client 变量，其实就是 TransportClient 的实例，下面再给出不同版本 Elasticsearch 的 TransportClient 初始化方式【需要注意，访问不同版本的 Elasticsearch 集群，需要依赖不同版本的 org.elasticsearch 官方包，而且特别要注意 5.x 版本的还需要额外的 transport 依赖包】。

1、1.7.5 版本，需要集群名字、主机名、tcp 端口等信息。

```
Settings settings = ImmutableSettings.settingsBuilder()
                .put("cluster.name", "your_cluster_name")
                .put("client.transport.ping_timeout", "60s")
                .put("client.transport.sniff", true)
                .put("discovery.zen.fd.ping_retries", 5)
                .build();
String[] hostArr = new String[]{"hostname1:port", "hostname2:port", "hostname3:port"};
TransportAddress[] transportAddresses = new InetSocketTransportAddress[hostArr.length];
TransportClient client = new TransportClient(settings);
for (int i = 0; i < hostArr.length; i++) {
	String[] parts = hostArr[i].split(":");
	try {
		InetAddress inetAddress = InetAddress.getByName(parts[0]);
		transportAddresses[i] = new InetSocketTransportAddress(inetAddress, Integer.parseint(parts[1]));
	}
	catch (UnknownHostException e) {
	}
}
client = client.addTransportAddresses(transportAddresses);
```

2、2.3.2 版本，需要集群名字、主机名、tcp 端口等信息，生成方式与 1.7.5 版本的略有不同。

```
Settings settings = Settings.settingsBuilder()
                .put("cluster.name", "your_cluster_name")
                .put("client.transport.ping_timeout", "60s")
                .put("client.transport.sniff", true)
                .build();
String[] hostArr = new String[]{"hostname1:port", "hostname2:port", "hostname3:port"};
TransportAddress[] transportAddresses = new InetSocketTransportAddress[hostArr.length];
for (int i = 0; i < hostArr.length; i++) {
	String[] parts = hostArr[i].split(":");
	try {
		InetAddress inetAddress = InetAddress.getByName(parts[0]);
		transportAddresses[i] = new InetSocketTransportAddress(inetAddress, Integer.parseint(parts[1]));
	}
	catch (UnknownHostException e) {
	}
}
TransportClient client = TransportClient.builder()
                .settings(settings)
                .build()
                .addTransportAddresses(transportAddresses);
```

3、5.1.1 版本，需要集群名字、主机名、tcp 端口等信息，生成方式与 2.3.2 版本的略有不同，特别要注意 5.1.1 版本的还需要额外的 transport 依赖包，否则找不到 PreBuiltTransportClient 类。

额外的依赖包信息：

```
<dependency>
    <groupId>org.elasticsearch</groupId>
    <artifactId>elasticsearch</artifactId>
    <version>5.1.1</version>
</dependency>
<dependency>
    <groupId>org.elasticsearch.client</groupId>
    <artifactId>transport</artifactId>
    <version>5.1.1</version>
</dependency>
```

代码信息：

```
Settings settings = Settings.builder()
                .put("cluster.name", "your_cluster_name")
                .put("client.transport.ping_timeout", "60s")
                .put("client.transport.sniff", true)
                .build();
String[] hostArr = new String[]{"hostname1:port", "hostname2:port", "hostname3:port"};
TransportAddress[] transportAddresses = new InetSocketTransportAddress[hostArr.length];
for (int i = 0; i < hostArr.length; i++) {
	String[] parts = hostArr[i].split(":");
	try {
		InetAddress inetAddress = InetAddress.getByName(parts[0]);
		transportAddresses[i] = new InetSocketTransportAddress(inetAddress, Integer.parseint(parts[1]));
	}
	catch (UnknownHostException e) {
	}
}
TransportClient client = new PreBuiltTransportClient(settings)
                .addTransportAddresses(transportAddresses);
```


# 参考


参考内容来自于官方文档，注意不同版本有不同的文档，某些内容稍有不同：

- [5.2版本的 Java 接口](https://www.elastic.co/guide/en/elasticsearch/client/java-api/5.2/java-docs-delete-by-query.html)
- [5.2版本的 HTTP 接口](https://www.elastic.co/guide/en/elasticsearch/reference/5.2/docs-delete-by-query.html)


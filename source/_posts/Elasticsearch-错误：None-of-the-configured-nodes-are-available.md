---
title: Elasticsearch 错误：None of the configured nodes are available
id: 2018041301
date: 2018-04-13 20:52:00
updated: 2020-01-14 20:52:00
categories: 大数据技术知识
tags: [Elasticsearch,TransportClient,SearchRequestBuilder]
keywords: Elasticsearch,TransportClient,SearchRequestBuilder
---


在使用 `Elasticsearch` 的 `TransportClient` 的时候，遇到异常：`None of the configured nodes are available`，后来发现是 `Elasticsearch` 集群不稳定，通过增加重试次数的方式解决。本文涉及的开发环境：`Elasticsearch v1.7.5`。


<!-- more -->


# 问题出现


本文中提及的 `Elasticsearch` 版本为 `v1.7.5`，是一个比较陈旧的版本，读者在阅读时可能会发现某些方法与高版本不一样，不用理会。

涉及到的业务场景很简单，就是使用 `TransportClient` 方式去连接 `Elasticsearch` 集群，然后发送请求、获取结果，解析结果后得到需要的数值。

在某一次常规的运行过程中，出现异常：

```
org.elasticsearch.client.transport.NoNodeAvailableException: None of the configured nodes are available: []
    at org.elasticsearch.client.transport.TransportClientNodesService.ensureNodesAreAvailable(TransportClientNodesService.java:305)
    at org.elasticsearch.client.transport.TransportClientNodesService.execute(TransportClientNodesService.java:200)
    at org.elasticsearch.client.transport.support.InternalTransportClient.execute(InternalTransportClient.java:106)
    at org.elasticsearch.client.support.AbstractClient.search(AbstractClient.java:338)
    at org.elasticsearch.client.transport.TransportClient.search(TransportClient.java:430)
    at org.elasticsearch.action.search.SearchRequestBuilder.doExecute(SearchRequestBuilder.java:1112)
    at org.elasticsearch.action.ActionRequestBuilder.execute(ActionRequestBuilder.java:91)
    at org.elasticsearch.action.ActionRequestBuilder.execute(ActionRequestBuilder.java:65)
    ......
```

核心在于 `NoNodeAvailableException: None of the configured nodes are available: []`，无法获取可用的节点，说明无法连接上指定的主机。可能是主机 `ip` 指定错误，也可能是 `Elasticsearch` 集群故障，也可能是网络不好。


# 问题分析解决


如果上面的主机 `ip` 配置正确，就没问题，通过查看配置正确，而且并不是开始运行就失败抛出异常，而是运行一段时间后才抛出异常，说明网络环境，或者 `Elasticsearch` 集群有问题。

其中，生成 `TransportClient` 的代码如下，需要指定 `ip`、集群名称、其它参数：

```
/**
     * 获取Es TransportClient
     *
     * @param clusterName: 集群名
     * @param hosts        : IPs
     * @return
     */
public static TransportClient getEsClient(String clusterName, String hosts) {
	Settings settings = ImmutableSettings.settingsBuilder()
	                .put("cluster.name", clusterName)
	                .put("client.transport.ping_timeout", "120s")
	                .put("discovery.zen.fd.ping_retries", 5)
	                // 嗅探整个集群的状态,不用手动设置集群里所有集群的ip到连接客户端
	.put("client.transport.sniff", true)
	                .build();
	TransportClient client = new TransportClient(settings);
	String[] host = hosts.split(",");
	for (String h : host) {
		String[] vals = h.split(":");
		int port = vals.length > 1 ? Integer.parseint(vals[1]) : 9300;
		client.addTransportAddress(new InetSocketTransportAddress(vals[0], port));
	}
	return client;
}
```

而在抛出异常的地方，代码为：

```
searchRequestBuilder.execute().actionGet(new TimeValue(timeOutMinute * 60 * 1000))
```

`searchRequestBuilder` 来自于 `TransportClient` 对象，代码如下：

```
// boolQueryBuilder 是查询条件对象
SearchRequestBuilder searchRequestBuilder = client.prepareSearch(indexName)
                .setTypes(indexType)
                .clearRescorers()
                .setQuery(boolQueryBuilder)
                .setSize(size);
```

理清代码逻辑后，观察 `Elasticsearch` 集群多次，没发现异常，那就可能是网络问题了，准备加上重试机制。

在 `searchRequestBuilder.execute()` 抛出异常后等待5秒再次重试，最大重试5次。

再次运行程序，观察后仍旧有部分请求会失败，但是由于有等待重试的逻辑，不会影响到业务结果。

这种偶尔的网络问题只能反馈给运维人员排查了。


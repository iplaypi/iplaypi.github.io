---
title: es-hadoop 版本不匹配导致 discoverNodes 异常
id: 2020-02-24 01:04:14
date: 2018-05-29 01:04:14
updated: 2020-02-24 01:04:14
categories:
tags:
keywords:
---


2018052901
踩坑系列
Elasticsearch,elasticsearch-hadoop,Spark,Hadoop


<!-- more -->


# 问题出现


业务中使用的 `elasticsearch-hadoop` 版本为 `v2.1.0`：

```
<dependency> 
  <groupId>org.elasticsearch</groupId>  
  <artifactId>elasticsearch-hadoop</artifactId>  
  <version>2.1.0</version> 
</dependency>
```

图。。

一直都是处理 `Elasticsearch 1.7.5` 的数据，某次临时处理了 `Elasticsearch v2.4.5` 的数据，结果发现异常，`Spark` 进程无法启动：

```
java.lang.StringIndexOutOfBoundsException: String index out of range: -1
at java.lang.String.substring(String.java:1967)
at org.elasticsearch.hadoop.rest.RestClient.discoverNodes(RestClient.java:110)
at org.elasticsearch.hadoop.rest.InitializationUtils.discoverNodesIfNeeded(InitializationUtils.java:58)
at org.elasticsearch.hadoop.rest.RestService.findPartitions(RestService.java:227)
at org.elasticsearch.spark.rdd.AbstractEsRDD.esPartitions$lzycompute(AbstractEsRDD.scala:51)
at org.elasticsearch.spark.rdd.AbstractEsRDD.esPartitions(AbstractEsRDD.scala:50)
at org.elasticsearch.spark.rdd.AbstractEsRDD.getPartitions(AbstractEsRDD.scala:26)
at org.apache.spark.rdd.RDD$$anonfun$partitions$2.apply(RDD.scala:239)
at org.apache.spark.rdd.RDD$$anonfun$partitions$2.apply(RDD.scala:237)
at scala.Option.getOrElse(Option.scala:120)
```

图。。

如果只看 `StringIndexOutOfBoundsException` 异常，发现就是一个普通的下标越界而已，得不到任何有用的信息，毕竟这是 `elasticsearch-hadoop` 框架抛出的，给出这样一个异常，并没有指明常见异常类型【例如网络连接、数据格式不对】，只能顺藤摸瓜去看源代码了。

再看异常栈里面有一个 `RestClient.discoverNodes` 定位，基本可以找到源代码了。


# 问题分析解决


## 源码查看

直接定位到源代码位置：

```
@SuppressWarnings({"rawtypes", "unchecked"})
public List<String> discoverNodes() {
	String endpoint = "_nodes/transport";
	Map<String, Map> nodes = (Map<String, Map>) get(endpoint, "nodes");
	List<String> hosts = new ArrayList<String>(nodes.size());
	for (Map value : nodes.values()) {
		String inet = (String) value.get("http_address");
		if (StringUtils.hasText(inet)) {
			int startIp = inet.indexOf("/") + 1;
			int endIp = inet.indexOf("]");
			inet = inet.substring(startIp, endIp);
			hosts.add(inet);
		}
	}
	return hosts;
}
```

图。。

可以看到这是一个发现节点的方法，结合异常栈里面的 `RestService.findPartitions` 可以猜测这是在读取数据前寻找节点，然后再创建连接。

异常代码是这一行，如上图红框中的：

```
inet = inet.substring(startIp, endIp);
```

截取网络地址从而获取 `ip` 信息，出现异常，说明网络地址格式不对，以至于按照标准方法截取时出现异常。

通过代码中的 `_nodes/transport` 接口【再获取 `http_address` 的值】，我们可以自己看一下集群的信息：

```
localhost:9202/_nodes/transport
```

图。。

可以看到 `http_address` 的值是 `ip:port` 的格式，而在源代码中是通过截取 `/`、`]` 之间的子串来确定 `ip:port` 的值，这显然会造成 `substring` 的异常【`startIp`=0，`endIp`=-1】。

其实，对于 `ip:port` 这种格式的 `http_address` ，应该直接获取值就行了，不需要截取，但是 `v2.1.0` 的 `elasticsearch-hadoop` 还无法考虑到 `Elasticsearch v2.4.5` 的节点格式，毕竟很难做到向后兼容。

那我们再回头看一下 `v1.7.5` 的 `Elasticsearch` 节点信息：

图。。

可以看到 `http_address` 的值是 `inet[/ip:port]` 的格式，这个刚好可以被源码处理。

总而言之，`v2.1.0` 的 `elasticsearch-hadoop` 无法正确读取处理 `Elasticsearch v2.4.5` 的节点信息，所以也就无法处理数据了。

## 升级版本

解决方案也很简单，直接升级 `elasticsearch-hadoop` 的版本即可，找到适配 `Elasticsearch v2.4.5` 的，那干脆配置一个一样的版本：`v2.4.5`。

不妨也来看一看它的源码是怎样的：

```
@SuppressWarnings({ "rawtypes", "unchecked" })
public List<String> discoverNodes() {
	String endpoint = "_nodes/transport";
	Map<String, Map> nodes = (Map<String, Map>) get(endpoint, "nodes");
	List<String> hosts = new ArrayList<String>(nodes.size());
	for (Map value : nodes.values()) {
		String inet = (String) value.get("http_address");
		if (StringUtils.hasText(inet)) {
			hosts.add(StringUtils.parseIpAddress(inet).toString());
		}
	}
	return hosts;
}
```

图。。

可以看到，源码单独重新写了一个方法单独处理 `ip:port` 的信息，想必是考虑了多种情况，接着往下看：

```
public static IpAndPort parseIpAddress(String httpAddr) {
	// strip ip address - regex would work but it's overkill
	// there are four formats - ip:port, hostname/ip:port or [/ip:port] and [hostname/ip:port]
	// first the ip is normalized
	if (httpAddr.contains("/")) {
		int startIp = httpAddr.indexOf("/") + 1;
		int endIp = httpAddr.indexOf("]");
		if (endIp < 0) {
			endIp = httpAddr.length();
		}
		if (startIp < 0) {
			throw new EsHadoopIllegalStateException("Cannot parse http address " + httpAddr);
		}
		httpAddr = httpAddr.substring(startIp, endIp);
	}
	// then split
	int portIndex = httpAddr.lastIndexOf(":");
	if (portIndex > 0) {
		String ip = httpAddr.substring(0, portIndex);
		int port = Integer.valueOf(httpAddr.substring(portIndex + 1));
		return new IpAndPort(ip, port);
	}
	return new IpAndPort(httpAddr);
}
```

图。。

果然，考虑周全，一共四种情况全部考虑到。这样的话，就可以利用 `elasticsearch-hadoop v2.4.5` 愉快地处理各种版本的 `Elasticsearch` 集群里面的数据了。

## 多版本小技巧

在 `Maven` 项目中，如果的确需要应对多版本的 `Elasticsearch` 环境，而又不能同时依赖两个版本的 `elasticsearch-hadoop` 包，那怎么办呢，总不能写两套代码吧，或者至少需要两份 `pom` 文件。

其实，大可不必，`Maven` 中有非常好用的 `profile`功能，可以在编译打包时动态指定激活哪一份配置。

xxx


# 等价的依赖


另外还有一种 `elasticsearch-spark` 依赖，它和 `elasticsearch-hadoop` 一样，添加了对 `Elasticsearch` 并发处理的支持扩展，并且它们大部分的源码是一样的，只不过对于 `Spark SQL` 的版本支持不一致。

```
<dependency> 
  <groupId>org.elasticsearch</groupId>  
  <artifactId>elasticsearch-spark_2.10</artifactId>  
  <version>2.1.0</version> 
</dependency>
```

![es-spark 依赖](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2018/20200224011208.png "es-spark 依赖")

看官网说明是为了支持 `spark SQL` 的，链接：[Supported Spark SQL versions](https://www.elastic.co/guide/en/elasticsearch/hadoop/master/spark.html) 。

> Spark SQL while becoming a mature component, is still going through significant changes between releases. Spark SQL became a stable component in version 1.3, however it is not backwards compatible with the previous releases. Further more Spark 2.0 introduced significant changed which broke backwards compatibility, through the Dataset API. elasticsearch-hadoop supports both version Spark SQL 1.3-1.6 and Spark SQL 2.0 through two different jars: elasticsearch-spark-1.x-\<version>.jar and elasticsearch-hadoop-\<version>.jar support Spark SQL 1.3-1.6 (or higher) while elasticsearch-spark-2.0-\<version>.jar supports Spark SQL 2.0. In other words, unless you are using Spark 2.0, use elasticsearch-spark-1.x-\<version>.jar


# 备注


最好还是升级 `elasticsearch-hadoop` 版本与 `Elasticsearch` 保持一致，例如升级到 `v2.4.5`【与 `Elasticsearch` 版本保持一致】。

但是，`v2.4.5` 版本的 `elasticsearch-hadoop` 自有它的坑【是很严重的 `bug`】，那就是它在处理数据时，会过滤掉中文的字段，导致读取中文字段丢失，影响中间的 `ETL` 处理逻辑。而如果数据处理完成后，再写回去原来的 `Elasticsearch` 索引就悲剧了，采用 `index` 方式会覆盖数据，导致中文字段全部丢失；采用 `update` 方式不会导致数据覆盖。

中文字段丢失问题，只针对某些版本，关于此问题的踩坑记录可以参考我的另外一篇博客：[es-hadoop 读取中文字段丢失问题](https://www.playpi.org/2017102301.html) 。

`Elasticsearch-hadoop v5.x` 版本分散了依赖包的功能，单独拆分出来 `elasticsearch-rest-client` 用于请求相关的功能，类的包名也变为了 `org.elasticsearch.rest`。


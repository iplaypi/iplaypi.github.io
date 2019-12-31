---
title: Elasticsearch 异常之 too many open files
id: 2018070901
date: 2018-07-09 21:15:08
updated: 2018-07-09 21:15:08
categories: 大数据技术知识
tags: [Elasticsearch,Java]
keywords: Elasticsearch,Java
---


目前在 `Java` 项目中普遍使用 `Elasticsearch` 的 `Java API` 进行连接集群、发送请求、解析结果，方便快捷。在某一次运行时发生了异常，异常信息如下：

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
  ...(省略更多业务代码)
  
  备注：以上异常信息实际是因为创建HTTP链接过多，超过了操作系统设置的最大值，这个异常与创建TransportClient过多类似，所以拿它举例，实际排查思路还是以TransportClient为准。
```

查看异常信息里面的重点内容：`java.net.SocketException: Too many open files`，有时候在中文运行系统环境中会显示：`打开的文件过多`，其实是一个意思。

本文介绍遇到此问题后分析、解决的方法，开发环境基于 `Elasticsearch v1.7.5`【这是一个很古老的版本了】、`JDK v1.8`，其它版本的报错详细信息可能会大同小异，但是主要异常信息以及原因是一致的。


<!-- more -->


# 问题出现


首先说明一下业务代码中的相关逻辑，使用 `Elasticsearch` 中的 `TransportClient` 接口连接集群，进行查询操作，`TransportClient` 接口的使用方式可以参考我的另外一篇博文：[Elasticsearch 根据查询条件删除数据的 API](https://blog.playpi.org/2018022401.html) 。

今天启动程序正常运行一段时间后，抛出异常，持续多次，日志内容如下：

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
  ...(省略更多业务代码)
  
  备注：以上异常信息实际是因为创建HTTP链接过多，超过了操作系统设置的最大值，这个异常与创建TransportClient过多类似，所以拿它举例，实际排查思路还是以TransportClient为准。
```

**备注**：以上异常信息实际是因为创建 `HTTP` 链接过多，超过了操作系统设置的最大值，这个异常与创建 `TransportClient` 过多类似，所以拿它举例，实际排查思路还是以 `TransportClient` 为准。

![异常日志](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2018/20191117154740.png "异常日志")

在这里看不到具体的代码出错位置，首先需要跟踪找到业务代码。经过排查，发现是在一个关于 `Elasticsearch` 的工具类中，在创建 `TransportClient` 连接实例的时候，抛出这个异常。

代码已经被我上传至 `GitHub`，详见：[EsClusterUtil.initTransportClient](https://github.com/iplaypi/iplaypistudy/tree/master/iplaypistudy-elasticsearch/src/main/java/org/playpi/study/util) ，搜索类名 `EsClusterUtil` 即可，仅供参考【此代码的书写基于 `Elasticsearch v5.6.8`，与 `v.1.7.5` 略有不同】。

方法代码如下：

```
/**
     * 根据主机端口列表/集群名称,创建es连接
     * 由于开启连接需要占用资源,不要开启过多,并在使用完毕后及时关闭
     *
     * @param hostArr
     * @param clusterName
     * @return
     */
public static TransportClient initTransportClient(String[] hostArr, String clusterName) {
	TransportClient client = null;
	Settings settings = Settings.builder()
	                .put("cluster.name", clusterName)
	                .put("client.transport.ping_timeout", "60s")
	                .put("client.transport.sniff", true)//开启嗅探特性
	.build();
	/**
         * String[] hostArr = new String[]{"hostname1:port", "hostname2:port", "hostname3:port"};
         */
	TransportAddress[] transportAddresses = new InetSocketTransportAddress[hostArr.length];
	for (int i = 0; i < hostArr.length; i++) {
		String[] parts = hostArr[i].split(":");
		try {
			InetAddress inetAddress = InetAddress.getByName(parts[0]);
			transportAddresses[i] = new InetSocketTransportAddress(inetAddress, Integer.parseint(parts[1]));
		}
		catch (UnknownHostException e) {
			log.error("!!!!es连接初始化出错: " + e.getMessage(), e);
			return client;
		}
	}
	client = new PreBuiltTransportClient(settings)
	                .addTransportAddresses(transportAddresses);
	return client;
}
```

可以看到，这里的方法不是单例模式，仅仅是创建一个 `TransportClient` 实例。

如果在业务代码中频繁调用这个方法，可能会创建大量的连接，而如果又没有及时关闭，有潜在的危险。

顺着这个思路继续找下去，的确，在业务代码中会创建大量的连接，然后请求 `Elasticsearch` 集群，更为奇葩的是，在使用完成后也没有关闭 `TransportClient` 连接，而是不管不问，让它自生自灭。

这样怎么能行，肯定会有大量连接没有关闭，占用着 `Elasticsearch` 集群的资源。


# 问题分析解决


上面对于问题的分析、排查基本完成，下面就要仔细分析集群的设置以及给出可行的解决思路。

先使用 `Elasticsearch` 官方的 `api` 查看集群的文件句柄使用情况：`GET /_nodes/stats?pretty`，找到 `process` 下面的配置 `open_file_descriptors`、`max_file_descriptors` 。

`v5.6.8` 的查看结果

![v5.6.8 查看 open_file_descriptors](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2018/20191117184201.png "v5.6.8 查看 open_file_descriptors")

`v1.7.5` 的查看结果，没有 `max_file_descriptors` 显示

![v1.7.5 查看 open_file_descriptors](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2018/20191117184244.png "v1.7.5 查看 open_file_descriptors")

使用 `GET _nodes/stats/process?filter_path=**.max_file_descriptors` 查看集群的最大限制，和上面的结果一致，可以看到是数十万，已经是很大的数值了【`v5.6.8` 可以查看，`v1.7.5` 不可查看】。

![v5.6.8 查看 max_file_descriptors](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2018/20191117184253.png "v5.6.8 查看 max_file_descriptors")

根据 `open_file_descriptors` 的结果，仅仅使用了数千个，而集群允许使用数十万个【`max_file_descriptors` 参数】，所以业务中不可能使用这么多连接，真的使用这么多集群恐怕无法正常运行了。

由此进一步猜测，业务中的报错可能和执行进程的操作系统、用户有关，根据官网的介绍：[file-descriptors](https://www.elastic.co/guide/en/elasticsearch/reference/5.6/file-descriptors.html) ，不妨查看系统的配置，打开系统的 `cat /etc/security/limits.conf` 文件，可以看到限制的最大文件句柄数为65535【星号表示针对所有的用户生效】。

![查看系统的 limits](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2018/20191117184050.png "查看系统的 limits")

还可以继续使用 `ulimit -a` 验证操作系统对当前用户的限制是不是这么大，如下图所示，根据 `open files` 配置，的确是的。

![查看用户的 ulimit](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2018/20191117184018.png "查看用户的 ulimit")

这么一来，程序运行时如果创建的连接数超过65535个，就会被操作系统限制，而这个数万级别的数量还是有可能的。

至此，问题基本分析出来了，主要就是业务代码中创建的 `Elasticsearch` 连接数过多，被操作系统拒绝了，才会导致本文开头的异常。那么解决方案就很简单了，在业务代码中限制创建的连接数即可【使用单例模式创建连接或者使用完成后及时关闭连接】。

最后总结一下：

这种创建连接的操作，最好使用单例模式进行设计，这样无论业务代码怎么调用，都不会创建过多的实例，从根本上杜绝滥用的情况。

在使用这种占用资源的场景下，例如：`Elasticsearch` 的 `TransportClient` 对象，使用完成后要及时关闭，不能占用着连接不使用但是又不关闭，这样肯定是给 `Elasticsearch` 集群造成压力，其它文件流也是类似。等到连接数达到最大时，`Elasticsearch` 集群也就会一直报错：打开的文件过多。

但是，还要注意一点，在不使用单例模式的情况下，合理地关闭连接也可能会有问题，因为 `Elasticsearch` 会维护一个连接池，代码显示 `close` 后连接并不一定真的被关闭，因此使用单例模式是最好的选择。

加大系统的文件句柄数【或者是用户的文件句柄数】不是根本解决办法，只是滋养了烂代码的生存空间，最终还是会重现问题。最好的方式当然是把生成 `TransportClient` 的方法改成单例模式，或者使用完成后及时关闭连接，简单正确，可以永久解决此问题。


# 备注


以上排查思路以客户端连接数为切入点，因为一开始查到 `Elasticsearch` 集群的 `max_file_descriptors` 参数设置的足够大，所以不太可能是 `Elasticsearch` 集群的问题，转而把关注点放到客户端的使用上。其实，无论是使用 `HTTP` 连接还是官方的 `TransportClient` 连接，如果连接数超过了操作系统的设置，就会出现 `Too many open files` 这个异常。

关于文件描述符的官网介绍：[file-descriptors](https://www.elastic.co/guide/en/elasticsearch/reference/5.6/file-descriptors.html) 。

使用单例模式，解决问题，[博客园](https://www.cnblogs.com/GoQC/p/6803341.html) 。

关于用户、系统的文件句柄数上限，[elastic 中文社区](https://elasticsearch.cn/question/4702) 。如果是启动 `Elasticsearch` 进程时出现这个问题，导致启动失败，可以查看对应的进程占用了多少个文件句柄，使用命令：`losf -p pid |wc -l`。如果是 `Elasticsearch` 本身占用了过多的文件句柄，可以考虑是不是索引的段个数设置不合理，参考：[索引段个数的问题](https://www.jianshu.com/p/0ceb59025521) ，可以使用 `GET your_index_name/_segments` 查看段信息。

关于系统配置生效问题：[记一次修改 elasticsearch 文件描述符数量](http://imsilence.github.io/2015/09/16/elasticsearch/elasticsearch_max_open_files) 。


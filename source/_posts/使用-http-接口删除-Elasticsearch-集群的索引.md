---
title: 使用 http 接口删除 Elasticsearch 集群的索引
id: 2019082101
date: 2019-08-21 23:00:47
updated: 2019-08-22 23:00:47
categories: 大数据技术知识
tags: [Elasticsearch,Java,HTTP,curl]
keywords: Elasticsearch,Java,HTTP,curl
---


在工作中遇到需要定期关闭、删除 `Elasticsearch` 集群索引的需求，关闭索引或者删除索引是一个很简单的操作，直接向 `Elasticsearch` 集群发送一个请求即可。而且，为了实现批量删除，可以一次性发送多个索引名称，使用逗号分隔即可，甚至可以使用通配符【需要 `Elasticsearch` 集群的相关设置开启】，会直接删掉满足通配符条件的索引。

本文基于最简单的一个场景：单个索引的关闭、删除，使用 `Java` 编程语言、`HTTP` 接口，尝试关闭、删除 `Elasticsearch` 集群的索引，属于入门级别，开发环境基于 `Elasticsearch v1.7.5`，这是一个很旧的版本，`JDK v1.8`。


<!-- more -->


首先声明，本文内容是基于 `Elasticsearch v1.7.5`，这是一个很旧的版本，目前各个公司应该只有在一些历史遗留的项目中使用，一般大家都会使用 `v5.x`、`v6.x` 之类的版本了。此外，在 `v6.x` 及以上版本取消了索引 `type` 的概念，在那个场景下可以随便删除一个索引，而不用再考虑单个索引 `index` 下面存在的多个 `type` 的情况，没有误删除的风险。


# 背景介绍


我的目的只有两个：关闭索引、删除索引，是不是很简单的问题。

回归到我的具体业务，其实就是由于历史数据的积压，创建了很多个索引，而这些数据平时又没有用处，特别是比较久远的数据，根本不会有人用到，留着它们纯属浪费磁盘空间。

仔细分析、调研，对于最近几个月的数据，还会有一些价值，偶尔有人翻看，其实可以先关闭索引，如果确实有人需要，再临时打开。但是对于已经存在一年以上的数据，不会有人用到，可以说是无人关心、无人问津，这种数据对应的索引就应该被删除，不需要保留。

那么为了实现这个需求，可以写一个定时程序来处理。


# 技术分析


根据以上的想法，我去查看了 `Elasticsearch` 的官方文档，发现有非常简单的 `HTTP` 接口可以使用，我也决定使用它。但是需要注意，在 `Elasticsearch` 中只能删除整个 `index`，而不能只是删除 `index` 下面的某个 `type`。也就是说只要对某个 `index` 执行删除操作，则此 `index` 下面的所有 `type` 都会被一起删除，所以这是一个有点危险的操作，读者需要慎重执行，千万不要只想着**一顿操作猛如虎**，最终沦落为**不领工资快跑路**的境地，或者造成**明天去一趟财务室**的严重后果。

参考官方文档内容如下：

- [indices-delete-index](https://www.elastic.co/guide/en/elasticsearch/reference/1.7/indices-delete-index.html)
- [indices-open-close](https://www.elastic.co/guide/en/elasticsearch/reference/1.7/indices-open-close.html)

看文档很明显，我需要使用三个 `HTTP` 接口，请读者继续往下看。

## 删除索引

删除索引，使用 `curl -XDELETE http://localhost:9200/your_index` 接口即可，把主机地址、端口号、索引名称更换成实际的取值即可。

![删除索引文档](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20190823232341.png "删除索引文档")

如果想一次性删除多个索引，可以传入多个索引名称，使用逗号连接，例如：`index1,index2,index3`，这样就可以一次性删除，但是索引也不能太多，我在自己的集群测试，只能传入20个，再多会被忽略，不会被删除。

当然，为了方便用户使用，`Elasticsearch` 也是支持通配符的，例如使用：
`curl -XDELETE http://localhost:9200/_all`、
`curl -XDELETE http://localhost:9200/*` 
就可以把所有的索引删除。其中，`_all`、`*` 就是通配符，匹配所有的索引名称，显然这是一个极度危险的操作，如果做了真的是只能**删库跑路**。

另外还有一种比较安全的通配符，就是前缀匹配，例如使用 `curl -XDELETE http://localhost:9200/test-*` 就可以把以 `test-` 开头的索引删除，不会删除不满足这个匹配条件的索引。

当然，是有办法可以避免这种潜在的危险操作，那就是关闭通配符的功能，在 `Elasticsearch` 的配置文件 `elasticsearch.yml` 中，有一个 `action.destructive_requires_name=true` 参数，控制着 `_all`、`*` 这两个通配符的开启还是关闭【配置为 true 表示拒绝通配符，只能匹配特定的索引名称】。

除了直接更改配置文件，需要重启 `Elasticsearch` 集群，也可以通过**动态变更参数**接口来改变这个参数的取值，这样就不用重启集群。但是，这一特性需要 `v2.x` 以上的版本才会支持，参考官方文档：[cluster-update-settings](https://www.elastic.co/guide/en/elasticsearch/reference/2.1/cluster-update-settings.html) 。

![动态更新配置文档](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20190823232359.png "动态更新配置文档")

以下使用配置举例：

```
curl XPUT http://localhost:9200/_cluster/settings -d '
{
    永久生效
    "persistent" : {
        "action.destructive_requires_name" : true
    },
    本次生效,重启集群后失效
    "transient" : {
        "iaction.destructive_requires_name" : true 
    }
}'
```

其实仔细想想，关闭通配符可以保证数据安全，但是却给操作带来了一定的麻烦，这个需要读者自己权衡。

## 开启关闭索引

开启、关闭索引的接口比较简单，如下：

- 开启索引，`curl -XPOST http://localhost:9200/your_index/_open`
- 关闭索引，`curl -XPOST http://localhost:9200/your_index/_close`

把主机地址、端口号、索引名称更换成实际的取值即可。

![开启关闭索引文档](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20190823232821.png "开启关闭索引文档")

这里的通配符使用方式与上面的一致，不再赘述。


# 代码实现


技术分析完毕，开始使用代码实现，这样就可以在服务器起一个定时程序，用来定时关闭一些索引，定时删除一些索引，以后只需要定期检查有无误操作即可。

代码逻辑比较简单，使用参数封装 `HTTP` 请求，然后发送给 `Elasticsearch` 集群，再解析返回的数据，来判断操作是否成功。

代码示例我已经放在 `GitHub` 上面，仅供参考：[CleanEsClusterClient.java](https://github.com/iplaypi/iplaypistudy/tree/master/iplaypistudy-elasticsearch/src/main/java/org/playpi/study/client) ，搜索 **CleanEsClusterClient** 类即可，此外，核心的处理类是 **EsClusterUtil**，里面封装了主要逻辑。

下面使用删除索引的 `HTTP` 请求处理来展示一下代码示例：

```
/**
     * 删除指定的索引
     * 索引可以批量传入,使用逗号分隔即可
     *
     * @param hostport
     * @param indexName
     * @param useSsl    是否使用https协议
     * @return
     */
public static Boolean deleteIndex(String hostport, String indexName, Boolean useSsl) {
	String url = "http://" + hostport + "/" + indexName;
	String resultStr = HttpUtil.getHttpResult(url, null, HttpUtil.HTTP_METHOD.DELETE, useSsl);
	Map<String, Object> resultMap = new Gson().fromJson(resultStr, Map.class);
	if (null != resultMap && Boolean.valueOf(resultMap.getOrDefault("acknowledged", false).toString())) {
		return true;
	}
	return false;
}
```

![删除索引代码示例](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20190823234735.png "删除索引代码示例")

可以看到只有几行代码，其中 `HttpUtil` 是一个工具类，也可以在 `GitHub` 项目中搜索。


# 使用命令发送请求


演示完了代码，下面演示使用 `curl` 命令的方式来操作 `Elasticsearch` 集群，与 `Java` 代码发送 `HTTP` 请求的效果是一样的，我这里只是简单演示关闭索引的操作。

使用如下命令向我的 `Elasticsearch` 集群发送一个关闭索引的请求：

```
curl -XPOST http://dev2:9200/test-index-v2/_close
```

发送成功后，可以看到返回结果，关闭成功：

```
{"acknowledged":true}
```

![发送命令返回结果](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20190823234220.png "发送命令返回结果")

去 `Elasticsearch` 集群看一下索引的状态，索引 `test-index-v2` 的确已经被关闭了。

![v2 索引被关闭](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20190823234312.png "v2 索引被关闭")


---
title: 记一次愚蠢的 HBase 错误
id: 2019061701
date: 2019-06-17 23:07:49
updated: 2019-06-18 23:07:49
categories: 大数据技术知识
tags: [HBase,Spark]
keywords: HBase,Spark
---


最近在整理一个单独的 Maven 项目，是从其它项目迁移过来的，主要存放的是和业务强相关的代码，略显混乱的代码是必不可少的，我的职责就是把现存的代码抽象出来，尽量删除一些无用的代码，只保留少量的可复用的代码。在整理的过程中，我几乎把所有的代码全部删除了，只保留一些高复用性的 `util`、`constant` 之类的代码，但是在整理和 HBase 相关的代码时，遇到了一个诡异的问题，报错信息截取片段：`Cannot get replica 0 location for`，后来经过排查发现不是现象诡异，而是自己太愚蠢，本文记录这个过程。


<!-- more -->


# 代码问题


代码逻辑很简单，根据批量的 `pk 值` 去 `HBase` 表中查询数据，只需要查询指定的**列簇**，然后对返回结果进行解析，按行输出为文本文件。

具体的代码逻辑：

1. 根据 `pk` 构造 `Get` 对象，并指定**列簇**
2. 根据 `HBase` 表名称以及环境配置参数构造 `HTable` 对象
3. 调用 `HTbale` 对象的 `get` 方法获取结果
4. 解析 3 中返回的结果

在测试的时候，发现总是在第3个步骤出现大量的异常信息：

```
2019-06-17_23:09:40 [Executor task launch worker-11] ERROR client.AsyncProcess:927: Cannot get replica 0 location for {"cacheBlocks":true,"totalColumns":1,"row":"ef7e0077a525929788b387dda294b9bb","families":{"r":["publish_date"]},"maxVersions":1,"timeRange":[0,9223372036854775807]}
```

此外我还看到一些 `HBase` 查询时的错误，只列出了 `HBase` 相关的片段：

```
org.apache.hadoop.hbase.client.RetriesExhaustedWithDetailsException: Failed 1007 actions: IOException: 1007 times, 
	at org.apache.hadoop.hbase.client.AsyncProcess$BatchErrors.makeException(AsyncProcess.java:228)
	at org.apache.hadoop.hbase.client.AsyncProcess$BatchErrors.access$1700(AsyncProcess.java:208)
	at org.apache.hadoop.hbase.client.AsyncProcess$AsyncRequestFutureImpl.getErrors(AsyncProcess.java:1605)
	at org.apache.hadoop.hbase.client.HTable.batch(HTable.java:936)
	at org.apache.hadoop.hbase.client.HTable.batch(HTable.java:950)
	at org.apache.hadoop.hbase.client.HTable.get(HTable.java:911)
```

而且是所有的查询请求全部都是这种错误，看起来像是查询不到数据，但是不知道为何如此。我一开始猜测是环境的原因，可能是哪里把环境参数的配置文件搞错了，于是检查了一遍配置文件，没有发现任何问题。后来猜测可能是集群的问题，但是检查了一遍，集群一直正常运行。

折腾了一个多小时，最终实在没有办法，只好把这段查询数据的逻辑代码单独拆出来，重新手写一遍，查询2条测试数据的发表时间：`publish_date`，并单步调试，看看究竟发生了什么。

```
@Test
    public void TestHBase() {
	String string = "XX_POST_TABLE_NAME";
	try {
		HTable hTable = new HTable(XxxConfig.getInstance(), TableName.valueOf(string));
		List<Get> getList = Lists.newArrayList();
		Get get = new Get(Bytes.toBytes("0000135807e05492e830ade76a8a0c38x"));
		get.addColumn(XxxConsts.R, "publish_date".getBytes());
		getList.add(get);
		Get get2 = new Get(Bytes.toBytes("0000135807e05492e830ade76a8a0c38"));
		get.addColumn(XxxConsts.R, "publish_date".getBytes());
		getList.add(get2);
		Result[] resultArr = hTable.get(getList);
		for (Result result : resultArr) {
			Cell cell = result.getColumnLatestCell(RhinoETLConsts.R, "publish_date".getBytes());
			if (null != cell) {
				System.out.println("====" + Bytes.toString(cell.getValueArray(), cell.getValueOffset(), cell.getValueLength()));
			} else {
				System.out.println("====null");
			}
		}
	}
	catch (IOException e) {
		e.printStackTrace();
	}
}
```

![手写代码单元测试](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20190619000313.png "手写代码单元测试")

经过运行测试，发现是正常的，没有任何错误信息出现，需要的**发表时间**字段可以正常查询出来，我立即懵了，这可怎么办。懵了3秒，我立刻缓过神来，作为一个有三年工作经验的工程师，我觉得这都是小场面。

而且，此刻我的内心已经有了答案：**没出问题就说明有问题**，至于哪里有问题则很容易确认，要么是旧代码有问题，要么是我手写的新代码有问题，只要仔细对比一下真相就出来了。

接着我仔细对比了一下两份代码的不同之处，没用3分钟就发现了蹊跷之处，而且是很低级的错误，且看下一小节的分析。


# 错误代码片段


在上面的开头我已经列出来了代码逻辑的4个步骤，本以为出错原因在第3个步骤，没想到真实原因在第2个步骤：根据 `HBase` 表名称以及环境配置参数构造 `HTable` 对象，代码如下：

```
/**
     * 获取 HBase 连接
     *
     * @param htableStr
     * @return
     */
public static HTable getHTable(String htableStr) {
	HTable hTable = null;
	try {
		hTable = new HTable(XxxConfig.getInstance(), TableName.valueOf(htableStr));
	}
	catch (Exception e) {
		LOG.error(e.getMessage(), e);
	}
	finally {
		if (null != hTable) {
			try {
				hTable.close();
			}
			catch (IOException e) {
				e.printStackTrace();
			}
		}
	}
	return hTable;
}
```

![获取HBase表连接的代码片段](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20190619000540.png "获取HBase表连接的代码片段")

代码乍一看好像没有问题，就那么几行，但是千万要留意 `finally` 代码块中的代码，它是在做什么？它把刚刚创建好的 `HTable` 链接关了，关闭之前还友好地判断了一下是不是为 `null`，我真是一口老血喷出来。

注意，这里的关闭操作完全不影响后续的查询请求，在代码层面是判断不出来有什么问题的，即不会产生**编译错误**，直到运行起来真正去查询的时候才发现报错，但是报错信息又很模糊，没有表明具体的原因。


# 个人思考


我回顾了一下，这个问题明显是一个很低级的错误，但是为什么出现在我身上呢，总结原因有二：一是直接复制了别处的代码，稍做改动，结果改错了；二是在晚上整理的代码，已经工作了一天，状态不够好，容易犯小错误。

从小事中吸取教训，总结如下：

1、在状态不好的时候，还是先休息好最重要，否则坚持写出来的代码会有一些低级错误，而且还自信地认为没有问题，给后续的排查留下坑。同理，做其它事情也是一样，对于一些要求严格的事情，为了保证质量，一定要在一天中状态最好的时间段去处理，才能最大程度地避免出问题。

2、对自己写出的代码不要过于自信，特别是一些简单的代码，自己想当然地认为不可能有问题，不舍得花费几分钟检查一下，或者测试一下，这会为自己带来浪费时间的风险，就像现在这样，早晚要为自己的失误买单。做其它事情也是一样，一定要反复检查自己负责的部分，如果有时候局限于时间排期，没有充足的时间检查，无法保证可靠性的话，宁愿延期解决，也不要坑自己和别人。当然，也不要因此自卑或者退缩，该是自己负责的时候一定要积极，按时保质保量完成。


---
title: Spark 读取 Elasticsearch 异常：Unexpected end-of-input in VALUE_STRING
id: 2020-01-15 01:59:18
date: 2019-10-20 01:59:18
updated: 2020-01-15 01:59:18
categories:
tags:
keywords:
---


2019102001
Spark,Elasticsearch,Hadoop
大数据技术知识


业务场景：使用 `elasticsearch-hadoop` 读取 `Elasticsearch` 的数据，指定了查询条件、过滤字段，平时每天都会有很多个任务，可以正常跑完。今天发现有几个异常终止的任务，没有正常处理完数据，查看日志发现有 `JsonParseException` 出现，由于没有清晰的异常信息，只能通过源码排查，本文记录整个过程。

开发环境基于 `Elasticsearch v5.6.8`、`elasticsearch-hadoop v5.6.8`。


<!-- more -->



# 问题出现


直接查看日志，找到异常信息：

```
org.apache.spark.SparkException: Job aborted due to stage failure: Task 105 in stage 9.0 failed 1 times, most recent failure: Lost task 105.0 in stage 9.0 (TID 1941, localhost): org.elasticsearch.hadoop.serialization.EsHadoopSerializat
ionException: org.codehaus.jackson.JsonParseException: Unexpected end-of-input in VALUE_STRING
 at [Source: org.apache.commons.httpclient.AutoCloseInputStream@6750b4a5; line: 1, column: 17579]
	at org.elasticsearch.hadoop.serialization.json.JacksonJsonParser.nextToken(JacksonJsonParser.java:95)
	at org.elasticsearch.hadoop.serialization.ParsingUtils.skipCurrentBlock(ParsingUtils.java:313)
	at org.elasticsearch.hadoop.serialization.ScrollReader.map(ScrollReader.java:855)
	at org.elasticsearch.hadoop.serialization.ScrollReader.read(ScrollReader.java:708)
	at org.elasticsearch.hadoop.serialization.ScrollReader.readHitAsMap(ScrollReader.java:474)
	at org.elasticsearch.hadoop.serialization.ScrollReader.readHit(ScrollReader.java:399)
	at org.elasticsearch.hadoop.serialization.ScrollReader.read(ScrollReader.java:294)
	at org.elasticsearch.hadoop.serialization.ScrollReader.read(ScrollReader.java:267)
	at org.elasticsearch.hadoop.rest.RestRepository.scroll(RestRepository.java:367)
	at org.elasticsearch.hadoop.rest.ScrollQuery.hasNext(ScrollQuery.java:92)
	at org.elasticsearch.spark.rdd.AbstractEsRDDIterator.hasNext(AbstractEsRDDIterator.scala:61)
	at scala.collection.Iterator$$anon$11.hasNext(Iterator.scala:327)
	at scala.collection.Iterator$$anon$11.hasNext(Iterator.scala:327)
	at org.apache.spark.rdd.PairRDDFunctions$$anonfun$saveAsHadoopDataset$1$$anonfun$13$$anonfun$apply$7.apply$mcV$sp(PairRDDFunctions.scala:1195)
	at org.apache.spark.rdd.PairRDDFunctions$$anonfun$saveAsHadoopDataset$1$$anonfun$13$$anonfun$apply$7.apply(PairRDDFunctions.scala:1195)
	at org.apache.spark.rdd.PairRDDFunctions$$anonfun$saveAsHadoopDataset$1$$anonfun$13$$anonfun$apply$7.apply(PairRDDFunctions.scala:1195)
	at org.apache.spark.util.Utils$.tryWithSafeFinallyAndFailureCallbacks(Utils.scala:1277)
	at org.apache.spark.rdd.PairRDDFunctions$$anonfun$saveAsHadoopDataset$1$$anonfun$13.apply(PairRDDFunctions.scala:1203)
	at org.apache.spark.rdd.PairRDDFunctions$$anonfun$saveAsHadoopDataset$1$$anonfun$13.apply(PairRDDFunctions.scala:1183)
	at org.apache.spark.scheduler.ResultTask.runTask(ResultTask.scala:66)
	at org.apache.spark.scheduler.Task.run(Task.scala:89)
	at org.apache.spark.executor.Executor$TaskRunner.run(Executor.scala:227)
	at java.util.concurrent.ThreadPoolExecutor.runWorker(ThreadPoolExecutor.java:1149)
	at java.util.concurrent.ThreadPoolExecutor$Worker.run(ThreadPoolExecutor.java:624)
	at java.lang.Thread.run(Thread.java:748)
Caused by: org.codehaus.jackson.JsonParseException: Unexpected end-of-input in VALUE_STRING
 at [Source: org.apache.commons.httpclient.AutoCloseInputStream@6750b4a5; line: 1, column: 17579]
	at org.codehaus.jackson.JsonParser._constructError(JsonParser.java:1433)
	at org.codehaus.jackson.impl.JsonParserMinimalBase._reportError(JsonParserMinimalBase.java:521)
	at org.codehaus.jackson.impl.JsonParserMinimalBase._reportInvalidEOF(JsonParserMinimalBase.java:454)
	at org.codehaus.jackson.impl.JsonParserMinimalBase._reportInvalidEOF(JsonParserMinimalBase.java:448)
	at org.codehaus.jackson.impl.JsonParserBase.loadMoreGuaranteed(JsonParserBase.java:426)
	at org.codehaus.jackson.impl.Utf8StreamParser._skipString(Utf8StreamParser.java:2015)
	at org.codehaus.jackson.impl.Utf8StreamParser.nextToken(Utf8StreamParser.java:441)
	at org.elasticsearch.hadoop.serialization.json.JacksonJsonParser.nextToken(JacksonJsonParser.java:93)
	... 24 more
```

![VALUE_STRING 异常](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20200225224303.png "VALUE_STRING 异常")

重点看 `JsonParseException: Unexpected end-of-input in VALUE_STRING`，这个异常在平时没见过，而且和源代码有关联，只能去排查源代码了。

由于业务紧急，决定先重跑任务，重跑之后发现异常仍旧出现，直到第三次重跑没有再复现，数据结果也是正常的。

当前可以怀疑在某个时刻网络或者 `Elasticsearch` 集群有问题，导致读取的数据不是 `JacksonJsonParser` 需要的规范格式【可能是集群直接返回的异常信息，例如超时信息、查询异常信息等等】，这样 `JacksonJsonParser` 在解析数据的时候，无法正常解析，从而抛出异常。

当然，这只是一个临时猜测，具体是什么原因还是得查看源代码才能搞清楚。


# 查看源码


实话说，我印象当中在以前也遇到过这个问题，但是由于事情紧急，没有仔细排查，重跑成功之后就抛在了脑后。今天再次遇到这个问题，并且重跑了两次还是重复出现异常，直到重跑第三次才正常，这就值得探索一下了。

晚上有点时间，接着重跑测试，发现偶尔可以复现，这个问题突然出现的概率这么大【难道以前也是经常出现，但是我们没发现？】，就进一步勾起了我的兴趣，让我们共同来看一下源代码吧。

直接搜索 `JacksonJsonParser` 这个类，跳转到第95行，看到内容：

```
@Override
public Token nextToken() {
    try {
        return convertToken(parser.nextToken());
    } catch (IOException ex) {
        throw new EsHadoopSerializationException(ex);
    }
}
```

![抛出异常点](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20200225224907.png "抛出异常点")

可以看到就是这里抛出的异常，异常类型为 `EsHadoopSerializationException`。

但是这里并没有详细的逻辑代码，进一步查看，异常是由 `parser.nextToken()` 里面抛出的，接着看它里面的内容就行。

根据异常日志中的 `Caused by` 内容，找到方法实现的地方，从 `Utf8StreamParser.java:441` 开始，到 `nextToken()` 方法、`_skipString()` 方法、`loadMoreGuaranteed()` 方法，最后进入 `_reportInvalidEOF` 方法，报告异常，抛出异常。

现在知道了大概流程，需要进一步搞清楚这些方法做了什么，为什么要抛出异常，其中 `_skipString()` 是关键的地方，看一下 `_skipString()` 方法的注释：

> Method called to skim through rest of unparsed String value,if it is not needed.
> This can be done bit faster if contents need not be stored for future access.

大概就是跳过了。。。处理速度更快，猜测和 `_source` 字段有关，如果在字段过滤中去掉【怪不得有些索引读取没问题，出问题的总是那几个，看记录验证一下】。

继续看。。。


# 备注


在想复现问题而多次重跑的过程中，偶尔还会有以下各种类型的异常信息。

`Unexpected end-of-input in field name` 异常：

```
org.apache.spark.SparkException: Job aborted due to stage failure: Task 0 in stage 8.0 failed 1 times, most recent failure: Lost task 0.0 in stage 8.0 (TID 1834, localhost): org.elasticsearch.hadoop.serialization.EsHadoopSerializationE
xception: org.codehaus.jackson.JsonParseException: Unexpected end-of-input in field name
 at [Source: org.apache.commons.httpclient.AutoCloseInputStream@47286a6e; line: 1, column: 117405]
	at org.elasticsearch.hadoop.serialization.json.JacksonJsonParser.nextToken(JacksonJsonParser.java:95)
	at org.elasticsearch.hadoop.serialization.ScrollReader.map(ScrollReader.java:852)
	at org.elasticsearch.hadoop.serialization.ScrollReader.read(ScrollReader.java:708)
	at org.elasticsearch.hadoop.serialization.ScrollReader.readHitAsMap(ScrollReader.java:474)
	at org.elasticsearch.hadoop.serialization.ScrollReader.readHit(ScrollReader.java:399)
	at org.elasticsearch.hadoop.serialization.ScrollReader.read(ScrollReader.java:294)
	at org.elasticsearch.hadoop.serialization.ScrollReader.read(ScrollReader.java:267)
	at org.elasticsearch.hadoop.rest.RestRepository.scroll(RestRepository.java:379)
	at org.elasticsearch.hadoop.rest.ScrollQuery.hasNext(ScrollQuery.java:112)
	at org.elasticsearch.spark.rdd.AbstractEsRDDIterator.hasNext(AbstractEsRDDIterator.scala:61)
	at scala.collection.Iterator$$anon$11.hasNext(Iterator.scala:327)
	at scala.collection.Iterator$$anon$11.hasNext(Iterator.scala:327)
	at org.apache.spark.rdd.PairRDDFunctions$$anonfun$saveAsHadoopDataset$1$$anonfun$13$$anonfun$apply$7.apply$mcV$sp(PairRDDFunctions.scala:1195)
	at org.apache.spark.rdd.PairRDDFunctions$$anonfun$saveAsHadoopDataset$1$$anonfun$13$$anonfun$apply$7.apply(PairRDDFunctions.scala:1195)
	at org.apache.spark.rdd.PairRDDFunctions$$anonfun$saveAsHadoopDataset$1$$anonfun$13$$anonfun$apply$7.apply(PairRDDFunctions.scala:1195)
	at org.apache.spark.util.Utils$.tryWithSafeFinallyAndFailureCallbacks(Utils.scala:1277)
	at org.apache.spark.rdd.PairRDDFunctions$$anonfun$saveAsHadoopDataset$1$$anonfun$13.apply(PairRDDFunctions.scala:1203)
	at org.apache.spark.rdd.PairRDDFunctions$$anonfun$saveAsHadoopDataset$1$$anonfun$13.apply(PairRDDFunctions.scala:1183)
	at org.apache.spark.scheduler.ResultTask.runTask(ResultTask.scala:66)
	at org.apache.spark.scheduler.Task.run(Task.scala:89)
	at org.apache.spark.executor.Executor$TaskRunner.run(Executor.scala:227)
	at java.util.concurrent.ThreadPoolExecutor.runWorker(ThreadPoolExecutor.java:1149)
	at java.util.concurrent.ThreadPoolExecutor$Worker.run(ThreadPoolExecutor.java:624)
	at java.lang.Thread.run(Thread.java:748)
Caused by: org.codehaus.jackson.JsonParseException: Unexpected end-of-input in field name
 at [Source: org.apache.commons.httpclient.AutoCloseInputStream@47286a6e; line: 1, column: 117405]
	at org.codehaus.jackson.JsonParser._constructError(JsonParser.java:1433)
	at org.codehaus.jackson.impl.JsonParserMinimalBase._reportError(JsonParserMinimalBase.java:521)
	at org.codehaus.jackson.impl.JsonParserMinimalBase._reportInvalidEOF(JsonParserMinimalBase.java:454)
	at org.codehaus.jackson.impl.Utf8StreamParser.parseEscapedFieldName(Utf8StreamParser.java:1503)
	at org.codehaus.jackson.impl.Utf8StreamParser.slowParseFieldName(Utf8StreamParser.java:1404)
	at org.codehaus.jackson.impl.Utf8StreamParser._parseFieldName(Utf8StreamParser.java:1231)
	at org.codehaus.jackson.impl.Utf8StreamParser.nextToken(Utf8StreamParser.java:495)
	at org.elasticsearch.hadoop.serialization.json.JacksonJsonParser.nextToken(JacksonJsonParser.java:93)
	... 23 more
```

图。。。

还有 `Unexpected end-of-input: expected close marker for ARRAY` 异常：

```
org.apache.spark.SparkException: Job aborted due to stage failure: Task 10 in stage 10.0 failed 1 times, most recent failure: Lost task 10.0 in stage 10.0 (TID 1953, localhost): org.elasticsearch.hadoop.serialization.EsHadoopSerializat
ionException: org.codehaus.jackson.JsonParseException: Unexpected end-of-input: expected close marker for ARRAY (from [Source: org.apache.commons.httpclient.AutoCloseInputStream@2fd29c70; line: 1, column: 16778])
 at [Source: org.apache.commons.httpclient.AutoCloseInputStream@2fd29c70; line: 1, column: 18368]
	at org.elasticsearch.hadoop.serialization.json.JacksonJsonParser.skipChildren(JacksonJsonParser.java:137)
	at org.elasticsearch.hadoop.serialization.ScrollReader.readHitAsMap(ScrollReader.java:520)
	at org.elasticsearch.hadoop.serialization.ScrollReader.readHit(ScrollReader.java:399)
	at org.elasticsearch.hadoop.serialization.ScrollReader.read(ScrollReader.java:294)
	at org.elasticsearch.hadoop.serialization.ScrollReader.read(ScrollReader.java:267)
	at org.elasticsearch.hadoop.rest.RestRepository.scroll(RestRepository.java:367)
	at org.elasticsearch.hadoop.rest.ScrollQuery.hasNext(ScrollQuery.java:92)
	at org.elasticsearch.spark.rdd.AbstractEsRDDIterator.hasNext(AbstractEsRDDIterator.scala:61)
	at scala.collection.Iterator$$anon$11.hasNext(Iterator.scala:327)
	at scala.collection.Iterator$$anon$11.hasNext(Iterator.scala:327)
	at org.apache.spark.rdd.PairRDDFunctions$$anonfun$saveAsHadoopDataset$1$$anonfun$13$$anonfun$apply$7.apply$mcV$sp(PairRDDFunctions.scala:1195)
	at org.apache.spark.rdd.PairRDDFunctions$$anonfun$saveAsHadoopDataset$1$$anonfun$13$$anonfun$apply$7.apply(PairRDDFunctions.scala:1195)
	at org.apache.spark.rdd.PairRDDFunctions$$anonfun$saveAsHadoopDataset$1$$anonfun$13$$anonfun$apply$7.apply(PairRDDFunctions.scala:1195)
	at org.apache.spark.util.Utils$.tryWithSafeFinallyAndFailureCallbacks(Utils.scala:1277)
	at org.apache.spark.rdd.PairRDDFunctions$$anonfun$saveAsHadoopDataset$1$$anonfun$13.apply(PairRDDFunctions.scala:1203)
	at org.apache.spark.rdd.PairRDDFunctions$$anonfun$saveAsHadoopDataset$1$$anonfun$13.apply(PairRDDFunctions.scala:1183)
	at org.apache.spark.scheduler.ResultTask.runTask(ResultTask.scala:66)
	at org.apache.spark.scheduler.Task.run(Task.scala:89)
	at org.apache.spark.executor.Executor$TaskRunner.run(Executor.scala:227)
	at java.util.concurrent.ThreadPoolExecutor.runWorker(ThreadPoolExecutor.java:1149)
	at java.util.concurrent.ThreadPoolExecutor$Worker.run(ThreadPoolExecutor.java:624)
	at java.lang.Thread.run(Thread.java:748)
Caused by: org.codehaus.jackson.JsonParseException: Unexpected end-of-input: expected close marker for ARRAY (from [Source: org.apache.commons.httpclient.AutoCloseInputStream@2fd29c70; line: 1, column: 16778])
 at [Source: org.apache.commons.httpclient.AutoCloseInputStream@2fd29c70; line: 1, column: 18368]
	at org.codehaus.jackson.JsonParser._constructError(JsonParser.java:1433)
	at org.codehaus.jackson.impl.JsonParserMinimalBase._reportError(JsonParserMinimalBase.java:521)
	at org.codehaus.jackson.impl.JsonParserMinimalBase._reportInvalidEOF(JsonParserMinimalBase.java:454)
	at org.codehaus.jackson.impl.JsonParserBase._handleEOF(JsonParserBase.java:473)
	at org.codehaus.jackson.impl.Utf8StreamParser._skipWSOrEnd(Utf8StreamParser.java:2327)
	at org.codehaus.jackson.impl.Utf8StreamParser.nextToken(Utf8StreamParser.java:444)
	at org.codehaus.jackson.impl.JsonParserMinimalBase.skipChildren(JsonParserMinimalBase.java:101)
	at org.elasticsearch.hadoop.serialization.json.JacksonJsonParser.skipChildren(JacksonJsonParser.java:135)
	... 21 more
```

图。。。

还有 `Unexpected end-of-input: expected close marker for OBJECT` 异常：

```
org.apache.spark.SparkException: Job aborted due to stage failure: Task 32 in stage 0.0 failed 1 times, most recent failure: Lost task 32.0 in stage 0.0 (TID 752, localhost): org.elasticsearch.hadoop.serialization.EsHadoopSerialization
Exception: org.codehaus.jackson.JsonParseException: Unexpected end-of-input: expected close marker for OBJECT (from [Source: org.apache.commons.httpclient.AutoCloseInputStream@2b07b09d; line: 1, column: 256627])
 at [Source: org.apache.commons.httpclient.AutoCloseInputStream@2b07b09d; line: 1, column: 259475]
	at org.elasticsearch.hadoop.serialization.json.JacksonJsonParser.nextToken(JacksonJsonParser.java:95)
	at org.elasticsearch.hadoop.serialization.ScrollReader.map(ScrollReader.java:852)
	at org.elasticsearch.hadoop.serialization.ScrollReader.read(ScrollReader.java:708)
	at org.elasticsearch.hadoop.serialization.ScrollReader.readHitAsMap(ScrollReader.java:474)
	at org.elasticsearch.hadoop.serialization.ScrollReader.readHit(ScrollReader.java:399)
	at org.elasticsearch.hadoop.serialization.ScrollReader.read(ScrollReader.java:294)
	at org.elasticsearch.hadoop.serialization.ScrollReader.read(ScrollReader.java:267)
	at org.elasticsearch.hadoop.rest.RestRepository.scroll(RestRepository.java:379)
	at org.elasticsearch.hadoop.rest.ScrollQuery.hasNext(ScrollQuery.java:112)
	at org.elasticsearch.spark.rdd.AbstractEsRDDIterator.hasNext(AbstractEsRDDIterator.scala:61)
	at scala.collection.Iterator$$anon$11.hasNext(Iterator.scala:327)
	at scala.collection.Iterator$$anon$11.hasNext(Iterator.scala:327)
	at org.apache.spark.rdd.PairRDDFunctions$$anonfun$saveAsHadoopDataset$1$$anonfun$13$$anonfun$apply$7.apply$mcV$sp(PairRDDFunctions.scala:1195)
	at org.apache.spark.rdd.PairRDDFunctions$$anonfun$saveAsHadoopDataset$1$$anonfun$13$$anonfun$apply$7.apply(PairRDDFunctions.scala:1195)
	at org.apache.spark.rdd.PairRDDFunctions$$anonfun$saveAsHadoopDataset$1$$anonfun$13$$anonfun$apply$7.apply(PairRDDFunctions.scala:1195)
	at org.apache.spark.util.Utils$.tryWithSafeFinallyAndFailureCallbacks(Utils.scala:1277)
	at org.apache.spark.rdd.PairRDDFunctions$$anonfun$saveAsHadoopDataset$1$$anonfun$13.apply(PairRDDFunctions.scala:1203)
	at org.apache.spark.rdd.PairRDDFunctions$$anonfun$saveAsHadoopDataset$1$$anonfun$13.apply(PairRDDFunctions.scala:1183)
	at org.apache.spark.scheduler.ResultTask.runTask(ResultTask.scala:66)
	at org.apache.spark.scheduler.Task.run(Task.scala:89)
	at org.apache.spark.executor.Executor$TaskRunner.run(Executor.scala:227)
	at java.util.concurrent.ThreadPoolExecutor.runWorker(ThreadPoolExecutor.java:1149)
	at java.util.concurrent.ThreadPoolExecutor$Worker.run(ThreadPoolExecutor.java:624)
	at java.lang.Thread.run(Thread.java:748)
Caused by: org.codehaus.jackson.JsonParseException: Unexpected end-of-input: expected close marker for OBJECT (from [Source: org.apache.commons.httpclient.AutoCloseInputStream@2b07b09d; line: 1, column: 256627])
 at [Source: org.apache.commons.httpclient.AutoCloseInputStream@2b07b09d; line: 1, column: 259475]
	at org.codehaus.jackson.JsonParser._constructError(JsonParser.java:1433)
	at org.codehaus.jackson.impl.JsonParserMinimalBase._reportError(JsonParserMinimalBase.java:521)
	at org.codehaus.jackson.impl.JsonParserMinimalBase._reportInvalidEOF(JsonParserMinimalBase.java:454)
	at org.codehaus.jackson.impl.JsonParserBase._handleEOF(JsonParserBase.java:473)
	at org.codehaus.jackson.impl.Utf8StreamParser._skipWSOrEnd(Utf8StreamParser.java:2327)
	at org.codehaus.jackson.impl.Utf8StreamParser.nextToken(Utf8StreamParser.java:444)
	at org.elasticsearch.hadoop.serialization.json.JacksonJsonParser.nextToken(JacksonJsonParser.java:93)
	... 23 more
```

图。。。

分析一下这些是什么。


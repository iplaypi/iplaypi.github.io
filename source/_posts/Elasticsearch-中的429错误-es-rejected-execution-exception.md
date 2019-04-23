---
title: Elasticsearch 中的429错误 es_rejected_execution_exception
id: 2017042601
date: 2017-04-26 19:46:43
updated: 2019-04-23 19:46:43
categories: 踩坑系列
tags: [Elasticsearch,HBase,mapreduce,BulkProcessor]
keywords: Elasticsearch,HBase,mapreduce,BulkProcessor
---


今天在处理数据，处理逻辑是从 HBase 中扫描读取数据，经过转换后写入 Elasticsearch 中，程序的整体方案使用的是 mapreduce 结构。map 负责扫描 HBase 数据，并转换为 Map 结构，reduce 负责把 Map 结构的数据转为 JSON 格式，并验证合法性、补充缺失的字段、过滤非法数据等，最后使用 elasticsearch 官方发布的 BulkProcessor 把数据批量写入 elasticsearch。

在处理数据的过程中，遇到了一个诡异的问题，说它诡异是因为一开始不知道 BulkProcessor 存在的坑。关于这个问题，表面现象就是漏数，写入 elasticsearch 中的数据总是少于 HBase 中的数据，而且差距巨大。当然，如果是有经验的工程师，可以猜测好几个原因：扫描读取 HBase 的数据时设置过滤器过滤掉了不该过滤的数据、ETL 的处理逻辑中有误过滤数据的 bug、写入 elasticsearch 时数据不合法导致写入失败、由于 BulkProcessor 潜在的问题导致写入漏数。本文就记录解决这个问题的过程。


<!-- more -->


# 问题出现


问题其实就是漏数，HBase 里面的数据写入到 Elasticsearch 后发现数据量对不上，而且重跑了几次作业，每次重跑都会有多一点点的数据写入 Elasticsearch，这就很诡异了，不像普通的漏数。这个漏数现象复现不了，虽然每次重跑作业都会漏数，但是数据量对不上，说明背后有一只无形的手在操控着这一切，而且操控过程随心所欲，让人疑惑不解。

漏数现象出现后，作为一个有经验的工程师，我先初步怀疑了几个关键点，然后逐步分析，抽丝剥茧，找到了问题所在。

Elasticsearch 版本为 v5.6.8。


# 问题解决


## 怀疑点排查

1、扫描读取 HBase 的数据时设置过滤器过滤掉了不该过滤的数据，经过查看，扫描过滤器只是设置了某个时间字段的范围，并且提交作业时设置的参数属于正常范围，不会影响数据量，排除此种可能。

2、ETL 的处理逻辑中有误过滤数据的 bug，仔细查看了 ETL 的处理逻辑，里面有多处过滤数据的处理逻辑，例如发表时间、id 等必要的字段必须存在，但是不会过滤掉正常的数据，而且给对应的过滤指标设置了累加器。一旦有数据被正常过滤掉，累加器会记录数据量的，在作业的日志中可以查看，排除此种可能。

3、写入 elasticsearch 时数据不合法导致写入失败，在作业运行中，如果出现这种情况，一定会抛出异常【使用 BulkProcessor 不会抛出异常，但是有回调方法可以使用，从而检测异常情况】，所以在业务代码中，考虑了异常情况的发生，把对应的数据格式输出到日志中，方便查看。我仔细搜索检查了日志文件，没有发现数据不合法的异常日志内容，排除此种可能。

4、由于 BulkProcessor 潜在的问题导致写入漏数，这个怀疑点就比较有意思了，使用 BulkProcessor 来批量把数据写入 elasticsearch 时，会有两个隐藏的坑：一是写入失败不会抛出异常，注意，批量的内容全部失败或者部分失败都不会抛出异常，只能在它提供的回调方法【afterBulk()】中捕捉异常信息，二是资源紧张会导致 elasticsearch 拒绝请求，导致写入数据失败，注意，此时也不会抛出异常，只能通过回调方法捕捉错误信息。所以有可能是这个原因。

## 重点排查

好了，已经逐条分析了可能的原因，并初步定位了最有可能的原因，接下来就是利用 BulkProcessor 提供的回调方法，把异常信息捕捉，并在日志中输出所有必要的信息，以方便发现问题后排查具体原因。

代码更新完成后重跑作业，为了速度快一点，先筛选少量的数据进行重跑，然后观察日志。

查看日志，发现有大量的错误信息，就是从 **BulkProcessor** 的回调方法 **afterBulk()** 里面捕捉打印的【以下日志片段本来是一行，为了友好地显示，我把它格式化多行了】：

```
......省略
2019-04-23 17:37:22,738 ERROR [I/O dispatcher 68] org.playpi.blog.client.es.ESBulkProcessor: bulk [43 : 1556012242738] - 
{
    "cause": {
        "reason": "Elasticsearch exception [type=es_rejected_execution_exception, reason=rejected execution of org.elasticsearch.transport.TransportService$7@45c00a5f on EsThreadPoolExecutor[bulk, queue capacity = 1500, org.elasticsearch.common.util.concurrent.EsThreadPoolExecutor@53ffdb18[Running, pool size = 32, active threads = 32, queued tasks = 4527, completed tasks = 26531491]]]",
        "type": "exception"
    },
    "id": "f176fd6b68d22ad357a61714313d2748",
    "index": "org-playpi-datatype-post-year-2018-v1",
    "status": 429,
    "type": "post"
}
......省略
```

更多错误内容如截图所示
![某个reduce任务的日志](https://ws1.sinaimg.cn/large/b7f2e3a3gy1g2cy72abpej20xt0bxq54.jpg "某个reduce任务的日志")

找到里面的关键信息：**es_rejected_execution_exception**、**"status": 429**，到这里，可以确定这个错误不是由于数据格式不合法导致写入 Elasticsearch 失败，否则错误信息应该携带 **source invalid ** 字样。可惜，进一步，我看不懂这个异常错误，只能借助搜索引擎了。

经过搜索，发现这个问题的原因在于 Elasticsearch 集群的资源不足，处理请求的线程池队列全部被占用，无法接收新的请求，于是拒绝，这也就导致了数据漏掉。

在这里先提前说明一下，以下内容的配置信息是基于**数据索引所在的集群、节点**，例如索引A在某个集群，分配了3个节点，那就只看这个集群的这3个节点，可能还有其它几百个节点存放的是其它的数据索引，不用关心。这样才能准确找到问题所在，否则如果看到配置信息对不上，就会感到疑惑。另外在使用 API 接口时，可以在 url 结尾增加 **?pretty** 协助格式化结果数据，查看更容易，**?v** 参数可以协助返回结果增加表头，显示更为友好。

其实，Elasticsearch 分别对不同的操作【例如：index、bulk、get 等】提供不同的线程池，并设置线程池的线程个数与排队任务上限。可以在数据索引所在节点的 **settings** 中查看，如果有 head 插件【或者 kopf 插件】，在**概览 -> 选择节点 -> 集群节点信息**中查看详细配置。
![使用 head 插件查看节点信息](https://ws1.sinaimg.cn/large/b7f2e3a3gy1g2cy83tslkj20iq0k5t93.jpg "使用 head 插件查看节点信息")

其中在**settings -> thread_pool**里面有各个操作的线程池配置。
![使用 head 插件查看 thread_pool 信息](https://ws1.sinaimg.cn/large/b7f2e3a3gy1g2cy8baeesj20ek0f7zki.jpg "使用 head 插件查看 thread_pool 信息")

这里面，有两种类型的线程池，一种是 fixing，一种是 scaling，其中 fixing 是固定大小的线程池，默认是 core 个数的5倍，也可以指定大小，scaling 是动态变化的线程池，可以设置最大值、最小值。

如果不使用 head 插件，直接通过 Elasticsearch 集群的 http 接口【前提是开放 http 端口或者设置了转发端口，否则无法访问】也可以获取这个数据，例如通过 **/\_nodes/节点唯一标识/settings/** 查看某个节点的配置信息。这个节点唯一标识【uuid】可以通过 head 插件获取，我这里使用 **q6GpFsnCSOOfLoLl72MVAg** 演示。

使用 head 插件获取节点的唯一标识。
![查看节点的唯一标识](https://ws1.sinaimg.cn/large/b7f2e3a3gy1g2cy972bq0j20md07p3yj.jpg "查看节点的唯一标识")

使用 API 接口查看节点的配置信息
![使用 API 查看节点的配置信息](https://ws1.sinaimg.cn/large/b7f2e3a3gy1g2cy9knbhej20ra0mm3z0.jpg "使用 API 查看节点的配置信息")

可以看到数据所在节点的线程池配置，对于**bulk**类型的操作，线程池的大小为32【由于 min 和 max 都设置为了32，并且线程池类型为 fixing，所以是32】，队列上限为1500。好，至此，再结合上面错误日志中的信息：**bulk, queue capacity = 1500**、**Running, pool size = 32, active threads = 32, queued tasks = 4527**，可以发现，当前节点【某个 node，不能说整个集群】处理数据时线程的队列已经超过了上限1500，而且我惊讶地发现已经到达了4527，这种情况下 Elasticsearch 显然是要拒绝请求的。

此外，使用集群的 API 接口也可以看到节点的线程池使用情况，包括拒绝请求量，**/\_cat/thread\_pool?v**，查看详情如下图所示。
![使用 API 查看节点的线程池使用情况](https://ws1.sinaimg.cn/large/b7f2e3a3gy1g2cyav2c1rj20ke097aa9.jpg "使用 API 查看节点的线程池使用情况")

不妨再次探索一下 mapreduce 的日志，搜索关于 bulk 的错误，可以看到大量的错误都是这种，超过队列上限而被拒绝请求。
![大量的线程池超过最大限制错误](https://ws1.sinaimg.cn/large/b7f2e3a3gy1g2cyb09mggj21dq0mcn28.jpg "大量的线程池超过最大限制错误")

## 解决方案

原因找到了，解决方案也可以定下来了。

1、给 Elasticsearch 的索引增加更多的节点，这样就可以把线程池扩大了，但是需要消耗资源，一般无法实现。

2、优化批量的请求，尽量不要发送多个小批量的请求，而是发送少量的大批量请求。这个方法还是适合的，把 bulk 请求的数据量增大一点，收集多一点数据再发送请求。

3、改善索引性能，让文档编制索引速度更快，这样处理请求就更快，批量队列就不太容易阻塞了。这个方法说起来容易，做起来有点难，需要优化整个索引设计，例如取消某些字段的索引、删除冗余的字段等。

4、在不增加节点的情况下，把节点的线程池设置大一点、队列上限设置大一点，就可以处理更多的请求了。这个方法需要改变 Elasticsearch 集群的配置，然后重启集群，但是一般情况下会有风险，因为节点的硬件配置【内存、CPU】没有变化，单纯增加线程池，会给节点带来压力，可能会宕机，谨慎采用。配置信息参考如下：

```
-- 修改 elasticsearch.yml 配置文件
threadpool.bulk.type: fixed
threadpool.bulk.size: 64
threadpool.bulk.queue_size: 1500
```

5、如果确实在硬件、集群方面都无法改变，那就直接在使用方式上优化吧，例如把并发设置的小一点，请求一批后休眠一段时间，保障 Elasticsearch 可以把请求处理完，接着再进行下一批数据的请求。这种做法立竿见影，不会再影响到 Elasticsearch 的线程池，但是缺点就是牺牲了时间，运行作业的时间会大大增加。

迫于资源紧张，我只能选择第5种方式了，减小并发数，数据慢慢写入 Elasticsearch，只要不再漏数，时间可以接受。


# 问题总结


除了上面的排查总结，再描述一下一开始针对业务逻辑的具体的思路。

拿到错误日志后，简单搜索统计了一下，一个 reduce 任务的错误信息有16万次，也就是有16万条数据没有成功写入 Elasticsearch。而整个 mapreduce 作业的 reduce 个数为43，可以预估一下有688万次错误信息，也就是有688万条数据没有成功写入 Elasticsearch，这可是个大数目。

再查看作业日志的统计值，累加器统计结果，在 driver 端的日志中，发现一共处理了1413万数据，这样一计算，漏掉了接近49%的数据，太严重了。
![查看累加器的取值](https://ws1.sinaimg.cn/large/b7f2e3a3gy1g2cyb6wscxj20gv0kcgme.jpg "查看累加器的取值")

再对比一下我文章开头的描述，每次重跑作业，总是有一部分数据可以重新写入 Elasticsearch，但是成功的数据量仅仅限于几十条、几条。最终还差500多条数据的时候，已经重跑了5次以上了，所以我才会更加怀疑是程序写入 Elasticsearch 方式的问题。


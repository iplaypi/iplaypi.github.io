---
title: Zookeeper 日志查看
id: 2019092001
date: 2019-09-20 21:26:41
updated: 2020-02-11 21:26:41
categories: 大数据技术知识
tags: [Zookeeper,log]
keywords: Zookeeper,log
---


`Zookeeper` 是大数据组件中不可或缺的一种组件，是一个开源的分布式协调服务，提供了诸如统一命名服务、配置管理、集群管理等功能，在很多场景中都可以见到它的身影。本文简单介绍 `Zookeeper` 的日志查看，开发环境基于 `v3.4.6`。


<!-- more -->


# 开篇


`Zookeeper` 服务器会产生三类日志：**事务日志**、**快照日志**和 **log4j 日志**。

在 `Zookeeper` 默认的配置文件 `zoo.cfg`【也可以修改文件名，在 `bin/zkEnv.sh` 指定使用的配置文件】中有一个配置项 `dataDir`，该配置项用于配置 `Zookeeper` 快照日志和事务日志的存储地址。

在官方提供的默认参考配置文件 `zoo_sample.cfg` 中【解压下载的安装包后，在 `conf` 目录下可以找到】，只有 `dataDir` 配置项，配置为：`dataDir=/tmp/zookeeper`。其实在实际应用中，还可以为事务日志专门配置存储地址，配置项名称为 `dataLogDir`，在 `zoo_sample.cfg` 中并未体现出来。

在没有 `dataLogDir` 配置项的时候，`Zookeeper` 默认将事务日志文件和快照日志文件都存储在 `dataDir` 对应的目录下。但是我们建议将事务日志【`dataLogDir`】与快照日志【`dataDir`】单独配置，存储时分开存储，因为当 `Zookeeper` 集群进行频繁的数据读写操作时，会产生大量的事务日志信息，将两类日志分开存储会提高系统的性能。而且，还可以允许将两类日志存储在不同的存储介质上，减少单一的磁盘压力。

总结，`dataDir` 表示快照日志目录，`dataLogDir` 表示事务日志目录【不配置的时候事务日志目录同 `dataDir`】。

而 `log4j` 用于记录 `Zookeeper` 集群服务器运行日志，该日志的配置项在安装包解压后的 `conf` 目录下的 `log4j.properties`文件中【这个想必很多读者都熟悉了】。在 `bin/zkEnv.sh` 文件中有使用到一个变量 `ZOO_LOG_DIR=.`，表示 `log4j` 日志文件与执行程序【`zkServer.sh`】在同一目录下，当执行 `zkServer.sh` 时，在该目录下会产生 `zookeeper.out` 日志文件；另外还有一个变量 `ZOO_LOG4J_PROP` 表示日志级别。而这些变量，都可以在 `conf/zookeeper-env.sh` 文件中提前设置好，例如：`export ZOO_LOG_DIR=/var/log/zookeeper`。

下面主要介绍**事务日志**与**快照日志**。


# 事务日志


事务日志是指 `Zookeeper` 系统在正常运行过程中，针对所有的更新操作，在返回客户端**更新成功**的响应前，`Zookeeper` 会保证已经将本次更新操作的事务日志写到磁盘上，只有这样，整个更新操作才会生效。

根据上文所述，可以通过 `zoo.cfg` 文件中的 `dataLogDir` 配置项找到事务日志存储的路径：`dataLogDir=/cloud/data1/hadoop/zookeeper`【如果没有配置就看 `dataDir` 参数】，在 `dataLogDir` 对应的目录下存在一个文件夹 `version-2`，该文件夹中保存着所有事务日志文件，例如：`log.6305208d3f`。

事务日志文件的命名规则为 `log.**`，文件大小为 `64MB`【超过后就会生成新的事务日志文件】，`**`表示写入该日志文件的第一个事务的 `ID`【也可以说触发该日志文件的事务】，十六进制表示。日志文件的个数与参数 `autopurge.snapRetainCount` 配置有关，默认是3个，本文最后也会讲到。

## 事务日志可视化

`Zookeeper` 的事务日志为二进制文件，不能通过 `vim` 等工具直接访问，其实可以通过 `Zookeeper` 自带的 `jar` 包中的工具类读取事务日志文件。

首先将 `libs` 中的 `slf4j-api-1.6.1.jar` 文件和 `Zookeeper` 根目录下的 `Zookeeper-3.4.6.jar` 文件复制到临时文件夹 `tmplibs` 中【不复制也可以，只要明确 `jar` 包位置，引用一下即可】，然后执行如下命令，将原始事务日志内容输出至 `6305208d3f.log` 文件中：

```
java -classpath .:./slf4j-api-1.6.1.jar:./zookeeper-3.4.6.2.2.6.0-2800.jar org.apache.zookeeper.server.LogFormatter ./log.6305208d3f > 6305208d3f.log
```

实际上就是手动调用 `Zookeeper` 包里面的实现类，把二进制日志内容格式化，转换为人类可以理解的日志。`-classpath` 就是在 `Java` 中设置第三方 `jar` 包的方式。

产生可以查看的日志文件一份：`6305208d3f.log`。

![事务日志文件转换](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20200212010141.png "事务日志文件转换")

## 日志分析

声明一下，每次对 `Zookeeper` 操作导致的状态改变都会产生一个 `zxid`，即 `ZooKeeper Transaction Id`。

接着就可以挑一些日志进行简单分析一下，输出前10行，最好能挑到前后有关联的，例如同一个会话的打开、关闭操作。

```
ZooKeeper Transactional Log File with dbid 0 txnlog format version 2
19-9-20 下午06时04分05秒 session 0x46d0bf6e8cc50b8 cxid 0x1 zxid 0x6305208d3f error -101

19-9-20 下午06时04分05秒 session 0x56af0a7efa70533 cxid 0x2 zxid 0x6305208d40 closeSession null
19-9-20 下午06时04分05秒 session 0x46d0bf6e8cc50b8 cxid 0x2 zxid 0x6305208d41 closeSession null
19-9-20 下午06时04分05秒 session 0x56af0a7efa70534 cxid 0x3 zxid 0x6305208d42 closeSession null
19-9-20 下午06时04分05秒 session 0x66af3690a390cc4 cxid 0x0 zxid 0x6305208d43 createSession 4000

19-9-20 下午06时04分05秒 session 0x66af3690a390cc4 cxid 0x3 zxid 0x6305208d44 closeSession null
19-9-20 下午06时04分05秒 session 0x76af0f5294b008c cxid 0x6c3549 zxid 0x6305208d45 setData '/storm/supervisors/a7d11d05-8b97-4bc5-ad43-f43cd28f98cc,#ffffffacffffffed05737202b6261636b747970652e73746f726d2e6461656d6f6e2e636...太长省略,2025456
```

![事务日志内容查看](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20200212010948.png "事务日志内容查看")

第一行：`ZooKeeper Transactional Log File with dbid 0 txnlog format version 2`，这是每个事务日志文件都有的日志头，输出了 `dbid` 还有 `version`。

第二行：`... session 0x46d0bf6e8cc50b8 cxid 0x1 zxid 0x6305208d3f error -101`，这也就是具体的事务日志内容了，这里是说某一时刻有一个 `sessionid` 为 `0x46d0bf6e8cc50b8`，`cxid` 为 `0x1`，`zxid` 为 `0x6305208d3f` 的请求，但是出错了。

继续看第五行【第三行是空白】：`... session 0x46d0bf6e8cc50b8 cxid 0x2 zxid 0x6305208d41 closeSession null`，还是第二行那个 `sessionid`，请求类型为 `closeSession`，表示关闭了会话。

看第七行：`... session 0x66af3690a390cc4 cxid 0x0 zxid 0x6305208d43 createSession 4000`，这个请求是 `createSession` 类型，表示创建会话，超时时间为4000毫秒。

直接看第十行：`... session 0x76af0f5294b008c cxid 0x6c3549 zxid 0x6305208d45 setData ...`，请求类型是 `setData`，表示写入数据，数据内容是经过 `ASCII` 编码的。


# 快照日志


`Zookeeper` 的数据在内存中是以树形结构进行存储的，而快照就是每隔一段时间会把整个 `DataTree` 的数据序列化后，存储在磁盘中，这就是 `Zookeeper` 的快照日志。

`Zookeeper` 快照日志的存储路径同样可以在 `zoo.cfg` 中查看，如上文所示，访问 `dataDir` 对应的路径就可以看到 `version-2` 文件夹。

```
dataDir=/cloud/data1/hadoop/zookeeper
```

`Zookeeper` 快照日志文件的命名规则为 `snapshot.**`，其中 `**` 表示 `Zookeeper` 触发快照的那个瞬间，提交的最后一个事务的 `ID`，类似于前面的事务日志文件命名规则，文件示例：`snapshot.6501d41a74`。

## 可视化

与事务日志文件一样，快照日志文件不可直接查看，需要通过 `Zookeeper` 为快照日志文件提供的可视化工具转换，对应的类为 `org.apache.zookeeper.server` 包中的 `SnapshotFormatter`，接下来就使用该工具转换该事务日志文件，并举例解释部分内容。

执行命令：

```
java -classpath .:./slf4j-api-1.6.1.jar:./zookeeper-3.4.6.2.2.6.0-2800.jar org.apache.zookeeper.server.SnapshotFormatter ./snapshot.6501d41a74 > 6501d41a74.snapshot.log
```

把快照文件转换为普通的文本文件，结果输出到 `6501d41a74.snapshot.log` 文件中。

![快照日志文件转换](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20200212215807.png "快照日志文件转换")

## 快照分析

由于快照日志文件的内容比较长，把 `Zookeeper` 的所有节点内容全部输出，主要是因为 `Zookeeper` 的目录比较多，所以只需要挑两个出来即可分析，其它目录都是类似的内容。

```
ZNode Details (count=26650):
----
/
  cZxid = 0x00000000000000
  ctime = Thu Jan 01 08:00:00 CST 1970
  mZxid = 0x00000000000000
  mtime = Thu Jan 01 08:00:00 CST 1970
  pZxid = 0x00006401bcbf78
  cversion = 75
  dataVersion = 0
  aclVersion = 0
  ephemeralOwner = 0x00000000000000
  dataLength = 0
----
/prc
  cZxid = 0x000063029f34a0
  ctime = Sat Jul 27 14:14:01 CST 2019
  mZxid = 0x000063029f34a0
  mtime = Sat Jul 27 14:14:01 CST 2019
  pZxid = 0x000063029f34a1
  cversion = 1
  dataVersion = 0
  aclVersion = 0
  ephemeralOwner = 0x00000000000000
  no data
----
...省略很多内容
```

![快照日志内容查看](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20200212220328.png "快照日志内容查看")

看到第一行：`ZNode Details (count=26650):`，表示 `ZNode` 节点的个数，我这里有26650个，太多了。

从 `----` 开始到下一个 `----` 结束，就是一个 `ZNode` 的信息，包含路径、创建时间、数据长度等等，下面简单说明【以上面的 `/prc` 为例】：

- `/prc`，路径
- `cZxid`，创建节点时的 `Zxid`
- `ctime`，创建节点的时间
- `mZxid`，节点最近一次更新对应的 `Zxid`
- `mtime`，节点最近一次更新的时间
- `pZxid`，父节点的 `Zxid`
- `cversion`，子节点更新次数
- `dataVersion`，数据更新次数
- `aclVersion`，节点 `acl` 更新次数
- `ephemeralOwner`，如果节点为 `ephemeral` 节点则该值为 `sessionid`，否则为0
- `no data`，表示没有数据，如果有的话会显示 `dataLength = xx`，即数据长度为 `xx`

在快照文件的末尾，会有很多如下格式的内容：

```
Session Details (sid, timeout, ephemeralCount):
0x56efad063889c37, 60000, 0
0x1703047aa123b27, 60000, 1
0x4701974cffc62fa, 90000, 0
0x56efad063885c32, 90000, 0
0x4701974cffc62fc, 90000, 0
0x56efad063885c33, 90000, 0
0x66f1c157df79788, 10000, 0
0x4701974cffc62fe, 90000, 0
0x76efad06454f9ed, 90000, 0
0x4701974cffc62ff, 90000, 0
...省略很多个
```

![快照日志文件末尾](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20200212223216.png "快照日志文件末尾")

这里表达的是当前抓取快照日志文件的时间，`Zookeeper` 中 `session` 的详情，第一个 `session` 的超时时间是60000毫秒，`ephemeral` 节点为0；第二个 `session` 的超时时间是60000毫秒，`ephemeral` 节点为1。

## 清理机制

有两个参数，从不同维度考虑，配置在 `zoo.cfg` 文件中，实现日志文件的清理。

- `autopurge.purgeInterval=24`，在 `v3.4.0` 及之后的版本，`Zookeeper` 提供了自动清理事务日志文件和快照日志文件的功能，这个参数指定了清理频率，单位是小时，需要配置一个1或更大的整数。默认是0，表示不开启自动清理功能
- `autopurge.snapRetainCount=30`，参数指定了需要保留的事务日志文件和快照日志文件的数目，默认是保留3个，和 `autopurge.purgeInterval` 搭配使用


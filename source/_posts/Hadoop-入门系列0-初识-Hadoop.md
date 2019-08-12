---
title: Hadoop 入门系列0--初识 Hadoop
id: 2017040101
date: 2017-04-01 15:58:54
updated: 2018-11-21 15:58:54
categories: Hadoop 从零基础到入门系列
tags: [Hadoop,Zookeeper,HDFS,MapReduce]
keywords: Hadoop,Zokkeeper,入门到精通,Hadoop 入门,HDFS,MapReduce
---


今天是愚人节，可以说是个好日子，也可以说是个坏日子。那我就选择从今天开始整理**Hadoop 入门系列**的博客内容，给自己开个玩笑，同时也给自己定一个目标，看看自己能不能坚持写下去。本文是这一系列博客内容的第零篇：**初识 Hadoop**，会讲一些关于 `Hadoop` 的基础概念以及基本知识点，不需要技术基础，也不需要手动操作，能看懂就行。


<!-- more -->


首先声明，以下内容基于 `Hadoop v1.x` 讲解，不存在 `HA（High Availability，高可用）` 的概念，了解 `v1.x` 的基础概念后，才能更好的继续学习 `v2.x、v3.x` 的内容。由于 `Hadoop` 的 `v2.x、v3.x` 与 `v1.x` 的版本差异比较大，更为复杂，一些概念一开始难以理解，所以采用这种由易入难的方式能循序渐进，有利于初学者、零基础者。


# 入门概念


首先需要了解，`Hadoop` 是什么？简单来说，`Hadoop` 是适合大数据的**分布式存储平台**与**分布式计算平台**，包含两个核心组件，即 `HDFS` 与 `MapReduce`。其中，`HDFS` 的全称是 `Hadoop Distributed File System`，表示一种**分布式文件系统**，`MapReduce` 表示一种**并行计算框架**。

它的创始人是 `Doug Cutting`，现在是 `Cloudera` 的首席架构师。

再说一下关于 `Hadoop` 这个名字的趣事，`Hadoop` 的发音是 `hædu:p`，它的来源是这样的：`Doug Cutting` 的儿子在牙牙学语时，抱着一个黄色的小象玩偶，嘴里发出类似于 `hædu:p` 的发音，`Doug Cutting` 灵光闪现，就把当时正在开发的项目命名为 `Hadoop`。

所以，这个名字不是一个缩写，也不是一个单词，它是一个虚构的名字。该项目的创建者，`Doug Cutting` 如此解释 `Hadoop` 的命名：首先它是我的孩子在玩耍时发出的声音，而我的命名标准就是简短、容易发音、拼写，小孩子都能发出来，就说明选对了。众所周知，给软件命名不是件太容易的事，要尽量找没有被使用过、没有带有特殊意义的词、不会被用于别处，否则把它写进了程序就可能会影响编程。

`Hadoop` 的版本发布有两种：

- `Apache` 开源版本，官方版本
- `Cloudera` 公司维护的打补丁版本，稳定、有商业支持，下载使用比较多


# HDFS 基础知识


`HDFS` 是基于 `Google` 的论文 `The Google File System` 而开发实现的。

## 文件结构

`HDFS` 中的文件有自己独特的存储方式，一个文件会被划分为大小固定的多个文件块，称之为 `block`，分布存储在集群中的多个数据节点上，每个文件块的大小默认为 `64MB`【在 v1.x 中是这个默认值，在 v2.x 默认是128MB】。

文件块的大小参数如下，单位是字节【134217728B 即 128MB】：

```
<property> 
  <name>dfs.blocksize</name>  
  <value>134217728</value> 
</property>
```

![文件块参数设置](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2017/20190812004101.jpg "文件块参数设置")

关于这个文件块参数的解释说明：

>The default block size for new files, in bytes. You can use the following suffix (case insensitive): k(kilo), m(mega), g(giga), t(tera), p(peta), e(exa) to specify the size (such as 128k, 512m, 1g, etc.), Or provide complete size in bytes (such as 134217728 for 128 MB).

参考官网：[hdfs-default.xml](http://hadoop.apache.org/docs/stable/hadoop-project-dist/hadoop-hdfs/hdfs-default.xml) 。

![文件块参数解释说明](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2017/20190812004121.jpg "文件块参数解释说明")

## 副本概念

同时，为了保证数据文件安全，避免丢失，同一个文件块在不同的数据节点中有多个副本。

`HDFS` 设置副本数的参数是在 `hdfs-site.xml` 配置文件中，默认为3，在一般场景下都是可以保证数据安全的。如果觉得浪费资源可以设置为2，但是磁盘的价格是不贵的，多一份可以保障数据更加安全，当然，太多了也没有必要，会造成磁盘的浪费。

```
<property>
  <name>dfs.replication</name>
  <value>3</value>
</property>
```

![副本数参数设置](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2017/20190812004034.png "副本数参数设置")

注意，`HDFS` 中的副本参数的概念不是中文语境下的复制次数，而是总的数量，例如把 **dfs.replication** 设置为3，虽然翻译为副本数为3，其实表示的总共有3份数据【主本1份 + 副本2份】。

注意，如果按照中文语境下的含义来解释，副本数应该是2，加上主本一共有3份数据，这看起来有歧义，也会令人疑惑。它不像在 `Elastisearch` 中设置副本的参数 **number_of_replicas**，表示的就是副本数，如果想保存总共3份数据，需要把 **number_of_replicas** 设置为2 。下图中此参数的值设置为1，即副本为1，表示总共保存2份数据。

![Elastisearch 设置副本数](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2017/20190812003816.jpg "Elastisearch 设置副本数")

## 文件系统

到了这里，我们会思考，文件结构好像还有点复杂，那么 `HDFS` 是怎么管理这些文件的呢？这是接下来的重点。

`HDFS` 这个分布式文件系统遵循**主从结构**，有一个主节点，称之为 `NameNode`【NN，管理节点】，有多个从节点，称之为 `DataNode`【DN，数据节点】。

它们各自的作用如下。

`NameNode` 节点的作用：

- 接收客户端的请求
- 维护分布式文件系统的目录结构
- 管理文件与 `block` 之间的关系，管理 `block` 与 `DataNode` 节点之间的关系

`DataNode` 节点的作用：

- 真正存储文件
- 文件被分成文件块存储到磁盘上，文件块默认大小为 64MB，可以配置
- 为了保证数据安全，文件会被有多个副本，即备份，默认值为3

## 问题思考

1、如果从客户端上传一个文件，大小为 128MB，会有多少个文件块？

答：根据文件块的大小，此时应该有2个文件块，但是由于副本的存在，总计是6个文件块。

2、如果从客户端上传一个文件，大小为 65MB，会有多少个文件块？

答：此时有2个块，一个块大小是 64MB，一个块大小是 1MB，后者占用的真实存储空间也是 1MB，并不是 64MB。副本也是同样的大小。

3、如果从客户端再上传一个大小为 24MB 的文件，那么这个文件块会与2中的那个 1MB 的文件块进行合并吗？

答：不会，文件块不会合并，它只是一个逻辑概念，实际占用的存储空间是以文件大小为准的。所以这个 24MB 的文件上传后是一个独立的文件块，占用存储空间大小为 24MB。

那么有读者可能会疑惑，既然是这样，那这个文件块有什么必要，它的作用是什么？请看 `Hadoop Community` 的解释说明：

>The block size is a meta attribute. If you append tothe file later, it still needs to know when to split further - so it keeps that value as a mere metadata it can use to advise itself on write boundaries.

可见，文件块的概念是一种**元数据**信息，这种概念在很多大数据框架中都能见到，它可以在追加文件时合理地给文件分块【随着对 `HDFS` 的深入理解，后面的博客内容还会解释文件块的合理性】。

此外，使用 `hdfs fsck` 命令【也可以使用已经被废弃的 hadoop fsck】可以查看 `HDFS` 文件的详细信息。

![查看文件详细信息](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2017/20190812003754.jpg "查看文件详细信息")

这里需要看两个重点内容：`Total size:24135B`、`Total blocks(validated):22(avg. block size 1097B)`，其中，前者表示文件的总大小，总计 24135B，后者表示文件块的个数，有22个。但是留意一下最后还有一个备注信息 ：`avg. block size 1097B`，看起来像是文件块的大小【元数据】，其实不是，它是单个文件的平均大小【文件真实大小】，乘以22就等于前面的文件总大小。

关于这一点，`Hadoop Community` 也给出过解释说明：

>The fsck is showing you an "average blocksize", not the block size metadata attribute of the file like stat shows. In this specific case, the average is just the length of your file, which is lesser than one whole block.

此外，从上图中还可以看到文件的**备份数**、**机架数**等信息。

## 副本存放策略

副本的存放策略在不同版本之间存在差异，主要是很久之前的低版本与现在的版本有差异，主要版本分界点在 `v0.17`，下面就以默认的三份副本数为例描述副本的存放策略【如果有更多的副本数，参见**其它副本**的描述】。

`v0.17` 之前【不包含 v0.17】：

- 副本一：同 `Client` 一个机架的不同 `DataNode` 节点
- 副本二：同 `Client` 一个机架的另一个 `DataNode` 节点
- 副本三：不同 `Client` 机架的另一个 `DataNode` 节点
- 其它副本：随机挑选

`v0.17` 之后【包含 v0.17】：

- 副本一：同 `Client` 的 `DataNode` 节点
- 副本二：不同 `Client` 机架的一个 `DataNode` 节点
- 副本三：同副本二的机架中的另一个 `DataNode` 节点
- 其它副本：随机选择

这种副本存放策略有利于数据的安全，就算有的 `DataNode` 节点出问题，也不会引起数据丢失，哪怕事故很严重【例如某个交换机损坏】，导致整个机架的 `DataNode` 节点都出问题，也不会引起数据丢失，这也是副本设置为三份的好处。

## 机架知识

上文的**副本存放策略**中出现了一个名词：**机架**【Rack】，下面使用文字与图片简单描述一下**机架**的概念，免不了还会涉及到**主机**【服务器】、**交换机**、**机柜**的概念。

主机：物理概念，就是一台服务器，永远在运行。

机柜：物理概念，有序存放主机的一个柜子，为了合理利用空间，一个机柜中可以存放多台主机。

交换机：物理概念，连接多台主机的设备，用来给不同主机之间通信使用，一般有连接数量限制，要看交换机上面有多少个网口。

机架：逻辑概念，使用一台交换机连接的所有主机以及机柜构成了一个机架，一个机架可以包含多个机柜、多台主机。

下面给出一个简单的示意图：

![机架示意图](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2017/20190812003731.png "机架示意图")


# MapReduce 基础知识


`MapReduce` 是基于 `Google` 的论文 `Simplified Data Proceessing on Large Clusters` 而开发实现的。

## 基本概念

`MapReduce` 是一种编程模型，具体实现后是一种并行计算框架，用于大规模数据集的并行计算，过程可以拆分为： `Map`、`Reduce`，它是分布式计算的利器，采用分而治之的思维，节约内存【速度比较慢】，并行计算，适合海量数据的处理。

其它的计算框架都采用了类似的思想，理解了 `MapReduce` 就更容易在以后的时间学习其它的框架，例如**Spark**、**Hive**、**HBase**。

## 场景举例

例如当前有一个文本文件，每行有一个数字，求出所有数字中最大的那个，需要分别考虑文件大小为1MB、1GB、1TB等情况。

如果文件比较小，可以随便读取文件的内容加载到内存中，然后遍历元素，进行简单判断，保留最大的那个数字即可。但是，当文本文件非常大的时候，是不可能加载到内存中的，此时需要采用基础算法中的一种常用思想：**分而治之**，即把文本文件拆分为很小的多份文本文件，分别计算最大的数字，最后再汇总，汇总后数据量已经小了很多，最终再计算即可得出想要的结果。

可以从下图看出这种简单的思路过程，比较符合人类自然的思考过程：

![MapReduce 示意图](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2017/20190813000921.png "MapReduce 示意图")

当然，这种方式必然牺牲了时间，拆分文件越多越耗时，但是却节约了空间，不用很大的内存也可以处理海量的数据，这就是 `MapReduce` 的核心思想。

## 主从架构

和 `HDFS` 一样，`MapReduce` 也是**主从架构**，两种节点分别为 `JobTracker`、`TaskTracker`，前者称之为主节点【管理节点】，只有一个，后者称之为从节点【计算节点】，可以有多个。

下面总结一下主节点、从节点各自的作用，读者可以与 `HDFS` 中的 `NameNode`、`DataNode` 的作用对比一下。

`JobTracker` 的作用：

- 接收客户端提交的计算任务
- 把计算任务分配给 `TaskTracker` 执行
- 监控 `TaskTracker` 的执行情况

`TaskTracker` 的作用：

- 执行 `JobTracker` 分配过来的计算任务
- 向 `JobTracker` 汇报任务的执行情况

读者可以思考一下，这种架构是不是很像生活中的领导与员工的关系，或者更为具体一些，像是产品经理与工程师之间的关系，一个人负责接收需求、分配任务、监督执行情况，另外一群人负责具体实现，并定时汇报进度。


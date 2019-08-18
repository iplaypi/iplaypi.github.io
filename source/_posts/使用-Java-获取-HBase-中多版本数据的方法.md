---
title: 使用 Java 获取 HBase 中多版本数据的方法
id: 2019071101
date: 2019-07-11 23:35:05
updated: 2019-08-11 23:35:05
categories: 大数据技术知识
tags: [Java,HBase,version]
keywords: Java,HBase,version
---


最近工作比较繁忙，在处理需求、写代码的过程中踩到了一些坑，不过问题都被我一个一个解决了，所以最近三周都没有更新博客内容。不过，我是整理了提纲、打了草稿，近期会陆续整理出来。今天就先整理出来一个简单的知识点：使用 `Java API` 从 `HBase` 中获取多版本【Version 的概念】数据的方法，开发环境基于 `JDK v1.8`、`HBase v1.1.2`、`Zookeeper v3.4.6`，在演示过程中还会使用原生的 `HBase Shell` 进行配合，加深理解。


<!-- more -->


# 入门概念


先列举一些关于 `HBase` 的基础概念，有助于继续阅读下文，如果不太了解需要先回顾一下：

- 列式分布式数据库，基于 `Google BigTable` 论文开发，适合海量的数据存储
- Rowkey、Column Family、Qualifier、Timestamp、Cell、Version 的概念
- HBase Shell、Java API、Phoenix


# 示例代码


下面的演示会以 `HBase Shell`、`Java API` 这两种方式分别进行，便于读者理解。

## 建表造数据

为了使用 `Java API` 获取多版本数据，我要先做一些基础工作：创建表、造数据、造多版本数据。为了尽量简化数据的复杂度，以及能让读者理解，我准备了2条数据，下面使用一个表格来整理这2条数据，读者可以看得更清晰：

| Rowkey | Column Family | Qualifier | Version | Value |
| :----: | :----: | :----: | :----: | :----: |
|row01|cf|name|1|JIM|
|row01|cf|name|2|Jack|
|row02|cf|name|1|Lucy|
|row02|cf|age|1|20|

从上表可以看出，一共2条数据，`row01` 有1列，2个版本，`row02` 有2列，1个版本。下面使用原生的 `HBase Shell` 开始逐步建表、造数据。

1、进入交互式客户端

使用 `hbase shell` 进入交互式客户端，在输出的日志中可以看到当前环境 `HBase` 的版本号。

登录成功后终端显示：

![登录成功](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20190818192301.png "登录成功")

2、创建表：学生表

使用 `create 'TB_HBASE_STUDENT','cf'` 创建一张表，为了便于后面的操作，表名最好使用大写形式，否则涉及到表名的操作需要加单引号。由于 `HBase` 是列式存储结构，所以创建表时不需要指定具体的列名称，只要指定 `Column Family` 名称即可。

执行后终端显示：

```
0 row(s) in 2.5260 seconds
 => Hbase::Table - TB_HBASE_STUDENT
```

![创建表](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20190818192317.png "创建表")

3、查看表结构

使用 `describe 'TB_HBASE_STUDENT'` 查看表结构，执行后终端显示：

```
Table TB_HBASE_STUDENT is ENABLED
TB_HBASE_STUDENT
COLUMN FAMILIES DESCRIPTION
{NAME => 'cf', BLOOMFILTER => 'ROW', VERSIONS => '1', IN_MEMORY => 'false', KEEP_DELETED_CELLS => 'FALSE', DATA_BLOCK_ENCODING => 'NONE', TTL => 'FOREVER', COMPRESSION => 'NONE', MIN_VERSIONS => '0', BLOCKCACHE => 'true', BLOCKSIZE => '65536', REPLICATION_SCOPE => '0'}
1 row(s) in 0.0390 seconds
```

![查看表结构](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20190818192331.png "查看表结构")

可以看到表的基本信息，其中 `Column Family` 名称为 `cf`，最大版本 `VERSIONS` 为1，这会导致只会存储一个版本的列数据，当再次插入数据的时候，后面的值会覆盖掉前面的值。

4、修改最大版本

为了满足我的需求，需要更改表，把 `cf` 的最大版本数 `VERSIONS` 增加，设置为3 。使用 `alter 'TB_HBASE_STUDENT',{NAME=>'cf',VERSIONS=>3}` 命令即可。执行后终端显示：

```
Updating all regions with the new schema...
0/1 regions updated.
1/1 regions updated.
Done.
0 row(s) in 3.7710 seconds
```

![修改最大版本数](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20190818192344.png "修改最大版本数")

修改成功后，我使用 `describe 'TB_HBASE_STUDENT'` 再次查看表结构，终端显示：

```
Table TB_HBASE_STUDENT is ENABLED
TB_HBASE_STUDENT
COLUMN FAMILIES DESCRIPTION
{NAME => 'cf', BLOOMFILTER => 'ROW', VERSIONS => '3', IN_MEMORY => 'false', KEEP_DELETED_CELLS => 'FALSE', DATA_BLOCK_ENCODING => 'NONE', TTL => 'FOREVER', COMPRESSION => 'NONE', MIN_VERSIONS => '0', BLOCKCACHE => 'true', BLOCKSIZE => '65536', REPLICATION_SCOPE => '0'}
1 row(s) in 0.0380 seconds
```

![再次查看表结构](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20190818192357.png "再次查看表结构")

这次可以看到，`VERSIONS => '3'` 表示 `cf` 已经支持存储3个版本的数据了。

5、插入2条数据

`HBase` 的插入数据功能是使用 `put` 命令，每次插入1列，根据上述表格数据格式，需要执行4次 `put` 操作。

```
put 'TB_HBASE_STUDENT','row01','cf:name','JIM'
put 'TB_HBASE_STUDENT','row01','cf:name','Jack'
put 'TB_HBASE_STUDENT','row02','cf:name','Lucy'
put 'TB_HBASE_STUDENT','row02','cf:age','20'
```

执行后终端显示如下：

```
1.8.7-p357 :012 >   put 'TB_HBASE_STUDENT','row01','cf:name','JIM'
0 row(s) in 0.1600 seconds

1.8.7-p357 :013 > put 'TB_HBASE_STUDENT','row01','cf:name','Jack'
0 row(s) in 0.0180 seconds

1.8.7-p357 :014 > put 'TB_HBASE_STUDENT','row02','cf:name','Lucy'
0 row(s) in 0.0160 seconds

1.8.7-p357 :015 > put 'TB_HBASE_STUDENT','row02','cf:age','20'
0 row(s) in 0.0180 seconds

1.8.7-p357 :016 > 
```

![插入2条数据](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20190818192412.png "插入2条数据")

## 命令行查看

1、先尝试使用 `get` 命令来获取这2条数据，分别执行3次 `get` 操作。

```
get 'TB_HBASE_STUDENT','row02','cf:name'
get 'TB_HBASE_STUDENT','row02','cf:age'
get 'TB_HBASE_STUDENT','row01','cf:name'
```

执行后终端显示如下：

```
1.8.7-p357 :026 >   get 'TB_HBASE_STUDENT','row02','cf:name'
COLUMN                CELL
cf:name               timestamp=1566118670447, value=Lucy

1 row(s) in 0.0160 seconds

1.8.7-p357 :027 > get 'TB_HBASE_STUDENT','row02','cf:age'
COLUMN                CELL
cf:age                timestamp=1566118677185, value=20

1 row(s) in 0.0060 seconds

1.8.7-p357 :028 > get 'TB_HBASE_STUDENT','row01','cf:name'
COLUMN                CELL
cf:name               timestamp=1566118661397, value=Jack

1 row(s) in 0.0080 seconds

1.8.7-p357 :029 >
```

![读取数据](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20190818192431.png "读取数据")

可以看到，此时并没有获取到 `row01` 的2个版本的数据，只获取了最新版本的结果。

2、使用 `get` 获取多版本数据，执行 `get` 时需要加上 `VERSIONS` 相关的参数。

```
get 'TB_HBASE_STUDENT','row01',{COLUMN=>'cf:name',VERSIONS=>3}
```

执行后终端显示如下：

```
1.8.7-p357 :029 > get 'TB_HBASE_STUDENT','row01',{COLUMN=>'cf:name',VERSIONS=>3}
COLUMN                CELL
cf:name               timestamp=1566118661397, value=Jack
cf:name               timestamp=1566118652009, value=JIM

2 row(s) in 0.0140 seconds

1.8.7-p357 :030 >
```

![读取多版本数据](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20190818192445.png "读取多版本数据")

可以看到，2个版本的数据都读取出来了。

3、使用 `scan` 扫描数据

此外还有一个 `scan` 命令可以扫描表中的数据，使用 `scan 'TB_HBASE_STUDENT',{LIMIT=>5}` 尝试扫描5条数据出来。

执行后终端显示如下：

```
1.8.7-p357 :031 >   scan 'TB_HBASE_STUDENT',{LIMIT=>5}
ROW                   COLUMN+CELL
row01                 column=cf:name, timestamp=1566118661397, value=Jack
row02                 column=cf:age, timestamp=1566118677185, value=20
row02                 column=cf:name, timestamp=1566118670447, value=Lucy

2 row(s) in 0.0420 seconds

1.8.7-p357 :032 >
```

![扫描数据](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20190818192456.png "扫描数据")

由于表中只有2条数据，所以只显示出2条，而且 `scan` 默认也是获取最新版本的数据结果。

4、如果想退出 `HBase Shell` 交互式客户端，使用 `!quit` 命令即可。

![退出客户端](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20190818192505.png "退出客户端")

## 代码示例

上面使用原生的 `HBase Shell` 操作演示了创建表、插入数据、读取数据的过程，下面将使用 `Java API` 演示读取数据的过程，而创建表、插入数据的过程就不再演示。

这里需要特别注意，为了正常使用 `Java API` 的相关接口，`Java` 项目需要依赖 `hbase-client`、`commons-configuration`、`hadoop-auth`、`hadoop-hdfs` 等组件。我的代码已经上传至 `GitHub`，详见：[TestHBase.java](https://github.com/iplaypi/iplaypistudy/tree/master/iplaypistudy-hbase/src/main/java/org/playpi/study/test) ，搜索类名 `TestHBase` 即可。

1、代码示例

代码结构比较简单，分为：构造查询请求、发送请求、解析结果输出几部分，注释中也注明了各个部分的作用，总计也就50行代码左右。

```
/**
     * HBase Java API Get测试
     */
public void testGet() {
	String hTableName = "TB_HBASE_STUDENT";
	IplaypiStudyConfig configuration = IplaypiStudyConfig.getInstance();
	byte[] cfbyte = "cf".getBytes();
	byte[] col01byte = "name".getBytes();
	byte[] col02byte = "age".getBytes();
	try {
		// 构造查询请求,2条数据,多个版本
		List<Get> getList = Lists.newArrayList();
		Get get = new Get(Bytes.toBytes("row01"));
		get.addColumn(cfbyte, col01byte);
		// 设置最大版本数,默认为1
		get.setMaxVersions(3);
		getList.add(get);
		Get get2 = new Get(Bytes.toBytes("row02"));
		get2.addColumn(cfbyte, col01byte);
		get2.addColumn(cfbyte, col02byte);
		getList.add(get2);
		// 发送请求,获取结果
		HTable hTable = new HTable(configuration, hTableName);
		Result[] resultArr = hTable.get(getList);
		/**
             * 以下有两种解析结果的方法
             * 1-通过Result类的getRow()和getValue()两个方法,只能获取最新版本
             * 2-通过Result类的rawCells()方法返回一个Cell数组,可以获取多个版本
             * 注意,高版本不再建议使用KeyValue的方式,注释中有说明
             */
		// 1-
		log.info("====get result by first method");
		for (Result result : resultArr) {
			log.info("");
			log.info("--------");
			String rowStr = Bytes.toString(result.getRow());
			log.info("====row:[{}]", rowStr);
			// 如果包含name列,则获取输出
			if (result.containsColumn(cfbyte, col01byte)) {
				String valStr = Bytes.toString(result.getValue(cfbyte, col01byte));
				log.info("====name:[{}],getValue", valStr);
				// 以下方式不建议使用,但是可以获取多版本
				List<KeyValue> keyValueList = result.getColumn(cfbyte, col01byte);
				for (KeyValue keyValue : keyValueList) {
					log.info("====name:[{}],getColumn -> getValue", Bytes.toString(keyValue.getValue()));
				}
			}
			// 如果包含age列,则获取输出
			if (result.containsColumn(cfbyte, col02byte)) {
				String valStr = Bytes.toString(result.getValue(cfbyte, col02byte));
				log.info("====age:[{}],getValue", valStr);
				// 以下方式不建议使用,但是可以获取多版本
				List<KeyValue> keyValueList = result.getColumn(cfbyte, col02byte);
				for (KeyValue keyValue : keyValueList) {
					log.info("====age:[{}],getColumn -> getValue", Bytes.toString(keyValue.getValue()));
				}
			}
		}
		// 2-
		log.info("");
		log.info("====get result by second method");
		for (Result result : resultArr) {
			log.info("");
			log.info("--------");
			String rowStr = Bytes.toString(result.getRow());
			log.info("====row:[{}]", rowStr);
			// name列
			List<Cell> cellList = result.getColumnCells(cfbyte, col01byte);
			// 1个cell就是1个版本
			for (Cell cell : cellList) {
				// 高版本不建议使用
				log.info("====name:[{}],getValue", Bytes.toString(cell.getValue()));
				// getValueArray:数据的byte数组
				// getValueOffset:rowkey在数组中的索引下标
				// getValueLength:rowkey的长度
				String valStr = Bytes.toString(cell.getValueArray(), cell.getValueOffset(), cell.getValueLength());
				log.info("====name:[{}],[getValueArray,getValueOffset,getValueLength]", valStr);
				log.info("====timestamp:[{}],cell", cell.getTimestamp());
			}
			// age列不演示了,省略...
		}
	}
	catch (IOException e) {
		log.error("!!!!error: " + e.getMessage(), e);
	}
}
```

2、运行结果

执行运行，可以看到结果输出，与数据表中一致，多版本数据结果也可以全部获取：

```
2019-08-18_17:54:18 [main] INFO test.TestHBase:58: ====get result by first method
2019-08-18_17:54:18 [main] INFO test.TestHBase:60: 
2019-08-18_17:54:18 [main] INFO test.TestHBase:61: --------
2019-08-18_17:54:18 [main] INFO test.TestHBase:63: ====row:[row01]
2019-08-18_17:54:18 [main] INFO test.TestHBase:67: ====name:[Jack],getValue
2019-08-18_17:54:18 [main] INFO test.TestHBase:71: ====name:[Jack],getColumn -> getValue
2019-08-18_17:54:18 [main] INFO test.TestHBase:71: ====name:[JIM],getColumn -> getValue
2019-08-18_17:54:18 [main] INFO test.TestHBase:60: 
2019-08-18_17:54:18 [main] INFO test.TestHBase:61: --------
2019-08-18_17:54:18 [main] INFO test.TestHBase:63: ====row:[row02]
2019-08-18_17:54:18 [main] INFO test.TestHBase:67: ====name:[Lucy],getValue
2019-08-18_17:54:18 [main] INFO test.TestHBase:71: ====name:[Lucy],getColumn -> getValue
2019-08-18_17:54:18 [main] INFO test.TestHBase:77: ====age:[20],getValue
2019-08-18_17:54:18 [main] INFO test.TestHBase:81: ====age:[20],getColumn -> getValue
2019-08-18_17:54:18 [main] INFO test.TestHBase:86: 
2019-08-18_17:54:18 [main] INFO test.TestHBase:87: ====get result by second method
2019-08-18_17:54:18 [main] INFO test.TestHBase:89: 
2019-08-18_17:54:18 [main] INFO test.TestHBase:90: --------
2019-08-18_17:54:18 [main] INFO test.TestHBase:92: ====row:[row01]
2019-08-18_17:54:18 [main] INFO test.TestHBase:98: ====name:[Jack],getValue
2019-08-18_17:54:18 [main] INFO test.TestHBase:103: ====name:[Jack],[getValueArray,getValueOffset,getValueLength]
2019-08-18_17:54:18 [main] INFO test.TestHBase:104: ====timestamp:[1566118661397],cell
2019-08-18_17:54:18 [main] INFO test.TestHBase:98: ====name:[JIM],getValue
2019-08-18_17:54:18 [main] INFO test.TestHBase:103: ====name:[JIM],[getValueArray,getValueOffset,getValueLength]
2019-08-18_17:54:18 [main] INFO test.TestHBase:104: ====timestamp:[1566118652009],cell
2019-08-18_17:54:18 [main] INFO test.TestHBase:89: 
2019-08-18_17:54:18 [main] INFO test.TestHBase:90: --------
2019-08-18_17:54:18 [main] INFO test.TestHBase:92: ====row:[row02]
2019-08-18_17:54:18 [main] INFO test.TestHBase:98: ====name:[Lucy],getValue
2019-08-18_17:54:18 [main] INFO test.TestHBase:103: ====name:[Lucy],[getValueArray,getValueOffset,getValueLength]
2019-08-18_17:54:18 [main] INFO test.TestHBase:104: ====timestamp:[1566118670447],cell
```

![Java 程序运行结果](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20190818192521.png "Java 程序运行结果")


# 备注

1、在使用 `Java API` 时注意低版本、高版本之间的差异，必要时及时升级，就像上文代码中的 `Result.getColumn`、`KeyValue.getValue()`、`Cell.getValue()` 这几个方法。

2、`Phoenix` 是一款基于 `HBase` 的工具，在 `HBase` 之上提供了 `OLTP` 相关的功能，例如完全的 `ACID` 支持、`SQL`、二级索引等，此外 `Phoenix` 还提供了标准的 `JDBC` 的 `API`。在使用 `Phoenix` 时，可以很方便地像操作 `SQL` 那样操作 `HBase`。

使用 `Phoenix` 创建表、查询数据示例如图。

创建表，使用：`CREATE TABLE IF NOT EXISTS TB_HBASE_STUDENT ("pk" varchar primary key, "cf"."name" varchar,"cf"."age" varchar);`

![使用 Phoenix 创建表](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20190818192546.png "使用 Phoenix 创建表")

查询示例，使用：`select * from "TB_HBASE_STUDENT" limit 5;`

![使用 Phoenix 查询](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20190818192540.png "使用 Phoenix 查询")

3、本示例的代码放在 `GirHub`，详见：[TestHBase.java](https://github.com/iplaypi/iplaypistudy/tree/master/iplaypistudy-hbase/src/main/java/org/playpi/study/test) ，搜索类名 `TestHBase` 即可。参考 `GitHub` 的代码时，注意在 `iplaypistudy-common-config` 模块中增加自己的配置文件，如果开发环境的版本不匹配，也要升级版本，在 `pom.xml` 更改即可。

4、想要使用 `HBase Shell` 删除表时，必须先使用 `disable YOUR_TABLE_NAME` 来禁用表，然后再使用 `drop YOUR_TABLE_NAME` 删除表，直接删除表是不被允许的。


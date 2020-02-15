---
title: es-hadoop 遇上 Elasticsearch 的 Date 类型字段
id: 2018041801
date: 2018-04-18 20:14:18
updated: 2020-01-16 20:14:18
categories: 踩坑系列
tags: [Elasticsearch,Hadoop,Date]
keywords: Elasticsearch,Hadoop,Date
---


最近在项目中遇到一个由 `Elasticsearch` 版本差异引起的奇怪现象，导致程序异常，一开始还以为是程序的问题，后来排查发现是由 `Elasticsearch` 的 `Date` 类型字段引起的，本文记录解决过程。开发环境基于 `Elasticsearch v1.7.5`、`Elasticsearch v2.4.5`。


<!-- more -->


# 问题出现


业务场景是利用 `es-hadoop` 官方工具包读取 `Elasticsearch` 数据，进行一连串 `ETL` 处理，最后再写入 `Elasticsearch` 中。某一次照常处理一批数据，发现异常：

```
java.lang.IllegalArgumentException: 2017/07/23
...省略
org.elasticsearch.hadoop.util.DateUtils.parseDateJdk(DateUtils.java:62)
org.elasticsearch.hadoop.serailization.builder.JdkValueReader.parseDate(JdkValueReader:351)
...省略
```

![异常信息](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2018/20200215180154.png "异常信息")

这导致 `Spark` 进程没有起来，程序退出。通过上面的异常可以明确看到日期转换的错误，无法转换日期为 `2017/07/23` 的数据，下面还有好几个类似的异常，进一步推断是无法转换 `yyyy/MM/dd` 格式的日期。

查看 `Elasticsearch` 的索引 `mapping` 定义，可以看到有一个 `publish_date` 字段的类型为 `Date`，并且设置了自定义格式 `yyyy/MM/dd HH:mm:ss||yyyy/MM/dd`，可以合理对应出现这种现象的数据。

![publish_date 字段](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2018/20200215180503.png "publish_date 字段")

看来是这个 `Date` 类型的字段导致了这个异常，我又翻看了以前的成功任务记录，发现它们处理的数据也有 `publish_date` 字段，但是字段类型是 `long`，存储的是秒级时间戳，所以不会有这个问题。

我又仔细检查了一下线上环境，才发现线上的 `Elasticsearch` 版本升级了【部分业务使用了新的 `Elasticsearch` 集群】，升级为 `v2.4.5`，而以前是 `v1.7.5`，目前处于两者共存的状态，估计以后会逐渐升级。

好，目前把业务场景排查清楚了，接下来准备解决问题。


# 分析解决


先查看一下源码【基于 `elasticsearch-hadoop v2.1.0`】，看看转换逻辑，可以发现，源码中能解析的是国际标准格式的日期，例如：`2018-02-07T05:01:05+08:00`【`ISO date`】，里面带着时区，而现在我们这种 `2017/07/23` 字符串格式的格式化日期，不能被解析。

```
    public static Calendar parseDateJdk(String value) {
        // check for colon in the time offset
        int timeZoneIndex = value.indexOf("T");
        if (timeZoneIndex > 0) {
            int sign = value.indexOf("+", timeZoneIndex);
            if (sign < 0) {
                sign = value.indexOf("-", timeZoneIndex);
            }

            // +4 means it's either hh:mm or hhmm
            if (sign > 0) {
                // +3 points to either : or m
                int colonIndex = sign + 3;
                // +hh - need to add :mm
                if (colonIndex >= value.length()) {
                    value = value + ":00";
                }
                else if (value.charAt(colonIndex) != ':') {
                    value = value.substring(0, colonIndex) + ":" + value.substring(colonIndex);
                }
            }
        }

        return DatatypeConverter.parseDateTime(value);
    }
```

![源码查看](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2018/20200215190242.png "源码查看")

那怎么办呢，再通过查看文档，发现有一个 `elasticsearch-hadoop` 参数可以控制日期类型数据的解析与否，参数名称为：`es.mapping.date.rich`，默认为 `true`，表示自动转换 `Date` 类型的字段，如上面的源码，会尝试解析为 `Calendar` 格式。

但是遇到格式错误的日期取值就抛出异常了，此时可以把这个选项关掉，设置为 `false`，不自动转换，而是直接读取字符串的格式，对字段的校验处理由我们业务的 `ETL` 进行，遇到的不合法的格式直接丢弃并记录就行，不影响整个程序的运行。

下图可以看到源码的解析流程，受到 `richDate` 参数的控制。

![源码查看](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2018/20200215191343.png "源码查看")

注意，这个参数需要 `elasticsearch-hadoop` 的支持，例如 `v1.x` 就不行，必须使用 `v2.x` 或者以上版本。

同时，如果不想更改配置，还有另外一种解决方案，使用 `es.read.field.include` 参数指定必要的某些字段【不包含 `publish_date` 字段】，这样读取数据时就不会把 `publish_date` 字段读取出来了，也就不会涉及格式转换问题。但是此时需要确保处理完成后的数据不会再写回原来的索引，否则会导致数据被覆盖，`publish_date` 字段就会丢失，如果非要写回原来的索引，写入方式使用 `update` 而不是 `index`。


# 扩展


那如果 `Elasticsearch` 里面存储的是毫秒时间戳格式的日期，`elasticsearch-hadoop` 在读取时又是如何处理的呢？下面来验证一下。

首先，在测试的索引里面写入一些测试数据，有一个字段是毫秒时间戳格式：`publish_timestamp`，从 `Elasticsearch` 中挑选1条数据如下：

```
{
  "took": 6,
  "timed_out": false,
  "_shards": {
    "total": 80,
    "successful": 80,
    "skipped": 0,
    "failed": 0
  },
  "hits": {
    "total": 1,
    "max_score": 11.363798,
    "hits": [
      {
        "_index": "ds-banyan-newsforum-post-year-2019-v3",
        "_type": "post",
        "_id": "ae75c92981148654195408f9f5260930",
        "_score": 11.363798,
        "_source": {
          "id": "ae75c92981148654195408f9f5260930",
          "url": "https://fxhh.jd.com/detail.html?id=226608850",
          "publish_timestamp": 1575129850000
        }
      }
    ]
  }
}
```

![查看测试数据](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2018/20200215184320.png "查看测试数据")

配置 `pom.xml` 文件，引入 `v2.4.5` 的 `elasticsearch-hadoop` 依赖。

```
<!-- 2.4.5版本获取Node过程兼容了2.1.0版本,但是读取ES数据中文字段会丢失 -->
<elasticsearch-hadoop.version>2.4.5</elasticsearch-hadoop.version>

        <!-- es-spark,要指定es-hadoop新版本 -->
        <!-- 以下2个依赖包都需要 -->
        <dependency>
            <groupId>org.elasticsearch</groupId>
            <artifactId>elasticsearch-hadoop</artifactId>
            <version>${elasticsearch-hadoop.version}</version>
            <!-- 必须移除,与spark-core_2.10里面有冲突 -->
            <exclusions>
                <exclusion>
                    <groupId>com.esotericsoftware</groupId>
                    <artifactId>kryo</artifactId>
                </exclusion>
            </exclusions>
        </dependency>
        <dependency>
            <groupId>javax.servlet</groupId>
            <artifactId>javax.servlet-api</artifactId>
            <version>4.0.1</version>
        </dependency>
```

测试程序的逻辑就是一个简单的读取数据、`ETL` 处理流程。

```
JavaPairRDD<String, Map<String, Object>> esRDD = JavaEsSpark.esRDD(jsc, sparkConf);
```

在 `ETL` 处理时会取出 `publish_timestamp` 字段进行使用，我们可以本地 `debug` 查看它的取值。

默认情况下，`es.mapping.date.rich` 是开启的【取值为 `true`，自动转换日期字段】，本地 `debug`，查看 `publish_timestamp` 字段的取值，可以发现已经被转为了 `Java` 中的 `Date` 类型【取值 `Sun Dec 01 00:04:10 CST 2019`】。

![转为 Date 类型](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2018/20200215191943.png "转为 Date 类型")

接着关闭 `es.mapping.date.rich`，本地 `debug`，查看 `publish_timestamp` 字段的取值，可以发现仍旧是毫秒时间戳【取值为 `1575129850000`】。

![仍旧是时间戳格式](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2018/20200215192158.png "仍旧是时间戳格式")

把这个毫秒时间戳转为格式化日期，可以看到取值是 `Sun Dec 1 00:04:10 CST 2019`，与上面的 `debug` 结果一致。

![格式化时间戳](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2018/20200215192346.png "格式化时间戳")


# 备注


关于 `elasticsearch-hadoop` 版本的选择，需要慎重，不仅要考虑匹配 `Elasticsearch` 环境的版本，还要注意一些坑。

例如，如果 `Elasticsearch` 版本为 `v2.4.5`，而使用 `elasticsearch-hadoop` 的版本为 `v2.1.0`，此时还无法完美支持 `Date` 字段，进而会导致程序异常，原因就是无法处理 `Date` 类型的字段，配置参数 `es.mapping.date.rich` 可以关闭转换逻辑。

此外最好还是升级 `elasticsearch-hadoop` 版本与 `Elasticsearch` 保持一致，例如升级到 `v2.4.5`【与 `Elasticsearch` 版本保持一致】。

但是，`v2.4.5` 版本的 `elasticsearch-hadoop` 自有它的坑【是很严重的 `bug`】，那就是它在处理数据时，会过滤掉中文的字段，导致读取中文字段丢失，影响中间的 `ETL` 处理逻辑。而如果数据处理完成后，再写回去原来的 `Elasticsearch` 索引就悲剧了，采用 `index` 方式会覆盖数据，导致中文字段全部丢失；采用 `update` 方式不会导致数据覆盖。

中文字段丢失问题，只针对某些版本，关于此问题的踩坑记录可以参考我的另外一篇博客：[es-hadoop 读取中文字段丢失问题](https://www.playpi.org/2017102301.html) 。


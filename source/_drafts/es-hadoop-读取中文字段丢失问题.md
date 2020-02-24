---
title: es-hadoop 读取中文字段丢失问题
id: 2020-02-15 19:30:07
date: 2017-10-23 19:30:07
updated: 2020-02-15 19:30:07
categories:
tags:
keywords:
---


2017102301
踩坑系列
Hadoop,Elasticsearch,Spark

在使用 `elasticsearch-hadoop` 包时遇到一个坑：读取 `Elasticsearch` 数据时会过滤掉中文名称的字段，影响了数据处理流程，排查、测试了一整天才找到根本原因，这个过程可以让我以后在遇到技术问题时快速定位、少走弯路，本文记录这个问题。

涉及到的开发环境基于 `Elasticsearch 2.4.5`，源码分析演示基于 `elasticsearch-hadoop v2.4.5`，当然，`elasticsearch-hadoop v2.3.x` 也是有这个问题的。


<!-- more -->


# 问题出现


首先简单描述一下业务场景：利用 `elasticsearch-hadoop` 包提供的工具，从 `Elasticsearch` 中读取数据，经过一系列的中间 `ETL` 处理，增加部分字段，最终再以 `index` 的方式【没有使用 `update` 的方式】写回原来的索引。

由于以前使用的 `Elasticsearch` 版本比较低，所以使用的 `elasticsearch-hadoop` 版本也比较低，这次临时需要处理 `v2.4.5` 版本的 `Elasticsearch` 数据，所以也升级了 `elasticsearch-hadoop`，于是就发生了问题。

问题现象是：对于一批数据，处理完成之后，再写回原来的索引，发现数据中的中文字段全部消失，而 `ETL` 处理产生的中文字段还在，这就导致这批数据废了，没有用处了。

先检查了 `ETL` 逻辑，没有发现任何问题，不会造成中文字段丢失。又检查了读取数据的配置，有没有设置只是读取部分字段【参数 `es.read.field.include`】，发现并没有单独设置，也就是全部字段都读取。

接着又回退到低版本 `elasticsearch-hadoop v2.1.0`，处理低版本的 `Elasticsearch v1.7.5` 数据，发现正常，处理 `Elasticsearch v2.4.5` 也是正常。

此时就可以严重怀疑是 `elasticsearch-hadoop v2.4.5` 包的问题了，话不多说，直接打开源码排查。

注意：`elasticsearch-hadoop` 中的部分依赖需要被排除，避免冲突：

```
<dependency> 
  <groupId>org.elasticsearch</groupId>  
  <artifactId>elasticsearch-hadoop</artifactId>  
  <version>2.1.0</version>  
  <!-- 必须移除,与spark-core_2.10里面有冲突 -->  
  <exclusions> 
    <exclusion> 
      <groupId>com.esotericsoftware</groupId>  
      <artifactId>kryo</artifactId> 
    </exclusion> 
  </exclusions> 
</dependency>
```

![es-hadoop 依赖](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2017/20200224005458.png "es-hadoop 依赖")

另外还有一种 `elasticsearch-spark` 依赖，它和 `elasticsearch-hadoop` 一样，添加了对 `Elasticsearch` 并发处理的支持扩展，并且它们大部分的源码是一样的，只不过对于 `Spark SQL` 的版本支持不一致。

```
<dependency> 
  <groupId>org.elasticsearch</groupId>  
  <artifactId>elasticsearch-spark_2.10</artifactId>  
  <version>2.1.0</version> 
</dependency>
```

![es-spark 依赖](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2017/20200224010013.png "es-spark 依赖")

看官网说明是为了支持 `spark SQL` 的，链接：[Supported Spark SQL versions](https://www.elastic.co/guide/en/elasticsearch/hadoop/master/spark.html) 。

> Spark SQL while becoming a mature component, is still going through significant changes between releases. Spark SQL became a stable component in version 1.3, however it is not backwards compatible with the previous releases. Further more Spark 2.0 introduced significant changed which broke backwards compatibility, through the Dataset API. elasticsearch-hadoop supports both version Spark SQL 1.3-1.6 and Spark SQL 2.0 through two different jars: elasticsearch-spark-1.x-\<version>.jar and elasticsearch-hadoop-\<version>.jar support Spark SQL 1.3-1.6 (or higher) while elasticsearch-spark-2.0-\<version>.jar supports Spark SQL 2.0. In other words, unless you are using Spark 2.0, use elasticsearch-spark-1.x-\<version>.jar


# 源码分析解读


对于遇到的网络问题【国内网络毕竟有一堵墙存在】，不要着急，解决方案一般有两种：一是设置国内镜像，二是设置代理。对于遇到的各种卡住问题，不少人被折磨的很难受，最后可能就丧失了学习的乐趣，这一点也是令人头疼的地方。

例如给 `Gradle` 设置代理，在项目的 `gradle.properties` 文件中配置【如果放在 `.gradle` 目录下就是全局生效了】：

```
org.gradle.jvmargs=-DsocksProxyHost=127.0.0.1 -DsocksProxyPort=1080
```

例如给 `IDEA` 设置代理，在 `File`、`Settings`、`HTTP Proxy`，选择 `Manual proxy configuration`，就可以设置了，使用 `check connection` 还可以测试代理有没有生效。

## 下载源码

首先需要下载源码，从 `GitHub` 上面下载，下载后记得要切换 `tag`，也就是切换到指定的版本，例如我这里切换到 `tag v2.5.4`【使用命令：`git checkout v2.4.5`】。

## 构建工具

`elasticsearch-hadoop` 使用的构建工具是 `Gradle`，导入 `IDEA` 需要注意【另外 `Elasticsearch` 从 `v5.0` 开始也将构建工具由 `Maven` 切换为 `Gradle` 了】。所以还需要提前安装好 `Gradle`，安装流程和 `Maven` 类似，比较简单，在此不再赘述，读者可以参考官网【最好配置一下 `GRADLE_HOME` 环境变量】。

但是配置时需要注意，如果遇到依赖包下载很慢卡住的现象，一般是网络问题，毕竟中央仓库在国外，地址：[http://repo1.maven.org/maven2](http://repo1.maven.org/maven2) ，所以需要更改仓库的镜像地址，类似于 `Maven` 那样。

当然，如果不配置环境变量，给每个项目都单独配置国内的镜像也可以，需要在项目的 `build.gradle` 文件中配置。

```
repositories {
    maven {
        url 'http://maven.aliyun.com/nexus/content/groups/public/'
    }
    mavenCentral()
}
```

但是如果项目多了需要改镜像地址则稍显麻烦，不如全局变量方便。如果是配置全局的仓库镜像，需要在安装目录下的 `.gradle` 目录中新建 `init.gradle` 文件【其实是一个 `Groovy` 脚本】，填写如下内容：

```
allprojects {
    repositories {
        maven {
            url 'http://maven.aliyun.com/nexus/content/groups/public/'
        }
    }
}
```

以上内容表示给所有的项目都指定了仓库镜像，当然，也可以给部分项目指定【写脚本只处理指定的仓库地址，被替换为我们自己的镜像】：

```
allprojects{
    repositories {
        def REPOSITORY_URL = 'http://maven.aliyun.com/nexus/content/groups/public/'
        all { ArtifactRepository repo ->
            if(repo instanceof MavenArtifactRepository){
                def url = repo.url.toString()
                if (url.startsWith('https://repo1.maven.org/maven2') || url.startsWith('https://jcenter.bintray.com/')) {
                    project.logger.lifecycle "Repository ${repo.url} replaced by $REPOSITORY_URL."
                    remove repo
                }
            }
        }
        maven {
            url REPOSITORY_URL
        }
    }
}
```

此外，别忘记设置**本地仓库**目录，但是 `Gradle` 并没有提供全局的配置文件，只能通过配置环境变量来解决这个问题，使用 `GRADLE_USER_HOME` 环境变量来标记 `Gradle` 的全局变量。如果不设置，默认为用户目录下的 `.gradle` 目录，所以还是设置一下好，例如指定为 `Gradle` 安装目录下的 `.gradle` 目录。

除了通过环境变量来设置，也可以使用 `Gradle` 原生的命令设置：`gradle -g 目录`，`-g` 是 `--gradle-user-home` 的简写。

## scala sdk 安装

`scala` 官网：[scala](https://www.scala-lang.org) 。

如果在 `Build` 过程中发现还是卡住：`Gradle: Resolve dependencies ':classpath'`，千万不要无谓地等待。这乍一看是依赖问题，可能会怀疑镜像的仓库没有设置好，其实不是，而是因为 `scala` 没有安装，`classpath` 环境变量没有配置好，需要下载安装配置。

由于 `elasticsearch-hadoop` 中与 `Elasticsearch` 相关的代码大部分是用 `scala` 写的，所以需要 `IDEA` 安装 `scala` 模块。

如果是直接使用 `IDEA`，打开 `scala` 文件后，它会自动检测并提示 `Setup scala SDK`，只要点击就行了。但是，这个安装包有点大，100MB左右，在国内的网络环境下，不知道要几十个小时，如果下载卡住了，`IDEA` 也就跟着卡住了，此时需要考虑给 `IDEA` 设置代理，即翻墙连接。

如果是在官网手动下载 `scala` 安装包，安装配置环境，类似于 `Java` 那样，也是可以的，但是国内的网络也是不行的【几KB/s】，使用浏览器下载很慢，也可以选择使用迅雷下载，会快很多【100KB/s】。

顺利使用 `IDEA` 打开项目后，就可以开始查看源码了。

## 浏览源码

先说一下核心类：`RestService`、`x`、`y`、`ScrollReader`，画了一张关联图：

图。。。

问题原因：

`es-spark` 读取数据时会获取`ES Mapping`，但是会过滤掉type=completion(这个类型是suggest专有的)的字段,然后使用restcilent srcoll方式读取es的数据,此时会读取包含type=completion字段的数据,此时es-hadoop会进行一个过滤,将type=completion的字段的数据过滤掉,在版本2.3会出现问题是,如果遇见type=completion的字段数据会过滤该数据,同时也会过滤掉后面的其他的字段,所以会导致取出数据不完成。

解决方案:

升级到5.0之后,可以解决该问题,不过如果是type=completion的数据也不会取出来,这时候好像只能用es的自带的接口了。

关键代码：

核心类RestService 读取数据org.elasticsearch.hadoop.rest.RestService.findPartitions方法: 根据shard读取数据,此时先用http _mapping读取mapping,然后进行过滤,过滤方法org.elasticsearch.hadoop.serialization.dto.mapping.Field.parseField内部调 org.elasticsearch.hadoop.serialization.FieldType.isRelevant()读取mapping结束后,采用scroll的方式取数据,核心类org.elasticsearch.hadoop.serialization.ScrollReader ,真正的读取数据读数调用方法:map(String fieldMapping),内部调用过滤方法shouldSkip(absoluteName) --> skipCurrentBlock()[bug方法]


# 备注


如果是使用 `index` 方式把数据写回原始索引，那么这些字段就彻底丢失了。

建议不要使用中文字段名称，虽然 `Elasticsearch` 官方支持，但还是要提防一些未知的坑，哪怕不全是英文字段名称，退一步使用拼音、数字都可以【合法的字母、数字】。

使用 `JDK` 版本的问题，需要适配，如果 `Elasticsearch` 已经升级到 `v5.x`，需要使用 `JDK v1.8` 以及以上的版本【`v1.8.0_73`】，不再支持使用低版本的 `JDK` 了。

官方说明：[setup](https://www.elastic.co/guide/en/elasticsearch/reference/5.0/setup.html) 。

> We recommend installing Java version 1.8.0_73 or later. Elasticsearch will refuse to start if a known-bad version of Java is used.


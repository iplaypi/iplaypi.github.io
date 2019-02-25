---
title: 依赖包缺失导致 Spark 任务无法启动
id: 2018100701
date: 2018-10-07 20:01:41
updated: 2019-02-26 00:01:41
categories: 基础技术知识
tags: [Spark,依赖问题,Maven,FilterRegistration]
keywords: Spark依赖,Maven依赖,FilterRegistration
---


本文讲述使用 Spark 的过程中遇到的错误：

```java
class "javax.servlet.FilterRegistration"'s signer information does not match signer information of other classes in the same package
```

最终通过查找分析 Maven 依赖解决问题。


<!-- more -->


# 遇到问题


由于最近的 elasticsearch 集群升级版本，到了 v5.6.8 版本，所用的功能为了兼容处理高版本的 elasticsearch 集群，需要升级相关依赖包，结果就遇到了问题。

使用 es-hadoop 包（v5.6.8）处理 elasticsearch （v5.6.8）里面的数据，具体点就是通过 es-spark 直接读取 elasticsearch 里面的数据，生成 RDD，然后简单处理，直接写入 HDFS 里面。

编译、打包的过程正常，运行代码的时候，抛出异常：

```java
class "javax.servlet.FilterRegistration"'s signer information does not match signer information of other classes in the same package
```

![报错](https://ws1.sinaimg.cn/large/b7f2e3a3gy1fxyhhwukskj21g20aumyl.jpg "报错")

一看到这种错误，就知道肯定是 Maven 依赖出现了问题，要么是版本冲突，要么是包缺失，但是从这个错误信息里面来看，无法区分具体是哪一种，因为没有报 ClassNotFound 之类的错误。


# 解决方法


现象已经看到了，问题也找到了，那么第一步就是直接搜索 Maven 项目的依赖，看看有没有 FilterRegistration 这个类，我的 IDEA 直接使用 Ctrl + Shift + T 快捷键，搜索 FilterRegistration，发现有这个类，但是包名对不上，注意包名是：javax.servlet。

现在就可以断定，是包缺失，通过搜索引擎查找文档，需要引入 javax.servlet-api 相关的包， pom.xml 文件的具体依赖信息是：

```xml
<dependency>
    <groupId>javax.servlet</groupId>
    <artifactId>javax.servlet-api</artifactId>
    <version>4.0.1</version>
</dependency>
```

当然，版本信息根据实际的场景需要进行选择，我这里选择4.0.1版本。

需要注意的是，有另外一个包，它的 artifactId 是 servlet-api，可能你会因为没看清而配置了这个依赖包，导致还是包缺失，所以一定要看清楚。

我这里遇到的问题比较简单，只是包缺失而已，如果遇到的是包版本冲突，需要移除不需要的版本，只保留一个依赖包即可，此时可以借助 Maven 的 dependency 构建来进行分析查找：

```bash
mvn dependency:tree
```

这个命令会输出项目的所有依赖树，非常清晰，如果内容太多，可以使用：

```bash
mvn dependency:tree > ./tree.txt
```

重定向到文本文件中，再进行搜索查找。


# 总结


1、还遇到一种情况，在正式环境运行正常（没有单独配置这个依赖，使用的是别的依赖包里面的同名类，org.eclipse.jetty.orbit:javax.servlet），但是在本机跑，创建 SparkContext 的时候就会报错，无法创建成功；

2、在本机连接测试环境的 yarn，创建 SparkContext 的时候无法指定用户名，默认总是当前系统的用户名，导致创建 SparkContext 失败，伪装用户无效，只有打 jar 包执行前使用命令切换用户名：export HADOOP_USER_NAME=xx，而在代码中设置 System.setProperty("user.name", "xx")、System.setProperty("HADOOP_USER_NAME", "xx") 是无效的（这个问题会有一篇文章专门分析，需要查看源代码）；

3、针对2的情况，简单通过 local 模式解决，暂时不使用 yarn-client 模式；


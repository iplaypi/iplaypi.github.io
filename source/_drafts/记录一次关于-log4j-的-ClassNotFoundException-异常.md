---
title: 记录一次关于 log4j 的 ClassNotFoundException 异常
id: 2019-07-29 01:04:36
date: 2019-07-29 01:04:36
updated: 2019-07-29 01:04:36
categories:
tags:
keywords:
---
2019073001
基础技术知识
log4j,slf4j,ClassNotFoundException,DailyRollingFileAppender,Spark,maven-shade-plugin,Maven

本来一个正常的 Java 项目，某一次运行的时候发现了一个异常：
`java.lang.ClassNotFoundException: org.apache.log4j.DailyRollingFileAppender`
我觉得很奇怪，这种常用的类怎么可能会缺失。但是，**代码之多，无奇不有**，遇到这种奇怪的问题也是检验我技术高低的良机，看我怎么步步排查，找到问题所在。本文环境基于 `Java v1.8+`、`Spark v1.6.x`。


<!-- more -->


# 问题出现


运行代码报错

错误日志信息如下：

```
log4j:ERROR Could not instantiate class [org.apache.log4j.DailyRollingFileAppender].
java.lang.ClassNotFoundException: org.apache.log4j.DailyRollingFileAppender
	at java.net.URLClassLoader.findClass(URLClassLoader.java:381)
	at java.lang.ClassLoader.loadClass(ClassLoader.java:424)
	at sun.misc.Launcher$AppClassLoader.loadClass(Launcher.java:338)
	at java.lang.ClassLoader.loadClass(ClassLoader.java:357)
	at java.lang.Class.forName0(Native Method)
	at java.lang.Class.forName(Class.java:264)
	at org.apache.log4j.helpers.Loader.loadClass(Loader.java:178)
	at org.apache.log4j.helpers.OptionConverter.instantiateByClassName(OptionConverter.java:317)
	at org.apache.log4j.helpers.OptionConverter.instantiateByKey(OptionConverter.java:120)
	at org.apache.log4j.PropertyConfigurator.parseAppender(PropertyConfigurator.java:629)
	at org.apache.log4j.PropertyConfigurator.parseCategory(PropertyConfigurator.java:612)
	at org.apache.log4j.PropertyConfigurator.configureRootCategory(PropertyConfigurator.java:509)
	at org.apache.log4j.PropertyConfigurator.doConfigure(PropertyConfigurator.java:415)
	at org.apache.log4j.PropertyConfigurator.doConfigure(PropertyConfigurator.java:441)
	at org.apache.log4j.helpers.OptionConverter.selectAndConfigure(OptionConverter.java:468)
	at org.apache.log4j.LogManager.<clinit>(LogManager.java:122)
	at org.slf4j.impl.Log4jLoggerFactory.getLogger(Log4jLoggerFactory.java:64)
	at org.slf4j.LoggerFactory.getLogger(LoggerFactory.java:285)
	at org.slf4j.LoggerFactory.getLogger(LoggerFactory.java:305)
	at com.xxx.yyy.client.hbase.HBaseUtils.<clinit>(HBaseUtils.java:36)
```

图。。

主要看这一行信息：`java.lang.ClassNotFoundException: org.apache.log4j.DailyRollingFileAppender`，找不到 `DailyRollingFileAppender` 这个类。


查了很多网上的相同问题，都说是依赖包缺失，但是我觉得不可能，因为其它模块都在正常使用，于是就验证一下。


在项目中搜索类又能搜索到。
图。。


在依赖树中查看，也能看到关于 `slf4j` 的两个依赖包以及关于 `log4j` 的一个依赖包，说明没有缺失，此时陷入了僵局。

```
[INFO] |  |  +- org.slf4j:slf4j-api:jar:1.7.10:compile
[INFO] |  |  +- org.slf4j:slf4j-log4j12:jar:1.7.10:compile
...
[INFO] +- log4j:log4j:jar:1.2.12:compile

```

图1。。
图2。。


# 问题分析解决


其实，此时需要考虑一个问题，本机查看的项目代码和打包后的可能不一样，比如冲突问题导致的选择，或者插件造成的部分无效依赖被移除。

我也一直在回想我改动了什么代码或者配置，才触发了这个问题，果然，通过 `Git` 的提交记录找到了蛛丝马迹。

最后，通过仔细的对比，发现了问题所在，原来在 pom.xml 文件中，使用了 shade 插件进行依赖瘦身，导致将 slf4j 相关的依赖全部被移除。归根结底，还是因为我在代码中没有使用 slf4j 的相关类【但是父类使用了】，shade 插件误以为这两个依赖都是无用的，就全部移除了。等到程序启动运行的时候，发现找不到相关的类了。

图。。

pom 配置关键代码贴上来。。

```
<!-- shade 构件,打包时可以:包含依赖构件,重命名包名避免冲突,移除特定的类避免冲突 -->
<!-- 具体参考:http://maven.apache.org/plugins/maven-shade-plugin/ -->
<!-- <minimizeJar>true</minimizeJar> 可以自动移除无用的类,瘦身 jar 包 -->
<plugin>
  <groupId>org.apache.maven.plugins</groupId>
  <artifactId>maven-shade-plugin</artifactId>
  <version>3.1.0</version>
  <executions>
    <execution>
      <!-- 绑定 Maven 的 package 阶段 -->
      <phase>package</phase>
      <goals>
        <goal>shade</goal>
      </goals>
      <!-- 详细配置项 -->
      <configuration>
        <!-- 自动移除无用的依赖,坑:项目没用到slf4j,但是依赖的父类用到,却被移除 -->
        <!--<minimizeJar>true</minimizeJar>-->
        <!-- 将指定文件以 append 方式加入到构建的 jar 包中 -->
        <transformers>
          <transformer implementation="org.apache.maven.plugins.shade.resource.AppendingTransformer">
            <resource>reference.conf</resource>
          </transformer>
        </transformers>
        <!-- 过滤匹配到的文件 -->
        <filters>
          <filter>
            <artifact>*:*</artifact>
            <excludes>
              <exclude>META-INF/*.SF</exclude>
              <exclude>META-INF/*.DSA</exclude>
              <exclude>META-INF/*.RSA</exclude>
            </excludes>
          </filter>
        </filters>
        <!-- 附加所有构件,并指定后缀名,与主程序 jar 包区分开 -->
        <shadedArtifactAttached>true</shadedArtifactAttached>
        <shadedClassifierName>jar-with-dependencies</shadedClassifierName>
      </configuration>
    </execution>
  </executions>
</plugin>
```

其中，`<minimizeJar>true</minimizeJar>` 这个配置影响了打包的依赖保留还是去除，也就导致了本文开头的问题。

看来，shade 插件的依赖瘦身功能，还是要慎用，像今天这种情况就很是莫名其妙，只能靠经验来发现问题、解决问题。

只要把这个配置移除，问题就解决了。还有另外一种解决方式，在代码中显式使用 `log4j` 的相关类，其实就是使用 `slf4j` 里面的实现类。


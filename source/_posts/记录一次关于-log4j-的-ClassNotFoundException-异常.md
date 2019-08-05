---
title: 记录一次关于 log4j 的 ClassNotFoundException 异常
id: 2019073001
date: 2019-07-30 01:04:36
updated: 2019-08-05 01:04:36
categories: 基础技术知识
tags: [log4j,slf4j,ClassNotFoundException,DailyRollingFileAppender,Spark,maven-shade-plugin,Maven]
keywords: log4j,slf4j,ClassNotFoundException,DailyRollingFileAppender,Spark,maven-shade-plugin,Maven
---


本来一个正常的 `Java` 项目，某一次运行的时候发现了一个异常：
`java.lang.ClassNotFoundException: org.apache.log4j.DailyRollingFileAppender`，
我觉得很奇怪，这种常用的类怎么可能会缺失。但是，**代码之多，无奇不有**，遇到这种奇怪的问题也是检验我技术高低的良机，看我怎么步步排查，找到问题所在。本文开发环境基于 `Java v1.8+`、`Spark v1.6.x`、`Maven v3.5.x` 。


<!-- more -->


# 问题出现


场景描述：一个常规的 `Java` 项目，单线程处理数据，一直以来都正常运行，某一天我做了小小的代码改动，接着运行就报错。

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

![错误日志片段截图](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20190804183345.png "错误日志片段截图")

错误日志很多，主要看这一行信息：
`java.lang.ClassNotFoundException: org.apache.log4j.DailyRollingFileAppender`，
找不到 `DailyRollingFileAppender` 这个类，即类缺失。显然，这不可能是代码改动引起的问题，这种情况可能是虚拟机没有加载到类，或者加载了多个版本不一致的类导致冲突。

查了很多网上的相同问题，都说是依赖包缺失，但是我觉得不太可能，因为这个 `Java` 项目中的其它模块都能正常使用【使用多个 `Maven` 模块管理整个 `Java` 项目，它们的环境一致】，于是想办法验证一下。

先在 `Java` 项目中搜索类，可以看到能搜索到，说明不会缺失【此处不考虑打包过程中移除的情况】。

![全局搜索类](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20190804183506.png "全局搜索类")

再使用 `mvn dependency:tree` 生成依赖树信息，在依赖树信息中搜索查看，也能看到关于 `slf4j` 的两个依赖包以及关于 `log4j` 的一个依赖包，说明没有缺失。

```
[INFO] |  |  +- org.slf4j:slf4j-api:jar:1.7.10:compile
[INFO] |  |  +- org.slf4j:slf4j-log4j12:jar:1.7.10:compile
...
[INFO] +- log4j:log4j:jar:1.2.12:compile

```

![查看 slf4j 相关类](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20190804183531.png "查看 slf4j 相关类")

![查看 log4j 相关类](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20190804183539.png "查看 log4j 相关类")

根据上面的操作分析，依赖没有缺失，而且，从搜索结果看只有一个类，从依赖树信息中看也没有多版本冲突，此时看似陷入了僵局。


# 问题分析解决


我努力回想改动了什么代码或者配置才会导致这个问题，使用 `Git` 查一下，通过查看提交历史记录，发现了一处微小的改动，在 `Maven` 子模块的 `pom.xml` 文件中。这也是造成这个问题的罪魁祸首，下面详细说明。

其实，此时需要考虑一个问题，本机查看的项目代码和打包后的可能不一样，比如冲突问题导致的版本选择，或者插件造成的部分无效依赖被移除等原因会造成前后差异。

我也一直在回想我改动了什么代码或者配置，才触发了这个问题，果然，通过 `Git` 的提交记录找到了蛛丝马迹。

通过仔细的对比，发现了问题所在，原来在 `pom.xml` 文件中，使用了 `maven-shade-plugin` 插件进行依赖瘦身，导致将 `slf4j`、`log4j` 相关的依赖全部被移除。归根结底，还是因为我在代码中没有使用 `slf4j`、`log4j` 的相关类【但是在父类中使用了】，`maven-shade-plugin` 插件误以为这两个依赖都是无用的，就全部移除了。等到程序启动运行的时候，发现找不到相关的类了。

![shade 插件配置](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20190804183620.png "shade 插件配置")

`pom.xml` 配置信息如下：

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

其中，`<minimizeJar>true</minimizeJar>` 这个配置决定了打包的依赖保留还是移除，我把它配置为 `true`，打包时会自动帮我移除无用的依赖包，其中包括 `log4j`、`slf4j`，也就导致了本文开头的问题。

看来，`maven-shade-plugin` 插件的依赖瘦身功能，还是要慎用，像今天这种情况就很是莫名其妙，只能靠细心、靠经验来发现问题、解决问题，如果是别人的代码还真难发现。

解决方法很简单，只要把这个配置移除【或者设置为 `false`】，问题就解决了。还有另外一种解决方式，在代码中显式使用 `log4j` 的相关类，其实真实是使用 `slf4j` 里面的实现类，这样打包时 `maven-shade-plugin` 插件则不会移除相关的类。


# 问题总结


在这种 `ClassNotFoundException` 异常现象的分析过程中，可以借助一款工具：[Arthas（阿尔萨斯）](https://alibaba.github.io/arthas) ，这是一款由**阿里巴巴**开源的一款 `Java` 诊断工具，深受开发者喜爱。

它可以解决类似如下的问题：

- 这个类从哪个 `jar` 包加载的？为什么会报各种类相关的 `Exception`？
- 我改的代码为什么没有执行到？难道是我没 `commit`？分支搞错了？
- 遇到问题无法在线上 `debug`，难道只能通过加日志再重新发布吗？
- 线上遇到某个用户的数据处理有问题，但线上同样无法 `debug`，线下无法重现！
- 是否有一个全局视角来查看系统的运行状况？
- 有什么办法可以监控到 `JVM` 的实时运行状态？

比如针对我这个场景，我就可以快速查到 `DailyRollingFileAppender` 这个类有没有被虚拟机加载，以及从哪个 `jar` 包加载的。可以快速发现：虚拟机中并没有加载这个类，这个时候就可以断定类缺失，然后转换思路去查为什么类缺失。如果在项目中搜索、查看依赖树信息都没有发现类缺失的迹象，就可以怀疑是不是打包过程中被移除了，甚至可以怀疑是不是上传了错误的 `jar` 包去执行程序。

这样就可以一步一步、有理有据地分析问题，直到解决问题，不至于全程懵逼，靠经验与猜测去碰运气。显然，解决问题的过程肯定是目的明确而且高效的。


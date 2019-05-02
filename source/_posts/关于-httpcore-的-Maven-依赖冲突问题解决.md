---
title: 关于  httpcore 的 Maven 依赖冲突问题解决
id: 2019042201
date: 2019-04-22 20:17:45
updated: 2019-04-22 20:17:45
categories: 踩坑系列
tags: [httpcore,maven,dependency,enforcer]
keywords: httpcore,maven,dependency,enforcer
---


今天，又遇到一个 Maven 冲突的问题，这种问题我遇到的多了，每次都是因为项目依赖管理混乱或者为新功能增加依赖之后影响了旧功能，这次就是因为后者，新增加的依赖的传递依赖覆盖了原有的依赖，导致了问题的产生。大家如果搜索我的博客，搜索关键词 maven 或者 mvn，应该可以看到好几篇类似的文章，每次的情况都略有不同，每次解决问题的过程也是很崩溃。不过，每次崩溃之后都是一阵喜悦，毕竟感觉自己的经验又扩充了一些，以后遇到此类问题可以迅速解决。


<!-- more -->


# 问题出现


写了一个 mapReduce 程序从 HBase 读取数据，写入到 Elasticsearch 中，整体的框架是从别的项目复制过来的，自己重写了处理逻辑以及环境相关的参数，但是跑起来的时候，map 过程很顺利，几百个 task 全部成功完成，但是 reduce 过程直接挂了，几十个 task 全部失败，重试了还是失败。

我只能去查看日志，去 Hadoop 监控界面，看到对应任务的报错日志如下：

```
2019-04-22 16:01:30,469 ERROR [main] com.datastory.banyan.spark.ScanFlushESMRV2$FlushESReducer: org/apache/http/message/TokenParser
java.lang.NoClassDefFoundError: org/apache/http/message/TokenParser
	at org.apache.http.client.utils.URLEncodedUtils.parse(URLEncodedUtils.java:280)
	at org.apache.http.client.utils.URLEncodedUtils.parse(URLEncodedUtils.java:237)
	at org.apache.http.client.utils.URIBuilder.parseQuery(URIBuilder.java:111)
	at org.apache.http.client.utils.URIBuilder.digestURI(URIBuilder.java:181)
	at org.apache.http.client.utils.URIBuilder.<init>(URIBuilder.java:91)
	at org.apache.http.client.utils.URIUtils.rewriteURI(URIUtils.java:185)
	at org.apache.http.impl.nio.client.MainClientExec.rewriteRequestURI(MainClientExec.java:494)
	at org.apache.http.impl.nio.client.MainClientExec.prepareRequest(MainClientExec.java:529)
	at org.apache.http.impl.nio.client.MainClientExec.prepare(MainClientExec.java:156)
	at org.apache.http.impl.nio.client.DefaultClientExchangeHandlerImpl.start(DefaultClientExchangeHandlerImpl.java:125)
	at org.apache.http.impl.nio.client.InternalHttpAsyncClient.execute(InternalHttpAsyncClient.java:129)
	at org.elasticsearch.client.RestClient.performRequestAsync(RestClient.java:343)
	at org.elasticsearch.client.RestClient.performRequestAsync(RestClient.java:325)
	at org.elasticsearch.client.RestClient.performRequestAsync(RestClient.java:268)
	at org.elasticsearch.client.RestHighLevelClient.performRequestAsync(RestHighLevelClient.java:445)
	at org.elasticsearch.client.RestHighLevelClient.performRequestAsyncAndParseEntity(RestHighLevelClient.java:423)
	at org.elasticsearch.client.RestHighLevelClient.bulkAsync(RestHighLevelClient.java:206)
	at com.datastory.banyan.client.es.ESBulkProcessor.lambda$new$0(ESBulkProcessor.java:154)
	at org.elasticsearch.action.bulk.Retry$RetryHandler.execute(Retry.java:230)
	at org.elasticsearch.action.bulk.Retry.withAsyncBackoff(Retry.java:87)
	at org.elasticsearch.action.bulk.BulkRequestHandler$AsyncBulkRequestHandler.execute(BulkRequestHandler.java:138)
	at org.elasticsearch.action.bulk.BulkProcessor.execute(BulkProcessor.java:350)
	at org.elasticsearch.action.bulk.BulkProcessor.executeIfNeeded(BulkProcessor.java:341)
	at org.elasticsearch.action.bulk.BulkProcessor.internalAdd(BulkProcessor.java:276)
	at org.elasticsearch.action.bulk.BulkProcessor.add(BulkProcessor.java:259)
	at org.elasticsearch.action.bulk.BulkProcessor.add(BulkProcessor.java:255)
	at org.elasticsearch.action.bulk.BulkProcessor.add(BulkProcessor.java:241)
	at com.datastory.banyan.client.es.ESBulkProcessor.addIndexRequest(ESBulkProcessor.java:237)
	at com.datastory.banyan.spark.ScanFlushESMRV2$FlushESReducer.reduce(ScanFlushESMRV2.java:212)
	at com.datastory.banyan.spark.ScanFlushESMRV2$FlushESReducer.reduce(ScanFlushESMRV2.java:158)
	at org.apache.hadoop.mapreduce.Reducer.run(Reducer.java:171)
	at org.apache.hadoop.mapred.ReduceTask.runNewReducer(ReduceTask.java:627)
	at org.apache.hadoop.mapred.ReduceTask.run(ReduceTask.java:389)
	at org.apache.hadoop.mapred.YarnChild$2.run(YarnChild.java:168)
	at java.security.AccessController.doPrivileged(Native Method)
	at javax.security.auth.Subject.doAs(Subject.java:422)
	at org.apache.hadoop.security.UserGroupInformation.doAs(UserGroupInformation.java:1709)
	at org.apache.hadoop.mapred.YarnChild.main(YarnChild.java:162)
```

截图如下：
![异常日志信息](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/old/b7f2e3a3gy1g2brjd9bl2j210d0j9q4k.jpg "异常日志信息")

看到关键部分：**java.lang.NoClassDefFoundError: org/apache/http/message/TokenParser**，表面看是类未定义，但是真实情况是什么还要继续探索，例如依赖缺失、依赖冲突导致的类不匹配等。


# 问题解决


## 初步分析

先搜索类 **TokenParser** 吧，看看能不能搜索到，在 IDEA 中搜索，我的环境是使用 **ctrl + shift + t** 快捷键，搜索之后发现存在这个类，记住对应的 jar 包坐标以及版本：

```
org.apache.httpcomponents:httpcore:jar:4.3.2
```

这里需要注意一点，如果你的项目是由多个子项目聚合而成的，此时使用 IDEA 的搜索功能并不准确，会搜索出来其它子项目的同名依赖，从而误导你的视线，所以还是使用依赖分析插件比较好，例如：depedency，下面也会讲到。

既然类已经存在，说明有极大可能是依赖冲突导致的 **NoClassDefFoundError**。继续从错误日志中寻找蛛丝马迹，看到 **at org.apache.http.client.utils.URLEncodedUtils.parse(URLEncodedUtils.java:280)** 这里，接着搜索类 **URLEncodedUtils** 并查看第280行的 **parse** 方法。

```
org.apache.httpcomponents:httpclient:jar:4.5.2
```

上面是依赖坐标以及版本，看到这里有经验的工程师已经可以发现问题所在了：两个同类型的依赖 jar 包版本差别太大，这里暂且不分析。

接着查看源码：
![URLEncodedUtils源码](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/old/b7f2e3a3gy1g2brkjzrvrj20v50djt9j.jpg "URLEncodedUtils源码")

好，到这里已经把基本情况分析清楚了，程序异常里面的 **NoClassDefFoundError** 并不是类缺失，所以没有报错 **ClassNotFound**。根本原因是类版本不对，导致 **URLEncodedUtils** 找不到自己需要的特定版本的类，尽管有一个同名的低版本的类存在，但是对于 Java 虚拟机来说这是完全不同的两个类，这也是容易误导人的地方。

再延伸一下话题，如果真的是类不存在，使用 IDEA 查看源码时会显示红色字体提示的，如图：
![类不存在错误提示](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/old/b7f2e3a3gy1g2brle6hgjj20zc0ieq49.jpg "类不存在错误提示")

## 详细分析

接下来就使用依赖分析插件 **dependency** 来分析这两个 jar 包的来源以及版本差异，在项目的根目录执行 **mvn dependency:tree -Dverbose > tree.txt** ，把依赖树信息重定向到 tree.txt 文件中，里面的 -Dverbose 参数可以使我们更为清晰地看到版本冲突的 jar 包以及实际使用的 jar 包。

找到 httpclient 和 httpcore 的来源，依赖树片段截取如下：

```
[INFO] +- com.company.commons3:ds-commons3-es-rest:jar:1.2:compile
[INFO] |  +- org.apache.httpcomponents:httpclient:jar:4.5.2:compile

......省略

[INFO] |  +- org.apache.httpcomponents:httpasyncclient:jar:4.0.2:compile
[INFO] |  |  +- org.apache.httpcomponents:httpcore:jar:4.3.2:compile
[INFO] |  |  +- (org.apache.httpcomponents:httpcore-nio:jar:4.3.2:compile - omitted for duplicate)
[INFO] |  |  +- (org.apache.httpcomponents:httpclient:jar:4.3.5:compile - omitted for conflict with 4.5.2)
[INFO] |  |  \- (commons-logging:commons-logging:jar:1.1.3:compile - omitted for duplicate)
```

可以看到 **httpclient** 来自于 **ds-commons3-es-rest**，版本为4.5.2，而 **httpcore** 来自于 **httpasyncclient**，版本为4.3.2。

特别注意：**httpasyncclient** 里面还有一个4.3.5版本的 **httpclient** 由于版本冲突被忽略了，这也是导致问题的元凶。

依赖树片段截图如下：
![依赖树片段1](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/old/b7f2e3a3gy1g2brlwy34ij210404e74q.jpg "依赖树片段1")

![依赖树片段2](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/old/b7f2e3a3gy1g2brm3rutxj211508h0tr.jpg "依赖树片段2")

到这里已经可以知道问题所在了，**httpclient**、**httpcore** 这两个依赖的版本差距太大，前者4.5.2，后者4.3.2，导致前者的类 URLEncodedUtils 在调用后者的类 TokenParser 时，找不到满足条件的版本，于是抛出异常：NoClassDefFoundError。

## 解决方案

那这个问题也是很容易解决的，指定版本接近的两个依赖即可，但是还是要根据实际情况而来。本来最简单的方案就是移除所有相关依赖，然后在 pom.xml 中显式地指定这两个依赖的版本。但是这么做太简单粗暴了，因为这两个依赖不是一级依赖，而是传递依赖，不必手动管理。所以要适当地移除某一些传递依赖，保留另一些传递依赖，让它们不要交叉出现。

我的做法就是移除 **ds-commons3-es-rest** 里面的传递依赖，保持 **httpasyncclient** 里面的传递依赖，这样它们的版本号接近，而且是同一个依赖里面传递的，基本不可能出错。

pom.xml 配置如图：
![修复后的pom配置](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/old/b7f2e3a3gy1g2brnorbdej211p0amaaq.jpg "修复后的pom配置")

httpclient 的小版本号是可以比 httpcore 高一点的，继续查看依赖树，可以看到 httpclient 的版本为4.3.5，httpcore 的版本为4.3.2。
![修复后的http依赖版本号](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/old/b7f2e3a3gy1g2brntqakfj20rp021aa1.jpg "修复后的http依赖版本号")

## 引申插件

除了 dependency 插件外，还有另外一个插件也非常好用：enforcer，插件的坐标如下：

```
<!-- 帮助分析依赖冲突的插件,可以在编译时期找到依赖问题 -->
<plugin>
    <groupId>org.apache.maven.plugins</groupId>
    <artifactId>maven-enforcer-plugin</artifactId>
    <version>1.4.1</version>
    <executions>
        <execution>
            <id>enforce-ban-duplicate-classes</id>
            <goals>
                <goal>enforce</goal>
            </goals>
            <configuration>
                <!-- 设置规则,否则没法检查 -->
                <rules>
                    <!-- 检查重复类 -->
                    <banDuplicateClasses>
                        <!-- 忽略一些类 -->
                        <ignoreClasses>
                            <ignoreClass>javax.*</ignoreClass>
                            <ignoreClass>org.junit.*</ignoreClass>
                            <ingoreClass>org.aspectj.*</ingoreClass>
                            <ingoreClass>org.jboss.netty.*</ingoreClass>
                            <ingoreClass>org.apache.juli.*</ingoreClass>
                            <ingoreClass>org.apache.commons.logging.*</ingoreClass>
                            <ingoreClass>org.apache.log4j.*</ingoreClass>
                            <ingoreClass>org.objectweb.asm.*</ingoreClass>
                            <ingoreClass>org.parboiled.*</ingoreClass>
                            <ingoreClass>org.apache.xmlbeans.xml.stream.*</ingoreClass>
                            <ingoreClass>org.json.JSONString</ingoreClass>
                        </ignoreClasses>
                        <!-- 除了上面忽略的类,检查所有的类 -->
                        <findAllDuplicates>true</findAllDuplicates>
                    </banDuplicateClasses>
                    <!-- JDK在1.8以上 -->
                    <requireJavaVersion>
                        <version>1.8.0</version>
                    </requireJavaVersion>
                    <!-- Maven在3.0.5以上 -->
                    <requireMavenVersion>
                        <version>3.0.5</version>
                    </requireMavenVersion>
                </rules>
                <fail>true</fail>
            </configuration>
        </execution>
    </executions>
    <!-- 官方的默认规则 -->
    <dependencies>
        <dependency>
            <groupId>org.codehaus.mojo</groupId>
            <artifactId>extra-enforcer-rules</artifactId>
            <version>1.0-beta-6</version>
        </dependency>
    </dependencies>
</plugin>
```

这个插件需要配置在 pom.xml 中，并且绑定 Maven 的生命周期，默认是绑定在 compile 上面，然后需要给 enforcer 配置一些规则，例如检查重复的类。接着在编译期间，enforcer 插件就会检验项目的依赖中所有的类【可以设置忽略容器中的类，例如作用域为 provided 的依赖包】，如果有重复的类，就会报错，编译不会通过。

注意，这个插件除了可以检查依赖、类的冲突【通过设置规则 rule 来实现】，还可以设置一些其它的开发规范，例如规定 JDK 版本、开发系统环境必须为 Windows、使用的 Maven 版本等等。此外，官方也提供了一些规则列表可以参考：[http://maven.apache.org/enforcer/enforcer-rules/index.html](http://maven.apache.org/enforcer/enforcer-rules/index.html) ，而且还有 API 允许我们自定义规则，非常灵活。


# 问题总结


## 抽象总结

总结一下现象，其实就是项目本来依赖了 B 包，B 包里面有传递依赖包1、包2，由于包1、包2都来自于 B 包，所以版本差别不大，很适配。包1的类调用包2的类很顺利，不会有问题。

后来由于其它功能需要，项目又加入了 A 包，此时没有注意到 A 包里面也有包1，而且比 B 包里面的包1版本高，这本来不是问题，只是潜在风险。但是，编译打包时 A 包里面的包1把 B 包里面的包1覆盖了，包2仍旧是来自于 B 包，这就出问题了，风险变成灾难了。当程序运行时包1需要调用包2，由于版本差别过大，找不到符合条件的类了，抛出异常：NoClassDefFoundError。

这里面的验证机制浅显地描述就是每个类都会有自己的序列化编号，如果有严格要求同版本依赖的类，调用方法时会严格验证。

## 关于编译的疑问

到这里，读者会有疑问，为什么编译不报错，能顺利通过呢？其实从上面就能看到答案了，这种依赖包之间相互引用的类，类是存在的，只是版本不一致而已，编译时并不能检测出来。如果是你自己写的类源码，引用了别的依赖包的类，同时对版本要求严格的话，编译是一定会报错的。

但是，如果你提前知道了是哪个类，一般不可能知道，只有报错了才会知道，而且会有不止一个类，这也是令人头疼的地方。

如果进一步分析异常信息，发现它归属于 ERROR，并不是运行时异常，更不用谈编译时异常了，这种错误和 OutOfMemoryError 类似，是虚拟机运行时出现问题，比较严重。

## 感悟

找到这种问题的原因是没有什么难度的，一眼就可以看出来是依赖冲突。但是解决过程可谓是难度极大，而且可以让人崩溃，对于初学者来说可以放弃了，折腾三天可能都不会有结果的。特别在依赖庞大的情况下，几百个依赖包，几百 M 大小，这时候找起来特别麻烦，有时候改动了一点会影响到其它的依赖，引起连锁反应，可能问题还没解决，又引发了其它问题。

所以，在项目开发的初始阶段，一定要管理好项目的依赖，并且在依赖变更时要一起讨论，否则后患无穷。

此外，在解决依赖冲突的过程中，有2个插件工具很好用：dependency、enforcer。


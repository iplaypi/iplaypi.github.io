---
title: jackson 包缺失导致 NoSuchMethodError
id: 2018120101
date: 2018-12-01 02:02:03
updated: 2018-12-01 02:02:03
categories: 基础技术知识
tags: [NoSuchMethodError,jackson,Maven,SpringMVC]
keywords: java.lang.NoSuchMethodError:com.fasterxml.jackson.databind,java.lang.NoSuchMethodError,com.fasterxml.jackson.databind.JavaType.isReferenceType(),Maven包冲突,Maven包缺失
---

本文讲述 Java 项目由 Maven 包冲突或者缺失导致的运行时错误：
```java
java.lang.NoSuchMethodError: com.fasterxml.jackson.databind.JavaType.isReferenceType()Z
```

<!-- more -->

# 起因

今天在升级 Web 项目的相关接口，更新了所依赖的 SDk 版本，删除了一些旧代码，测试时发现某个功能不可用，直接抛出异常，异常是在运行时抛出的，编译、打包、部署都没有任何问题。

![NoSuchMethodError 异常](https://ws1.sinaimg.cn/large/b7f2e3a3gy1fxqmy8sggbj213t0eyq5s.jpg "NoSuchMethodError 异常")

我看到第一眼，就知道肯定是 Maven 依赖问题，要么是版本冲突（存在不同版本的2个相同依赖），要么是依赖版本不对（太高或者太低），但为了保险起见，我还是先检查了一下 Git 的提交记录，看看有没有对 pom.xml 配置文件做相关改动。检查后发现，除了一些业务逻辑的变动，以及无关 jackson 依赖的版本升级，没有其它对 pom.xml 文件的改动，由此可以断定，某个依赖的升级导致了此问题，问题原因找到了，接下来就是解决问题。

# 解决办法

## 查看项目的 Maven 依赖树

由于依赖太多，使用可视化的插件查看太繁杂，所以选择直接使用 maven 的 dependency 构件来生成文本，然后再搜索查看：
```bash
mvn dependency:tree > tree.txt
```
![mvn 命令行脚本](https://ws1.sinaimg.cn/large/b7f2e3a3gy1fxqnq28eqmj20nb071jrm.jpg "mvn 命令行脚本")

在 tree.txt 文件中搜索 jackson，可以找到 jackson-databind 相关的依赖包，还有 jackson-annotations、jackson-core 这2个依赖包。
![jackson 依赖搜索](https://ws1.sinaimg.cn/large/b7f2e3a3gy1fxqob296i5j218a0q2whw.jpg "jackson 依赖搜索")

jackson-databind 的版本为2.9.3
![jackson-databind 的版本](https://ws1.sinaimg.cn/large/b7f2e3a3gy1fxqovrmijgj20vz0gg0ub.jpg "jackson-databind 的版本")

确定了使用的版本，接下来可以在 IDEA 里面搜索一下这个类，然后再找调用的方法，直接去查看源码，看看到底有没有这个方法。搜索 JavaType Java 类，注意包的路径，可能会有很多重名的类出现，我是用 Ctrl + Shift + T 的快捷键搜索，各位根据自己的快捷键设置进行搜索。
![搜索 JavaType 类](https://ws1.sinaimg.cn/large/b7f2e3a3gy1fxqoyomz3nj21ha0ketbp.jpg "JavaType")

然后进入类的源代码，搜索方法 isReferenceType，报错信息后面的大写的 Z，是 JNI 字段描述符，表示这个方法的返回值类型，Z 表示 Boolean 类型，我们搜索看看有没有这个方法。
![搜索方法 isReferenceType](https://ws1.sinaimg.cn/large/b7f2e3a3gy1fxqp3posd9j218h0l2dhd.jpg "搜索方法 isReferenceType")

我们发现连同名的方法都没有，更不用看返回值类型了，但是注意还是要去父类还有接口里面去搜索一下，保证都没有才是最终的没有。经过查找，没发现这个方法（主要原因是父类 ResolvedType 的版本太低，父类所在的 jackson-core 的版本只有2.3.3，所以找不到这个方法），到这里就要准备升级 jackson-core 或者降级 jackson-databind 依赖了。

## 去除多余依赖

如果是检查到存在依赖冲突的情况，一般是高低版本之间的冲突（最多的情况是多级传递依赖引起的），然后 Maven 编译打包时会全部打进业务的包。

1、导致运行时程序不知道选择哪一个，于是抛出 NoSuchMethodError 异常，此时根据需要，移除多余的依赖包即可；

2、步骤1操作后，还是一种可能是虽然只存在一个版本，但是由于版本太新或者太旧，无法兼容所有的调用，导致多处需要调用这个依赖包的地方总会有某个地方出现 NoSuchMethodError 异常。此时就比较麻烦，如果能找到一个合适版本的依赖包，兼容所有的调用，当然是好的；或者升级调用处对应的接口版本；如果还是无法解决，就只能通过 Shade 构件解决问题了，此处就不赘述了。

经过检查，我这里遇到的就是步骤2的情况，虽然只剩下一个依赖包，但是版本太低或者太高，导致调用时找不到 isReferenceType 方法，类其实是存在的，所以要采用升级或者降级的方式。

## 升级降级依赖

如果是检查到只有一个依赖，并没有冲突的情况，就容易了，直接找到最稳定的版本或者适合使用的旧版本，提取依赖的坐标，配置到 pom.xml 文件中即可。

经过检查，我这里遇到的就是这种情况，去 Maven 私服中搜索 jackson，找到合适的版本（自己根据需要选择，我这里选择 jackson-databind 的2.9.7版本，然后 jackson-core 也指定2.9.7版本，就可以了，然后又查资料也发现这个方法是2.6.0版本之后才开始加上的），配置到 pom.xml 文件中即可。

私服搜索
![jackson 搜索](https://ws1.sinaimg.cn/large/b7f2e3a3gy1fxqnn8b0rmj219s0nugn4.jpg "jackson 搜索")

配置到 pom.xml
![jackson 配置](https://ws1.sinaimg.cn/large/b7f2e3a3gy1fxqq62vwuvj20mw07kdg4.jpg "jackson 配置")

我这里使用了常量，在 pom.xml 文件的 properties 属性下面配置即可。
![Maven 版本常量](https://ws1.sinaimg.cn/large/b7f2e3a3gy1fxqq73kgcsj20oo02o746.jpg "Maven 版本常量")

# 踩坑总结

1、其实 jackson 这个依赖我并没有使用，而是引用的一个第三方依赖内部使用的，但是这个第三方依赖并没有一同打进来，也没有说明需要什么版本的，所以导致我自己在实验，最终找到到底哪一个版本合适。

2、为了统一，jackson-core 的版本要与 jackson-databind 的版本一致，jackson-databind 里面是已经自带了 jackson-annotations 的，由于 jackson-databind 里面的类继承了 jackson-core 里面的，所以才都要升级并且保持版本一致。

3、搜索类方法时，注意留意父类和接口里面，不一定非要在当前类里面出现。更改版本后同样也去类里面搜索一下，看看有没有需要额度方法出现，确定版本用对了再继续做测试。

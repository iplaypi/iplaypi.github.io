---
title: 解决 jar 包冲突的神器：maven-shade-plugin
id: 2019-12-01 00:54:21
date: 2019-12-01 00:54:21
updated: 2019-12-01 00:54:21
categories:
tags:
keywords:
---


2019120101
踩坑记录
Java,Maven,shade


https://www.cnblogs.com/ilinuxer/p/6819560.html

https://blog.csdn.net/taiyangdao/article/details/78324723


还要注意一点，低版本的 `shade` 插件并不支持 `relocation` 参数来制作影子。

v3.2.1

新建模块卡住的问题：

archetypeCatalog=internal

打包完成之后，在解压的包里面可以看到原本com.google.common下面的类全部被保留，低版本的路径没有变化，高版本的被放在了iplaypi下面，而这正是shade的功劳。如此一来，高、低版本的所有类都分离开了，调用方可以任意使用，不会再有冲突或者缺失情况。

当然，调用方的代码处的 import 包路径也被同步替换。

这里需要注意的是，在a中并不能随意调用c中的方法，如果方法不存在的话编译不会通过【maven 先加载了低版本的guava】。而c是一个独立的模块，所以c中的方法不受编译的限制，只有在运行时才会抛出异常。




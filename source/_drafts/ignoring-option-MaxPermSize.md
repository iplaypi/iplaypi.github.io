---
title: ignoring option MaxPermSize
id: 2020-05-15 01:56:05
date: 2018-09-19 01:56:05
updated: 2020-05-15 01:56:05
categories:
tags:
keywords:
---




2018091901：

JVM,Java,MaxPermSize


简单整理


<!-- more -->


遇到warning警告，参数会无效

```
Java HotSpot(TM) 64-Bit Server VM warning: ignoring option MaxPermSize=512m; support was removed in 8.0
```

JDK 8的 JVM 配置；

JDK8中用metaspace代替permsize，因此在许多我们设置permsize大小的地方同样需要修改配置为metaspace

将-XX:PermSize=200m;-XX:MaxPermSize=256m;

修改为：-XX:MetaspaceSize=200m;-XX:MaxMetaspaceSize=256m;


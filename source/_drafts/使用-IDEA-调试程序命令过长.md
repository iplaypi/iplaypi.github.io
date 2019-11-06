---
title: 使用 IDEA 调试程序命令过长
id: 2019-11-06 23:35:22
date: 2019-11-06 23:35:22
updated: 2019-11-06 23:35:22
categories:
tags:
keywords:
---


在日常学习中，使用 `IDEA` 调试 `Java` 程序，突然出现异常：`Command line is too long.`，本文记录过程，开发环境基于 `Windows10 x64`、`JDK v1.8`、`IDEA ULTIMATE 2017.2`。


<!-- more -->

2019040201
踩坑系列
IDEA,Python,Java


# 问题解决


在使用 `IDEA` 调试 `Java` 程序的时候，启动主程序，发现报错，提示信息：

```
Error running TegDataCli: 
Command line is too long. In order to reduce its length classpath file can be used. Would you like to enable classpath file mode for all run configurations of your project?
```

![提示信息](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20191107002909.png "提示信息")

可以看到，应该是触发了什么限制，命令过长，无法继续运行。

可以开启文件模式来避免这个问题，直接在弹出的提示信息中点击 `Enable`即可。

或者，如果弹出的提示信息消失了，也可以直接在 `IDEA` 的配置文件 `.idea/workspace.xml` 【此文件在项目的根目录下】中更改配置，把参数值改为 `false`：

```
<property name="dynamic.classpath" value="false" />
```

参考：[stackoverflow](https://stackoverflow.com/questions/6381213/idea-10-5-command-line-is-too-long) 。


# 备注


另外，在 `Python` 中，也会出现路径长度的限制，安装后需要取消这个限制，否则后续会带来麻烦。这个限制长度和上面那个 IDEA 限制 `Java` 命令的长度有类似含义，可以类比参考，如果读者需要安装使用 `Python` 可以留意一下。

![Python 路径限制](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20191107003421.png "Python 路径限制")


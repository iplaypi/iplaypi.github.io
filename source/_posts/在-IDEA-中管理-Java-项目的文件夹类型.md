---
title: 在 IDEA 中管理 Java 项目的文件夹类型
id: 2018090101
date: 2018-09-01 01:19:36
updated: 2018-09-01 01:19:36
categories: 基础技术知识
tags: IDEA,Java,Maven
keywords: [IDEA,Java,Maven]
---


今天在使用 `IntelliJ IDEA` 时，发现在 `Maven` 项目中无法创建 `Java` 类【在 `test` 目录创建测试用例】，哪怕手动创建了一个 `Java` 类文件，`IDEA` 也无法识别，说明项目的设置有问题。后来检查了一下，发现文件夹类型没有设置为项目的**测试文件夹**。

开发环境基于 `Windows 10`、`IntelliJ IDEA 2017.2`。


<!-- more -->


# 问题出现


在一个 `Maven` 项目中，新建测试用例【在 `test` 文件夹下面】，结果发现 `IDEA` 的右键 `New` 列表中没有对应的选项。

![列表无法选择类文件](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20200308112906.png "列表无法选择类文件")

即找不到 `Java Class`、`Kotlin File/Class` 等等选择，一开始还以为是 `IDEA` 的设置哪里有问题，怀疑被隐藏了，但是找了设置项，并没有发现与此有关的问题。

同时，在 `src main java` 里面可以正常创建类文件，这就可以怀疑是 `Maven` 项目的设置有问题。

![列表可以选择类文件](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20200308112934.png "列表可以选择类文件")

注意到 `test` 文件夹的颜色很普通，这个颜色是 `IDEA` 用来标记文件夹的类型的，说明这个文件夹不受 `IDEA` 管理，它只是一个普通的系统目录而已，看来需要找一下在哪里可以设置这个文件夹类型。


# 问题解决


我们打开 `Maven` 项目的 `Project Structure`，依次找到 `Modules`、`Sources`，可以看到这里对文件夹的类型都做了设置，例如 `Sources`、`Tests`。

![打开模块管理](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20200308113028.png "打开模块管理")

它们分别表示不同的作用，下面简单描述一下：

- `Sources`，源码文件夹，里面存放项目的源码，会被编译、打包
- `Tests`，测试文件夹，里面存放我们写的测试类，编译、打包时可以被移除
- `Resources`，资源文件夹，里面存放配置文件，例如 `xml`、`yaml`、`json` 等等，编译、打包时会被放进 `jar`包里面特有的目录
- `Test Resources`，测试资源文件夹，里面存放测试时的配置文件，编译、打包时可以被移除
- `Excluded`，排除文件夹，里面存放临时文件，例如本地编译的 `class` 文件，本地打包的 `jar` 文件，这些只是自己测试时临时使用，不算是项目的一部分，编译、打包时会被移除

同时，读者可以注意到，这些不同类型的文件夹有不同的颜色，就是为了标记，让用户可以快速分辨。

好，回到我这里的问题，没法新建类文件就是因为 `test` 文件夹没有被设置为**测试文件夹**，在上面的截图中，可以选中文件夹后直接设置，接着就可以新建类文件了。

同时，还有一种快捷的设置方法，在主界面中，选择文件夹，右键后会有一个 `Mark Directory as` 选项【选项中的标识都以 `Root` 作为结尾】，这就是用来设置文件夹的属性的，直接选择即可。

![鼠标右键快捷设置](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20200308113115.png "鼠标右键快捷设置")

好，至此我的问题解决，又可以愉快地去写代码了。


# 备注


0、注意，如果一个文件夹没有被设置为 `Sources Root`，它里面的子文件夹【`Java` 里面的包概念】也是不能被识别为源码目录的，也就是我们无法在里面创建类文件【`Java Class`、`Kotlin File/Class`】，即右键 `New` 里面是没有类文件的选项的，只有普通的文件选项。而且，哪怕我们手动创建一个 `Java` 类文件放进去，`IDEA` 也不会识别管理。

1、在创建 `Maven` 项目时，初始化之后默认会生成各种类型的文件夹，并且会生成一个默认的类文件，如果一开始觉得不需要文件夹而删除，以后新建时记得要把文件夹的属性更改一下，改为对应的类型，否则 `IDEA` 无法做对应的类管理。

2、`IDEA` 官网：[jetbrains](https://www.jetbrains.com/idea) 。


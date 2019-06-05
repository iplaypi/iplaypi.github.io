---
title: Redis Desktop Manager 的安装及使用
id: 2017030301
date: 2017-03-03 23:37:49
updated: 2019-06-05 23:37:49
categories: 大数据技术知识
tags: [Redis,Manager]
keywords: Redis,Manager
---


在技术类岗位的工作中，一般都会使用到 Redis 这个非关系型数据库，在很多场景下它会被作为一个缓存数据库使用。而如果在日常工作中接触到了 Redis，哪怕使用得不是很深入，也需要了解一些 Redis 的基础知识以及常用的命令，以备不时之需。然而，为了方便使用 Redis，还有另外一条路可以选，那就是借助可视化管理工具，让新手或者非技术人员也可以轻松使用 Redis 数据库【例如产品经理、测试人员都可以灵活查询数据库】。而在众多的可视化管理工具中，Redis Desktop Manager 又是比较好用而且轻量的一款工具。本文除了简单介绍一下 Redis 的基础知识，其它篇幅主要讲解这款工具的安装使用，环境基于 Windows 10 X64。


<!-- more -->


# 非关系型数据库的知识入门


什么是非关系型数据库，区别联系，各有什么产品。
Oracle、MySql【免费开源，小巧好用】、SQL Server【微软的产品】、MongodDB、HBase、Neo4j【高性能的 NoSql 图形数据库】、Redis【应用广泛】。

## Redis 介绍

111。

## 常用命令举例

lrange xx 0,-1
lrem xx 0 val
lpop xx


# 可视化管理工具的安装使用


就像在使用关系型数据库的时候，有众多的可视化管理工具可以使用，例如：**MySQL Workbench**、**Navicat**、**phpMyAdmin** 等等。类比一下，在管理 Redis 的时候，就可以使用 Redis 的管理工具 **Redis Desktop Manager**，以下内容介绍这款工具的安装使用，只是入门级别的使用，零基础完全可以上手。

## 安装

从官方网站购买下载，[下载地址](https://redisdesktop.com/download) ，安装包不大，大概27MB。下载完成后直接双击应用程序，根据引导完成安装即可，注意根据实际需要选择安装目录。

下载程序
![下载程序](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20190606005025.png "下载程序")

双击安装
![双击安装](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20190606005035.png "双击安装")

选择安装目录
![选择安装目录](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20190606005046.png "选择安装目录")

安装完成
![安装完成](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20190606005052.png "安装完成")

启动主界面
![启动主界面](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20190606005100.png "启动主界面")

## 创建连接

打开主界面，可以看到左下角有一个绿色的加号，并标识：`Connect to Redis Server`，也就是创建连接，直接点击加号，弹出一个对话框，里面填写连接 Redis 的基本信息：连接名称、主机、端口、认证信息。
创建连接
![创建连接](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20190606005619.png "创建连接")

请大家根据实际情况填写参数，我填写的如下图，连接名称可以是任意的字符串，但是为了有意义不要随便起名字，以免混淆。
填写连接信息
![填写连接信息](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20190606011842.png "填写连接信息")

本来填写完参数就可以直接创建连接了，但是实际的场景可能没有这么简单，可能工作环境不允许直接从本机连接远程的 Redis 服务器，而是需要经过 **SSL 秘钥**、**SSH 隧道**【SSH Tunnel】等认证方式。无论是哪种认证方式，都需要额外配置，例如我的环境需要 **SSH 隧道**认证，其实就是经过一个中间的代理服务器去连接真实线上环境的 Redis 服务器，都是为了安全。因此，我需要额外配置，在 SSH Tunnel 选项卡中填写补充信息，需要填写 SSH 主机的地址、端口、用户名、密码等，记得勾选 `Use SSH Tunnel` 选项。

填写 SSH 隧道信息
![填写 SSH 隧道信息](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20190606011854.png "填写 SSH 隧道信息")

所有的信息填写完成后，不要着急点击 `OK` 创建连接，可以先点击左下角的 `Test Connection` 来测试一下能不能连接成功，用测试连接的结果来验证参数填写是否有误。如果连接失败，会显示失败的具体原因，例如认证不通过、找不到主机、端口访问拒绝等错误，遇到错误再根据实际情况解决即可。下图是我的测试连接，直接成功通过。

测试连接成功
![测试连接成功](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20190606011907.png "测试连接成功")

最后一步，点击 `OK` 按钮，创建连接成功，可以看到主界面左侧的面板中有一个连接，它的名字就是刚才指定的连接名字。

主界面左侧面板
![主界面左侧面板](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20190606012247.png "主界面左侧面板")

## 使用

在主界面的左侧面板中，选择任意一个连接【如果有多个连接的话】，鼠标左键选中时它会自动连接，可以在主界面的中部下方看到有一个 `System log` 的选项卡，里面会实时输出打印连接日志。打开连接后，可以看到 Redis 数据库的默认16个桶，编号从0到15，一般只会用到其中的一个桶，可以看到我这里有两个桶【0号和3号】被使用。

打开连接
![打开连接](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20190606013705.png "打开连接")

如果需要进一步操作数据，直接在展开的树形结构中，选择需要操作的 key，然后可以使用右侧的操作按钮直接操作，例如**删除**、**添加**、**设置 TTL 值** 等，也可以使用鼠标右键选择对应的功能。

查看 Redis 数据
![查看 Redis 数据](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20190606013715.png "查看 Redis 数据")

到这里可以看出，一切操作都是肉眼可见的，很方便而且很容易理解，非技术人员也可以熟练操作。但是，如果你作为一个技术人员，觉得这样用鼠标点来点去很麻烦，想直接使用命令操作怎么办？有办法，这款工具也支持使用命令行操作。

在选中连接后，使用鼠标右键打开选择列表，选择 **Console** 打开连接，即表示连接后进入命令行。
打开命令行
![打开命令行](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20190606014427.png "打开命令行")

接着在主界面的下方就会打开一个名字和连接名字一样的选项卡，里面的背景是灰黑色的，可以看到里面有一个 `Connected` 关键词，这就是进入命令行的样子，接着就可以自由自在地敲下你熟悉的命令了。

使用命令
![使用命令](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20190606014434.png "使用命令")


# 备注


1、Redis Desktop Manager 官方网站：[https://redisdesktop.com](https://redisdesktop.com) ，它是一款收费的软件，价格不贵，不过项目是开源的，贡献代码可以免费使用一定的时间【目前是一年】。

2、Redis 命令大全，参见官方网站：[https://redis.io/commands](https://redis.io/commands) ，列举了十几个系列的命令，总计两百多个命令，请根据实际情况查询使用。


---
title: Win10 取消 Skype for Business 自动登录
id: 2018090701
date: 2018-09-07 12:41:50
updated: 2019-02-17 12:41:50
categories: 知识改变生活
tags: [Skype for Business,自动登录,Win10,Skype]
keywords: 取消 Skype for Business 自动登录,卸载 Skype
---


最近在使用 Win10 系统，遇到一个问题，每次开机，Skype for Business 都会自动弹出来，提示登录，每次我都会关掉它。遇到多次之后，我想这个应用我不需要，直接卸载掉算了，但是却找不到这个应用的信息，最后只能通过关闭**开机自动启动**的方式来解决问题，本文记录解决问题的过程。


<!-- more -->


# 问题出现


最近在使用 Win10 的时候，每次开机后，Skype for Business（这个应用不同于 Skype，虽然功能一样）总会弹出来，提示我登录，我每次都会毫不犹豫地关掉它。

Skype for Business 登录界面
![Skype for Business 登录](https://ws1.sinaimg.cn/large/b7f2e3a3gy1g09f643hbhj20dq0orwf8.jpg "Skype for Business 登录")

正常的 Skype 应用登录界面
![正常的 Skype 应用登录](https://ws1.sinaimg.cn/large/b7f2e3a3gy1g09f6h7kmtj20xc0pwgqj.jpg "正常的 Skype 应用登录")

但是出现多次之后，很麻烦，当我想卸载这个应用的时候，发现从应用列表里面找不到，也就无从卸载。后来就想能不能关闭开机启动，找了一些文档发现可以，那就这么办了（而且还发现 Skype for Business 根本卸载不了）。


# 问题解决

1、Skype for Business 是属于 Office 套件中的一个软件，所以在安装整个 Office 的同时也会自动安装上 Skype for Business。由于是一次安装整个 Office 套件，所以无法单独删除其中的一个软件（Skype for Business）。如果不需要开机自动启动 Skype for Business（也就不会提示我登录了），可以在 Skype for Business 的**设置**菜单中的**个人**选项里将**当我登录到 Windows 时自动启动应用**这个设置取消。

设置（在登录界面的右上角，有一个齿轮按钮）
![设置](https://ws1.sinaimg.cn/large/b7f2e3a3gy1g09f7pheokj20dq0orq3b.jpg "设置")

取消当我登录到 Windows 时自动启动应用
![取消](https://ws1.sinaimg.cn/large/b7f2e3a3gy1g09f87o24fj20qh09sgmz.jpg "取消")

2、不知道哪一天 Windows 升级到了新的系统后，Skype for Business 不见了（怎么找也找不到），随之而来的是 Skype，尽管它也属于 Office 中的一个应用（还有很多其它一系列应用），但是这个应用可以单独安装卸载，不再与 Office 绑为一个整体。

打开我的 Office
![打开我的 Office](https://ws1.sinaimg.cn/large/b7f2e3a3gy1g09f8r9mqgj20i00iu46e.jpg "打开我的 Office")

查看应用列表，也可以直接安装显示的应用
![查看应用列表](https://ws1.sinaimg.cn/large/b7f2e3a3gy1g09f989oipj20rh0go0ti.jpg "查看应用列表")


# 问题总结


1、我是一开始关闭了 Skype for Business 的登录界面，然后再想打开它，就找不到了，不知道在哪（理论上应该隐藏在某个应用列表里面，目前我还没找到，可能是 Windows 系统升级导致的），但是现在却自动有了 Skype 这个应用（可能是 Windows 系统升级替换了以前的 business 版本），其实这2个应用应该差不多。

2、现在 Windows 系统升级到最新版本（最新升级时间是2019-02-17）后，Skype for Business 已经不存在了，替换它的是 Skype，而这个应用是可以单独卸载的。

3、参考：[官方回复](https://answers.microsoft.com/zh-hans/msoffice/forum/msoffice_sfb-mso_win10-mso_o365b/%E6%9C%80%E8%BF%91%E4%B8%80%E5%BC%80%E6%9C%BA/b7ca9aee-76b5-4e7f-a6bc-c94844ed8cdb) 、[设置方式](https://support.office.com/zh-cn/article/%E8%AE%BE%E7%BD%AE-%E4%B8%AA%E4%BA%BA-%E9%80%89%E9%A1%B9-c09b21ac-7334-49cf-a510-d8c432fcaf01)、[Skype for Business 应用介绍](https://support.office.com/zh-cn/article/%E5%AE%89%E8%A3%85%E7%94%B1%E4%B8%96%E7%BA%AA%E4%BA%92%E8%81%94%E8%BF%90%E8%90%A5%E7%9A%84-skype-for-business-93b6e966-120f-493b-955a-365b298ce828) 。


---
title: Chrome 浏览器点击登录就闪退
id: 2020-05-15 02:03:09
date: 2019-0-14 02:03:09
updated: 2020-05-15 02:03:09
categories:
tags:
keywords:
---




2019031401
基础技术知识


简单整理



<!-- more -->


chrome点击登录就闪退

chrome://chrome-signin/?source=2

在地址栏登陆以上地址就可以。

此问题无法解决，因为chrome的原因，只要设置了proxy就会如此。 所以你可以关闭插件，然后用anyconnect或者其他方式连接好vpn，登录google账号，此后再断开vpn，用chrome插件方式，无他法，抱歉。



# 备注



4045 端口，Google 浏览器打不开问题。


/Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome --explicitly-allowed-ports=4045


所以在 Saprk 集群查看任务信息时，如果恰好 Spark UI 申请了这个端口，则无法打开。


---
title: CentOS7 自动安装 Shadowsocks 脚本
id: 2019082801
date: 2019-08-28 23:48:21
updated: 2019-09-19 23:48:21
categories: 技术改变生活
tags: [Shell,shadowsocks,firewalld,Shadowsocks,CentOS]
keywords: Shell,shadowsocks,firewalld,Shadowsocks,CentOS
---


以前我整理过一篇博客，详细叙述了如何自己搭建梯子，图文并茂，可以参见：[使用 Vultr 搭建 Shadowsocks（VPS 搭建 SS）](https://www.playpi.org/2018111601.html) 。里面有涉及到购买一台云服务器后该如何操作：初始化环境、安装 `Shadowsocks`、配置参数、安装防火墙、启动服务、检查服务状态等等步骤。

虽然过程很详细，只要几个命令就可以完成 `Shadowsocks` 服务的搭建，但是对于没有技术基础又不想折腾的读者来说，还是有点困难。所以我把安装过程整理成一个自动化的 `Shell` 脚本，读者下载下来之后，直接运行即可，在运行过程中如果需要交互，例如填写用户名、密码、端口号，读者直接填写即可。


<!-- more -->


首先说明，使用这个自动化 `Shell` 脚本，零基础的读者也可以自行安装 `Shadowsocks`，整个安装过程不到五分钟，非常友好而高效，运行脚本后慢慢等待即可，当然别忘记填写必要信息。

本脚本已经被我上传至 `GitHub`，读者可以下载查看并使用：[auto_deploy_shadowsocks.sh](https://github.com/iplaypi/iplaypistudy/tree/master/iplaypistudy-normal/src/bin/20190828) ，需要注意的是，这个自动化 `Shell` 脚本只针对 `CentOS 7x64` 操作系统有效，其它操作系统我没有测试，不保证能用。所以为了稳妥起见，请读者还是参考我上面给出的那篇博客来创建云主机。


# 自动化安装思路


待整理。


# 自动更换端口重启


待整理。


# 监控服务正常


待整理。


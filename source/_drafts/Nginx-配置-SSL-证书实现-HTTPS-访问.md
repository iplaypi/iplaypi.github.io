---
title: Nginx 配置 SSL 证书实现 HTTPS 访问
id: 2019030501
date: 2019-03-05 02:14:23
updated: 2019-03-06 02:14:23
categories: 建站
tags: [Nginx,https,ssl,证书]
keywords: Nginx,https,ssl,证书
---


由于 GitHub Pages 把百度爬虫屏蔽了，导致百度爬虫爬取不到我的个人主页，所以被百度收录的内容很少，能收录的基本都是我手动提交的。后来我的解决办法就是自己搭建了一台 Web 服务器，然后在 DNSPod 中把百度爬虫的访问流量引到我的 Web 服务器上面，服务器主机是我自己购买的 VPS，服务器应用我选择的是强大的 Nginx。本文就记录 Web 服务器搭建以及配置 SSL 证书这个过程。


<!-- more -->


# 安装Nginx


我的 VPS 是 CentOS 7 X64 版本的，所以安装 Nginx 的过程比较麻烦一点，需要自己下载源码、编译、安装，如果需要用到附加模块【例如 ssl 证书模块】，还需要重新编译，整个过程比较耗时。如果不熟悉的话，遇到问题也要折腾半天才能解决。所以，我在不熟悉的 Nginx 的情况下选择了一种简单的方式，直接自动安装，并自带了一些常用的模块，例如 ssl 证书模块。但是缺点就是安装过程稍微长一点，在网络好的情况下可能需要3-5分钟。我还参考了别人的文档：[https://gist.github.com/ifels/c8cfdfe249e27ffa9ba1]() ，但是仅供参考，因为我发现也有一些不能使用的地方。

## 创建源配置文件

在 /etc/yum.repos.d/ 目录下创建一个源配置文件 nginx.repo，如果不存在这个目录，先使用 mkdir 命令创建目录，然后在目录中添加一个文件 nginx.repo，使用命令：

```bash
vi nginx.repo
```

进入编辑模式，填写如下内容：

```
[nginx]
name=nginx repo
baseurl=http://nginx.org/packages/centos/$releasever/$basearch/
gpgcheck=0
enabled=1
```

编辑完成后保存即可。

## 自动安装 Nginx

接下来就是使用命令自动安装 Nginx 了【敲下命令，看着就行了，会有刷屏的日志输出】：

```bash
yum install nginx -y
```

安装完成后，使用以下命令启动：

```bash
service nginx start
```

可以使用命令 **service nginx status** 查看 Nginx 是否启动：
图。。。

然后你就能看到 Nginx 的主页了，默认是80端口，直接使用 ip 访问即可。
图。。。


# 获取SSL证书、配置参数

## SSL 证书获取

证书的获取可以参考我的文章：[利用阿里云申请免费的 SSL 证书](https://www.playpi.org/2019030401.html)。我在阿里云获取的证书是免费的、有效期一年的，等证书过期了可以重新申请【不知道能不能自动续期】，因为我有阿里云的帐号，所以就直接使用了。当然，通过其它方式也可以获取 SSL 证书，大家自行选择。
阿里云的证书截图。。。

## Nginx 参数配置

更改配置文件，填写自己的配置内容：

```bash
# 配置
vi /etc/nginx/nginx.conf
```

填写内容如下【我这里只是基本的参数，大家当然可以根据实际需要配置更为丰富的参数】：

```

```

## 验证参数是否准确

有时候配置了参数，可能因为字符、参数名问题导致启动失败，然后再回来改配置文件，比较繁琐，所以可以直接使用 Nginx 提供的命令来验证配置文件的内容是否合法，如果有问题可以在输出警告日志中看到，改起来也非常方便。

```bash
nginx -t
```

xx
xx
xx
xx


# 开启端口、启动 Nginx


xx
xx

```bash
# 查看已经开启的端口
firewall-cmd --list-ports
# 开启端口
firewall-cmd --permanent --zone=public --add-port=80/tcp
# 重载更新的端口信息 
firewall-cmd --reload
# 启动Nginx
# 这种方式不行,找不到目录
/etc/init.d/nginx start
# 这种方式可以
service nginx start
# 如果需要重启,直接使用
nginx -s reload
```
xx
xxx


# 验证站点


打开站点，愉快地访问了。
https链接的绿锁
图。。。

查看证书的信息。
图。。。


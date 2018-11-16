---
title: 使用 Vultr 搭建 Shadowsocks（VPS 搭建 SS）
id: 2018111601
date: 2018-11-16 19:25:52
updated: 2018-11-16 19:25:52
categories:
tags: [Shadowsocks,Vultr,Avast,VPS]
keywords: Vultr,Shadowsocks,SS,VPS,搭梯子,梯子搭建,翻墙工具
---

本文讲述通过 Vultr 云主机搭建 Shadowsocks 的过程，非常不详细。当然，关于云主机很多 VPS 都可以选择，根据价格、配置、地区等可以自由选择。

<!-- more -->

# 主机购买

使用Vultr的云主机，选择洛杉矶地区的或者日本的，我的推广链接：[我的推广链接](https://www.vultr.com/?ref=7443790)，官网：[Vultr](https://my.vultr.com)。

价格有 &#36;2.5/月（只有 IP6 地址）、&#36;3.5/月、&#36;5/月等等，更贵的也有，一般选择这三个中的一个就够用了，但是要注意便宜的经常售罄，而且最便宜的只支持 IP6，慎用。

# Shadowsocks服务安装

云主机选择 CentOS 7 x64 版本，全程操作使用 Linux 命令（注意，如果选择其它系统命令会不一致，请自己查询，例如：Debian/Ubuntu 系统的安装命令更简洁，先 apt-get install python-pip，再 pip install shadowsocks 即可）。

注意如果安装了防火墙（更安全），需要的端口一定要开启，否则启动 Shandowsocks 会失败。

安装组件：

``` bash
yum install m2crypto python-setuptools
easy_install pip
pip install shadowsocks
```

过程如图：

![python-setuptools 安装](https://ws1.sinaimg.cn/large/b7f2e3a3gy1fxa31ivc8mj21hc0mhdh5.jpg "python-setuptools 安装")

![pip 安装](https://ws1.sinaimg.cn/large/b7f2e3a3gy1fxa3g9phq7j21hc0jb405.jpg "pip 安装")

![ss 安装](https://ws1.sinaimg.cn/large/b7f2e3a3gy1fxa3h3eeyaj210k04edfx.jpg "ss 安装")

配置服务器参数：

```bash
vi  /etc/shadowsocks.json
```

如下列出主要参数解释说明

| 参数名称 | 解释说明 |
| :------: | :------: |
| server | 服务器地址，填ip或域名 |
|    local_address      | 本地地址 |
| local_port | 本地端口，一般1080，可任意 |
| server_port | 服务器对外开的端口 |
| password | 密码，每个端口可以设置不同的密码 |
| port_password | server_port + password ，服务器端口加密码的组合 |
| timeout | 超时重连 |
| method | 加密方法，默认：“aes-256-cfb” |
| fast_open | 开启或关闭 [TCP_FASTOPEN](https://github.com/shadowsocks/shadowsocks/wiki/TCP-Fast-Open)，填 true / false，需要服务端支持 |

配置多端口信息（多个帐号，多人也可用）：

```json
{
    "server": "你的 IP 地址"（例如：192.168.0.1）,
    "local_address": "127.0.0.1"（默认值）,
    "local_port":1080（默认值）,
    "port_password"（开启的端口和密码，自己按需配置，确保端口打开并不被其它程序占用）: {
        "1227": "pengfeivpn1227",
        "1226": "pengfeivpn1226",
        "1225": "pengfeivpn"
    },
    "timeout":300（超时时间，默认值）,
    "method":"aes-256-cfb"（加密方法，默认值）,
    "fast_open": false
}
```

配置一个端口信息（只有一个帐号，多人也可用）：

```json
{
    "server":"你的 IP 地址"（例如：192.168.0.1）,  
    "server_port":1225（唯一的端口）,
    "local_address":"127.0.0.1",
    "local_port":1080,
    "password":"pengfeivpn"（唯一的密码）,
    "timeout":300,
    "method":"aes-256-cfb",
    "fast_open":false
}
```

Shadowsocks 性能优化：

另外还有很多参数可以优化性能，例如设置连接数、字节大小等，比较复杂，在此略过。

防火墙安装：

```bash
# 安装防火墙
yum install firewalld
# 启动防火墙
systemctl start firewalld
# 端口号是你自己设置的端口
firewall-cmd --permanent --zone=public --add-port=1225/tcp
firewall-cmd --permanent --zone=public --add-port=1226/tcp
firewall-cmd --permanent --zone=public --add-port=1227/tcp
# 重载更新的端口信息
firewall-cmd --reload
```

过程如图：

![安装启动防火墙](https://ws1.sinaimg.cn/large/b7f2e3a3gy1fxa3il37mlj20ka074dfy.jpg "安装启动防火墙")

![开启端口重载](https://ws1.sinaimg.cn/large/b7f2e3a3gy1fxa3hxmaftj20jd04zmx6.jpg "开启端口重载")

启动 Shadowsocks：

```bash
# 后台运行    
ssserver -c /etc/shadowsocks.json -d start
# 调试时使用下面命令，实时查看日志
ssserver -c /etc/shadowsocks.json
```

过程如图：

![启动 ss](https://ws1.sinaimg.cn/large/b7f2e3a3gy1fxa3j16ymwj20hf03eglj.jpg "启动 ss")




# 客户端使用

## Windows平台使用

下载Windows平台的客户端，下载地址：[shadowsocks-windows GitHub](https://github.com/shadowsocks/shadowsocks-windows)，[shadowsocks 官网](http://shadowsocks.org/en/download/clients.html)，直接解压放入文件夹即可使用，不需要安装。

但是注意配置内容（端口、密码、加密协议等等），另外注意有些Windows系统缺失Shadowsocks必要的组件（.NET Framework），需要安装，官网也有说明。

配置示例：

![ss 配置](https://ws1.sinaimg.cn/large/b7f2e3a3gy1fxa3pjtymuj20g60dp75k.jpg "ss 配置")


## Android平台使用

下载Android平台的客户端，下载地址：[shadowsocks 官网](http://shadowsocks.org/en/download/clients.html)。

# 踩坑记录

1、在云主机安装服务端后，又安装了防火墙，但是没有开启 Shadowsocks 需要的端口，导致启动 Shadowsocks 总是失败，但是报错信息又是 Python 和 Linux 的，看不懂，搜索资料也搜不到，后来重装，并且想清楚每一步骤是干什么的，会造成什么影响，通过排除法找到了根本原因。

2、在 Windows 平台使用的时候，安装了客户端，也安装了 .NET Framework 组件，配置信息确认无误，但是就是上不了外网，同样的操作使用Android 客户端却可以，所以有理由怀疑是自己的主机问题。后来，重启系统，检查网络，关闭杀毒软件，还是不行，后来，依靠搜索，找到了是杀毒软件 Avast 的问题，扫描 SSL 连接被开启了，大坑，关闭即可。

![Avast 截图](https://ws1.sinaimg.cn/large/b7f2e3a3gy1fxa0mkrws7j20pc0nkglz.jpg)

3、参考：[梯子搭建](https://github.com/sirzdy/shadowsocks)


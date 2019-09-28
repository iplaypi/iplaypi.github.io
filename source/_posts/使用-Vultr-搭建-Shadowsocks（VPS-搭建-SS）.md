---
title: 使用 Vultr 搭建 Shadowsocks（VPS 搭建 SS）
id: 2018111601
date: 2018-11-16 19:25:52
updated: 2018-11-16 19:25:52
categories:
tags: [Shadowsocks,Vultr,Avast,VPS,影梭]
keywords: Vultr,Shadowsocks,SS,VPS,搭梯子,梯子搭建,翻墙工具,影梭
---


本文讲述通过 `Vultr` 云主机搭建 `Shadowsocks` 的过程，图文并茂，非常详细。当然，关于云主机有很多 `VPS` 都可以选择，例如**搬瓦工**、**Godaddy**、**Vultr**，读者可以根据价格、配置、地区、操作系统等因素自由选择，但我还是推荐 `Vultr`，因为它扣费灵活、主机管理灵活、价格优惠，并且还支持支付宝和微信支付，简直太方便了。

**声明**：2019年08月09日发现 `Vultr` 官方不会再赠送`$10`的代金券给新注册用户，只会给我发放代金券，但是`$25`的代金券仍然有效，请读者选择`$25`对应的链接打开注册，以免错失了代金券。


<!-- more -->


# 主机购买


使用 `Vultr` 的云主机，最好选择洛杉矶地区的或者日本的服务器，我亲自测试这两个地区的服务器最稳定，已经推荐给很多人，而且网速相对来说较好，我的推广链接【可以获取10美元的代金券，只要充值10美元就能使用】：[我的10美元推广链接](https://www.vultr.com/?ref=7443790) ，官网链接也在这里：[Vultr](https://my.vultr.com) 。

这里再多说点，如果使用上面的推广链接注册 `Vultr` 帐号，可以获取10美元的代金券，需要在30天之内使用，使用的条件就是充值10美元以上的钱。例如充值10美元就会获取20美元的帐号余额，这些钱如果购买3.5美元的主机可以使用半年了，挺划算的。

此外还有一个限时的大优惠，如果准备长期使用 `Vultr`，肯定要充值多一点，我这里有一个限时的推广链接：[我的25美元推广链接](https://www.vultr.com/?ref=7861302-4F) ，可以获取25美元的代金券，使用条件就是充值25美元以上的金额。假如充值了25美元，总共获取50美元入账，购买3.5美元的主机可以使用14个多月，适合长期使用 `Vultr` 的。

以下列举 `Vultr` 的五大好处：

- **扣费灵活**，`Vultr` 有一个好处就是主机的费用并不是按照月份扣除的，而是按照天扣除的，每天扣除的费用是 **月租/30**。例如你的主机只用了10天，然后销毁不用了，实际只会扣除月租1/3的钱，这种方式很是灵活，哪怕主机的 `IP` 地址被屏蔽了也可以销毁重新生成一个，并不会浪费钱。它不像国内的云服务商，一般是按照月份扣费的。
- **主机管理灵活**，它不像国内的云服务商，购买一台云主机后，直接先扣费，然后分配一台主机，`IP` 地址是固定的，如果有问题只能重启。而在 `Vultr` 中是可以随意创建、销毁虚拟主机的，根据你自己的需求，选择配置、主机机房位置、操作系统，几分钟就可以生成一台主机，如果用了几天觉得不好，或者 `IP` 地址被封，再销毁重新创建即可，`Vultr` 只会扣除你几天的费用，非常人性化。
- **价格优惠**，根据配置的不同，价格有多个档次，有 `$2.5/月`（只有 `IP6` 地址）、`$3.5/月`、`$5/月`等等，更贵的也有，一般个人使用选择这三个中的一个就够用了，但是要注意便宜的经常售罄，而且最便宜的只支持 `IP6`，慎用。大家如果看到没有便宜的主机了不用着急，可以先买了贵的用着，反正费用是按照天数扣除的，等后续发现便宜的套餐赶紧购买，同时把贵的主机给销毁，不会亏钱的。
- **付费方式灵活**，付费方式除了支持常见的**Paypal**、**信用卡**等方式，它还支持**比特比**、**支付宝**、**微信**等方式。就问你是不是很人性化，作为一家国外的公司，还特意支持**支付宝**、**微信**的方式支付，也从侧面反映了随着中国的日益强大，中国的电子支付方式正在走向全球，越来越流行。
- **机房分布全球**，它的机房位置遍布全球，例如**日本**、**新加坡**、**澳大利亚**、**美国**、**德国**、**英国**、**加拿大**，读者根据网络的需求可以灵活选择。

关于 `Vultr` 云主机的生成以及 `Vultr` 系统的常用功能使用，由于不在这篇博客的介绍内容中，所以在此不再赘述。但是，我会在以后的某一天把它补充完整，并放上链接：[使用 Vultr 创建云主机详细步骤](https://www.playpi.org/2019072801.html) 。


# Shadowsocks服务安装


下文中涉及的 `shadowsocks` 配置文件模板已经被我上传至 `GitHub`，读者可以提前下载参考：[shadowsocks_conf](https://github.com/iplaypi/iplaypistudy/tree/master/iplaypistudy-normal/src/resource/20181116) ，有两份，一份是单用户的【只开一个端口】，一份是多用户的【开多个端口】。

再说明一下，如果有技术零基础的读者不想折腾，就不用往下看了，可以直接参考我的另外一篇博客：[CentOS7 自动安装 Shadowsocks 脚本](https://www.playpi.org/2019082101.html) ，只要下载对应的自动安装脚本，就可以一键运行、自动安装，不需要考虑是否有技术基础，边等边喝水，几分钟就会安装完成。

下面开始进入正题，详细描述 `shadowsocks` 服务的手动安装过程。

云主机选择 `CentOS 7 x64` 版本，全程操作使用 `Linux` 命令【注意，如果选择其它系统命令会不一致，请自己查询，例如：`Debian/Ubuntu` 系统的安装命令更简洁，先 `apt-get install python-pip`，再 `pip install shadowsocks` 即可】。

注意如果安装了防火墙【更安全】，需要的端口一定要开启，否则启动 `Shandowsocks` 会失败。

安装组件：

``` bash
yum install m2crypto python-setuptools
easy_install pip
pip install shadowsocks
```

过程如图：

![python-setuptools 安装](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/old/b7f2e3a3gy1fxa31ivc8mj21hc0mhdh5.jpg "python-setuptools 安装")

![pip 安装](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/old/b7f2e3a3gy1fxa3g9phq7j21hc0jb405.jpg "pip 安装")

![ss 安装](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/old/b7f2e3a3gy1fxa3h3eeyaj210k04edfx.jpg "ss 安装")

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

配置多端口信息【多个帐号，多人也可用】：

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

配置多端口信息【纯净版本，更改 `ip`、端口等信息直接复制使用】：

```json
{
    "server": "x.x.x.x",
    "local_address": "127.0.0.1",
    "local_port":1080,
    "port_password": {
        "1227": "vpn1227",
        "1226": "vpn1226",
        "1225": "vpn"
    },
    "timeout":300,
    "method":"aes-256-cfb",
    "fast_open": false
}
```

配置一个端口信息【只有一个帐号，多人也可用】：

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

配置一个端口信息【纯净版本，更改 `ip`、端口等信息直接复制使用】：

```json
{
    "server":"x.x.x.x",  
    "server_port":1225,
    "local_address":"127.0.0.1",
    "local_port":1080,
    "password":"vpn",
    "timeout":300,
    "method":"aes-256-cfb",
    "fast_open":false
}
```

`Shadowsocks` 性能优化：

另外还有很多参数可以优化性能，例如设置连接数、字节大小等，比较复杂，在此略过。

防火墙安装：

```bash
# 安装防火墙
yum install firewalld
# 启动防火墙
systemctl start firewalld
# 查看目前已经开启的端口号
firewall-cmd --list-ports
# 端口号是你自己设置的端口
firewall-cmd --permanent --zone=public --add-port=1225/tcp
firewall-cmd --permanent --zone=public --add-port=1226/tcp
firewall-cmd --permanent --zone=public --add-port=1227/tcp
# 重载更新的端口信息
firewall-cmd --reload
```

过程如图：

![安装启动防火墙](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/old/b7f2e3a3gy1fxa3il37mlj20ka074dfy.jpg "安装启动防火墙")

![开启端口重载](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/old/b7f2e3a3gy1fxa3hxmaftj20jd04zmx6.jpg "开启端口重载")

这里需要注意，如果没安装防火墙，或者安装防火墙但是没有开启端口，启动 `Shadowsocks` 时会报错：**socket.error: [Errno 98] Address already in use**，启动失败，无法提供翻墙服务，而且不要被错误信息误导，不是端口被占用，是端口没有开启。

启动 `Shadowsocks`：

```bash
# 后台运行    
ssserver -c /etc/shadowsocks.json -d start
# 调试时使用下面命令，实时查看日志
ssserver -c /etc/shadowsocks.json
# 停止运行    
ssserver -c /etc/shadowsocks.json -d stop
```

过程如图：

![启动 ss](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/old/b7f2e3a3gy1fxa3j16ymwj20hf03eglj.jpg "启动 ss")

在使用 **ssserver -c /etc/shadowsocks.json** 查看启动日志时，发现除了正常的启动信息，还会有错误信息：

```
INFO: loading config from /etc/shadowsocks.json
2019-05-06 15:46:11 INFO     loading libcrypto from libcrypto.so.10
2019-05-06 15:46:11 INFO     starting server at 66.42.105.87:1227
Traceback (most recent call last):
  File "/usr/bin/ssserver", line 9, in <module>
    load_entry_point('shadowsocks==2.8.2', 'console_scripts', 'ssserver')()
  File "/usr/lib/python2.7/site-packages/shadowsocks/server.py", line 68, in main
    tcp_servers.append(tcprelay.TCPRelay(a_config, dns_resolver, False))
  File "/usr/lib/python2.7/site-packages/shadowsocks/tcprelay.py", line 582, in __init__
    server_socket.bind(sa)
  File "/usr/lib64/python2.7/socket.py", line 224, in meth
    return getattr(self._sock,name)(*args)
socket.error: [Errno 98] Address already in use
```

错误信息截图
![错误信息截图](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20190507000812.png "错误信息截图")

根据关键词 **socket.error: [Errno 98] Address already in use** 查阅资料，发现是主机的配置问题，停止的 `ss` 服务没有及时释放端口，导致启动时报错。但是我发现这种报错信息并没有影响到后台 `ss` 服务的正常启动，也就是说端口正常提供服务，可以顺利翻墙。同时，我按照其他人的解释说明，在 **/etc/sysctl.conf** 配置文件中增加了 `ip` 的配置：

```
net.ipv4.tcp_syncookies = 1 
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_tw_recycle = 1
net.ipv4.tcp_fin_timeout = 5
```

然后使用 **/sbin/sysctl -p** 命令让内核参数生效，结果在重启 `ss` 服务时看到日志里面还会有上面那种错误信息。后续考虑到这种现象并没有影响正常的服务，也就先不放在心上，专心做其它的工作。


# 客户端使用


## Windows平台使用

下载 `Windows` 平台的客户端，下载地址：[shadowsocks-windows GitHub](https://github.com/shadowsocks/shadowsocks-windows)，[shadowsocks 官网](http://shadowsocks.org/en/download/clients.html)，直接解压放入文件夹即可使用，不需要安装。

但是注意配置内容【端口、密码、加密协议等等】，另外注意有些 `Windows` 系统缺失 `Shadowsocks` 必要的组件【`.NET Framework`】，需要安装，官网也有说明。

配置示例：

![ss 配置](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/old/b7f2e3a3gy1fxa3pjtymuj20g60dp75k.jpg "ss 配置")

实际上下载程序后，无需安装，直接解压即可，解压后只有一个 `exe` 文件，双击即可运行【最好放入指定文件夹中，便于程序管理和升级】。第一次启动，需要设置参数，如上图所示，至少配置一台机器，另外还可以设置开机启动，以后不用重新打开。此外，如果有更新版本的程序，会放在 `ss_win_temp` 文件夹下，直接解压后复制替换掉当前的 `exe` 文件即可；如果文件夹中有 `gui-config.json`、`statistics-config.json` 这2个文本文件，它们是程序的配置以及前面设置的翻墙配置，不能删掉；如果使用系统代理的 `PAC` 模式（推荐使用），会生成 `pac.txt` 文本文件，存放从 `GFWList` 获取的被墙的网址，必要时才会通过翻墙代理访问，其它正常的网址则直接访问，这样可以节约流量。

![ss 文件夹](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/old/b7f2e3a3ly1fxbhx6e12jj20h004qgln.jpg "ss 文件夹")

如果有切换代理的需求，搭配浏览器的插件来完成，例如 [Proxy SwitchyOmega](https://chrome.google.com/webstore/detail/proxy-switchyomega/padekgcemlokbadohgkifijomclgjgif?hl=zh-CN) 就可以。

关于启动系统代理并使用 `PAC` 模式【根据条件过滤，不满足的直连】，如果是入门级别使用，直接设置完就可以用了，不用再管其它设置，切记要定时更新 `GFWList` 列表，因为如果某些网站最近刚刚被屏蔽，不在以前的 `HFWList` 列表里面，就会导致无法连接，只有及时更新才能正常连接。但是还有一种极端情况，就是某些网站 `GFWList` 迟迟没有收录，怎么更新都不会起作用，别着急，此时可以使用用户自定义规则，模仿 `GFWList` 填写自己的过滤规则，即可实现灵活的切换，使用用户自定义规则后会在安装文件夹中生成 `user-rule.txt` 文本文件。

![开启系统代理并使用PAC模式](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/old/b7f2e3a3gy1fxbo5moanxj20cj0a5dga.jpg "开启系统代理并使用 PAC 模式")

![PAC 模式下更新 GFWList 内容](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/old/b7f2e3a3gy1fxbo6rej96j20ip0axjs7.jpg "PAC 模式下更新 GFWList 内容")

![PAC 模式下自定义过滤规则](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/old/b7f2e3a3gy1fxbo7ifow9j20j80apt9k.jpg "PAC 模式下自定义过滤规则")

其实，`PAC` 模式的原理就是根据公共的过滤规则【收集被屏蔽的网站列表】，自动生成了一个脚本文件，把脚本文件绑定到浏览器的代理设置中，使浏览器访问网站前都会运行这个脚本，根据脚本的结果决定是直接访问还是通过本地代理访问，脚本在 `Shadowsocks` 的 `PAC` 设置中可以看到，浏览器的设置信息可以在代理设置中看到【浏览器在 `Shadowsocks` 开启系统代理的时候会自动设置代理，无需人工干预】。

由此可以得知，通过本机访问网络，决定是直接连接还是通过 `Shadowsocks` 代理连接的是 `PAC` 脚本，并不是 `Shadowsocks` 本身，所以如果使用系统的 `Ping` 命令访问 www.google.com 仍然是不能访问的，因为直接 `Ping` 没有经过 `PAC` 脚本，还是直接连接了，不可能访问成功。除了浏览器之外，如果其它程序也想访问被屏蔽的网站【例如 `Git`、`Maven` 仓库】，只能通过程序自己的代理设置进行配置，完成访问的目的。【如果放弃 `PAC` 模式，直接使用全局模式，则不需要配置任何信息，本机所有的网络请求会全部经过翻墙代理，当然这样做会导致流量消耗过大，并且国内的正常网站访问速度也会很慢】

![获取 PAC 的脚本地址](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/old/b7f2e3a3gy1fxbof33m9dj20ij0aa0tl.jpg "获取 PAC 的脚本地址")

获取到的 `PAC` 脚本地址为：
http://127.0.0.1:1080/pac?t=20181118030355597&secret=qZKsW49fDFezR4jJQtRDhUVPRqnFu6JC3Nc+vtXDb0g=

![浏览器代理配置](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/old/b7f2e3a3gy1fxboiacqtbj20se0kojse.jpg "浏览器代理配置")

以上是查看 `Chrome` 浏览器和 `IE` 浏览器的代理设置信息，对于 `Microsoft Edge`【`Windows 10` 自带的】浏览器来说，界面有点不一样，在**设置** -> **高级** -> **代理设置**里面。

![Edge 浏览器设置代理脚本](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/old/b7f2e3a3gy1fxbooa2ikvj20xc0pwq93.jpg "Edge浏览器设置代理脚本")

此外，如果在浏览器中有更灵活的需求应用， 例如在设置多个代理的情况下，针对公司内网是一套，针对指定的几个网站是一套，针对被屏蔽的网站是一套，剩余的直接连接。在这种情况下仅仅使用代理脚本就不能完成需求了，显得场景很单一，当然也可以把脚本写的复杂一点，但是成本太高，而且不方便维护更新。这个时候就需要浏览器的插件出场了，例如在 `Chrome` 下我选择了 [SwitchyOmega](https://chrome.google.com/webstore/detail/proxy-switchyomega/padekgcemlokbadohgkifijomclgjgif?hl=zh-CN) 这个插件，可以设置多种情景模式，根据实际情况自由切换，非常方便。我设置了三种情景模式：`hdpProxy`【公司内网】、`shadowSocks`【翻墙代理】、`auto switch`【根据条件自动切换】，前面两种情景模式直接设置完成即可，最后的 `auto switch` 需要配置得复杂一点，根据正则表达式或者通配符指定某些网站的访问方式必须使用 `hdpProxy` 代理，另外其它的根据规则列表
【https://raw.githubusercontent.com/gfwlist/gfwlist/master/gfwlist.txt ，和 `Shadowsocks` 的` GFWList` 列表类似】必须通过翻墙代理，剩余的才是直接连接。当然，此时就不需要把 `Shadowsocks` 设置为系统代理了，保持 `Shadowsocks` 后台运行就可以了。

![SwitchyOmega 插件配置](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/old/b7f2e3a3gy1fxbp79ywuej21hc0q20v7.jpg "SwitchyOmega 插件配置")

## Android平台使用

`Android` 平台的安装使用方法就非常简单了，分为**安装、配置、启动**这3个步骤，没有其它多余的操作。

### 安装

下载 `Android` 平台的客户端，一般我们都称之为**影梭**，在应用商城是找不到的，因为通不过审核，所以只能去官网下载，下载地址：[shadowsocks 官网](http://shadowsocks.org/en/download/clients.html)。切记，千万不要去第三方网站下载，因为下载的安装包可能带有其它的应用，导致给你的手机安装了一堆软件。当然，如果你连官网都不信，可以自己下载源代码，自己打包 `apk` 文件，也是可以的，懂一点点 `Android` 开发就行了，源代码全部是开源的，放在了 `GitHub` 上面：https://github.com/Jigsaw-Code/outline-client/ 。

下载完 `apk` 文件，安装也就是和安装普通的应用一样，需要注意的是有些 `Android` 手机会禁止外部来源的 `app`【不是从应用商店下载安装的】安装，所以需要同意一下，也就是**信任此应用**，才能顺利完成安装。

### 配置

需要配置的内容和 `Windows` 平台的一样，把那些必要的参数填进去就行了，其它内容不需要关心。例如我这里配置了 `ip`、端口、密码、加密方式等。
![配置信息](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/old/b7f2e3a3gy1g0pzdu7hdhj20u01me0xa.jpg "配置信息")

### 启动

启动只要点击右上角的灰色圆形按钮，里面有一个小飞机，大概等待几秒钟，就会变绿，表示已经连接上 `VPN` 了，此时手机就可以连接被屏蔽的网站了。唯一的缺点就是，不支持设置类似于 `PAC` 规则的站点切换【**路由**默认设置的是绕过中国大陆地址】，因为只要一连上 `VPN`，手机上所有的国外连接都是走 `VPN`，会导致连某些正常的国外的网站也会慢一点，还浪费 `VPS` 的流量。当然，如果是在 `WIFI` 的环境下，通过 `Android` 系统的网络代理设置也可以设置一些类似于 `PAC` 的规则，就不细说了。启动后，还可以看到流量发送接收统计信息。
![启动成功](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/old/b7f2e3a3gy1g0pzebvxr7j20u01mcae9.jpg "启动成功")

在手机的设置里面也可以看到 `VPN` 的开启
![查看系统开启的VPN](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/old/b7f2e3a3gy1g0pzegquf2j20u01jc0wu.jpg "查看系统开启的VPN")


# 踩坑记录


1、在云主机安装服务端后，又安装了防火墙，但是没有开启 `Shadowsocks` 需要的端口，导致启动 `Shadowsocks` 总是失败，但是报错信息又是 `Python` 和 `Linux` 的，看不懂，搜索资料也搜不到，后来重装，并且想清楚每一步骤是干什么的，会造成什么影响，通过排除法找到了根本原因。

2、在 `Windows` 平台使用的时候，安装了客户端，也安装了 `.NET Framework` 组件，配置信息确认无误，但是就是上不了外网，同样的操作使用 `Android` 客户端却可以，所以有理由怀疑是自己的主机问题。后来，重启系统，检查网络，关闭杀毒软件，还是不行，后来，依靠搜索，找到了是杀毒软件 `Avast` 的问题，扫描 `SSL` 连接被开启了，大坑，关闭即可。

![Avast 截图](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/old/b7f2e3a3gy1fxa0mkrws7j20pc0nkglz.jpg)

3、参考：[梯子搭建](https://github.com/sirzdy/shadowsocks) 。

4、本来以为 `Shadowsocks` 的**启用系统代理**中的 `PAC` 模式会在接收到网络请求的基础上进行过滤，即 `Shadowsocks` 能控制所有的网络请求进行过滤判断，然后该翻墙的翻墙，该直连的直连。如果浏览器没有使用任何代理插件，类似于 `SwitchyOmega`这种，还是可以自动根据 `PAC` 列表进行过滤的的，但是后来发现浏览器如果被代理插件给代理了，那么浏览器插件 `SwitchyOmega` 设置代理规则后，`PAC` 脚本就不会生效了，通过 `SwitchyOmega` 插件使用 `Shadowsocks` 代理的网站都直接翻墙，不会有任何关于 `PAC` 列表的判断。如果想拥有类似于 `PAC` 列表的判断，应该在 `Shadowsocks` 代理插件中好好配置，不应该交给 `Shadowsocks`。这也导致优酷视频消耗了大量的流量，而且速度还很慢。

这里面的根本原因就是 `PAC` 列表与 `SwitchyOmega` 代理插件的作用是类似的，都是为了区分网络请求，二者不可共存。如果谷歌浏览器安装了 `SwitchyOmega` 代理插件，但是 `IE` 浏览器没有安装，那么谷歌浏览器被 `SwitchyOmega` 代理，`IE` 浏览器还是按照 `PAC` 的规则来，都可以根据各自的网站规则进行访问。

另外，为了保证国内的网站不是经过翻墙代理，能直接连接，就不能使用 `Shadowsocks` 设置**系统代理模式**中的**全局模式**。

5、使用插件 `SwitchyOmega` 的过程中，一开始是自己整理一些规则，而没有使用
https://raw.githubusercontent.com/gfwlist/gfwlist/master/gfwlist.txt 列表规则，导致配置信息很多，而且自己看着头都大，不好维护与查看，后来就发现了列表规则，解放了劳动力。

6、解决了 `Chrome` 浏览器的收藏跨平台自动更新同步的问题，以前在三台电脑之间添加取消收藏，总是不能更新同步，需要手动开启系统代理设置全局模式【`Chrome` 浏览器的收藏同步功能被屏蔽了，我又不知道 `url` 是什么】，等一会更新同步之后再关闭【防止其它场景也翻墙了】。目前使用规则列表，收藏可以自动更新同步了，不需要手动来回切换了，也不用担忘记同步的情况了。


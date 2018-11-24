---
title: 使用 Aria2 加速百度网盘下载
date: 2018-11-09 01:37:18
updated: 2018-11-09 01:37:18
id: 2018110901
categories: 知识改变生活
tags: [Aria2,百度网盘]
keywords: Aria2,百度网盘,百度网盘下载,破解百度网盘,百度网盘限速
---

在日常工作和生活当中，应该有不少人自愿或者被迫使用百度网盘，一是因为其它厂商基本都关停了网盘服务；二是在获取互联网资料的时候，基本都是先获取到百度网盘链接，然后自己再去下载；三是有时候想备份一些文件，也只能想起来有百度网盘可以使用。这样的话，慢慢地总是会碰到需要百度网盘的时候，我们暂且不考虑这家企业的口碑怎么样，百度网盘这个产品本身还是不错的：有免费的大量空间，使用人群多，分享获取资料方便。但是，产品让人诟病的地方也有几个，而且由此造成的用户体验非常差，大家骂声一片。本文就详细讲述百度网盘这个产品让人诟病的地方以及可以使用技术方式绕过它，从而提升自己的体验。当然，如果你的钱到位的话，直接充值会员吧，可以消除一切不好的使用体验，同时也免去了阅读本文的时间。

<!-- more -->

# 使用中遇到的问题

本文是针对不充会员的免费用户群体的，在 Windows 平台安装，在 Chrome 浏览器中使用。

## 下载速度太慢，慢到反人类

让人诟病的问题之一是下载速度太慢了，对于免费用户基本维持在几 KB/s 到十几 KB/s 之间，也就是说如果你想下载一部1 G 大小的电影，按照1000 M 计算，下载速度按照10 KB/s 算（取这样的数值方便后续计算），下载完需要1000个100秒，也就是约等于27.78个小时（10万秒），所以在下载列表中经常看到下载任务还需要大于一天才能完成，这怎么让人受得了，不骂才怪呢！

但是只要充值会员，下载速度基本就暴增，可以完全利用宽带的带宽，例如100 M 的宽带，下载速度可达12.8 MB/s，哪怕只是10 M 的宽带，下载速度也能到 1.28 MB/s。因此，百度网盘客户端对于免费用户限制速度限制得太严重了，不充值会员根本没法使用。而且，有时候勉强能使用的时候，经常会弹出会员试用300秒的提示，只要选择了，下载速度立马飞速提升，300秒后又急速下降，经常下降到只有3.14 KB/s，让人抓狂。

## 网页版限制下载大文件，强迫安装百度网盘客户端

既然百度网盘客户端做了下载速度限制，那么大多数人会想到选择使用浏览器直接下载，同时又可以免去安装百度网盘客户端的麻烦，浏览器的下载速度通常在几百 KB/s，不会像百度网盘客户端那样特别地慢。但是，直接使用网页版的百度网盘下载文件，对文件大小有限制，太大的文件会被网页拦截，下载不了，而是弹出安装百度网盘客户端的提示，这样又回到了原点，因为如果用百度网盘客户端下载速度被限制了。

# 解决问题

## 使用 aria2 突破线程数限制、下载速度限制

### 简介

Aria2 是一个多平台轻量级的下载工具，支持 Http、Ftp、BitTorrent、Web 资源等多种格式，使用命令行启动任务，更多具体信息查看官网说明：[Aria2 介绍](https://aria2.github.io)。这种工具可以最大程度利用你的网络带宽，实际上你可以自由配置，包括线程数、网络传输速度、RPC 端口、断点续传是否开启等。

### 安装

去官网下载安装包：[Aria2 安装包](https://github.com/aria2/aria2/releases)，我的 Widows 系统64位，选择对应的安装包下载。
![安装包下载](https://ws1.sinaimg.cn/large/b7f2e3a3gy1fxjctk362fj20ih0gdt90.jpg "安装包下载")

下载完成后，得到一个 zip 格式的文件，其实直接解压即可，不需要安装，解压后会得到一系列文件，为了方便管理，都放在 aria2 文件夹下面，再复制到程序对应的目录。其中，有一个 .exe 文件，就是运行任务时需要的文件。此外，为了方便起见，把 .exe 文件的路径配置到系统的环境变量中去，这样在任何目录都可以执行 aria2 命令了；如果不配置则只能在 aria2 目录中执行相关命令，否则会找不到程序。
![解压](https://ws1.sinaimg.cn/large/b7f2e3a3gy1fxjcyfaaw9j20in08kmxd.jpg "解压")

### 配置

1、如果单纯使用命令行启动下载任务，可以把参数信息直接跟在命令后面，临时生效，也就是参数只对当前下载任务有效。显然，这样做很麻烦，每次都是一长串的命令，而且当任务非常多的时候也无法管理，所以不建议使用这种方式。当然，如果只是测试折腾一下，或者也不经常使用，只是偶尔下载一个东西，还是用这种方式比较简介，不用管其它复杂的配置，不用管插件的安装。

单命令行启动任务示例，从电影天堂下载《一出好戏》这部电影。如果下载百度网盘的文件，需要使用 [baiduexporter](https://chrome.google.com/webstore/detail/baiduexporter/jgebcefbdjhkhapijgbhkidaegoocbjj?hl=zh-CN) 插件生成 url，生成方式见后续步骤。
```bash
aria2c.exe -c -s32 -k32M -x16 -t1 -m0 --enable-rpc=true 下载 url 取值
-t1 表示的是每隔1秒重试一次
-m0 表示的是重试设置
此外，下载 url 中会包含 --header 的信息：User-Agent、Referer、Cookie、url
理论上 User-Agent、Referer 应该时固定的，Cookie、url 每次会生成不一样的
User-Agent: netdisk;5.3.4.5;PC;PC-Windows;5.1.2600;WindowsBaiduYunGuanJia
Referer: http://pan.baidu.com/disk/home"
```
![aria2 命令行参数](https://ws1.sinaimg.cn/large/b7f2e3a3gy1fxjec4bt6kj20gj0ahgm8.jpg "aria2 命令行参数")

2、如果是后台启动，通过其它管理插件来创建下载任务，则直接使用配置文件，文件名称为 aria2.conf，并在启动 aria2 时指定配置文件的位置。这样做的好处是使用一个配置文件就可以指定常用的参数配置，不用更改，每次下载文件前启动 aria2 即可。

配置文件可选项如下，例如下载文件存放位置、是否开启RPC、是否开启断点续传，具体更为详细的内容请参考文档：[Aria2 配置信息文档](https://aria2.github.io/manual/en/html/index.html)

```bash
## '#'开头为注释内容, 选项都有相应的注释说明, 根据需要修改 ##
## 被注释的选项填写的是默认值, 建议在需要修改时再取消注释  ##
## 文件保存相关 ##
# 文件的保存路径(可使用绝对路径或相对路径), 默认: 当前启动位置
dir=E:\\aria2download\\
# 启用磁盘缓存, 0为禁用缓存, 需1.16以上版本, 默认:16M
disk-cache=32M
# 文件预分配方式, 能有效降低磁盘碎片, 默认:prealloc
# 预分配所需时间: none < falloc < trunc < prealloc
# NTFS建议使用falloc
file-allocation=none
# 断点续传
continue=true

## 下载连接相关 ##
# 最大同时下载任务数, 运行时可修改, 默认:5
max-concurrent-downloads=32
# 同一服务器连接数, 添加时可指定, 默认:1
max-connection-per-server=5
# 最小文件分片大小, 添加时可指定, 取值范围1M -1024M, 默认:20M
# 假定size=10M, 文件为20MiB 则使用两个来源下载; 文件为15MiB 则使用一个来源下载
min-split-size=16M
# 单个任务最大线程数, 添加时可指定, 默认:5
split=32
# 整体下载速度限制, 运行时可修改, 默认:0
#max-overall-download-limit=0
# 单个任务下载速度限制, 默认:0
#max-download-limit=0
# 整体上传速度限制, 运行时可修改, 默认:0
max-overall-upload-limit=1M
# 单个任务上传速度限制, 默认:0
#max-upload-limit=1000
# 禁用IPv6, 默认:false
disable-ipv6=false

## 进度保存相关 ##
# 从会话文件中读取下载任务
input-file=aria2.session
# 在Aria2退出时保存`错误/未完成`的下载任务到会话文件
save-session=aria2.session
# 定时保存会话, 0为退出时才保存, 需1.16.1以上版本, 默认:0
#save-session-interval=60

## RPC相关设置 ##
# 启用RPC, 默认:false
enable-rpc=true
# 允许所有来源, 默认:false
rpc-allow-origin-all=true
# 允许非外部访问, 默认:false
rpc-listen-all=true
# 事件轮询方式, 取值:[epoll, kqueue, port, poll, select], 不同系统默认值不同
#event-poll=select
# RPC监听端口, 端口被占用时可以修改, 默认:6800
#rpc-listen-port=6800
# 设置的RPC授权令牌, v1.18.4新增功能, 取代 --rpc-user 和 --rpc-passwd 选项
#rpc-secret=mivm.cn
# 设置的RPC访问用户名, 此选项新版已废弃, 建议改用 --rpc-secret 选项
#rpc-user=<USER>
# 设置的RPC访问密码, 此选项新版已废弃, 建议改用 --rpc-secret 选项
#rpc-passwd=<PASSWD>

## BT/PT下载相关 ##
# 当下载的是一个种子(以.torrent结尾)时, 自动开始BT任务, 默认:true
follow-torrent=true
# BT监听端口, 当端口被屏蔽时使用, 默认:6881-6999
listen-port=51413
# 单个种子最大连接数, 默认:55
#bt-max-peers=55
# 打开DHT功能, PT需要禁用, 默认:true
enable-dht=true
# 打开IPv6 DHT功能, PT需要禁用
#enable-dht6=false
# DHT网络监听端口, 默认:6881-6999
#dht-listen-port=6881-6999
# 本地节点查找, PT需要禁用, 默认:false
#bt-enable-lpd=true
# 种子交换, PT需要禁用, 默认:true
enable-peer-exchange=true
# 每个种子限速, 对少种的PT很有用, 默认:50K
#bt-request-peer-speed-limit=50K
# 客户端伪装, PT需要
peer-id-prefix=-TR2770-
user-agent=Transmission/2.77
# 当种子的分享率达到这个数时, 自动停止做种, 0为一直做种, 默认:1.0
seed-ratio=0.1
# 强制保存会话, 即使任务已经完成, 默认:false
# 较新的版本开启后会在任务完成后依然保留.aria2文件
#force-save=false
# BT校验相关, 默认:true
#bt-hash-check-seed=true
# 继续之前的BT任务时, 无需再次校验, 默认:false
bt-seed-unverified=true
# 保存磁力链接元数据为种子文件(.torrent文件), 默认:false
#bt-save-metadata=true
```

配置完成后在启动 aria2 时指定配置文件的位置即可，例如我把 aria.conf 与 aria2c.exe 放在同一个文件夹下，则启动时直接指定
```bash
aria2c.exe --conf-path=aria2.conf
```
![aria2 配置文件](https://ws1.sinaimg.cn/large/b7f2e3a3gy1fxjeqk8oznj20l8096aai.jpg "aria2 配置文件")

当然，这样做只是启动了 aria2，并没有开始创建下载任务，不像单个命令行那样简单，直接设置参数就起任务了。接下来还需要浏览器插件的配合，才能保证下载任务的创建与监控，虽然配置步骤麻烦一点，但是使用起来更为方便。

为了避免启动时还要输入命令行，在 Windows 平台下可以写一个 bat 脚本，每次双击脚本即可，以下脚本内容供参考：
```bash
@echo off & title Aria2
aria2c.exe --conf-path=aria2.conf
```

### 使用

1、使用命令行启动单个任务无需多做介绍，直接敲下命令行，等待文件下载就行了。如果需要连续下载多个文件，则唯一的做法就是多敲下几个命令，多等待而已。因此，这种方式不适合任务数量多的情况，那这种情况下显然是需要批量下载的，并且可以对下载任务进行管理，那就要看下面的一项了：后台起 aria2 服务。

生成下载 url 的过程需要借助 [baiduexporter](https://chrome.google.com/webstore/detail/baiduexporter/jgebcefbdjhkhapijgbhkidaegoocbjj?hl=zh-CN)、[YAAW for Chrome](https://chrome.google.com/webstore/detail/yaaw-for-chrome/dennnbdlpgjgbcjfgaohdahloollfgoc?hl=zh-CN) 插件，直接从 Chrome 浏览器的插件商店搜索安装即可，如果无法翻墙，也可以从离线镜像库下载离线文件进行安装，离线库可以参考本站点的[关于页面](https://www.playpi.org/about)给出的工具链接。

接下来描述使用方式，登录百度网盘账号，把需要下载的文件保存在自己的网盘中，选择需要下载的文件，然后可以看到本来的下载按钮旁边又多了导出下载按钮，包含几个选项：ARIA2 RPC、文本导出、设置。
![Aria2 导出下载](https://ws1.sinaimg.cn/large/b7f2e3a3gy1fxjftqq3ugj210w0ejjs0.jpg "Aria2 导出下载")

选择文本导出就会弹出当前下载文件的下载 url，复制粘贴到命令后即可直接下载该资源。
![Aria2 文本导出](https://ws1.sinaimg.cn/large/b7f2e3a3gy1fxjfx3u157j21200ifmy2.jpg "Aria2 文本导出")
导出的内容格式如下，当然实际使用的时候里面的参数也是可以更改的，但是下载 url 一定不不能变的。

```bash
https://pcs.baidu.com/rest/2.0/pcs/file?method=download&app_id=250528&path=%2F%E9%80%86%E5%90%91%E8%B5%84%E6%96%99%2FIDA%20Pro%E6%9D%83%E5%A8%81%E6%8C%87%E5%8D%97.pdf
```

2、根据前面的描述，后台起了 aria2 服务，但是还没真正用起来，想要用起来，必须配合两个插件：[baiduexporter](https://chrome.google.com/webstore/detail/baiduexporter/jgebcefbdjhkhapijgbhkidaegoocbjj?hl=zh-CN)、[YAAW for Chrome](https://chrome.google.com/webstore/detail/yaaw-for-chrome/dennnbdlpgjgbcjfgaohdahloollfgoc?hl=zh-CN)。这2个插件中前者的作用是获取百度网盘的文件 url，这个 url 当然不是分享文件产生的 url，而是下载文件产生的 url；后者插件的作用是配合前者自动创建下载任务，实际下载利用的是已经启动的 aria2 后台，并时时监控任务状态，提供任务管理界面。

插件的安装不再赘述，接下来直接描述使用流程，要确保以上两个安装的插件都已经启用。根据上一步骤已经知道导出下载这个按钮，里面包含着一个 ARIA2 RPC 选项，这个选项就是直接使用 后台 aria2 服务创建下载任务，然后 YAAW for Chrome 插件监控着所有下载任务。

还有一个前提，就是启动 aria2 服务时要开启 RPC 模式。
```bash
# 启用RPC,默认:false
enable-rpc=true
```
这样做了之后，aria2 后台服务会开启一个端口，一般默认6800（如果 aria2 更改了端口，YAAW for Chrome 也要做相应的配置），这个端口用来给 YAAW for Chrome 汇报下载任务的情况，并提供管理下载任务的接口，这样的话，直接通过 YAAW for Chrome 就可以通过可视化的方式创建、暂停、查看任务。

后台启动 aria2，开启 RPC 模式。
![后台启动 aria2](https://ws1.sinaimg.cn/large/b7f2e3a3gy1fxjg7ftepxj20gj0ahmxk.jpg "后台启动 aria2")

打开 YAAW for Chrome 插件查看端口配置信息。
![YAAW 配置](https://ws1.sinaimg.cn/large/b7f2e3a3gy1fxjga6q57mj20y30kyaav.jpg "YAAW 配置")

通过 baiduexporter 插件，直接选择 PRC 下载，再去 YAAW 界面刷新查看下载任务。
![RPC 下载](https://ws1.sinaimg.cn/large/b7f2e3a3gy1fxjgepy1l1j21400dcaao.jpg "RPC 下载")

可以看到，aria2 参数还没优化（线程数、分块大小设置），下载速度已经有将近400 Kb/s了。
![YAAW 查看任务](https://ws1.sinaimg.cn/large/b7f2e3a3gy1fxjgfb0g00j21000cnq3b.jpg "YAAW 查看任务")

## 使用油猴插件绕过浏览器下载大文件的限制

### 现象

还是刚才那个文件，文件大小只有 149 M，不想通过百度网盘客户端下载，只想通过网页版下载，那就直接点击下载按钮，发现被限制了，必须让你安装百度网盘客户端。
![网页限制大文件](https://ws1.sinaimg.cn/large/b7f2e3a3gy1fxjglvadsdj212c0hzwff.jpg "网页限制大文件")

本来还在想通过网页版直接下载，速度也不会很慢，但是被限制了，这个时候我们的万能插件要出场了：[Tampermonkey](https://chrome.google.com/webstore/detail/tampermonkey/dhdgffkkebhmkfjojejmpbldmpobfkfo?hl=zh-CN)，又称油猴、暴力猴。

### 解决方式

使用万能的插件，屏蔽百度网盘网页版原来的网页内容，从而导致百度网盘的限制失效，这个插件就是 Tampermonkey：[官网](https://tampermonkey.net)、[Chrome 浏览器插件商店](https://chrome.google.com/webstore/detail/tampermonkey/dhdgffkkebhmkfjojejmpbldmpobfkfo?hl=zh-CN)。

这个插件的作用其实就是帮你管理各种自定义脚本，并运用在网页解析渲染中，从而实现对网页内容的改变，例如：去除网页的广告、去除百度搜索内容的广告条目、更改新浪微博展示界面。其中，也包括让百度网盘的下载文件大小限制失效，从而可以自由下载。

1、好，现在需要在插件的基础上安装一个脚本：百度网盘直接下载助手。要安装这个脚本，则首先需要找到它，选择获取新脚本，会引导我们进入脚本仓库。
![获取新脚本](https://ws1.sinaimg.cn/large/b7f2e3a3gy1fxjhpp1dbsj20ep0adt94.jpg "获取新脚本")

2、各种脚本仓库，我们选择 [GreasyFork](https://greasyfork.org/zh-CN)。
![脚本仓库列表](https://ws1.sinaimg.cn/large/b7f2e3a3gy1fxjhs41z1sj20zd0q2dhg.jpg "脚本仓库列表")

3、在搜索框中搜索：百度网盘直接下载助手，选择其中一个。
![选择脚本](https://ws1.sinaimg.cn/large/b7f2e3a3gy1fxjhuwpvohj20s70q2n18.jpg "选择脚本")

4、安装选择的脚本。
![安装脚本](https://ws1.sinaimg.cn/large/b7f2e3a3gy1fxjhwddpjgj20ro0q240i.jpg "安装脚本")

5、可以看到脚本内容，点击安装。
![脚本内容](https://ws1.sinaimg.cn/large/b7f2e3a3gy1fxjhyame9cj20xg0q2dht.jpg "脚本内容")

6、安装完成后，选择管理面板可以查看已经安装的脚本以及是否启用，也可以删除或者二次编辑。
![管理面板](https://ws1.sinaimg.cn/large/b7f2e3a3gy1fxji95kjl0j21hc0693yu.jpg "管理面板")

7、回到百度网盘，选择文件，可以看到多了一个下载助手选项，选择 API 下载，下载，即可使用浏览器直接下载，不会因为文件太大有网页的限制。
![下载助手](https://ws1.sinaimg.cn/large/b7f2e3a3gy1fxjidt1sdoj214a0q2ab1.jpg "下载助手")

8、当然，如果自己会写脚本，或者从别处直接复制的源脚本代码，在插件中选择添加新脚本，自己编辑即可。
![添加新脚本](https://ws1.sinaimg.cn/large/b7f2e3a3gy1fxjhte0bjfj20i009yt96.jpg "添加新脚本")
![编辑脚本内容](https://ws1.sinaimg.cn/large/b7f2e3a3gy1fxjigww3m8j20k00fv74q.jpg "编辑脚本内容")

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

虽然过程很详细，只要几个命令就可以完成 `Shadowsocks` 服务的搭建，但是对于没有技术基础又不想折腾的读者来说，还是有点困难。所以我把安装过程整理成一个自动化的 `Shell` 脚本，读者下载下来之后，直接运行即可，在运行过程中如果需要询问交互，例如填写密码、端口号等，读者直接填写即可，或者直接使用默认的设置。


<!-- more -->


首先说明，使用这个自动化 `Shell` 脚本，零基础的读者也可以自行安装 `Shadowsocks`，整个安装过程不到五分钟，非常友好而高效，运行脚本后慢慢等待即可，当然别忘记填写必要信息。

本脚本已经被我上传至 `GitHub`，读者可以下载查看并使用：[auto_deploy_shadowsocks.sh](https://github.com/iplaypi/iplaypistudy/tree/master/iplaypistudy-normal/src/bin/20190828) ，需要注意的是，这个自动化 `Shell` 脚本只针对 `CentOS 7x64` 操作系统有效，其它操作系统我没有测试，不保证能用。所以为了稳妥起见，请读者还是参考我上面给出的那篇博客来创建云主机。


# 自动化安装


下载 `GitHub` 上面的脚本时，如果有类似 `Shell` 的环境，就不用浏览器下载了，在 `Shell` 中可以直接使用 `wget` 命令下载，使用如下命令：

```
wget https://github.com/iplaypi/iplaypistudy/blob/master/iplaypistudy-normal/src/bin/20190828/auto_deploy_shadowsocks.sh
```

下载下来后接着直接运行即可，使用 `sh auto_deploy_shadowsocks.sh` 。

下面简单描述自动化脚本的思路：

```
1、提示用户输入端口号、密码，并读取输入，没有输入则使用默认值
2、利用端口号、密码，生成 /etc/shadowsocks.json 配置文件
3、安装 shadowsocks 以及其它组件：m2crypto、pip、firewalld
4、启动防火墙，开启必要的端口
5、检测当前是否有运行的 shadowsocks 服务，有则杀死
6、后台启动 shadowsocks 服务
7、输出部署成功的信息，如果部署失败，需要进一步查看日志文件
8、处理 server 酱通知
```

脚本内容整理如下，重要的地方已经注释清楚【这里要特别注意脚本中的换行符号，一律使用 `\\n` 的形式，否则会引起错误】：

```
#!/bin/bash
# 注意本脚本中的换行符号,一律使用\n的形式,否则会引起错误
# 日志路径,如果安装失败需要查看日志,是否有异常/报错信息
export log_path=/etc/auto_deploy_shadowsocks.log
# 设置端口号,从键盘接收参数输入,默认为2018,-e参数转义开启高亮显示
echo -n -e '\033[36mPlease enter PORT[2018 default]:\033[0m'
read port
if [ ! -n "$port" ];then
    echo "port will be set to 2018"
    port=2018
else
    echo "port will be set to $port"
fi
# 设置密码,从键盘接收参数输入,默认为pengfeivpn,-e参数转义开启高亮显示
echo -n -e '\033[36mPlease enter PASSWORD[pengfeivpn default]:\033[0m'
read pwd
if [ ! -n "$pwd" ];then
    echo "password will be set to 123456"
    pwd=pengfeivpn
else
    echo "password will be set to $pwd"
fi
# 创建shadowsocks.json配置文件,只开一个端口,server可以是0.0.0.0
echo "****************start generate /etc/shadowsocks.json"
cat>/etc/shadowsocks.json<<EOF
{
    "server":"0.0.0.0",
    "server_port":$port,
    "local_address": "127.0.0.1",
    "local_port":1080,
    "password":"$pwd",
    "timeout":300,
    "method":"aes-256-cfb",
    "fast_open": false
}
EOF
echo "****************start install shadowsocks and other tools"
# 安装shadowsocks/防火墙,携带-y参数表示自动同意安装,无需交互询问
# 日志全部输出到上面指定的日志文件中
echo "" >> ${log_path}
echo "********************************" >> ${log_path}
echo "start deploy shadowsocks,date is:"$(date +%Y-%m-%d-%X) >> ${log_path}
echo "********************************" >> ${log_path}
echo "" >> ${log_path}
echo "******************start install m2crypto" >> ${log_path}
ret=`yum install -y m2crypto python-setuptools >> ${log_path} 2>&1`
echo "" >> ${log_path}
echo "******************start install pip" >> ${log_path}
ret=`easy_install pip >> ${log_path} 2>&1`
echo "" >> ${log_path}
echo "******************start install shadowsocks" >> ${log_path}
ret=`pip install shadowsocks >> ${log_path} 2>&1`
echo "" >> ${log_path}
echo "******************start install firewalld" >> ${log_path}
ret=`yum install -y firewalld >> ${log_path} 2>&1`
echo "" >> ${log_path}
echo "******************start start firewalld" >> ${log_path}
ret=`systemctl start firewalld >> ${log_path} 2>&1`
echo "" >> ${log_path}
echo "******************start reload firewall" >> ${log_path}
# 开启端口
ret=`firewall-cmd --permanent --zone=public --add-port=22/tcp >> ${log_path} 2>&1`
ret=`firewall-cmd --permanent --zone=public --add-port=$port/tcp >> ${log_path} 2>&1`
ret=`firewall-cmd --reload >> ${log_path} 2>&1`
echo "****************start check shadowsocks"
# 如果有相同功能的进程则先杀死,$?表示上个命令的退出状态,或者函数的返回值
ps -ef | grep ssserver | grep shadowsocks | grep -v grep
if [ $? -eq 0 ];then
    ps -ef | grep ssserver | grep shadowsocks | awk '{ print $2 }' | xargs kill -9
fi
# 后台启动,-d表示守护进程
/usr/bin/ssserver -c /etc/shadowsocks.json -d start
# 启动成功
if [ $? -eq 0 ];then
# 获取本机ip地址
ip=`ip addr | grep 'state UP' -A2 | tail -n1 | awk '{print $2}' | cut -f1 -d '/'`
clear
cat<<EOF
***************Congratulation!*****************
shadowsocks deployed successfully!

IP:$ip
PORT:$port
PASSWORD:$pwd
METHOD:aes-256-cfb

*****************JUST ENJOY IT!****************
EOF
# 建议开启server酱自动通知,推送到微信,就可以直接复制信息转发给别人了
# 不开启请把以下内容注释掉,注释内容持续到'server酱通知完成'
# 关于server酱的使用请参考:https://sc.ftqq.com
# 注意server_key不要泄露,泄漏后可以去官网重置
echo "**************开始处理server酱通知"
server_key=SCU60861T303e1c479df6cea9e95fc54d210232565d7dbbf075750
# 传输2个参数:text/desp,desp使用markdown语法(注意换行符要使用2个换行)
cat>./shadowsocks_msg.txt<<EOF
text=shadowsocks服务部署启动完成
&desp=
- IP地址：$ip

- 端口号：$port

- 密码：$pwd

- 加密方式：aes-256-cfb
EOF
curl -X POST --data-binary @./shadowsocks_msg.txt  https://sc.ftqq.com/$server_key.send
echo ""
echo "**************server酱通知处理完成"
# 失败
else
clear
cat<<EOF
**************Failed,retry please!*************

cat /etc/ss.log to get something you need.

**************Failed,retry please!*************
EOF
fi

```

执行脚本的输出信息如下【我手动设置端口号为2019，密码使用默认值】，表示安装完成：

```
[root@playpi ~]# sh auto_deploy_shadowsocks.sh 
Please enter PORT[2018 default]:2019
port will be set to 2019
Please enter PASSWORD[pengfeivpn default]:
password will be set to 123456
****************start generate /etc/shadowsocks.json
****************start install shadowsocks and other tools
****************start check shadowsocks
root     13980     1  0 11:07 ?        00:00:00 /usr/bin/python /usr/bin/ssserver -c /etc/shadowsocks.json -d start
INFO: loading config from /etc/shadowsocks.json
2019-09-29 11:09:29 INFO     loading libcrypto from libcrypto.so.10
started
***************Congratulation!*****************
shadowsocks deployed successfully!

IP:45.32.79.20
PORT:2019
PASSWORD:pengfeivpn
METHOD:aes-256-cfb

*****************JUST ENJOY IT!****************
**************开始处理server酱通知
{"errno":0,"errmsg":"success","dataset":"done"}
**************server酱通知完成
[root@playpi ~]#
```

![自动安装成功](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20190929211341.png "自动安装成功")

同时，`server` 酱也接收到通知，可以很方便地直接转发给需要的人了。

![server 酱的通知](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20190929211352.png "server 酱的通知")


# 自动更换端口重启


在使用 `Shadowsocks` 的时候，有时候会遇到一个问题，端口被封了【`ip` 被封另外说，只能销毁主机新建】，特别是国家严厉管控非法 `VPN` 的时候，当然我这是属于误封，因为我只是用来学习、测试接口，这时候解决办法也简单，尝试更换一个端口即可。

步骤其实很简单，停止服务、更改配置文件、开启新端口、重启服务，但是作为一个追求效率的人，我还是想把操作简化一下，最好敲下一行命令等着就行。

其实把前面的步骤稍微整理一下，就变成了一个简单的脚本，直接执行即可。脚本已经被我上传至 `GitHub`，在 `Shell` 中可以直接使用 `wget` 命令下载，使用如下命令：

```
wget https://github.com/iplaypi/iplaypistudy/blob/master/iplaypistudy-normal/src/bin/20190828/auto_restart_shadowsocks.sh
```

下载下来后接着直接运行即可，使用 `sh auto_restart_shadowsocks.sh` 。

下面简单描述自动化脚本的思路：

```
1、提示用户输入端口号、密码，并读取输入，没有输入则使用默认值
2、利用端口号、密码，生成 /etc/shadowsocks.json 配置文件
3、安装 shadowsocks 以及其它组件：m2crypto、pip、firewalld
4、启动防火墙，开启必要的端口
5、检测当前是否有运行的 shadowsocks 服务，有则杀死
6、后台启动 shadowsocks 服务
7、输出部署成功的信息，如果部署失败，需要进一步查看日志文件
8、处理 server 酱通知
```

脚本内容整理如下，重要的地方已经注释清楚【这里要特别注意脚本中的换行符号，一律使用 `\\n` 的形式，否则会引起错误】：

```
yy
```

执行脚本的输出信息如下【需要手动设置新的端口号，我设置为2020，密码仍旧使用默认值】，表示重启完成：

```
zz
```

图。。

同时，`server` 酱也接收到通知，可以很方便地直接转发给需要的人了。

图。。


# 监控服务


鉴于国家管控越来越严格，有时候会误伤到我们的 `VPS`，毕竟我只是用来学习技术、测试接口，没有做什么违法的事，有时候突然挂掉了我也不知道，直到需要用到的时候才发现已经挂掉了，这时候还要去折腾，重启甚至更换 `ip`，影响心情，也影响做事的效率。

那么有没有可能做一个简单的监控服务，每隔一段时间检测一下服务是否正常，如果不正常则发送通知。如果连续多次不正常，则自动更换端口重启，重启成功后发送通知；如果是 `ip` 被封，此时重启没有用了，应该发送通知，提醒重新更换主机。

使用 `Shell` 可以做一个简化的版本，脚本已经被我上传至 `GitHub`，在 `Shell` 中可以直接使用 `wget` 命令下载，使用如下命令：

```
wget https://github.com/iplaypi/iplaypistudy/blob/master/iplaypistudy-normal/src/bin/20190828/auto_monitor_shadowsocks.sh
```

下载下来后接着直接运行即可，使用 `sh auto_monitor_shadowsocks.sh` 。

当然，这个监控脚本是要放在常用的主机上面运行，或者是在自己的电脑后台运行，但是为了确保一直后台运行，还是放在远程服务器上比较好，例如公司的公共服务器、阿里云主机等，这样就可以一直运行并监控。

下面简单描述自动化脚本的思路：

```
1、提示用户输入端口号、密码，并读取输入，没有输入则使用默认值
2、利用端口号、密码，生成 /etc/shadowsocks.json 配置文件
3、安装 shadowsocks 以及其它组件：m2crypto、pip、firewalld
4、启动防火墙，开启必要的端口
5、检测当前是否有运行的 shadowsocks 服务，有则杀死
6、后台启动 shadowsocks 服务
7、输出部署成功的信息，如果部署失败，需要进一步查看日志文件
8、处理 server 酱通知
```

脚本内容整理如下，重要的地方已经注释清楚【这里要特别注意脚本中的换行符号，一律使用 `\\n` 的形式，否则会引起错误】：

```
yy
```

执行脚本后，每隔30分钟检测一下 `ip` 或者端口是否可以正常访问。如果正常什么都不做；如果端口不正常则简单通知；如果端口连续不正常则发送故障报告，并自动重启，重启后通知结果；如果 `ip` 不正常则简单通知；如果 `ip` 连续不正常则发送故障报告，此时可以考虑更换主机了。

下面列举一些 `server` 酱的通知示例。

端口不正常。

图。。

端口连续不正常。

图。。

`ip` 不正常。

图。。

`ip` 连续不正常。

图。。


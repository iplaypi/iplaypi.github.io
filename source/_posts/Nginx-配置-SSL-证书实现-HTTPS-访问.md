---
title: Nginx 配置 SSL 证书实现 HTTPS 访问
categories: 建站
tags: [Nginx,https,ssl,证书]
keywords: Nginx,https,ssl,证书
id: 2019030501
date: 2019-03-05 02:14:23
updated: 2019-03-05 02:14:23
---


由于 GitHub Pages 把百度爬虫屏蔽了，导致百度爬虫爬取不到我的个人主页，所以被百度收录的内容很少，能收录的基本都是我手动提交的。后来我的解决办法就是自己搭建了一台 Web 服务器，然后在 DNSPod 中把百度爬虫的访问流量引到我的 Web 服务器上面，服务器主机是我自己购买的 VPS，服务器应用我选择的是强大的 Nginx。本文就记录 Web 服务器搭建以及配置 SSL 证书这个过程。


<!-- more -->


# 安装Nginx


我的 VPS 是 CentOS 7 X64 版本的，所以安装 Nginx 的过程比较麻烦一点，需要自己下载源码、编译、安装，如果需要用到附加模块【例如 http_ssl 证书模块】，还需要重新编译，整个过程比较耗时。如果不熟悉的话，遇到问题也要折腾半天才能解决。所以，我在不熟悉的 Nginx 的情况下选择了一种简单的方式，直接自动安装，并自带了一些常用的模块，例如 ssl 证书模块。但是缺点就是安装过程稍微长一点，在网络好的情况下可能需要3-5分钟。我还参考了别人的文档：[https://gist.github.com/ifels/c8cfdfe249e27ffa9ba1](https://gist.github.com/ifels/c8cfdfe249e27ffa9ba1) ，但是仅供参考，因为我发现也有一些不能使用的地方。

## 创建源配置文件

在 /etc/yum.repos.d/ 目录下创建一个源配置文件 nginx.repo，如果不存在这个目录，先使用 mkdir 命令创建目录，然后在目录中添加一个文件 nginx.repo，使用命令：

```
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

```
yum install nginx -y
```

安装完成后，使用以下命令启动：

```
service nginx start
```

可以使用命令 **service nginx status** 查看 Nginx 是否启动：
![查看Nginx状态](https://ws1.sinaimg.cn/large/b7f2e3a3gy1g0tj7nqpidj20pi085jrs.jpg "查看Nginx状态")

然后你就能看到 Nginx 的主页了，默认是80端口，直接使用 ip 访问即可【如果这里打不开，可能是端口80没有开启，被防火墙禁用了，需要重新开启，开启方法参考后面的章节】。
![Nginx主页](https://ws1.sinaimg.cn/large/b7f2e3a3gy1g0tj9c3v7aj20hw075t92.jpg "Nginx主页")


# 获取SSL证书、配置参数

## SSL 证书获取

证书的获取可以参考我的文章：[利用阿里云申请免费的 SSL 证书](https://www.playpi.org/2019030401.html)。我在阿里云获取的证书是免费的、有效期一年的，等证书过期了可以重新申请【不知道能不能自动续期】，因为我有阿里云的帐号，所以就直接使用了。当然，通过其它方式也可以获取 SSL 证书，大家自行选择。
![阿里云申请的SSL证书](https://ws1.sinaimg.cn/large/b7f2e3a3gy1g0tj9zp4g1j21hc0qx0ub.jpg "阿里云申请的SSL证书")

直接下载即可，下载后上传到站点的任意目录，但是要记住文件的位置，因为等一下配置 Nginx 的时候需要指定证书的位置。我把它们放在了 /site/ 目录，一共有2个文件：.key 文件时私钥文件，.pem 文件时公钥文件。
![SSL证书的2个文件](https://ws1.sinaimg.cn/large/b7f2e3a3gy1g0tjanlqz3j20o80dbaav.jpg "SSL证书的2个文件")

## Nginx 参数配置

更改配置文件，打开文件【使用 vi 命令会自动创建不存在的文件】，进入编辑模式：

```
# 配置
vi /etc/nginx/nginx.conf
```

填写内容如下【我这里只是配置基本的参数 server 有关内容，大家当然可以根据实际需要配置更为丰富的参数】，留意证书的公钥与私钥这2个文件的配置：

```
# 80端口是用来接收基本的 http 请求,里面做了永久重定向,重定向到 https 的链接
    server {
    listen       80;
    server_name  blog.playpi.org;
    access_log   /site/iplaypi.github.io.http-blog-access.log  main;
    rewrite ^/(.*)$ https://blog.playpi.org/$1 permanent;
    }
# 443端口是用来接收 https 请求的
server {
    listen 443 ssl;#监听端口
    server_name blog.playpi.org;#域名
    access_log   /site/iplaypi.github.io.https-blog-access.log  main;
    root         /site/iplaypi.github.io;
    ssl_certificate /site/1883927_blog.playpi.org.pem;#证书路径
    ssl_certificate_key /site/1883927_blog.playpi.org.key;#key路径
    ssl_session_cache shared:SSL:1m;#储存SSL会话的缓存类型和大小
    ssl_session_timeout 5m;#配置会话超时时间
    ssl_ciphers ECDHE-RSA-AES128-GCM-SHA256:ECDHE:ECDH:AES:HIGH:!NULL:!aNULL:!MD5:!ADH:!RC4;#为建立安全连接，服务器所允许的密码格式列表
    ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
    ssl_prefer_server_ciphers on;#依赖SSLv3和TLSv1协议的服务器密码将优先于客户端密码
    #减少点击劫持
    add_header X-Frame-Options DENY;
    #禁止服务器自动解析资源类型
    add_header X-Content-Type-Options nosniff;
    #防XSS攻击
    add_header X-Xss-Protection 1;
  }
```

只要按照如上的配置，就可以同时接收 http 请求与 https 请求【实际上 http 的请求被永久重定向到了 https】，我的配置如下图【请忽略 www 二级域名的配置项】：
![Nginx配置项server](https://ws1.sinaimg.cn/large/b7f2e3a3gy1g0tjbahmnzj20rm0kv75t.jpg "Nginx配置项server")

## 验证参数是否准确

有时候配置了参数，可能因为字符、参数名问题导致启动失败，然后再回来改配置文件，比较繁琐，所以可以直接使用 Nginx 提供的命令来验证配置文件的内容是否合法，如果有问题可以在输出警告日志中看到，改起来也非常方便。

```
nginx -t
```

可以看到，配置项正常，接下来就可以启动 Nginx 了。
![Nginx配置项检测](https://ws1.sinaimg.cn/large/b7f2e3a3gy1g0tjbrqeeuj20f603cglj.jpg "Nginx配置项检测")


# 开启端口、启动 Nginx


在上面的步骤中，如果在一开始想启动 Nginx，虽然启动成功了，但是却访问不了 Nginx 的主页，那很大可能是服务器的端口没有开启，导致访问请求被拒绝，所以需要适当开启必要的端口【如果没有安装防火墙工具 firewall 请自行安装】。

```
# 查看已经开启的端口
firewall-cmd --list-ports
# 开启端口80
firewall-cmd --permanent --zone=public --add-port=80/tcp
# 开启端口443
firewall-cmd --permanent --zone=public --add-port=443/tcp
# 重载更新的端口信息 
firewall-cmd --reload
# 这种方式可以,启动 Nginx
service nginx start
# 停止 Nginx
service nginx stop
# 如果需要重启,直接使用下面的更方便
nginx -s reload
```

大家看一下我的服务器的端口开启信息：
![服务器端口开启情况](https://ws1.sinaimg.cn/large/b7f2e3a3gy1g0tjc9ygu2j20bo02s0sl.jpg "服务器端口开启情况")


# 验证站点

打开站点[https://blog.playpi.org](https://blog.playpi.org) ，可以愉快地访问了，可以看到 https 链接的绿锁。
![安全的站点主页](https://ws1.sinaimg.cn/large/b7f2e3a3gy1g0tjcrc2zbj21hk0s6n10.jpg "安全的站点主页")

接着查看一下 SSL 证书的信息。
![查看SSL证书信息](https://ws1.sinaimg.cn/large/b7f2e3a3gy1g0tjd5kowxj20d60i90t0.jpg "查看SSL证书信息")


# 题外话


## 重定向问题思考

关于开启 https 的访问，我一开始也配置了 www 的二级域名，但是通过日志发现没有通过301重定向访问 https://www.playpi.org 的请求，一直不明白原因。后来发现，因为做重定向的时候还是重定向到 GitHub 上面了。同理，如果使用 ip 直接访问，可以观察到自动跳转到 https://www.playpi.org 了，查看证书还是 GitHub 的证书。所以后来直接把百度爬虫的请求转发到 blog 的二级域名还是明智的【www 的二级域名就不用自己再搞一套了】，否则百度爬虫还是抓取不到。如果百度爬虫直接使用 https 链接抓取还是可以的，但是看百度站长里面的说明，是通过 http 的301重定向抓取的。

## Nginx 的 https 模块安装

由于我使用的是简单小白的安装方式，不需要关心额外用到的模块，例如 http_ssl 模块，因为安装包里面自带了这个模块，可以使用 **nginx -V** 命令查看。
![http_ssl模块查看](https://ws1.sinaimg.cn/large/b7f2e3a3gy1g0uj2a8vf6j21gm08smxy.jpg "http_ssl模块查看")

因此，如果大家有使用源码编译安装的方式，注意 https 模块不能缺失，否则不能开启 https 的方式。


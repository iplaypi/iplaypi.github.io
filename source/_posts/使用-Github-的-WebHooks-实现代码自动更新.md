---
title: 使用 Github 的 WebHooks 实现代码自动更新
id: 2019030601
date: 2019-03-06 23:13:32
updated: 2019-03-07 23:13:32
categories: 建站
tags: [Github,PHP,WebHooks,Git,自动更新,钩子]
keywords: Github,PHP,WebHooks,Git,自动更新,钩子
---


我的静态博客为了百度爬虫单独部署了一个镜像，放在了我的 VPS 上面，并单独设置了二级域名 blog.playpi.org。但是，每次 GitHub 有新的提交时【基本每周都会有至少三次提交】，为了及时更新，我都会登录到 VPS 上面，到指定的项目下做一下拉取更新的操作，即执行 **git pull**。这样操作了三五次，我就有点不耐烦了，自己身为搞技术的人，怎么能忍受这个呢。于是，我就在想有没有更好的方法实现自动拉取更新。一开始想到，直接在 VPS 起一个周期性脚本不就行了，比如每隔1分钟自动执行 **git pull**，但是立马又被我否定了，虽然做法很简单，但是太不优雅了，而且极大浪费 CPU。后来想到，GitHub 自带了 WebHooks 功能，概念类似于回调钩子，可以给 GitHub 的项目设置各种各样的行为，满足一定的场景才会触发。例如我的自动化构建就是这样的原理，每当 source 分支有提交时，都会通知 tavis-ci【这就是一个行为】，然后在 travis-ci 中设置好脚本，自动运行脚本，就完成了自动生成、部署的操作。

根据这个思路，就可以给 GitHub 的项目设置一个行为，每当 master 分支有提交时【代表着静态博客有更新了】，会根据设置的链接自动发送消息到 VPS 上面，然后 VPS 再执行拉取更新，这样的话就优雅多了。但是问题又来了，满足这种场景还需要在 VPS 设置一个后台服务，用来接收 GitHub 的通知并执行拉取更新的操作。我想了一下，既然 VPS 上面已经起了 Nginx 服务，那就要充分利用起来，给 Nginx 设置好反向代理，把指定的请求转给另外一个服务就行了。那这个服务怎么选呢，当然是选择 PHP 后台了，毕竟 PHP 号称世界上最好的语言。本文就记录从安装配置到成功实现的整个过程，本文系统环境是基于 CentOS 7 x64，软件版本会在操作中指明。


<!-- more -->


# 配置服务器的 PHP 支持


VPS 上面的 Nginx 已经安装好了，就不再赘述过程，不清楚的可以参考我的另外一篇文章：[GitHub Pages 禁止百度蜘蛛爬取的问题](https://www.playpi.org/2019010501.html) 。配置 PHP 后台主要有三个步骤：一是配置安装 PHP，包括附加模块 PHP-FPM，二是配置启动 PHP-FPM 模块，三是配置重启 Nginx。由于我的机器配置问题，在这个过程踩了很多坑，我也会一一记录下来。

毕竟我是新手，有很多地方不是太懂，所以参考了一些别人的博客和官网，有时候看多了也会迷惑，有些内容描述的不一样。这些链接我放在这里给大家参考：[参考 PHP 官网](https://secure.php.net/manual/zh/install.unix.nginx.php) 、[CentOS 7.2环境搭建实录(第二章：php安装)](https://segmentfault.com/a/1190000013344675) 、[如何正确配置Nginx+PHP](https://www.cnblogs.com/ldj3/p/9298734.html) 、[PHP-FPM 与 Nginx 的通信机制总结](https://segmentfault.com/a/1190000018464303) 、[使用Github的WebHooks实现生产环境代码自动更新](https://qq52o.me/2482.html) 。

先安装软件仓库，我的已经安装好了，重复安装也没影响。
```
yum -y install epel-release
```

## 踩着坑安装 PHP

1、下载指定版本的 PHP 源码，我这里选择了最新的版本 7.3.3，然后解压。
```
-- 下载
wget http://php.net/get/php-7.3.3.tar.gz/from/this/mirror -O ./php-7.3.3.tar.gz
-- 解压
tar zxvf php-7.3.3.tar.gz
```

2、configure【配置】，指定 PHP 安装目录【默认是 /usr/local/php】和 PHP 配置目录【默认和 PHP 安装目录一致】，我这里特意指定各自的目录，更方便管理。
```
-- 配置,并且开启 PHP-FPM 模块
./configure --prefix=/site/php/ --with-config-file-path=/site/php/conf/ --enable-fpm
```

遇到报错：**configure: error: no acceptable C compiler found in $PATH**，竟然缺少 c 编译器，那就安装吧。
```
-- 安装 gcc 编译器
yum install gcc
```

安装成功
图。。

安装完成后，接着配置，又报错：**configure: error: libxml2 not found. Please check your libxml2 installation.**，这肯定是缺少对应的依赖环境库，接着安装就行。
```
-- 安装2个，环境库
yum install libxml2
yum install libxml2-devel -y
```

接着就顺利通过配置。

3、编译、安装。
```
-- 编译,安装一起进行
make && make install
```

遇到报错：
```
cc: internal compiler error: Killed (program cc1)
Please submit a full bug report,
with preprocessed source if appropriate.
See <http://bugzilla.redhat.com/bugzilla> for instructions.
make: *** [ext/fileinfo/libmagic/apprentice.lo] Error 1
```
这是由于服务器内存小于1G所导致编译占用资源不足【好吧，我的服务器一共就 512M 的内存，当然不足】。解决办法：在编译参数后面加上一行内容 **--disable-fileinfo**，减少内存的开销。

接着编译又报错：
```
cc: internal compiler error: Killed (program cc1)
Please submit a full bug report,
with preprocessed source if appropriate.
See <http://bugzilla.redhat.com/bugzilla> for instructions.
make: *** [Zend/zend_execute.lo] Error 1
```
这是因为虚拟内存不够用，我的主机只有 512M。没办法了，降低版本试试，先降为 v7.0.0【或者开启 swap 试试，不用了，切换低版本可以了】，接着重新下载、配置、编译、安装，从头再来。
```
-- 下载的时候改版本号就行
wget http://php.net/get/php-7.0.0.tar.gz/from/this/mirror -O php-7.0.0.tar.gz
```

更换了版本后，一切操作都很顺利，就不用考虑开启 swap 了。

## 真正开始配置

配置、编译、安装完成后，开始编辑配置文件，更改默认参数，包括配置 PHP 与 PHP-FPM 模块。

1、PHP 配置文件，在编译安装的目录，复制配置文件 **php.ini-development** 到 PHP 的配置目录【如果一开始 configure 时没有显示指定 PHP 的配置目录，默认应该和 PHP 的安装目录一致，要复制在 /usr/local/php 中，而我指定了 PHP 的配置目录 /site/php/conf】。
```
cp php.ini-development /site/php/conf/php.ini
```

更改 PHP 的配置文件，以避免遭受恶意脚本注入的攻击。
```
vi /site/php/conf/php.ini
cgi.fix_pathinfo=0
```

2、PHP-FPM 配置文件，在 PHP 的安装目录中，找到 etc 目录【如果在一开始的 configure 没有显示指定 PHP 的安装目录，默认安装在 /usr/local/php 中，则需要到此目录下寻找 etc 目录，而我指定了 PHP 的安装目录 /site/php/】，复制 PHP-FPM 模块的配置文件 **php-fpm.conf.default**。
```
-- PHP 的附加模块的配置默认安装在了 etc 目录下
cd /site/php/etc
cp php-fpm.conf.default php-fpm.conf
```

在上面的 etc 目录中，继续复制 PHP-FPM 模块的默认配置文件。
```
cp php-fpm.d/www.conf.default php-fpm.d/www.conf
```

配置完成后，开始启动 PHP-FPM 模块，在 PHP 的安装目录中执行。
```
-- PHP 的附加模块的脚本默认安装在了 sbin 目录下
cd /site/php
./sbin/php-fpm
-- 检验是否启动
ps aux|grep php-fpm
```

可以看到正常启动了
图。。

3、接下来就是更改 Nginx 的配置文件，让 Nginx 支持 PHP 请求，并且设置反向代理，把请求转给 PHP-FPM 模块处理【前提是在不影响 html 请求的情况下】，在 server 中增加一个配置 location。

```
-- 打开配置文件
vi /etc/nginx/nginx.conf
-- 更改 server 模块的内容,增加 php 的配置
-- 80端口就不管了,直接在443端口下配置
location ~* \.php$ {
      fastcgi_index   index.php;
      fastcgi_pass    127.0.0.1:9000;
      include         fastcgi_params;
      fastcgi_param   SCRIPT_FILENAME    $document_root$fastcgi_script_name;
      fastcgi_param   SCRIPT_NAME        $fastcgi_script_name;
    }
-- 重新加载 nginx 配置,不需要重启
nginx -s reload
```

这样配置就会把所有的 PHP 请求转给 PHP-FPM 模块处理，同时并不会影响原来的 html 请求。


# PHP 脚本


先在静态站点的根目录下，添加默认的 index.php 文件，用来测试，内容如下，内容的意思是输出 PHP 的所有信息。
```
vi index.php
<?php phpinfo(); ?>
```

打开浏览器访问，可以看到成功。
图。。

接下来就测试复杂的脚本，用来自动拉取 GitHub 的提交。再创建一个 auto_pull.php 文件，内容如下，会自动到执行目录拉取 GitHub 的更新，这样就能实现镜像的自动更新了【还加入了可靠性验证】。
```
vi auto_pull.php

```

接下来先手工测试一下 PHP 文件的访问是否正常，然后再测试对应的 GitHub 的 WebHooks 效果。
。。。


# 测试 WebHooks 效果





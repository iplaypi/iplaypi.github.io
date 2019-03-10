---
title: 使用 Github 的 WebHooks 实现代码自动更新
id: 2019030601
date: 2019-03-06 23:13:32
updated: 2019-03-07 23:13:32
categories: 建站
tags: [Github,PHP,WebHooks,Git,自动更新,钩子]
keywords: Github,PHP,WebHooks,Git,自动更新,钩子
---


使用。参考：[https://qq52o.me/2482.html](https://qq52o.me/2482.html) 。


<!-- more -->


# 配置服务器的 PHP 支持

参考 PHP 官网：[https://secure.php.net/manual/zh/install.unix.nginx.php](https://secure.php.net/manual/zh/install.unix.nginx.php) 。


https://www.cnblogs.com/ldj3/p/9298734.html 


https://segmentfault.com/a/1190000013344675

yum -y install epel-release
安装软件仓库


编译，指定php目录和配置目录
./configure --prefix=/site/php/ --with-config-file-path=/site/php/conf/ --enable-fpm


configure: error: no acceptable C compiler found in $PATH
缺少c编译器
yum install gcc
安装gcc编译器


configure: error: libxml2 not found. Please check your libxml2 installation.
缺少环境库
yum install libxml2
yum install libxml2-devel -y
安装2个


执行安装
make && make install


报错
```
cc: internal compiler error: Killed (program cc1)
Please submit a full bug report,
with preprocessed source if appropriate.
See <http://bugzilla.redhat.com/bugzilla> for instructions.
make: *** [ext/fileinfo/libmagic/apprentice.lo] Error 1
```
这是由于服务器内存小于1G所导致编译占用资源不足（好吧，我的服务器一共就1G的内存，当然不足）
解决办法：在编译参数后面加上一行内容 --disable-fileinfo


```
cc: internal compiler error: Killed (program cc1)
Please submit a full bug report,
with preprocessed source if appropriate.
See <http://bugzilla.redhat.com/bugzilla> for instructions.
make: *** [Zend/zend_execute.lo] Error 1
```
又报错，虚拟内存不够用，主机只有512M

没办法了，降低版本试试，7.0.0（或者开启swap试试，不用了，切换低版本可以了）
wget http://php.net/get/php-7.0.0.tar.gz/from/this/mirror


安装完成后，开始配置参数
在编译安装的目录，复制配置文件到php目录
```
cp php.ini-development /site/php/php.ini
```

在指定的php目录中的etc目录，复制fpm模块的配置文件
```
cp php-fpm.conf.default php-fpm.conf
```

在上面的etc目录，复制默认配置文件
```
cp php-fpm.d/www.conf.default php-fpm.d/www.conf
```

启动fpm模块，在php安装目录
```
./sbin/php-fpm
```

接下来更改nginx的配置文件，还不知道怎么配置，能不能同时支持html与php呢（配置在同一个server里面）



# PHP 脚本





# 测试 WebHooks 效果





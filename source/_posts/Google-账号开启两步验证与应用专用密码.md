---
title: Google 账号开启两步验证与应用专用密码
id: 2018111901
date: 2018-11-19 21:17:59
updated: 2018-11-19 21:17:59
categories: 知识改变生活
tags: [Google 账号,两步验证]
keywords: Google账号,两步验证,二次验证,应用专用密码
---

使用 Google 账号的都知道，带来了很多方便，不仅有强大的免费搜索服务，还有 Google 文档、云主机、云存储等各种服务，但是唯一的缺点是需要翻墙，让一些人望而却步，把很多人挡在了便利门外。本文是针对已经实现翻墙愿望，并在日常工作中会使用到 Google 账号的人，说不定可以给你带来一些冷知识，解决一些小问题。

<!-- more -->

# Google 账号的便利性

目前在日常工作与生活中，查找资料时，基本使用的都是 Google 搜索，并且使用非常好用的 Chrome 浏览器。其中我用的最多就是标签收藏，平时偶尔搜到什么有用的知识点或者需要反复查看的网页，来不及看完整理，就先把网页分类收藏了，以便日后查漏补缺。

此时，利用 Chrome 浏览器的标签收藏功能，可以很方便地把一切网页收藏起来，并且可以很好地分类存放，清晰明了。可能有人说也有很多其它的工具可以做到这一点，不久收藏吗？但是我觉得还是利用 Chrome 浏览器自带的这个功能比较好，再配合 Google 账号，就可以达到同步更新的效果了，公司的电脑、家里的电脑，只要都登录了 Google 账号，所有收藏的标签都可以实时同步。而且，所有的浏览记录、搜索历史、记住的账号密码等等，都可以同步，跨机器使用也很方便。再配合 Chrome 浏览器的插件，对收藏的网页搜索起来非常方便。

# Google 账号开启两步验证

为了安全起见，最好给 Google 账号开启两步验证，可以选择绑定手机号、启用身份验证器、安全密钥等方式，为了方便，我选择了绑定手机号。开启两步验证后，在陌生的设备上登录 Google 账号（包括 Google 自家的各种应用，例如邮件、YouTube等）需要验证码的二次验证，当然，如果把设备设置为可信任的设备，则不需要每次都重复输入验证码。

开启的方式非常简单，登录 Google 账号，在”登录与安全“中有”两步验证“的开启选项，选择自己需要的方式，继续即可。

启两步验证1
![开启两步验证1](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/old/b7f2e3a3gy1fxdpircndxj21hc0q2ac6.jpg "开启两步验证1")

启两步验证2
![开启两步验证2](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/old/b7f2e3a3gy1fxdpjdxg23j21hc0q20u8.jpg "开启两步验证2")

如果使用”身份验证器“的方式，还需要在手机上安装一个”身份验证器“应用，校准时间后，每隔30秒更新验证码，登录账号时需要使用当前的验证码，并且在有效期内完成登录的操作，否则验证码过期，需要使用新的验证码，类似于手机收到的验证码只有1分钟一样。同时，如果使用 Google 邮箱账号注册了其它平台的账号，例如注册了 Twitter，注册了 Facebook，为了安全起见也可以使用”身份验证器“的方式，一种验证方式管理着多种账号的安全。

# 开启两步验证后带来的问题

我遇到的问题之一就是自己手机的邮件客户端无法登录 Google 邮箱了，我使用的时第三方邮件客户端，总是提示我密码错误，其实密码没有错误，是因为 Google 账号开启两步验证后，邮箱的登录也需要对应方式的验证，但是第三方邮件应用并没有做这个验证，所以无法登录。

本来是想着单独把 Google 邮箱的两步验证关闭，但是找了半天设置选项也没有找到，看来 Google 账号已经是一个大统一的账号，不允许单独设置涉及安全性的信息，可以理解。

同理，使用其它应用客户端也会遇到相同的问题，当然，Google 官方解释说明也解释了有部分设备不需要关注这个问题，其它大部分设备或者应用还是要受到影响的。

见：[使用应用专用密码登录](https://support.google.com/mail/answer/185833?hl=zh-Hans&visit_id=636782289170925112-3791602481&rd=1)
![解释说明](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/old/b7f2e3a3gy1fxdpwpmmroj20ru0oimyf.jpg "解释说明")

此时，需要使用”应用专用密码“或者在手机上开发一个”具有账号访问权限的应用“用来代理整个 Google 的账号访问。

# 问题的解决方法

## 应用专用密码方式的使用

### 1、在 Google 账号的登录和安全中，可以找到”应用专用密码“这个选项：
![应用专用密码](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/old/b7f2e3a3gy1fxdq2531orj21hc0q2wgl.jpg "应用专用密码")

### 2、点击进入后，可以看到选择应用与选择设备，由于我使用的是一种不知名的 Android 手机，所以官方选项中没有可以选择的，只好自定义一种，随便起一个名字标识即可。
![应用设备选择](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/old/b7f2e3a3gy1fxdq4j220pj21hc0q2wfb.jpg "应用设备选择")

### 3、选择完成后，会生成一串16位的密码，这个密码就可以在其它设备上登录的时候使用，不需要使用原来的密码，也不需要使用 Google 验证码。
![生成专用密码](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/old/b7f2e3a3gy1fxdq6klijxj21hc0q2ta4.jpg "生成专用密码")

### 4、在使用过程中还可以看到设备的情况。
![设备活动和安全事件](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/old/b7f2e3a3gy1fxdqasrztdj21hc0q20ud.jpg "设备活动和安全事件")

## 具有账号访问权限的应用的使用

这种方式就是手机本身有一个后台应用，代理了 Google 账号的一切请求，把信息转发到本地应用（比如 Chrome 浏览器就是这样一个应用，只不过是官方开发的，只要登录了 Google 账号，邮件、YouTube、搜索、Play、相册、日历等等这些应用同步一起使用，不需要额外再登录，这也是我使用 Chrome 浏览器的原因。），所以后台应用如果知道了 Google 账号的用户名、密码，就可以代理所有 Google 应用的请求，无需关心 应用专用密码了。

我发现锤子手机的 Smartisan OS 系统（v6.0.3，Android 版本7.1.1）对邮件就做了这个后台应用 Smartisan Mail，所以在使用内置的邮件客户端时，即使开启了两步验证，也无需关心验证码的问题（第一次登录还是需要验证的）。

下面截图则是一步一步设置：

### 1、在邮件客户端设置中添加 Google 邮箱
![添加 Google 邮箱1](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/old/b7f2e3a3gy1fxdqs7cpoqj20u01meq6k.jpg "添加 Google 邮箱1")

### 2、输入 Google 账号密码（也是邮箱密码）
![添加 Google 邮箱2](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/old/b7f2e3a3gy1fxdqt5xsawj20u01mf0vr.jpg "添加 Google 邮箱2")

### 3、输入验证码（由于开启了两步验证，一定需要），此时切记勾选”在此计算机上不再询问“，才能保证邮件客户端正常收发 Goole 邮件，否则不行。
![添加 Google 邮箱3](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/old/b7f2e3a3gy1fxdqto569aj20u01mcjvf.jpg "添加 Google 邮箱3")

### 4、允许，可以看到 Smartisan Mail 想要访问 Google 账号
![添加 Google 邮箱4](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/old/b7f2e3a3gy1fxdqtv52cej20u01mejz8.jpg "添加 Google 邮箱4")

### 5、点开 Smartisan Mail，可以看到开发者信息，里面其实设置了代理转发
![添加 Google 邮箱5](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/old/b7f2e3a3gy1fxdqtysi1cj20u01matef.jpg "添加 Google 邮箱5")

### 6、此外，在登录成功后，在 Google 账号的登录和安全中，可以看到具有账号访问权限的应用：
![Smartisan Mail](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/old/b7f2e3a3gy1fxdqoifycuj21hc0q2myw.jpg "Smartisan Mail")

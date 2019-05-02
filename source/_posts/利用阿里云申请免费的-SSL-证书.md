---
title: 利用阿里云申请免费的 SSL 证书
id: 2019030401
date: 2019-03-04 21:45:38
updated: 2019-03-04 21:45:38
categories: 建站
tags: [阿里云,SSL证书,Nginx,https,Lets Encrypt]
keywords: 阿里云,SSL证书,Nginx,https,Lets Encrypt
---


在搭建博客的过程中，一开始是全部使用 GitHub，因为这样做就什么也不用考虑了，例如主机、带宽、SSL 证书，全部都交给 GitHub 了，自己唯一需要做的就是写 Markdown 文档。但是，后来发现 GitHub 把百度爬虫给禁止了，也就是百度爬虫爬取不到 GitHub 的内容，导致我的站点没有被百度收录。后来为了专门给百度爬虫搭建一条线路，自己搭建了一个镜像服务，也就是和 GitHub 上面的内容一模一样站点，是专门给百度爬虫使用的。而且，为了测试方便，在 DNSPod 中还增加了一条 blog 二级域名的解析记录，blog 的访问全导向自己的镜像，这样就可以方便观察部署是否成功。后来还把百度爬虫的 www 访问通过 CNANE 跳转到 blog 去，这样就不用单独再搞一个 www 了，因为挺麻烦的（域名解析线路问题、测试问题、证书确认问题，都挺麻烦）。而在这个过程中，就产生了使用阿里云申请免费的 SSL 证书这一流程（有效期一年），记录下来给大家参考。


<!-- more -->


# 注册阿里云、开启实名认证


这个步骤就不多说了，需要证书总得注册一个帐号吧，也方便后续管理。此外，国内的证书服务商都要求实名认证，这个也没办法。如果不想实名认证，可以使用开源的 [Lets Encrypt](https://letsencrypt.org) ，只不过有效期只能是3个月，也就是说每隔3个月就要更新一次，GitHub Pages 使用的就是它。阿里云的官网链接：[https://www.aliyun.com](https://www.aliyun.com) 。


# 购买 SSL 证书


1、在阿里云系统找到关于 SSL 证书的服务，**产品与服务**->**安全（云盾）**->**SSL 证书（应用安全）**。
![SSL 证书（应用安全）](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/old/b7f2e3a3gy1g0r4q5ikmnj21hc0q9gp7.jpg "SSL 证书（应用安全）")

2、进入后，点击右上角的**购买证书**。
![购买证书](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/old/b7f2e3a3gy1g0r4qkt3cwj21hc0q9tal.jpg "购买证书")

3、按照我截图中的步骤1、2、3选择，这里需要注意，这个免费的选项隐藏的很深，直接勾选是不会出现的，要按照我标识的步骤来勾选才行，这里看到出现的费用很贵不用害怕，等一下接着选择对了就会免费的。
![正确的选择流程](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/old/b7f2e3a3gy1g0r4qvpk2wj21hc0q9775.jpg "正确的选择流程")

最终选择**免费型 DV SSL**，按照我下图中的选项，可以看到费用是0元。
![免费型 DV SSL](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/old/b7f2e3a3gy1g0r4r9iriij21hc0q9gob.jpg "免费型 DV SSL")

选择后，下单即可，虽然要走购买流程，但是是不用付钱的。
![下单完成](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/old/b7f2e3a3gy1g0r4rjfjm2j21hc0q9jtw.jpg "下单完成")


# 绑定证书信息、等待审核


1、下单完成后开始**申请**，这里的**申请**的意思是申请使用它，要填写一些基本的信息，包括个人信息和网站信息，后续还需要验证身份，看你有没有权限管理你配置的网站。如果不申请**使用**，证书其实就一直闲置在那里。
![申请使用证书](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/old/b7f2e3a3gy1g0r4rvewbsj21hc0q9jti.jpg "申请使用证书")

填写个人信息，主要就是我个人的联系方式。
![填写个人信息](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/old/b7f2e3a3gy1g0r4s5trvij21hc0q9dho.jpg "填写个人信息")

填写网站信息，由于我使用的是自己的服务器上面搭建的 Web 服务，既没有使用阿里云也没有使用其它云服务，所以我选择了**文件验证**，即需要把验证文件上传到我的域名对应的目录下面，用来证明这个站点是我管理的。当然，验证通过后，这个文件可以删除。
![文件验证](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/old/b7f2e3a3gy1g0r4serk53j21hc0q9q58.jpg "文件验证")

2、填写完成后，会生成一个文件 fileauthor.txt，我需要把这个文件下载下来，然后上传到我的服务器对应的目录中，才能点击**验证**按钮，如果通过了，说明这个站点就是我管理的，也就是一个权限验证。

由于在验证 www 证书对应的文件的时候，需要把 fileauthor.txt 文件上传到服务器，但是由于在 DNSPod 中设置的域名解析是解析到 GitHub 的（没有专门针对阿里的设置），所以总是验证失败。后来就干脆临时把所有的 www 解析都指向我自己的服务器，等通过了验证再改回去，整个过程很是折腾。折腾了一大圈，最后还发现了更简单的方法，直接放弃 www 证书的申请，在 DNSPod 中把百度的流量通过 CNAME 直接引到 blog 上面去就行了，这样只要维护一个 blog 的 Web 服务就行了。这样只需要增加一条解析，而且 blog 的证书验证过程也方便简单。

DNSPod 解析示例
![DNSPod 解析示例](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/old/b7f2e3a3gy1g0r4srjg4xj21hc0q9ac4.jpg "DNSPod 解析示例")

在这个过程中，我还发现验证过程需要一定的时间，一开始显示失败，但是不告诉我原因，还以为是自己的服务器的问题，重试了多种方法，包括重启 Web 服务。我等了十几分钟，证书就莫名其妙审核通过了，然后还发送了短信通知（到这里我猜测阿里云的 Web 界面显示的内容是滞后的，短信通知的内容才是实时的）。

证书申请成功，可以使用了。
![证书申请成功](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/old/b7f2e3a3gy1g0r4t1jlj7j21hc0q9mz2.jpg "证书申请成功")


# 下载证书、上传到自己的服务器


下载证书、上传到自己的服务器这一步骤就不多说了，主要就是复制粘贴的工作。着重要说一下 Nginx 的配置，主要就是 server 属性的配置，由于我把 www、blog 这2个二级域名都保留了，所以需要分开配置。其实，这里配置的 www 的二级域名根本没有用，因为不会有流量过来的，重在测试证书的安装。Nginx 的配置内容参考（2个子域名分开配置，有2份 SSL 证书）：
```
    server {
    listen       80;
    server_name  www.playpi.org;
    access_log   /site/iplaypi.github.io.http-www-access.log  main;
    rewrite ^/(.*)$ https://www.playpi.org/$1 permanent;
    }

    server {
    listen       80;
    server_name  blog.playpi.org;
    access_log   /site/iplaypi.github.io.http-blog-access.log  main;
    rewrite ^/(.*)$ https://blog.playpi.org/$1 permanent;
    }

    server {
    listen 443 ssl;#监听端口
    server_name www.playpi.org;#域名
    access_log   /site/iplaypi.github.io.https-www-access.log  main;
    root         /site/iplaypi.github.io;
    ssl_certificate /site/1884603_www.playpi.org.pem;#证书路径
    ssl_certificate_key /site/1884603_www.playpi.org.key;#key路径
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

配置完成后重启 Nginx（使用 nginx -s reload），去浏览器查看证书信息，看到有效期一年。
![去浏览器查看证书信息](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/old/b7f2e3a3gy1g0r4tirwwkj20f00gdwfk.jpg "去浏览器查看证书信息")

打开链接，看到左上角的小绿锁，好了，网站是经过验证的了。
![打开链接](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/old/b7f2e3a3gy1g0r4tu5l57j21hl0rr0wt.jpg "打开链接")


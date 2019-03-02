---
title: GitHub Pages 禁止百度蜘蛛爬取的问题
id: 2019010501
date: 2019-01-05 00:42:49
updated: 2019-01-06 00:42:49
categories: 建站
tags: [建站,GitHub Pages,SEO,百度蜘蛛,Baiduspider]
keywords: GitHub Pages,SEO,百度蜘蛛,Baiduspider
---


最近才发现我的静态博客站点，大部分的网页没被百度收录，除了少量的网页是我自动提交（主动推动、自动推送）的，或者手动提交的，其它的网页都不被收录（网页全部是利用自动提交的 sitemap 方式提交的，一个都没收录）。我查看百度的站长工具后台，发现通过 sitemap 方式提交链接这种方式不可行，因为百度蜘蛛采集链接信息之前需要访问 baidusitemap.xml 文件，而这个文件是在 GitHub Pages 里面的，但是GitHub Pages 是禁止百度蜘蛛爬取的，所以百度蜘蛛在获取 baidusitemap.xml 文件这一步骤就被禁止了，GitHub Pages 返回403错误（在 http 协议中表示禁止访问），因此抓取失败（哪怕获取到 baidusitemap.xml 文件也不行，因为后续需要采集的静态网页全部是放在 GitHub Pages 中的，全部都会被禁止）。本文就详细描述这种现象，以及寻找可行的解决方案。


<!-- more -->


# 问题出现


## 网页收录对比差距大

利用搜索引擎的 site 搜索可以看到百度与谷歌明显的差别
百度搜索结果（只有少量的收录，仅有的还是通过主动推送与自动推送提交的）
![百度搜索结果](https://ws1.sinaimg.cn/large/b7f2e3a3gy1g0ojip7wffj20mf0q1abw.jpg "百度搜索结果")

谷歌搜索结果（收录很多，而且很全面）
![谷歌搜索结果](https://ws1.sinaimg.cn/large/b7f2e3a3gy1g0ojj5hv3qj20ng0pp0uv.jpg "谷歌搜索结果")

首先在百度站长工具（官方主页：https://ziyuan.baidu.com/ ）后台看到 baidusitemap.xml 抓取失败，查看具体原因是抓取失败（http 状态码 403）。

抓取失败
![抓取失败](https://ws1.sinaimg.cn/large/b7f2e3a3gy1g0ojjp6f0jj20um08h3yk.jpg "抓取失败")

抓取失败原因概述
![抓取失败原因概述](https://ws1.sinaimg.cn/large/b7f2e3a3gy1g0ojjzz7kaj20uj0l6wf0.jpg "抓取失败原因概述")

根据抓取失败原因，我还以为是文件不存在，或者根据链接打不开（链接是：[https://www.playpi.org/baidusitemap.xml](https://www.playpi.org/baidusitemap.xml) ），我使用浏览器和 curl 命令都尝试过了，链接没有问题，可以正常打开。然后根据 403 错误发现是拒绝访问，那就有可能是百度爬虫的问题了（被 GitHub Pages 禁止爬取了）。

使用浏览器打开
![浏览器能正常打开](https://ws1.sinaimg.cn/large/b7f2e3a3gy1g0ojkc7sggj212a0kbgmb.jpg "浏览器能正常打开")

这里需要注意一点，百度站长工具里面显示的链接是 http 开头的（如上面抓取失败原因概述截图中红框圈出的，不是 https 开头的，我觉得百度爬虫抓取使用的就是 http 开头的链接），不过没关系，我在域名解析里面已经配置了所有的域名情况，完全可以支持。但是有时候仍然会遇到打不开上面链接的情况（在某些电脑上面或者某些网络环境中），我猜测这可能是电脑的缓存或者当前网络的 DNS 设置问题，不是我的站点的问题。因为，哪怕你在浏览器中输入以 http 开头的链接，也会自动跳转到以 https 开头的链接去。

浏览器打不开链接的情况（其实不是链接的问题）
![浏览器打不开链接的情况](https://ws1.sinaimg.cn/large/b7f2e3a3gy1g0ojkvts8yj20v60jmjrm.jpg "浏览器打不开链接的情况")

使用命令行打开（如下使用 curl  命令）

````bash
curl https://www.playpi.org/baidusitemap.xml
````

执行命令结果截图
![执行命令结果](https://ws1.sinaimg.cn/large/b7f2e3a3gy1g0ojlapxs2j20ke0f1t9f.jpg "执行命令结果")

## 通过百度反馈寻找原因

于是接下来，我就给官方提交了反馈，官方只是回复我说是链接问题（意思就是链接无法正常打开，其实使用浏览器或者检测工具都是可以打开的，但是使用百度爬虫就不行）。

提交反馈（官方主页：https://ziyuan.baidu.com/feedback/apply ）
![提交反馈](https://ws1.sinaimg.cn/large/b7f2e3a3gy1g0ojmrakf5j20v90c3dfy.jpg "提交反馈")

反馈回复
![反馈回复](https://ws1.sinaimg.cn/large/b7f2e3a3gy1g0ojn41t81j20r50n8jsy.jpg "反馈回复")

前面我已经证明了链接没问题，那我就要猜想是百度蜘蛛爬虫的问题了，于是按照官方回复的建议，使用诊断工具看看是否可行。

诊断工具测试多次都失败
![诊断工具测试多次都失败](https://ws1.sinaimg.cn/large/b7f2e3a3gy1g0ojnhzr7xj21060gqq3w.jpg "诊断工具测试多次都失败")

如果抓取 UA 设置为移动端（即模拟手机、平板之类的设别），会有部分成功的，而使用 PC 端全部都是失败的。
![诊断工具UA代理部分成功](https://ws1.sinaimg.cn/large/b7f2e3a3gy1g0ojnn4r5bj20zf0l3q49.jpg "诊断工具UA代理部分成功")

失败原因仍旧是拒绝访问（http 403状态码）
![拒绝访问](https://ws1.sinaimg.cn/large/b7f2e3a3gy1g0ojnt73w4j20rb0ppgmu.jpg "拒绝访问")

我又接着查看文档（文档地址：https://ziyuan.baidu.com/college/courseinfo?id=267&page=9#007 ），发现拒绝访问的原因之一就是托管服务供应商阻止百度 Spider 访问我的网站，所以猜测是 GitHub Pages 拒绝了百度 Spider 的爬取请求，接着就想办法验证一下猜测是否正确。

文档说明截取片段
![文档说明](https://ws1.sinaimg.cn/large/b7f2e3a3gy1g0ojnz71jxj20rr04dmxf.jpg "文档说明")

接下来我又查找了资料，发现网上确实有很多这种说法，而且大家都遇到了这种问题，但是并没有官方的说明放出来。

于是，接着我又回复了百度站长对方的反馈，直接问是不是因为 GitHub Pages 禁止了百度爬虫，所以百度爬取的结果总是 403 错误。等了几个小时，对方果然这样回复，说是的（对方没有明确回复，可能是不想承认）。
图。。。

## 通过 GitHub Pages 找原因

另一方面，我尝试给 GitHub 的技术支持发送邮件询问，得到了确认的答复，GitHub 已经禁止了百度蜘蛛爬虫的访问，并且不保证在未来的时间恢复。主要是因为以前百度爬虫爬取太猛了，导致 GitHub Pages 不可用或者访问速度变慢，影响了其他正常的用户浏览使用 GitHub Pages，所以把百度爬虫给禁止了（当然，这是官方说法）。

GitHub Pages 的反馈链接（填写姓名、邮箱、内容描述即可）：https://github.com/contact ；

我发送了一封邮件过去，当然是借助谷歌翻译完成的，勉强能看
![邮件内容](https://ws1.sinaimg.cn/large/b7f2e3a3gy1g0ojt87natj235s1zw4k8.jpg "邮件内容")

成功发送邮件后的通知页面
![成功发送邮件](https://ws1.sinaimg.cn/large/b7f2e3a3gy1g0ojtr12gxj21hc0q9755.jpg "成功发送邮件")

内容全文如下，仅供参考：
```
A doubt with GitHub Pages

Hello,
I created my own homepage with GitHub Pages,it is https://github.com/iplaypi/iplaypi.github.io.If you input https://iplaypi.github.io,it jumps to https://www.playpi.org automatically because of CNAME file.The website is https://www.playpi.org,and my site only contains static pages and pictures.

But I have a problem,the following is my detailed description:
I use Google Search Console to crawl my pages and include them.I only need to provide a site file named website.xml,and it works fine.

But when i use Baidu Webmaster Tools(a tool made by a Chinese search engine company),it doesn't work properly.I only need to provide a site file named baiduwebsite.xml,Baidu Spider will crawl the link in this file .But Baidu cannot include my pages finally,and the reason is Baidu Spider can't crawl my html pages.

So,I am trying to find the real reason,then I succeeded.The real reason is Github Pages forbids the crawling of Baidu Spider.So when Baidu Spider crawls my pages,it will definitely fail.

Here I want to know is this phenomenon real?If yes,why Github Pages forbids Baidu Spider?And what should i do?

Thanks.
Best regards.
Perry
```

没隔几个小时，就有回复了
![GitHub邮件回复](https://ws1.sinaimg.cn/large/b7f2e3a3gy1g0oju7wg4tj21ar0npjtb.jpg "GitHub邮件回复")

回复的重点内容如下：
```
I've confirmed that we are currently blocking the Baidu user agent from crawling GitHub Pages sites. We took this action in response to this user agent being responsible for an excessive amount of requests, which was causing availability issues for other GitHub customers. This is unlikely to change any time soon, so if you need the Baidu user agent to be able to crawl your site you will need to host it elsewhere.
```

那么，我们再来回看一下百度站长里面爬取失败原因的页面，里面有一个用户代理的配置，其实就是构造 http 请求使用的消息头，可以看到正是 Baiduspider/2.0，所以才会被 GitHub Pages 给禁止了。
![百度爬虫的UA](https://ws1.sinaimg.cn/large/b7f2e3a3gy1g0ojur917gj20sp0hz0t7.jpg "百度爬虫的UA")


# 解决方案


至此，我已经把问题的原因搞清楚了。本来这个问题是很好解决的（更换静态博客存储的主机即可，例如各种项目托管服务：码市、gitcafe、七牛云等，或者自己购买一台云主机），但是我不能抛弃 GitHub，于是问题变得复杂了。

此时，我还有3个方案可以参考：
- 使用 CDN 加速，把每个静态页面都缓存下来，这样百度爬虫的请求就可能不会到达 GitHub Pages，但是不知道有没有保证，可以试试
- 放弃**自动提交**方式里面的 **sitemap 推送**，改为**主动推送**，hexo 里面有插件可以用。但是我是坚持大道至简的原则，不想再引用插件了，而且我看了那个插件，需要配置百度账号的信息，我不能把这些信息放在公共仓库里面，会暴露给别人，不想用
- 在更新博客的同时再部署一份相同的博客**（可以理解为镜像，需要在其它主机部署一份，可以自己搭建主机或者使用类似于 GitHub 的代码托管工具）**，把 master 分支的内容复制过去即可，然后利用域名解析服务，把百度爬虫的流量引到这份服务器上面（只是为了让百度收录），其他的流量仍然去访问 GitHub Pages，就可以让百度的爬虫顺利爬取到我的博客内容了。这个方法看起来虽然很绕，但是明白了细节实现起来就很简单，而且可靠，可以用

## CDN加速

我先不选择这种方式了，因为需要收费或者免费的加广告，或者服务不稳定，我还是愿意选择稳妥的方式。可以选择的产品有：七牛云、又拍云、阿里云、腾讯云等。

## 选择镜像方式

既然选择了使用复制博客的方式，再加上域名解析服务转移流量，那接下来就开始动手部署了。我手里正好还有一台翻墙使用的 VPS，每个月的流量用不完，所以也不打算使用第三方托管服务了，直接部署在我自己的 VPS 上面就行了。只不过还需要动动手搭建一下 Web 服务，当然是使用强大的 Nginx 了。

### 更改域名服务器和相关配置

1、在DNSPod中添加域名
DNSPod 账号自行注册，我使用免费版本，当然会有一些限制，例如解析的域名A记录个数限制为2个（GitHub Pages 有4个 ip，我在 Godday 中都是配置4个，但是没影响，配置2个也。或者直接配置 CNAME 记录就行了，以前我不懂就配置了 ip，多麻烦，ip 还要通过 ping iplaypi.github.io 获取，每次还不一样，一共得到了4个，多此一举。当然，如果域名被墙了而 ip 没被墙，还是需要这样配置的）。
![在DNSPod中添加域名](https://ws1.sinaimg.cn/large/b7f2e3a3gy1g0oviygtn3j21hc0qxgnz.jpg "在DNSPod中添加域名")

2、添加域名解析记录
我把 Godday 中的解析记录直接抄过来就行，不同的是由于使用的是 DNSPod 免费版本，A 记录会少配置2个，基本不会有啥影响**（其实不配置 A 记录最好，直接配置 CNAME 就行了，会根据域名自动寻找 ip，以前我不懂）**。另外还有一个就是需要针对百度爬虫专门配置一条 www 的 A 记录，针对百度的线路指向自己服务器的 ip（截图只是演示，其中 CNAME 记录应该配置域名，A 记录才是配置 ip），如果使用的是第三方托管服务，直接添加 CNAME 记录，配置域名就行（例如 yoursite.gitcafe.io）。
![添加域名解析记录](https://ws1.sinaimg.cn/large/b7f2e3a3gy1g0ovjinxzvj21hc0qxac2.jpg "添加域名解析记录")

不使用A记录的配置方式
![不使用A记录的配置方式](https://ws1.sinaimg.cn/large/b7f2e3a3gy1g0ovk0xljij21hc0qxta3.jpg "不使用A记录的配置方式")

3、在 Godday 中绑定自定义 域名服务器
第2个步骤完成，我们回到 DNSPod 的域名界面，可以看到提示我们修改 NS 地址，如果不知道是什么意思，可以点击提示链接查看帮助手册（其实就是去购买域名的服务商那里绑定 DNSPod 的域名服务器）。

提示我们修改 NS 地址
![提示我们修改 NS 地址](https://ws1.sinaimg.cn/large/b7f2e3a3gy1g0ovkf6k08j21hc0qxtb9.jpg "提示我们修改 NS 地址")

帮助手册
![帮助手册](https://ws1.sinaimg.cn/large/b7f2e3a3gy1g0ovkoigmaj20s60lymyk.jpg "帮助手册")

我是在 Godday 中购买的域名（不需要备案），所以需要在 Godday 中取消默认的 DNS 域名服务器，然后把 DNSPod 分配的域名服务器配置在 Godday 中。这里需要注意，在配置了新的域名服务器的时候，以前的配置的解析记录都没用了，因为 Godday 直接把域名解析的工作转给了我配置的 DNSPod 域名服务器（配置信息都转到了 DNSPod 中，也就是步骤1、步骤2中的工作）。
原有的解析记录与原有的域名服务器
![原有的解析记录](https://ws1.sinaimg.cn/large/b7f2e3a3gy1g0ovn10ghwj20wt0mvgm6.jpg "原有的解析记录")

![原有的域名服务器](https://ws1.sinaimg.cn/large/b7f2e3a3gy1g0ovncqfzuj20ww0atdfw.jpg "原有的域名服务器")

配置完成新的域名服务器（以前的解析记录都消失了）
![配置完成新的域名服务器](https://ws1.sinaimg.cn/large/b7f2e3a3gy1g0ovnq0lhgj20yi0m7q3i.jpg "配置完成新的域名服务器")

配置完成后使用**域名设置**里面的**自助诊断**功能，可以看到域名存在异常，主要是因为更改配置后的时间太少了，要耐心等待，不过一般10分钟就可以访问主页了。
![自助诊断](https://ws1.sinaimg.cn/large/b7f2e3a3gy1g0ovl23kqbj20tl0lfabk.jpg "自助诊断")

### 设置镜像服务器

我没有使用第三方托管服务器，例如：gitcafe、码市、coding，而是直接使用自己的 VPS，然后搭配 Nginx 使用。

#### 安装Nginx（基于 CentOS 7 X64）
CentOS 的安装过程参考（但是，不是全部可信，抽取有用的）：https://gist.github.com/ifels/c8cfdfe249e27ffa9ba1 。

1、由于Nginx的源头问题，先创建配置文件
```bash
cd /etc/yum.repos.d/
vim nginx.repo
```

填写内容
```
[nginx]
name=nginx repo
baseurl=http://nginx.org/packages/centos/$releasever/$basearch/
gpgcheck=0
enabled=1
```

2、安装配置Nginx
```bash
# 安装
yum install nginx -y
# 配置
vi /etc/nginx/nginx.conf
```

填写配置内容
```
user  nginx;
worker_processes  1;

error_log  /var/log/nginx/error.log warn;
pid        /var/run/nginx.pid;


events {
    worker_connections  1024;
}


http {
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;

    log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                      '$status $body_bytes_sent "$http_referer" '
                      '"$http_user_agent" "$http_x_forwarded_for"';

    access_log  /site/nginx.access.log  main;

    server {
    listen       80;
    server_name  blog.playpi.org www.playpi.org;
    access_log   /site/iplaypi.github.io.access.log  main;
    root         /site/iplaypi.github.io;
    }

    sendfile        on;
    #tcp_nopush     on;

    keepalive_timeout  65;

    #gzip  on;

    include /etc/nginx/conf.d/*.conf;
}
```

3、开启80端口（不开启不行），启动Nginx
```bash
# 开启端口
firewall-cmd --permanent --zone=public --add-port=80/tcp
# 重载更新的端口信息 
firewall-cmd --reload
# 启动Nginx
# 这种方式不行,找不到目录
/etc/init.d/nginx start
# 这种方式可以
service nginx start
```

#### 额外考虑情况

1、关于https认证
要不要考虑 https 的情况，如果百度爬虫没用到 https 抓取（除了 sitemap.xml 文件还要考虑文件里面的所有链接格式，也是 https 的），就算了。其实不能算了，百度爬虫用到了 https 链接去抓取，所以还要想办法开启 Nginx 的 https。

。。。

2、端口的问题
为什么在上面配置域名解析记录的时候，百度的 A 记录配置 VPS 的 ip  就行了呢，这是因为在 VPS 上面只有 Nginx 这一种 Web 服务，机器会分配给它一个端口（默认80，也是 http 的默认端口，可以配置），然后 www 的访问就使用这个端口，所以可以忽略端口的信息。但是如果一台机器上面有各种 Web 服务，切记确保端口不要冲突（例如 Tomcat 和 Nginx 同时存在的情况），并且给 Nginx 的就是80端口，然后如果有其它服务，可以使用 Nginx 做代理转发（例如把 email 二级域名转到一个端口，blog 二级域名转到另一个端口）。

#### 完善自动获取更新脚本，拉取 mater 分支的静态页面

1、先用简单的方式
使用 git 把项目克隆到：/site/iplaypi.github.io 即可。

2、利用钩子自动拉取 master 分支内容到指定目录
。。。

## 验证结果

使用最简单的方式验证就是在百度站长工具里面使用**抓取诊断**来进行模拟抓取多次，看看成功率是否是100%。通过测试，可以看到，每次抓取都会成功，那么接下来就等待百度自己抓取了（百度爬虫抓取 sitemap.xml 文件的频率很低，可能要等一周）。

使用抓取诊断方式来验证
图。。。

此外，既然我们知道了百度爬虫设置的用户代理，那么就可以直接使用 curl 命令来模拟百度爬虫的请求，观察返回的 http 结果是否正常。模拟命令如下：

```bash
curl -A "Mozilla/5.0 (compatible; Baiduspider/2.0; +http://www.baidu.com/search/spider.html)" https://www.playpi.org/baidusitemap.xml
```

模拟请求的结果，可以看到也是正常的
图。。。

后续还需要观察看看百度的收录结果（等待更新并截图）
图。。。


# 问题总结


1、这篇博客耗费了我一个多月才完成，当然不是写了一个多月，而是从发现问题到解决问题，最终写成这篇博客，前后经历了一个多月。在这一个多月里，我看了很多别人的博客，问了一些人，也看了一些技术资料，学到了很多以前不了解的知识，而且通过动手去解决问题，整个过程收获颇丰。

2、写 Markdown 文档，使用代码块标记的时候，使用3个反单引号来标记，如果不熟悉代码块里面的编程语言，可以省略类型（例如 java、bash、javascript），不要填写，否则填错了生成的 html 静态文件是空白的。还有就是如果代码块里面放的是一段英文文本，和编程语言无关，也不要填写类型，否则生成的 html 静态文件也是空白的。

3、通过实战学习了一些网络知识，例如：CNAME、A 记录、域名服务器、二级域名等、https 证书，也学习了一些关于 Nginx 的知识。

4、关于访问速度的问题，GitHub Pages 的 CDN 还是很强大的，不会出现卡顿的情况。但是有时候貌似 GitHub 会被墙，打不开。此外，我搞这么久就是为了让百度爬虫能收录我的站点文章，所以自己搭建的 VPS 只是为了给百度爬虫爬取用的，其它正常人或者爬虫仍旧是访问 GitHub Pages 的链接。


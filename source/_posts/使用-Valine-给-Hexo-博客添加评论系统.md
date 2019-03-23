---
title: 使用 Valine 给 Hexo 博客添加评论系统
id: 2019032001
date: 2019-03-20 20:44:40
updated: 2019-03-20 20:44:40
categories: 建站
tags: [Valine,Hexo,评论系统]
keywords: Valine,Hexo,评论系统
commemts: true
---


我的博客已经搭建得差不多了，一些配置也固定下来了，最近重点一直在补充博客内容，把以前的笔记都整理出来。然后有一天我就想，好像总感觉少点什么，发现评论这个功能是没有的。以前是为了追求简洁的风格，而且评论这个功能不稳定，主要是评论系统不好选择，很多都关闭了。思前想后，考虑了好几天，最终还是决定先加上评论功能，实验一阵子，看看有没有必要，后续再决定是取消还是继续，反正也就是改一下配置就行了，没有多大工作量。接下来查了一下当前还活着的评论系统的种类，最后选择了 **Valine** 这个评论系统。它不需要登录，无后台管理，非常简洁，比较符合我追求的理念。参考相关内容：[https://github.com/xCss/Valine](https://github.com/xCss/Valine) 、[https://valine.js.org](https://valine.js.org) 、[https://leancloud.cn](https://leancloud.cn) 。


<!-- more -->


# 注册帐号创建应用


>Valine 诞生于2017年8月7日，是一款基于 Leancloud 的快速、简洁且高效的无后端评论系统。

所以，第一步就需要注册 Leancloud 账号，然后才能申请应用的 appid 和 appkey。注册过程我就不赘述了，和注册普通的账号一样，官网地址：[https://leancloud.cn](https://leancloud.cn) 。接下来重点来了，需要申请免费的应用【有钱的话也可以购买收费的版本】，这里面有一些需要注意的地方，否则最后评论的时候没有效果，会导致 Leancloud 后台接收不到评论数据。

1、登录 Leancloud 系统，进入系统的控制台，然后创建应用。
从主页进入控制台
![从主页进入控制台](https://ws1.sinaimg.cn/large/b7f2e3a3gy1g1d797qim2j21hc0rvq6j.jpg "从主页进入控制台")

创建应用，我这里已经创建好一个应用了。
![创建应用](https://ws1.sinaimg.cn/large/b7f2e3a3gy1g1d79ng997j21hc0q974s.jpg "创建应用")

2、填写、选择应用的参数，这里需要填写应用的名字，选择开发版本【免费版本，限制请求并发数】。
![填写、选择应用的参数](https://ws1.sinaimg.cn/large/b7f2e3a3gy1g1d79uhbrqj21hc0q9q4e.jpg "填写、选择应用的参数")

3、创建完成后，进入设置详情页面。
点击齿轮，进入设置详情页面。
![进入设置详情页面](https://ws1.sinaimg.cn/large/b7f2e3a3gy1g1d79z1cf8j21hc0q9mxq.jpg "进入设置详情页面")

在设置详情页面里面，选择 **设置->应用 Key**，就可以看到应用的 appid 和 appkey，这2个字符串要记下来，等一下在 Hexo 里面配置的时候有用。
![查看应用 Key](https://ws1.sinaimg.cn/large/b7f2e3a3gy1g1d7a30cpmj21hc0q9jt5.jpg "查看应用 Key")

4、在 **存储->数据**里面查看默认的 Class 信息，有一些默认的 Class，例如 \_User、\_File、\_Role 等，这些都用不到，而 Hexo 的评论功能需要一个名称为 Comment 的 Class，现在发现没有这个 Class，要不要手动配置一个呢。其实不用担心，经过我的测试 Hexo 会自动生成这个 Class，所以不需要自己手动配置了。
![查看 Class 信息](https://ws1.sinaimg.cn/large/b7f2e3a3gy1g1d7agpw2ij21hc0q9gnc.jpg "查看 Class 信息")

5、在 **设置->安全中心**，把**文件上传、短信服务、推送服务、实时通信** 这几个服务全部关闭，因为用不到。然后需要特别注意的就是 **Web 安全域名** 这一个选项，里面一定要填写自己站点的域名，并且带上端口号，例如 http 请求的默认端口就是80，htps 请求的默认端口就是443。这里如果没有配置好，评论的时候也会失败的。
![设置 Web 安全域名](https://ws1.sinaimg.cn/large/b7f2e3a3gy1g1d7amoctcj21hc0rv76n.jpg "设置 Web 安全域名")


# 配置 Hexo 参数


上一步骤已经把 Leancloud 里面的应用申请好了，并且设置了重要的选项，获取到 appid 和 appkey，接下来配置 Hexo 就简单多了。打开 Hexo 主题的配置文件 **\_config.yml**，搜索一下 Valine，找到默认配置【这是因为 Hexo 已经自动集成了 Valine 评论系统，不需要安装什么，如果没有请升级 Hexo 版本】。

默认是关闭的，把配置更改如下图，更为详细内容参考：[https://valine.js.org/configuration.html](https://valine.js.org/configuration.html) 。
![Hexo 配置](https://ws1.sinaimg.cn/large/b7f2e3a3gy1g1d7at81uyj20ku0b0dgq.jpg "Hexo 配置")

主要配置的内容如下【重点是 appid、appkey、placeholder，至于验证、邮件提醒就按照自己的需要来配置吧】：

```
valine:
  # 开启Valine评论
  enable: true
  # 设置应用id和key
  appid: CCCJixxxxxxXXXxxxXXXX000-gzGzo000
  appkey: AA1RXXXXXhPXXXX00F0XXXJSq
  # mail notifier , https://github.com/xCss/Valine/wiki
  # 关闭提醒与验证
  notify: false
  verify: false
  # 文本框占位文字
  placeholder: 没有问题吗？
  # 需要填写的信息字段
  meta: ['nick','mail']
  # 默认头像
  avatar: wavatar
  # 每页显示的评论数
  pageSize: 10

```

这里面我发现一个问题，就是有一些配置项不生效，例如：**meta**、**avatar**，我也不知道是 Hexo 的问题还是 Valine 的问题，我也不懂，就先不管了，因为不影响评论这个功能。

另外还有一个就是评论的时候总会强制检验邮箱和 url 的规范性，如果没填或者填的不规范就弹框提示，我不知道怎么取消，只好在在 GitHub 提了一个 Issue，详见：[https://github.com/xCss/Valine/issues/168](https://github.com/xCss/Valine/issues/168) ，但是作者一直没回。
![强制检验邮箱和 url 的规范性](https://ws1.sinaimg.cn/large/b7f2e3a3gy1g1d7da6215j20u30fsdgb.jpg "强制检验邮箱和 url 的规范性")

那怎么才能让博客文章的底部显示评论对话框呢，其实很简单，什么都不用做，Hexo 默认是给每个页面都开启评论的【前提是在 Hexo 的配置文件中开启了一种评论系统】。它背后的配置就是 Markdown 文件的 comments 属性，默认设置是 true，所以不用配置了，如果非要配置也可以，如下图。
![配置底部显示评论对话框](https://ws1.sinaimg.cn/large/b7f2e3a3gy1g1d7dge614j20e408c0sy.jpg "配置底部显示评论对话框")

此外，还需要注意，如果博客还有除正文内容之外的页面存在，例如关于、分类、标签，要把他们的 Markdown 文件的 comments 属性设置为 false，否则这些页面在展示的时候也会有评论的功能出现，总不能让别人随便评论吧。
![取消一些不该有评论的页面](https://ws1.sinaimg.cn/large/b7f2e3a3gy1g1d7djunr3j20no03iq2r.jpg "取消一些不该有评论的页面")


# 测试效果


打开任意一篇博客文章，可以看到底部已经有评论的文本框了。
![查看文章的评论文本框](https://ws1.sinaimg.cn/large/b7f2e3a3gy1g1d7e6uw4mj20uk0o2q3s.jpg "查看文章的评论文本框")

试着填写内容，评论一下，可以看到评论列表的内容。
![文章的评论列表](https://ws1.sinaimg.cn/large/b7f2e3a3gy1g1d7e3f5njj20ta0q3750.jpg "文章的评论列表")

好了，此时可以再回到 Leancloud 系统，看一下评论数据吧。直接在 **存储->数据->Comment** 里面，可以看到已经有评论数据了。由于 Valine 是无后端的评论系统，所以数据直接被存储到了 Leancloud 系统的数据库表里面，看看就行了，不方便管理。如果评论数据很多，为了更方便管理评论数据，能收到更友好的邮件通知提醒，可以使用 Valine-Admin 来实现，我暂时先不用。
![Leancloud 系统的评论数据](https://ws1.sinaimg.cn/large/b7f2e3a3gy1g1d7dzjwhgj21hc0q9jt1.jpg "Leancloud 系统的评论数据")

经过几天的测试，可以看到应用的请求量统计信息。
![Leancloud 系统的应用请求量](https://ws1.sinaimg.cn/large/b7f2e3a3gy1g1d7dvlarqj21hc0rwt9f.jpg "Leancloud 系统的应用请求量")


# 附加 Valine-Admin 进行评论数据管理


这个插件我现在先不使用，因为还不知道评论数据会怎么样呢，等以后如果确实有需要再考虑增加，参考项目：[https://github.com/zhaojun1998/Valine-Admin](https://github.com/zhaojun1998/Valine-Admin) 。


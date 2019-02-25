---
title: Hexo 的踩坑经验
id: 2019022501
date: 2019-02-25 01:00:21
updated: 2019-02-26 01:00:21
categories: 基础技术知识
tags: [hexo,markdown,java,bash,xml]
keywords: hexo,markdown,java,bash,xml
---


大家知道，我是使用 Hexo 来构建我的静态站点的，每次使用 Markdown 语法书写 md 文档即可。写完后在本地使用 hexo g & hexo s 命令（在本地生成并且部署，默认主页是 localhost:4000）来验证一下是否构建正常。如果有问题或者对页面效果不满意就返回重新修改，如果没有问题就准备提交到 GitHub 上面的仓库里面（在某个项目的某个分支），后续 travid-cli 监控对应的分支变化，然后自动构建，并推送到 master 分支。至此，更新的页面就发布完成了，本人需要做的就是管理书写 md 文档，然后确保没问题就提交到 GitHub 的仓库。


<!-- more -->


# 问题清单


前言描述的很好，很理想，但是有时候总会出现一些未知的问题，而我又不了解其中的技术，所以解决起来很麻烦，大部分时候都是靠蒙的（当然，也可以直接在 Hexo 的官方项目上提出 Issue，让作者帮忙解决）。下面就记录一些遇到的问题，以及我自己找到的原因。

## Markdown 语法不规范

在使用 hexo 框架的时候，一定要确保 markdown 文件里面的代码块标识（标记代码的类型，例如：java、bash、html 等）使用正确。否则使用 **hexo g** 生成静态网页的时候，不会报错，但是却没有成功生成 html 静态网页，虽然 html 静态文件是有的，但是却查看不了，显示一片空白。

代码块示例：

Java 格式
![Java 格式](https://ws1.sinaimg.cn/large/b7f2e3a3gy1g0j7gk7162j20jn04bt8o.jpg "Java 格式")

xml 格式
![xml 格式](https://ws1.sinaimg.cn/large/b7f2e3a3gy1g0j7hmem4lj20de054mx2.jpg "xml 格式")

bash 格式
![bash 格式](https://ws1.sinaimg.cn/large/b7f2e3a3gy1g0j7hyp6j3j209o02j0si.jpg "bash 格式")

例如我把图一的 java 误写成了 bash，**hexo g** 的时候没有报错，但是生成的 html 静态网页却是空白一片，打开了什么也看不到。

空白页面
![空白页面](https://ws1.sinaimg.cn/large/b7f2e3a3gy1g0j7if0nmuj21hk0s5q4y.jpg "空白页面")

但是如果把 java 误写成了 xml，在本地执行 ** hexo g** 的时候不会报错，生成的 html 静态网页也是正常的。而一旦使用 travis-cli 执行自动构建的时候，构建是失败的，并且可以看到错误信息（图四，但是我看不懂错误原因，只能猜测找到问题所在，比较耗时）。

travis-cli 报错日志（我看不懂）：
travis-cli 日志1
![travis-cli 日志1](https://ws1.sinaimg.cn/large/b7f2e3a3gy1g0j7iqv9msj20th0ld0to.jpg "travis-cli 日志1")

travis-cli 日志2
![travis-cli 日志2](https://ws1.sinaimg.cn/large/b7f2e3a3gy1g0j7jt59f2j20rh0nvjur.jpg "travis-cli 日志2")

travis-cli 日志3
![travis-cli 日志3](https://ws1.sinaimg.cn/large/b7f2e3a3gy1g0j7jokkp6j20rh0p4dj2.jpg "travis-cli 日志3")


## Hexo 报错奇怪

在本地测试过程中，无论是 **hexo s** 还是 **hexo g** 都会报错，错误信息如图：
![报错信息](https://ws1.sinaimg.cn/large/b7f2e3a3gy1g0j7kb9p5zj20jt02k3yk.jpg "报错信息")

看着这个信息，很像在当前项目的目录中找不到 hexo 命令（和 java 类似），我就怀疑是不是安装的 hexo 被什么时候卸载了，其实不是的（在其它项目中还能用）。后来我发现是当前项目使用的模块缺失（为什么会缺失我也不知道），由于这些缺失的模块是通过 hexo 引入的，所以直接报错：hexo not found，给人以误导。

总的来说，就是报错有误导性，没有报模块缺失，而我又不懂这些，查了一些资料，手动测试了一些方法，总算找到原因所在。找到原因，那解决办法很简单了，直接安装缺失的模块即可，使用 **nmp install** 命令安装 package.json 里面的模块。

## Hexo 配置错误引起的误导性

这个错误和上面的类似，但是如果从报错信息上面看，也具有误导性。在更改了 \_config.yml 配置文件后，按照正常步骤去生成、部署的时候（使用 **hexo g & hexo s**命令），直接报错了，把我整蒙了，报错信息如下：
![报错信息](https://ws1.sinaimg.cn/large/b7f2e3a3gy1g0j7kzx1vij20k50iqq4q.jpg "报错信息")

关键配置部分如下（后续找到问题确实出在这里）：
![关键配置部分](https://ws1.sinaimg.cn/large/b7f2e3a3gy1g0j7les4wdj20lu08wt9j.jpg "关键配置部分")

从图中看信息，我也看不到什么原因，因为确实不懂。注意，我为了测试，发现 **hexo g** 是没有问题的，也就是生成没问题，那问题就出在部署步骤了，它会不认这个**hexo s** 命令？我查了资料，发现大部分人都说缺失 hexo server 模块，我通过检查可以确保本机有这个模块，而且卸载了重新装，所以不是这个问题。

最后发现是配置信息里面的参数（官方定义的关键词）错误了，里面的 **Plugins** 这个参数应该使用首字母大写，这谁能想到，正确的配置参数如下图：
![plugins 改为首字母大写](https://ws1.sinaimg.cn/large/b7f2e3a3gy1g0j7lre005j20nb08udgb.jpg "plugins 改为首字母大写")


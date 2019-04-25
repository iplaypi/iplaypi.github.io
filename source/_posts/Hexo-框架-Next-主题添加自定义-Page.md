---
title: Hexo 框架 Next 主题添加自定义 Page
id: 2017050701
date: 2017-05-07 00:37:23
updated: 2019-04-25 00:37:23
categories: 建站
tags: [Hexo,Next,page]
keywords: Hexo,Next,page
---


在整理博客的过程中，发现需要新增一些页面，对于 Hexo 框架来说是 **page** 的概念，例如**首页**、**关于**、**分类**、**搜索**等页面。这种页面不同于每一篇博客文章那种发表的内容，对于 Hexo 框架来说是 **post**，而是可以交互的页面，例如可以在**搜索**页面中搜索博客的内容，可以在**分类**页面中查看博客文章的分类统计。当然，类似于**关于**这种页面也是静态的，没有交互的概念。

上面提到的这些页面都是 Next 主题自带的，只要在 **\_config.yml** 配置文件中开启相关配置即可，不需要关心它是怎么实现的，例如开启了**分类**页面，它会自动把博客的分类统计好，展示出来。但是我的想法其实是新增一个页面，并且自定义图标、名称、内容，其实也可以实现，本文记录这个过程。


<!-- more -->


# 自带的页面

Hexo 自带的页面有好几种，例如：关于、首页、分类、搜索、站点地图、404页面等，可以在主题的配置文件中查看 menu 选项 。例如我使用的是 Next 主题，在 **themes/next/\_config.yml** 中查看 **menu** 选项，我这里已经配置好 **home、about、tags、categories、archives**，此外还有没有开启的 schedule、sitemap、commonweal 等，先忽略我新增的 books 页面。
![Hexo 自带的页面配置](https://ws1.sinaimg.cn/large/b7f2e3a3gy1g2f8d8zazwj20j508ldg9.jpg "Hexo 自带的页面配置")

这里面的配置有固定的格式，一共有四列：第一列是展示的名字以及页面标识、第二列是 url 地址、第三列是固定的双竖线、第四列是图标名称。我这里使用 **about: /about/ || user** 举例，**about** 就是页面的名字【虽然配置的是英文，但是有汉化字典转为中文，汉化字典文件为：themes/next/languages/zh-Hans.yml】，**/about/** 是页面的 url 地址，表示从主页跳转的地址，前面加上域名可以直接访问，**||** 双竖线是固定标识符，**user** 是图标名称，来自于一个图标库：[https://fontawesome.com](https://fontawesome.com) 。

只要开启这个配置，就可以看到关于的页面。
![关于页面](https://ws1.sinaimg.cn/large/b7f2e3a3gy1g2f8eqfnloj214i0bj0t7.jpg "关于页面")

这些页面都不需要特殊的处理，直接配置完成就可以直接使用，可以在项目的 source 目录里面查看子文件夹，每个子文件夹都会对应一个页面，文件夹里面有一个 index.md 文件，就是页面的原始数据。但是对于搜索、分类、归档等可以交互的页面，Hexo 在渲染时还会重新计算，这里面的 index.md 文件没有内容，只是表示开启了这个页面。而对于静态页面，直接在相应的 index.md 文件里面写上内容就行了，Hexo 值了渲染不会再重新计算内容。例如关于页面，就可以使用 Markdown 语法在 about/index.md 文件里面写上关于作者的简介，我下面要新增的页面也是类似这种格式。

各种页面对应的子文件夹
![各种页面对应的子文件夹](https://ws1.sinaimg.cn/large/b7f2e3a3gy1g2f8ihzp17j20ng09d3zp.jpg "各种页面对应的子文件夹")


# 新增页面


了解完了自带的页面，接下来准备新增自定义页面。

我需要新增的是一个静态页面，名称为**书籍**，里面会列出我的读书清单，并给出书籍的部分信息。

## 生成页面并编辑

经过查询 Hexo 的语法，生成新页面的命令为：**hexo new page name**，page 是关键字，name 表示页面的名字，我直接使用 **hexo new page books** 即可。

执行完命令后，可以在 **source** 目录看到生成了一个 **books** 目录，里面有一个 index.md 文件，直接编辑这个页面即可。

简单编辑内容如图：
![编辑内容](https://ws1.sinaimg.cn/large/b7f2e3a3gy1g2f90i7b71j20so0iyt9a.jpg "编辑内容")

这里需要注意文件头的内容，有固定的格式：

```
---
title: 书籍
date: 2019-04-25 00:16:58
type: books
comments: false
---
```

其中，title 就是渲染后 html 网页的居中标题以及网页的 title 标签值，会在浏览器的 tab 页上面显示【这里也可以使用英文名称 books，但是需要在汉化文件的 title 选项下面增加中英文配置，和后面的 menu 汉化类似】。type 就是页面的类别，与自定义页面名称保持一致。此外 comments 切记关闭，因为博客如果开启了评论功能，会默认在所有的页面都开启评论框，而这种自定义页面是不需要评论框的，因此选择关闭，即设置为 false。

## 开启页面配置

在主题的配置文件 **themes/next/\_config.yml** 中，配置自定义页面，在 **menu** 选项下面，配置内容如下：

```
books: /books/ || book
```

截图如下：
![配置自定义页面](https://ws1.sinaimg.cn/large/b7f2e3a3gy1g2f93rrtmnj20ke07ft8w.jpg "配置自定义页面")

其中，**books** 是新建的页面名称，**/books/** 是链接，**book** 是图标【因为没有 books 图标可以使用，只能使用 book 图标了，原因在最后会描述，主要是收费问题】。

## 汉化页面名称

配置 **themes/next/languages/zh-Hans.yml** 文件，也是在 **menu** 选项下面，配置内容如下：

```
books: 书籍
```

截图如下：
![汉化内容](https://ws1.sinaimg.cn/large/b7f2e3a3gy1g2f91cim2zj209v0740ss.jpg "汉化内容")

## 打开页面预览

在博客点击书籍页面或者直接输入**域名/books/** 链接，打开页面。
![预览书籍页面](https://ws1.sinaimg.cn/large/b7f2e3a3gy1g2f91ppnacj214n0n1411.jpg "预览书籍页面")


# 注意事项


注意，图标是来自于图标库：[https://fontawesome.com](https://fontawesome.com) ，只要提供图标的名字即可，Hexo 会自动匹配对应的图标展示。需要特别注意的是，这里面的图标有大部分是收费的【搜索时会显示灰色状态，能免费使用的才会显示黑色状态】，所以不能使用，即使配置了名称 Hexo 也不会展示出来。例如我想使用一个名字为 **books** 的图标，是收费的，发现 Hexo 不会展示，我换成了另外一个名字为 **book** 的免费图标，Hexo 就可以正常展示了。

搜索图标结果
![搜索图标结果](https://ws1.sinaimg.cn/large/b7f2e3a3gy1g2f92ey3d0j21g80k3dif.jpg "搜索图标结果")


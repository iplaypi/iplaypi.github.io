---
title: 微博 id mid 相互转换算法实现-Python 版本
id: 2018071801
date: 2018-07-18 02:07:31
updated: 2020-01-09 02:07:31
categories: 基础技术知识
tags: [Python,weibo,mid,id]
keywords: Python,weibo,mid,id
---


对微博数据有了解的人都知道，一条微博内容对应有唯一的微博 `url`，同时对微博官方来说，又会生成一个 `mid`，`mid` 就是一条微博的唯一标识【就像 `uid` 是微博用户的唯一标识一样】，也类似于人的身份证号。其实，微博 `url` 里面有一串看起来无意义的字符【称之为 `id`，由字母、数字组成，6-9个字符长度，当然以后也可能会变长】，可以和 `mid` 互相转换，本文就根据理论以及 `Python` 版本的实现，讲解微博 `id` 与 `mid` 的互相转换过程。


<!-- more -->


# 数据示例


下面列举一些微博内容的示例：

1、通过 `id`、`uid` 构造的 `url`，打开微博内容，示例：`https://weibo.com/3086148515/I1IGF4Ud1` ，其中，`3086148515` 是 `uid`，`I1IGF4Ud1` 是 `id`。

![通过微博 url 打开](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2018/20200113234603.png "通过微博 url 打开")

这种格式的 `url` 可以在网页端通过点击微博的发表时间获取，如下图。

![点击发表时间获取 url](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2018/20200113234623.png "点击发表时间获取 url")

2、通过 `id`、`mid` 构造的 `murl` 打开微博内容，示例：`https://m.weibo.cn/status/I1IGF4Ud1`、`https://m.weibo.cn/status/4404101091169383`，当然这种内容不适合在 `PC` 端的浏览器打开，排版不好。

![通过 id 构造 murl](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2018/20200113235344.png "通过 id 构造 murl")

![通过 mid 构造 murl](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2018/20200113235336.png "通过 mid 构造 murl")


# 代码实现

本文重点讲述 `id`、`mid` 的相互转换，其它的概念例如 `uid`、`url` 不再赘述，读者可以参考备注中的内容。

在此提前说明，下文中涉及的代码已经被我上传至 `GitHub`：[weibo_util.py](https://github.com/iplaypi/iplaypistudy/tree/master/iplaypistudy-normal/src/bin/20180718) ，读者可以提前下载查看。

1、`id` 转为 `mid` 的思路，例如：`I1IGF4Ud1`，有9个字符，从后开始以4个字符为单位进行拆分，拆分为：`I`、`1IGF`、`4Ud1`，然后再分别把它们转为62进制对应的10进制数值，得到：`44`、`0410109`【不足7位在前面补0】、`1169383`。紧接着再拼接所有的结果，得到最终的 `mid`：`4404101091169383`。

`Python` 代码逻辑很简洁，主要 `Python` 代码逻辑如下：

```
# id转换为mid
def id2mid(id):
    id = str(id)[::-1]
    size = int(len(id) / 4) if len(id) % 4 == 0 else int(len(id) / 4 + 1)
    result = []
    for i in range(size):
        s = id[i * 4: (i + 1) * 4][::-1]
        s = str(base62_decode(str(s)))
        s_len = len(s)
        if i < size - 1 and s_len < 7:
            s = (7 - s_len) * '0' + s
        result.append(s)
    result.reverse()
    return ''.join(result)
```

2、`mid` 转为 `id` 的思路，例如：`4404101091169383`，有18个字符，从后开始以7个字符为单位进行拆分，拆分为：`44`、`410109`【前面有0的直接去除】、`1169383`，然后再分别把它们转为10进制数值对应的62进制字符串，得到：`I`、`1IGF`、`4Ud1`。紧接着再拼接所有的结果，得到最终的 `id`：`I1IGF4Ud1`。

`Python` 代码逻辑很简洁，主要 `Python` 代码逻辑如下：

```
# mid转换为id
def mid2id(mid):
    mid = str(mid)[::-1]
    size = int(len(mid) / 7) if len(mid) % 7 == 0 else int(len(mid) / 7 + 1)
    result = []
    for i in range(size):
        s = mid[i * 7: (i + 1) * 7][::-1]
        s = base62_encode(int(s))
        s_len = len(s)
        if i < size - 1 and len(s) < 4:
            s = '0' * (4 - s_len) + s
        result.append(s)
    result.reverse()
    return ''.join(result)
```

3、以上内容运行单元测试后结果截图如下：

![运行单元测试](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2018/20200114000012.png "运行单元测试")


# 备注


关于 `Java` 版本的实现，可以参考我的另外一篇博客：[微博 url mid 相互转换算法实现-Java 版本](https://www.playpi.org/2018122001.html) 。


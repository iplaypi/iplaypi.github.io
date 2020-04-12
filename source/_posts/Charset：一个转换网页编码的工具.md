---
title: Charset：一个转换网页编码的工具
id: 2017082101
date: 2017-08-21 00:28:24
updated: 2017-08-21 00:28:24
categories: 知识改变生活
tags: [Charset,UTF8,Chrome]
keywords: Charset,UTF8,Chrome
---


在 `Web` 项目的开发、测试过程中，有时候会遇到显示乱码问题，而引起问题的原因可能是代码出错、缺少设置等，此时可以通过浏览器查看，进而修复问题。

但是，如果在使用一些第三方网站的工具时，遇到显示乱码的问题，就不能要求网站修复了，毕竟没那么及时，如果是碰到一些编码设置不规范或者不正确的网站【长期不更改】，浏览器无法准确判断其使用的编码，导致网站显示乱码。此时可以使用浏览器的编码设置，强制指定一种编码，使内容显示正确。

但是，有的浏览器不支持编码选择，例如 `Chrome` 浏览器【`v55` 以及之后】，此时就可以借助 `Charset` 插件来解决这个问题。


<!-- more -->


# 现状说明


`Chrome v55` 以后，去掉了网页编码设置的选项，用户不再能自定义指定网页的编码，而 `Chrome` 也会自动识别网页的编码。但是对于不规范的网页【没有指明解析编码】，则 `Chrome` 使用系统默认的编码，但是有时候这会导致显示乱码，`Chrome` 的变更可以参考 `Chrome` 的官方通知：[issues-597488](https://bugs.chromium.org/p/chromium/issues/detail?id=597488) 。

官方的说明：

> This is a part of the effort Project Eraser. Encoding-related UI will go away.

> Quoted from email thread:

> 1) "Auto Detect" option in the hamburger menu.  It's a sticky global boolean that turns on a heavy text analyzer to guess the encoding better.  It's off by default because it regresses page load time by 10%-20%.  By selecting this, users see less gibberish but they make Chrome slower (and don't realize that).

> 2) Manual encoding selection in the hamburger menu.  This is a temporary setting that forces the current tab to the specified encoding, no matter what.  It will turn pages into gibberish if the user selects the wrong one.

> 3) "Default encoding" selector buried in chrome://settings.  This specifies which encoding is selected if "Auto Detect" is disabled and the web page doesn't specify its encoding.  It defaults to the UI language of the Chrome installation.

如果需要自定义编码，例如开发人员、测试人员，可以安装第三方扩展插件，以下两个都可以，链接：[set-character-encoding](https://chrome.google.com/webstore/detail/set-character-encoding/bpojelgakakmcfmjfilgdlmhefphglae) 、[Charset](https://chrome.google.com/webstore/detail/charset/oenllhgkiiljibhfagbfogdbchhdchml) 。


# 举例演示


下面使用中国天气网的数据演示：

```
http://www.weather.com.cn/data/cityinfo/101190408.html
```

上述网页返回的是一组 `JSON` 数据，包含了**太仓**城市的天气情况，但是这个网页的返回信息中，没有指明编码的方式【`Response Headers` 里面的 `Content-Type` 属性】，而 `JSON` 数据内容实际使用的是 `UTF-8` 编码。

![返回头信息](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2017/20200401223432.png "返回头信息")

如果像上面那样使用 `Chrome` 浏览器打开，由于无法识别对方的编码信息，就会使用当前系统默认的编码方式显示，接着就会出现乱码显示的问题。因为 `Chrome` 浏览器使用系统默认编码 `GBK`，当然无法正常显示，还由于我这里安装的 `v80` 版本不支持手动设置显示编码，只能看着乱码的内容。

当然，如果直接查看 `JSON` 数据，是可以看到正确的数据显示的，查看 `Response` 里面的数据。

![查看JSON数据正常](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2017/20200401223424.png "查看JSON数据正常")

此时，为了直接看清楚返回的内容，可以使用 `Charset` 插件来更改解析显示数据使用的编码，我在这里选择 `Unicode(UTF-8)`，网页会自动刷新，数据显示正常。

![更改解析显示编码](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2017/20200401223415.png "更改解析显示编码")

![刷新后正常显示](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2017/20200401223401.png "刷新后正常显示")

同时，可以留意到 `Response Headers` 里面的 `Content-Type` 属性变化了，指定了编码，这也就是 `Charset` 插件的作用。


---
title: Aria2 Web 管理面板使用
id: 2018110902
date: 2018-11-09 01:44:11
updated: 2018-11-09 01:44:11
categories: 知识改变生活
tags: [aria2,百度云下载,百度云限速]
keywords: Aria2,百度云,百度云下载,破解百度云,百度云限速
---


如果使用浏览器默认的下载器，下载百度云的文件速度大多数情况下不理想，而且大文件不能下载，同时非客户端下载文件又会严重限速。如果使用插件和脚本配合，突破了百度云的限制，可以下载大文件，但是遇到下载中途失败的情况，有时候不能继续下载，还要重头来，会让人崩溃，体验非常不友好。那么我前面一篇文章描述了这个过程，同时给出了几个解决方案，本文就记录一下其中涉及到 Aria2 的使用以及其中一种管理面板【YAAW for Chrome】的使用。


<!-- more -->


# 插件的安装


这款插件的全名是 Yet Another Aria2 Web Frontend，简称 YAAW，可以去谷歌的插件商店获取：[YAAW](https://chrome.google.com/webstore/detail/yaaw-for-chrome/dennnbdlpgjgbcjfgaohdahloollfgoc?hl=zh-CN) 。当然，如果你没有翻墙，是打不开这个链接的，你可以选择去国内的镜像站点下载，例如：[chrome-extension-downloader](https://chrome-extension-downloader.com) ，或者 [getcrx](http://getcrx.cn/#) ，至于怎么使用可以参考本博客的[关于页面](https://www.playpi.org/about/) 。为了方便你们，我把这款插件的插件 id 也放出来：dennnbdlpgjgbcjfgaohdahloollfgoc。

详细的安装过程就不赘述了，不是重点，一般也就是在线安装或者下载 crx 离线文件安装，都不是困难的事情。


# 插件的使用


为了使用这款插件，还需要 Aria2 、baiduexporter 这2款工具的协助。Aria2 在前文已经描述过了，是用来下载文件的后台程序，本来直接使用它下载文件就可以了，但是奈何不方便批量下载以及任务管理，所以需要搭配 YAAW 来使用。baiduexporter 这款插件是用来转换百度云盘文件的链接的，转为 Aria2 可以直接使用的方式。

这2款工具的安装可以参考上一篇博客，在这里仅给出对应的链接和插件 id：[Aria2 安装包](https://github.com/aria2/aria2/releases) 、[Aria2 介绍](https://aria2.github.io/) 、[baiduexporter插件](https://chrome.google.com/webstore/detail/baiduexporter/jgebcefbdjhkhapijgbhkidaegoocbjj?hl=zh-CN) 、baiduexporter 插件的 id【jgebcefbdjhkhapijgbhkidaegoocbjj】。

## Aria2

一切准备就绪后，我先在后台启动 Aria2 进程。切记要开启 RPC 模式，否则 YAAW 插件无法监控后台的下载任务，也就无法进行管理了。还要开启断点续传，这样才能在下载出现异常中断之后，还能接着上次的进度继续下载，节约时间。

启动 Aria2 进程
![启动 Aria2 进程](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/old/b7f2e3a3gy1g12rdtxd1mj20nf0fbq47.jpg "启动 Aria2 进程")

## YAAW

如果一开始直接打开 YAAW 插件，会显示错误：**Error: Internal server error**，其实就是没有找到 Aria2 进程。
![直接打开 YAAW 插件](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/old/b7f2e3a3gy1g12rfb5jz5j21hc0rhmyg.jpg "直接打开 YAAW 插件")

那它们是怎么通信的呢，其实就是依靠一个端口，这个端口我们使用默认的就行了【默认就是6800】，否则要在 YAAW 和 Aria2 两边都要设置，并且保持一致。

YAAW 插件设置端口
![YAAW 插件设置端口](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/old/b7f2e3a3gy1g12rfu7534j21hc0rfjt6.jpg "YAAW 插件设置端口")

Aria2 设置端口
![Aria2 设置端口](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/old/b7f2e3a3gy1g12rfzt0nnj20j4036glo.jpg "Aria2 设置端口")

当然，从上面的截图中我们可以看到，还可以设置一些其它参数，例如：自动刷新时间、限速大小、用户代理、基础目录。然而，这些参数都是全局性的，我们没有必要设置，因为等到真正需要下载文件的时候，还可以重新设置，实际应用中不一定每次下载的设置都一致，所以放在每次下载文件的时候重新设置显得更灵活。

## baiduexporter

baiduexporter 的安装就比较简单了，就是一个浏览器插件而已，安装后打开即可。
![baiduexporter 插件](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/old/b7f2e3a3gy1g12rgfsynwj20ge0craah.jpg "baiduexporter 插件")

## 三者结合协同工作

打开我的百度云网盘，随意找一个文件测试
![打开百度网盘](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/old/b7f2e3a3gy1g12rgzfh7oj21hc0q90uf.jpg "打开百度网盘")

细心的人可以发现，在选中一个文件后，在本来的**下载**旁边多了一个选择项**导出下载**，如果移动鼠标到上面，**导出下载**会展开下拉列表，出来3个选项：Aria2 RPC、文本导出、设置。
![导出下载](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/old/b7f2e3a3gy1g12rhn2uy2j21hc0q9q4p.jpg "导出下载")

如果我选择第一个 Aria2 RPC，则会直接调用后台的 Aria2 进程，直接帮我下载文件了，不需要我使用 Aria2 的原生命令加上必要的参数去启动一个下载任务了。
![Aria2 RPC 下载文件](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/old/b7f2e3a3gy1g12ric7fwqj21hc0q9taf.jpg "Aria2 RPC 下载文件")

而第二个文本导出，其实就是导出这个百度云文件的 Aria2 完整的命令，这样我们就可以复制使用，在后台起一个 Aria2 的下载任务了【有了第一种的 RPC 方式，更为方便快捷，肯定不用这种方式】。
![文本导出](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/old/b7f2e3a3gy1g12rixl1p1j21hc0q9ac0.jpg "文本导出")

而设置则是导出的参数设置，这个没什么好说的，一般使用默认的就行了。
![导出的设置](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/old/b7f2e3a3gy1g12rj8h9n9j21hc0q9410.jpg "导出的设置")

好，接下来重点来了，必将能让你感受到什么叫做方便快捷。前面说那么多操作步骤，是不是发现还没 YAAW 插件什么事情，别着急，接下来的描述都是它的。直接打开插件：
![YAAW 任务列表](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/old/b7f2e3a3gy1g12rjw0jgyj21hc0q9t9j.jpg "YAAW 任务列表")

有没有发现什么，刚才下载的任务已经在这里可以看到了。不仅如此，还可以在这个控制面板中随意操管理任务：暂定、开始、删除，还可以看到下载的网速和进度百分比，多方便，这已经近似于一个下载管理软件了【虽然很简陋，但是比直接操作 Aria2 后台方便多了】。
![YAAW 任务管理](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/old/b7f2e3a3gy1g12rk0wdhej21hc0q9t9k.jpg "YAAW 任务管理")

刚才使用百度云下载文件的时候，是直接在**导出下载**中一键勾选的，很方便，但是如果是别人发给你一个 Aria2 能下载的链接，你该怎么办呢？是使用 Aria2 后台起一个下载任务，还是怎么样，因为此时没有像下载百度云盘文件那么方便的按钮给你选择。别担心，此时又要使用 YAAW 的另外一个功能了：创建任务，也就是相当于在迅雷中创建一个下载任务一样。在 YAAW 插件中有一个 **ADD** 按钮。
![YAAW 任务创建](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/old/b7f2e3a3gy1g12rk5z1fhj21hc0q9ab6.jpg "YAAW 任务创建")

点击后弹出一个配置的对话框，在里面填上对应的参数就行了。不知道大家有没有发现，这里面的参数和使用 baiduexporter 插件的**导出下载**里面的**文本导出**导出的文本里面的一些内容很是相似，另外需要自己设置一下文件名字、文件下载目录、用户代理等信息就行了。这里就不再具体演示了。

当然，以上只是使用百度云网盘作为示例，大家比较容易理解，演示给大家，纯粹是为了抛砖引玉，其实 Aria2 还支持更多的协议，大家可以自行参考 Aria2 的官方网站。如果下载磁力链接的东西，有时候迅雷更快，因为毕竟它是 p2p 的，可以加速，大家还是要看情况使用。


# 温馨提示


除了突破限速的场景，我还发现一个场景，那就是资源文件被禁用的时候，也可以突破禁用，自由下载资源文件，例如盗版电影的下载。在不久后的2019春节档，竟然出现了史无前例的电影高清资源泄漏的事件。重点包括《新喜剧之王》、《疯狂的外星人》、《流浪地球》、《飞驰人生》这几部，电影刚上映3天，就有高清资源【画质比较好，不是一般的枪版】流出来了，大家可以下载。接着电影官网就鼓励大家进行举报封禁，导致各大下载软件都屏蔽了资源，显示由于版权问题而禁止下载。

这时候各种开源的下载器就派上用场了，例如 Aria2 就是一个，但是缺点就是网速可能没有那么快，因为没有 p2p 加速机制。但是我仅仅是为了学习，测试一下也无妨。

可以看到，使用迅雷下载是被禁止的。
![迅雷下载被禁](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/old/b7f2e3a3gy1g12rl6jyahj209y0k6diy.jpg "迅雷下载被禁")

把 torrent 文件保存下来，转而使用 Aria2 下载，为了方便直接在 YAAW 插件上面建任务，直接上传 torrent 文件即可，其它参数则使用默认的。
![保存 torrent 文件](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/old/b7f2e3a3gy1g12rlh3exej217i0ndq4h.jpg "保存 torrent 文件")

可以看到，下载速度可以达到 2M 以上。
![下载顺利](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/old/b7f2e3a3gy1g12rlbkjcpj216q0ekq43.jpg "下载顺利")

以上下载电影实践中，当然目的只是为了学习使用，给你们演示一下而已，不是提倡下载盗版电影，在下载一些被屏蔽的资源或者被限速的情况下，可以使用这种方式试试。


---
title: Hexo 的踩坑经验
id: 2019022501
date: 2019-02-25 01:00:21
updated: 2019-02-26 01:00:21
categories: 基础技术知识
tags: [hexo,markdown,java,bash,xml]
keywords: hexo,markdown,java,bash,xml
---


大家知道，我是使用 Hexo 来构建我的静态站点的，每次使用 Markdown 语法书写 md 文档即可。写完后在本地使用 hexo g & hexo s 命令【在本地生成并且部署，默认主页是 localhost:4000】来验证一下是否构建正常。如果有问题或者对页面效果不满意就返回重新修改，如果没有问题就准备提交到 GitHub 上面的仓库里面【在某个项目的某个分支】，后续 travid-cli 监控对应的分支变化，然后自动构建，并推送到 master 分支。至此，更新的页面就发布完成了，本人需要做的就是管理书写 md 文档，然后确保没问题就提交到 GitHub 的仓库。


<!-- more -->


# 问题清单


前言描述的很好，很理想，但是有时候总会出现一些未知的问题，而我又不了解其中的技术，所以解决起来很麻烦，大部分时候都是靠蒙的【当然，也可以直接在 Hexo 的官方项目上提出 Issue，让作者帮忙解决】。下面就记录一些遇到的问题，以及我自己找到的原因。

# 1-Markdown 语法不规范

这个错误有在 travis 上面出现过，在 travis 的116号、117号错误：[https://travis-ci.org/iplaypi/iplaypi.github.io/builds/476399853](https://travis-ci.org/iplaypi/iplaypi.github.io/builds/476399853) 。

在使用 hexo 框架的时候，一定要确保 markdown 文件里面的代码块标识【标记代码的类型，例如：java、bash、html 等】使用正确。否则使用 **hexo g** 生成静态网页的时候，不会报错，但是却没有成功生成 html 静态网页，虽然 html 静态文件是有的，但是却查看不了，显示一片空白。

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

但是如果把 java 误写成了 xml，在本地执行 ** hexo g** 的时候不会报错，生成的 html 静态网页也是正常的。而一旦使用 travis-cli 执行自动构建的时候，构建是失败的【在 travis 的116号、117号错误：https://travis-ci.org/iplaypi/iplaypi.github.io/builds/476399853 】，并且可以看到错误信息，图四，但是我看不懂错误原因，只能猜测找到问题所在，比较耗时。

travis-cli 报错日志【我看不懂】：
travis-cli 日志1
![travis-cli 日志1](https://ws1.sinaimg.cn/large/b7f2e3a3gy1g0j7iqv9msj20th0ld0to.jpg "travis-cli 日志1")

travis-cli 日志2
![travis-cli 日志2](https://ws1.sinaimg.cn/large/b7f2e3a3gy1g0j7jt59f2j20rh0nvjur.jpg "travis-cli 日志2")

travis-cli 日志3
![travis-cli 日志3](https://ws1.sinaimg.cn/large/b7f2e3a3gy1g0j7jokkp6j20rh0p4dj2.jpg "travis-cli 日志3")

此外，写 Markdown 文档，使用代码块标记的时候，使用3个反单引号来标记，如果不熟悉代码块里面的编程语言，可以省略类型，例如 java、bash、javascript，不要填写，否则填错了生成的 html 静态文件是空白的。还有就是如果代码块里面放的是一段英文文本，和编程语言无关，也不要填写类型，否则生成的 html 静态文件也是空白的。


# 2-Hexo 报错奇怪

这个错误还没有到 travis 上面，所以 travis 上面没有记录；

在本地测试过程中，无论是 **hexo s** 还是 **hexo g** 都会报错，错误信息如图：
![报错信息](https://ws1.sinaimg.cn/large/b7f2e3a3gy1g0j7kb9p5zj20jt02k3yk.jpg "报错信息")

看着这个信息，很像在当前项目的目录中找不到 hexo 命令，和 java 类似，我就怀疑是不是安装的 hexo 被什么时候卸载了，其实不是的，在其它项目中还能用。后来我发现是当前项目使用的模块缺失，为什么会缺失我也不知道，由于这些缺失的模块是通过 hexo 引入的，所以直接报错：hexo not found，给人以误导。

总的来说，就是报错有误导性，没有报模块缺失，而我又不懂这些，查了一些资料，手动测试了一些方法，总算找到原因所在。找到原因，那解决办法很简单了，直接安装缺失的模块即可，使用 **nmp install** 命令安装 package.json 里面的模块。

# 3-Hexo 配置错误引起的误导性

这个错误还没有到 travis 上面，所以 travis 上面没有记录；

这个错误和上面的类似，但是如果从报错信息上面看，也具有误导性。在更改了 \_config.yml 配置文件后，按照正常步骤去生成、部署的时候【使用 **hexo g & hexo s**命令，直接报错了，把我整蒙了，报错信息如下：
![报错信息](https://ws1.sinaimg.cn/large/b7f2e3a3gy1g0j7kzx1vij20k50iqq4q.jpg "报错信息")

关键配置部分如下，后续找到问题确实出在这里：
![关键配置部分](https://ws1.sinaimg.cn/large/b7f2e3a3gy1g0j7les4wdj20lu08wt9j.jpg "关键配置部分")

从图中看信息，我也看不到什么原因，因为确实不懂。注意，我为了测试，发现 **hexo g** 是没有问题的，也就是生成没问题，那问题就出在部署步骤了，它会不认这个**hexo s** 命令？我查了资料，发现大部分人都说缺失 hexo server 模块，我通过检查可以确保本机有这个模块，而且卸载了重新装，所以不是这个问题。

最后发现是配置信息里面的参数【官方定义的关键词】错误了，里面的 **Plugins** 这个参数应该使用首字母大写，这谁能想到，正确的配置参数如下图：
![plugins 改为首字母大写](https://ws1.sinaimg.cn/large/b7f2e3a3gy1g0j7lre005j20nb08udgb.jpg "plugins 改为首字母大写")

# 4-travis 配置问题

这个错误有在 travis 上面出现过，在 travis 的27号：https://travis-ci.org/iplaypi/iplaypi.github.io/builds/448152737 。

在使用 travis 自动构建时，有一次突发奇想，想使用最新版本的 node_js，于是在 travis.yml 配置文件中，把 node_js 设为了 stable，即稳定版本，这样在构建的时候会使用最新稳定版本的 node_js，没想到就出问题了。

node_js 的配置如下：
![node_js 的配置](https://ws1.sinaimg.cn/large/b7f2e3a3gy1g0k90kw0e8j20oy0dujsd.jpg "node_js 的配置")

travis 报错日志如下：
![travis 报错日志](https://ws1.sinaimg.cn/large/b7f2e3a3gy1g0k91bjlrxj20rq0qxq4q.jpg "travis 报错日志")

重要部分：
```javascript
error nunjucks@3.1.3: The engine "node" is incompatible with this module. Expected version ">= 6.9.0 <= 11.0.0-0". Got "11.0.0"
error Found incompatible module
```

看来还是在搞清楚新旧版本之间的差异后再想着升级版本，不要随意来，要不然浪费的是自己的时间。后来解决办法就是手动指定 node_js 的版本。

# 5-无缘无故出现的问题

这个错误有在 travis 上面出现过，在 travis 的133号、134号错误、135号错误、136号错误，举例：https://travis-ci.org/iplaypi/iplaypi.github.io/builds/498318318 ；

日志部分截图：
![日志内容](https://ws1.sinaimg.cn/large/b7f2e3a3gy1g0k91nhkhkj20rk0l6761.jpg "日志内容")

这错误信息里面对我来说确实看不到有效的内容，还没找到解决办法，看似是文件路径不存在，但是项目配置也没变过。

```javascript
npm ERR! path /home/travis/.nvm/versions/node/v10.10.0/lib/node_modules/hexo-cli/node_modules/highlight.js/tools/build.js
npm ERR! code ENOENT
npm ERR! errno -2
npm ERR! syscall chmod
npm ERR! enoent ENOENT: no such file or directory, chmod '/home/travis/.nvm/versions/node/v10.10.0/lib/node_modules/hexo-cli/node_modules/highlight.js/tools/build.js'
npm ERR! enoent This is related to npm not being able to find a file.
npm ERR! enoent 
npm ERR! A complete log of this run can be found in:
npm ERR!     /home/travis/.npm/_logs/2019-02-25T18_45_08_713Z-debug.log
```

等待找问题的原因。

好，仔细看了日志、找了博客文档，没有解决方法，我也不懂，看到可能是版本原因【我不能升级 nodejs 版本，与 yarn 有关】，可能是权限问题。我用 sudo npm install -g hexo-cli 试了试，明显不行：[https://travis-ci.org/iplaypi/iplaypi.github.io/builds/498794142](https://travis-ci.org/iplaypi/iplaypi.github.io/builds/498794142) ，然后我就放弃了，直接改回来提交了，没想到无缘无故就可以了，构建日志：[https://travis-ci.org/iplaypi/iplaypi.github.io/builds/498796865](https://travis-ci.org/iplaypi/iplaypi.github.io/builds/498796865) 。

准备发邮件问问 travis 客服，我现在单方面怀疑是 travis 的环境问题或者构建脚本所依赖的环境问题。由于时差问题，先记录几个时区的缩写，方便查看邮件内容的时候核对时间：UTC【世界标准时间】、EST【东部标准时间，UTC-5】、CET【欧洲中部时间，UTC+1】。

我发送的邮件内容如下【发送于北京时间2019-02-28 14:42:00】：
![我发送的邮件内容](https://ws1.sinaimg.cn/large/b7f2e3a3gy1g0s7r7q8rsj230g1rswyo.jpg "我发送的邮件内容")

完整文字版供参考
```
Automatic building is failed

Hello,
I hava a repository in GitHub,and i use travis-ci to build it automatically.
I configured the correct script,and it has been built successfully more than one hundred times.
My script is :
https://github.com/iplaypi/iplaypi.github.io/blob/source/.travis.yml ;

But it built failed at 2019-02-26,the all log as follows(i retry it three times,but still failed):
https://travis-ci.org/iplaypi/iplaypi.github.io/builds/498267014
https://travis-ci.org/iplaypi/iplaypi.github.io/builds/498278045
https://travis-ci.org/iplaypi/iplaypi.github.io/builds/498297576
https://travis-ci.org/iplaypi/iplaypi.github.io/builds/498318318

I cannot find any usefuI information in my log.I am very sad and helpless.
But i retry it at 2019-02-27,it actually build successfully,amazing.
I swear I have not changed any files,the successful log is:
https://travis-ci.org/iplaypi/iplaypi.github.io/builds/498796865 ;
So i am puzzled,i donnot know why,i suspect it is a problem with the machine.
Can you help me?
Best wishes.
```

发送后对方自动有一个回复，告知我他们的工作时间【中国北京时间与对方时差+13】：
![对方自动回复](https://ws1.sinaimg.cn/large/b7f2e3a3gy1g0s7rpd5kbj219x0lq401.jpg "对方自动回复")

等了好几天，对方终于回复了【回复于北京时间2019-03-04 11:00:00】，对方回复内容如下：
![对方回复](https://ws1.sinaimg.cn/large/b7f2e3a3gy1g0s7s5bo3uj219x0lswfv.jpg "对方回复")

对方回复重要文字内容
```
Hey there,

Thanks for reaching out and I'm sorry for these spurious failures you have experienced.

I think it could be an issue with the package itself or the NPM registry on that specific day. I've looked at NPM's status and their was an incident on Feb. 27th. See https://status.npmjs.org/incidents/ptnlj2rtwfwm. Maybe it was already happening on Feb. 26th? Sorry for not having a better explanation.

Please let us know if this issue resurfaces again, we would be happy to have another look.

Thanks in advance and happy building!
```

看起来技术支持也没发现是啥问题，只是说有可能是 NPM 的问题，还给了一个链接：[https://status.npmjs.org/incidents/ptnlj2rtwfwm](https://status.npmjs.org/incidents/ptnlj2rtwfwm)，根据链接可以看到 NPM 的状态在某个时间点出问题了【时间点为2019-02-27 15:46:00 UTC，也就是北京时间2019-02-27 23:46:00】：
![nmp问题](https://ws1.sinaimg.cn/large/b7f2e3a3gy1g0s7sku7hvj20p00k0gmb.jpg "nmp问题")

但是我那个自动构建的问题是出在北京时间2019-02-26凌晨的，时间点也对不上，所以技术支持只是怀疑，也没有结论，那我也就不管了，继续观察以后有没有相同的问题出现。


# 6-排版问题


1、在 Markdown 文件中关于链接的，要使用 []、() 这2个完整的标记，不要直接放一个链接出来，会导致生成的 html 文件带链接的内容居中对齐，导致文字分散开来，不好看。

2、中文括号不要使用，也会导致居中对齐的问题，文字排版不好看，使用方括号吧：【内容示例】。


# 7-草稿问题


我在使用 Hexo 的草稿功能时，发现一个问题，操作完成发布时，发现 Markdown 文档的头部描述信息变化了。例如我本来设置的 id 又变回了日期【可以理解，因为模板就是这样设置的】，然后 tags 的中括号中的标签变为了无需列表【不可理解】。暂时还没发现内容的变化，可能是内容中没有特殊符号。

导致的问题就是草稿发布后【内容已经变化了】，提交到 source 分支，自动构建时，提交到主分支 master 后，这些文章的链接变为了日期的乱格式【因为是基于错误的 Markdown 文件构建的】。所以以后还是不要使用草稿功能了，没有必要，还麻烦，没写完也可以发布嘛，没啥大问题。
![文章链接是错误的](https://ws1.sinaimg.cn/large/b7f2e3a3gy1g0tkfnu178j20w50gj0tq.jpg "文章链接是错误的")


---
title: 注册 Facebook Twitter Tumblr 遇到的问题
id: 2018020101
date: 2018-02-01 19:25:16
updated: 2018-11-20 19:25:16
categories: 知识改变生活
tags: [Facebook,Twitter,Tumblr]
keywords: Facebook,Twitter,Tumblr,Twitter绑定手机号,Twitter冻结,Twitter被封
---


在这个地球上，有很多好用的工具或者网站被封了，在中国大陆地区无法访问，如果需要使用它们，首要的问题就是翻墙。然而，事情没有那么简单，有时候可以翻出去了，但是在使用的过程中还会遇到奇怪的问题，每一步都不好走。本文记录注册使用 Facebook、Twitter、Tumblr 等社交账号时可能遇到的问题、解决的办法，给自己留一个备份，同时也能给大家带去一些方便。


<!-- more -->


提前说明，需要翻墙的读者，可以使用浏览器插件或者一些免费的工具，但是大多数都不够稳定，如果想要稳定的方式，最好还是自己搭建梯子。我这里有一个硬核教程【需要一点点技术，或者找一个懂技术的人，10分钟可以搞定】，自己搭建 `shadowsocks`，手把手教学，图文并茂，顺便把客户端的使用方式也记录下来，参考我的另外一篇博文：[使用 Vultr 搭建 Shadowsocks（VPS 搭建 SS）](https://www.playpi.org/2018111601.html) 。当然，这种方式肯定不是免费的，租用云服务器每月需要一定的钱，但是也不多，几美元足够，如果几个人合伙使用的话，平摊费用算下来也不多。


# Facebook


待整理。


# Twitter


以下内容中涉及到的操作环境、截图示例都是基于 Web 版的 Twitter，没有使用手机客户端。

## 注册

注册 Twitter 帐号，首先需要一个邮箱帐号，或者手机号，进入注册首页，进行信息填写[注册页](https://twitter.com/i/flow/signup)，填写完成后，接下来也就是常规流程，发送短信验证码、语音验证码、邮箱激活链接等，基本没什么问题。

## 绑定手机号问题

由于我选择的是 Google 邮箱注册，注册完成之后可以正常登录，但是进入不了主页面，就被绑定手机号页面拦截了，**一直提示需要添加一个手机号**，要不然就停留在当前页面，什么也做不了，除非退出。那这个就是坑人了，登录之后卡在那里，什么都看不了，只能退出，那我还注册帐号干什么。
![Add a phone number](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/old/b7f2e3a3gy1fxerje8k7wj20p00exglz.jpg "Add a phone number")

接着我就按照提示，绑定手机号吧，但是，诡异的问题再次出现，我使用自己的手机号进行绑定时，提示错误：`由于技术问题，无法完成当前的请求，请重试【Due to a technical issue, we couldn't complete this request. Please try again.】`。

我是不相信 `Twitter` 能有什么技术问题，我只能怀疑是中国的手机号无法进行绑定，当然只是猜测。于是上网搜索了一下资料，发现果然是这个原因，铺天盖地的结果展现在搜索引擎的搜索列表中，很多人都遇到了这个问题。

再看看，一些过来人都建议一开始直接使用手机号注册，不要使用邮箱注册，就不会有这个问题了。唉，一开始不知道，接下来没有办法了，只能尝试寻找可行的办法，毕竟邮箱已经注册过了，不想浪费。

## 绑定手机号解决方案尝试

官方说法是当前帐号疑似是机器人【不是一个真实的人类】，所以被冻结了，必须添加一个可用的手机号，用来接收验证码，才能证明当前帐号是人为注册的，才能进行接下来的操作。那这样看起来很好办，想办法找一个可以使用的手机号接收验证码，或者能不能通过和客服沟通人工解封呢？

### 利用浏览器调试工具

利用 Chrome 浏览器的开发者工具更改下拉列表的值，把日本的编号81改为86，应用在页面上，从而伪造手机号码的所属国家编码，看看能不能收到验证码。**实际操作发现不行，所以大家不要使用这种方式，没有用，请使用第二种邮件申诉的方式，亲测可以使用，并且已经帮助好几个人成功注册激活**。没有用的原因在于 Twitter 验证的时候还是会重新刷新下拉列表，把国家编码更新。

具体操作为：在 Chrome 浏览器的对应页面，按下键盘的 F12 按键，就可以打开调试工具【或者点击鼠标的右键，选择检查】，在 `Elements` 选项中可以看到源代码，更改表单里面的下拉列表的值，即可，需要一点点技术知识。
![更改下拉列表内容](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/old/b7f2e3a3gy1fxertxa23qj21260p6myi.jpg "更改下拉列表内容")

### 邮件申诉

首先声明，**推荐大家使用这种方式来解封、激活帐号**，我自己使用有效，而且已经帮助过好几个人解决了问题，基本在24小时内可以解决问题【节假日不知道客服上不上班】。

去帮助中心，找客服，发送申诉邮件，内容解释说明你是一个真实的人，现在注册帐号被冻结了，请求解封。Twitter 帮助中心网址：[Twitter 帮助中心](https://help.twitter.com/en) ，在帮助中心选择 `Contact us`，进一步选择 `View all support topics` 。
![Contact us](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/old/b7f2e3a3gy1fxes1ihmuqj21hc0p6q49.jpg "Contact us")

进入选择页面后，进一步选择 `Suspended or locked account`，表示对冻结或者锁定的帐号进行申诉处理。
![Suspended or locked account](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/old/b7f2e3a3gy1fxes4iubaqj212y0p6jsx.jpg "Suspended or locked account")

最终进入的页面就是这样的：[申诉信息填写](https://help.twitter.com/forms/general?subtopic=suspended) ，可以开始填写申诉信息了。
![申诉信息填写](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/old/b7f2e3a3gy1fxes6m6189j219e0p6gmv.jpg "申诉信息填写")

这里面最主要的内容就是问题描述，请描述清楚你的问题，另外设备的选择按照自己的实际情况填写，全名和手机号也按照实际情况填写。此外，注意填写信息前需要登录帐号【虽然卡在验证页面，也要保持登录状态】，否则页面是锁定状态，无法填写任何信息。而且，登录后，大部分信息都是自动填充完成的，无需手动一个一个填写，只需要填写重要的几项内容即可。

例如我填写的问题描述，仅供参考：

```
Account suspended.Could not unsuspend it through phone number.Pls help to unsuspend the account.Thanks.
```

提交后会收到一封由 Twitter 官方技术支持【Twitter Support <support@twitter.com>】发送的邮件【邮件基本是秒回，肯定是系统自动回复】，告诉你应该怎么做，邮件内容如下截图。
![Twitter 技术支持邮件](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/old/b7f2e3a3gy1fxesj53y9zj215s0llgn7.jpg "Twitter 技术支持邮件")

但是看内容也看不出来什么，只是表明说你的帐号疑似是机器人帐号，需要绑定手机号码，后面列出来一系列的步骤。其实我也是想做这一步的，但是奈何中国的手机号码不支持，仔细看最后一句话：**如果还有问题，可以直接回复此邮件并说明问题详细**，好，机会来了。

接下来我又回复了一封邮件，说明自己遇到的问题，内容大概如下，解释说明自己是一个真实的人，但是由于手机号码是中国的，无法接收到验证码，请求人工解决：

```
Hello,
  I try in this way,But i am in China,i can not receive messages.
  I am a human indeed,and my phone number is +86 1********06.
  best wishes.
```

![回复邮件](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/old/b7f2e3a3gy1fxeso1yjgrj21870e3my0.jpg "回复邮件")

接下来就是等待官方的回复了，由于是客服人工操作的，或者系统审核，速度比较慢，需要等好几个小时，希望晚上睡一觉后明天会有好消息。

在等待了一夜后，又过了半天时间【总共大概17个小时】，收到了 Twitter 官方的回复，说我的帐号已经解冻，并解释了原因。这次回复等待了这么长时间，不像上次申诉回复那么快，说明很大可能是人工审核的，然后解冻了你的帐号，再回复这封通知邮件给我。

不管怎样，帐号可以使用了。
![官方解冻邮件回复](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/old/b7f2e3a3gy1fxfnvviw2gj21dk0n7mzb.jpg "官方解冻邮件回复")

接下来为了保证不被封号，最好重新设置一下昵称，并且填写一些必要的信息：**用户名【id】、头像、生日、国家、描述**等，也可以关注一些其他推主。

更改用户名在 `Settings and Privacy` 里面，由于用户名是唯一的【和 GitHub 的策略一样】，所以常用的都被别人注册过了，自己要注意寻找，如果遇到更改失败的情况，会显示用户名被占用，再换一个试试。
![更改用户名](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/old/b7f2e3a3gy1fxfp8312wuj216i0p6gnu.jpg "更改用户名")

更改**昵称、头像、背景墙、描述**等，在 `Profile` 里面。
![更改基本信息](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/old/b7f2e3a3gy1fxfpeugi9zj218p0p6wi6.jpg "更改基本信息")

流程总结：

1、此篇博文只针对使用 Google 邮箱注册的情况，注册后帐号被冻结，什么也做不了，绑定手机号又说不支持，只能通过申诉来解决【如果一开始注册时使用的就是手机号，应该没有问题】；
2、申诉的目的是为了解冻帐号，但是官方是自动回复，让绑定手机号，此时又回到了原地；
3、在步骤2的基础上可以直接回复邮件【邮件中有提示】，说明遇到的问题，等待将近一天就行了；【如果没有步骤2，直接给官方技术支持发邮件，应该是不行的】
4、步骤3官方回复的邮件中，问题已经解决，并提示说不要回复此邮件；【回复了应该也没人理】


# Tumblr


待整理。


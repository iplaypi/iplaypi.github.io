---
title: ItChat 系列0-初识 ItChat
id: 2019020701
date: 2019-02-07 22:58:07
updated: 2019-02-07 22:58:07
categories: ItChat 系列
tags: [ItChat,微信接口,自定义接口,自动回复,微信机器人]
keywords: ItChat,微信接口,自定义接口,自动回复,微信机器人
---


微信已经是我们日常生活中常用的 APP 之一，每天都离不开。作为掌握技术的理工科人员，有时候总想着是否可以利用微信的接口完成一些重复的工作，例如群发消息、自动回复、接入机器人自动聊天等。当然，这些都可以实现，而且只要是人工可以做到的事情，基本都可以做到自动化（前提是微信提供了对应的接口，反例就是自动收发红包不行，当然微信不会直接提供 API 接口，需要自己寻找）。本文就讲解为了做到这些，需要的入门知识点，主要就是利用 ItChat 工具（屏蔽了微信的 API 接口，简化了使用微信接口的过程，不懂技术的普通人也可以轻松掌握），当然本文只是一个入门的例子而已（完成后对自己来说很实用而且有成就感），后续会讲解更加深入与广泛的内容。本文基于 Windows 7 操作系统，Python 2.7 版本（为了兼容性与易维护性，我推荐使用 Python 3.x 版本）

<!-- more -->


# ItChat 简介


摘录官方文档描述：

>itchat 是一个开源的微信个人号接口，使用 python 调用微信从未如此简单；
>使用不到三十行的代码，你就可以完成一个能够处理所有信息的微信机器人；
>当然，该 api 的使用远不止一个机器人，更多的功能等着你来发现；
>该接口与公众号接口 itchatmp 共享类似的操作方式，学习一次掌握两个工具；
>如今微信已经成为了个人社交的很大一部分，希望这个项目能够帮助你扩展你的个人的微信号、方便自己的生活。

当然，我是觉得上面的描述有一些语句不通顺，但是不影响我们理解作者的原意。

其实微信官方并没有提供详细的 API 接口，ItChat 是利用网页版微信收集了接口信息，然后独立封装一层，屏蔽掉底层的接口信息，提供一套简单的使用接口，方便使用者调用，这不仅提升了效率，还扩展了使用人群。


# 使用入门


以下使用入门包括基础环境的安装、itcaht 的安装、代码的编写、实际运行，当然，为了避免赘述，不会讲解的很详细，如果遇到一些问题，自行利用搜索引擎解决。


## 安装 Python 环境

### 下载 Python

去官网：https://www.python.org/downloads/windows ，选择自己需要的版本，我这里选择 Windows 系统的版本（64位操作系统），Python 2.7（这是一个很古老的版本了，推荐大家使用 3.x 版本）；

我选择的版本
![Windows系统64位](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/old/b7f2e3a3gy1fzzcck7qfjj21hc0p6n0z.jpg "Windows系统64位")

下载过程就和下载普通的文件、视频等一样，根据网速的限制有快有慢。

### 安装 Python

就像安装普通程序一样，直接双击下载的程序文件，选择安装即可，这里就不再赘述详细的安装过程了；

如果你们的环境不是 Windows 7系统的，可以自行使用搜索引擎搜索教程；

这里一定要注意安装的版本是否适配自己的操作系统（包括系统类型与系统位数）；

在 Windows 系统的**程序和功能**中查看已经安装完成的 Python 程序（2.7版本，我是使用 Anaconda2 安装的，所以看起来有些不一样）：
![windows程序和功能](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/old/b7f2e3a3gy1fzzcbr6amhj20y80k5q5m.jpg "windows程序和功能")

### 配置环境变量

如果这一步忽略了，使用 Python 或者 Python 自带的插件的时候（比如安装 ItChat 的时候就会用到 pip 工具），会找不到应用程序，只能先进入到 Python 目录或者插件所在的目录再使用对应的工具（例如进入 Python 所在的目录或者 pip 所在的目录），比较麻烦，所以在此建议大家配置一下环境变量；

配置环境变量的过程也不再赘述，大家自己利用搜索引擎获取，下图是基于 Windows 7版本的配置截图示例；

**系统属性**
![系统属性](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/old/b7f2e3a3gy1fzzcdqptjbj215o0ngtez.jpg "系统属性")

**高级系统设置**
![高级系统设置](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/old/b7f2e3a3gy1fzzcf7mux2j20fe0f7ta0.jpg "高级系统设置")

**环境变量**，我这里编辑用户环境变量 PATH 的内容（如果不存在就新建，当然编辑系统环境变量 PATH 的内容也是可以的），切记内容一定是英文格式下的，多个使用英文逗号分隔
![环境变量](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/old/b7f2e3a3gy1fzzcfp2cdvj20ei0e03zq.jpg "环境变量")

**用户环境变量**，我这里需要填写2条内容，使用英文逗号隔开（如果是直接安装的 Python，pip 和 python 应该在同一个路径下面，所以只需要1条就行了）
![用户环境变量](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/old/b7f2e3a3gy1fzzcg8856yj20ei0e0q4d.jpg "用户环境变量")

我的环境需要配置2条内容
![配置2条内容](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/old/b7f2e3a3gy1fzzcgokfnqj209501tmwy.jpg "配置2条内容")

内容解释：

````bash
--pip 所在目录
D:\Anaconda2\Scripts\;
--python 所在目录
D:\Anaconda2;
````


## 安装 ItChat 工具


在 Python 安装完成的情况下，才能进行接下来的操作，因为 ItChat 是基于 Python 环境运行的；为了验证 Python 是否正确安装，可以在命令行中输入 python，如果看到以下内容，就说明 Python 安装成功：
![验证Python](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/old/b7f2e3a3gy1fzzfxmlh41j20n60873zj.jpg "验证Python")

接下来利用 pip 工具（Python 自带的）直接安装 itchat，非常简单，使用命令（如果 pip 命令不可用，请检查 Python 的安装目录是否存在 pip.exe 文件）：
````bash
pip install itchat
````

安装 ItChat
![itchat安装命令](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/old/b7f2e3a3gy1fzzfy2t8p5j20be016741.jpg "itchat安装命令")

如果看到以下内容，说明 ItChat 安装成功：
![itchat安装成功](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/old/b7f2e3a3gy1fzzfyl5gcsj20n60a6t9e.jpg "itchat安装成功")


## 入门代码示例


一切准备就绪，接下来就可以写代码了，当然，入门代码非常简单实用（我会尽可能多的添加注释说明）：

````python
#-*-coding:utf-8 -*-
# 从python环境中导入itchat包,re正则表达式包
import itchat, re
# 从itchat.content中导入所有类、常量(例如代码中的TEXT其实就是itchat.content.TEXT常量)
from itchat.content import *
# 导入时间包里面的sleep方法
from time import sleep
# 导入随机数包
import random
# 注册消息类型为文本(即只监控文本消息,其它的例如语音/图片/表情包/文件都不会监控)
# 也就是说只有普通的文字微信消息才能触发以下的代码
# isGroupChat=True开启群聊模式,即只是监控群聊内容(如果不开启就监控个人聊天,不监控群聊)
@itchat.msg_register([TEXT], isGroupChat=True)
# @itchat.msg_register([TEXT])
def text_reply(msg):
    # msg是消息体,msg['Text']用来获取消息内容
    # 第一个单引号中的内容是关键词,使用正则匹配,可以自行更改(我使用.*表示任意内容),如果使用中文注意2.x版本的Python会报错,需要u前缀
    message = msg['Text']
    print(message)
    match = re.search('.*', message)
    # match = re.search(u'年|春|快乐', message)
    # 增加睡眠机制,随机等待一定的秒数(1-10秒)再回复,更像人类
    second = random.randint(1,10)
    sleep(second)
    if match:
      # msg['FromUserName']用来获取用户名,发送消息给对方
      from_user_name = msg['FromUserName']
	  print(from_user_name)
      itchat.send(('====test message'), from_user_name)
      # 第一个单引号中的内容是回复的内容,可以自行更改
# 热启动,退出一定时间内重新登录不需要扫码(其实就是把二维码图片存下来,下次接着使用)
itchat.auto_login(hotReload=True)
# 开启命令行的二维码
itchat.auto_login(enableCmdQR=True)
# 运行
itchat.run()
````

代码截图如下：
![代码示例](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/old/b7f2e3a3gy1fzzh40wm8uj215v0lp0ve.jpg "代码示例")


## 演示


登录扫码
![运行代码扫码](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/old/b7f2e3a3gy1fzzfzy6tf8j21bm0oq76m.jpg "运行代码扫码")

登录成功
![登录成功](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/old/b7f2e3a3gy1fzzg0nho9pj20cq01sjr6.jpg "登录成功")

群聊自动回复（正则是任意内容，所以总是会自动回复）
![群聊自动回复](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/old/b7f2e3a3gy1fzzg1f8g7nj20u00rp0wd.jpg "群聊自动回复")

退出
![退出](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/old/b7f2e3a3gy1fzzg1qzmewj20n604omy3.jpg "退出")

重新登录继续聊天（由于开启了热启动，不需要重新扫码）
![重新登录](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/old/b7f2e3a3gy1fzzg26yztyj20n6084gmn.jpg "重新登录")

继续聊天
![继续聊天](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/old/b7f2e3a3gy1fzzg2p3tnuj20u01mc7co.jpg "继续聊天")


## 小问题总结


1、部分系统可能字幅宽度有出入，可以通过将 enableCmdQR 赋值为特定的倍数进行调整：
````python
# 如部分的 linux 系统,块字符的宽度为一个字符(正常应为两字符),故赋值为2
itchat.auto_login(enableCmdQR=2)
````

2、Python 2.7版本的中文报错问题（在 Python 2.7环境下使用中文需要额外注意，坑比较多）：
例如代码中正则匹配带中文（由于编码问题导致无法匹配，或者会抛出异常）

````python
# 正则搜索带中文,直接单引号在 Python 2.7环境下是不行的
match = re.search('年|春|快乐', message)
````

实际运行时就会报错（报错信息如果不捕捉后台是看不到的）或者匹配结果不是想象中的（仅针对 Python 2.x 环境）

需要使用 u 前缀

````python
# 正则搜索带中文,直接单引号在 Python 2.7环境下是不行的
# 增加 u 前缀,表示 unicode 编码,才行
match = re.search(u'年|春|快乐', message)
````

3、如果不开启热启动，每次重新登录时都会生成新的二维码，直接在 Wimdows 的命令行中，可能由于窗口太小显示不完整，此时需要拉伸一下命令行的窗口：

![窗口拉伸](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/old/b7f2e3a3gy1fzzg62t07ej20n60sctbf.jpg "窗口拉伸")

4、有些人的电脑设置问题，命令行环境背景为白色，生成的二维码的颜色黑白色是相反的，导致扫码时无法识别，此时需要设置代码：
````python
# 默认控制台背景色为暗色(黑色)，若背景色为浅色(白色)，可以将 enableCmdQR 赋值为负值
itchat.auto_login(enableCmdQR=-1)
````


## 接入机器人


一般读者做到上面的内容就算入门了，可以实现自动回复，并且关于 ItChat 也了解了一些，可以独自参考文档进行更加深入的开发了。但是，自动回复的内容毕竟太固定了，而且只能覆盖极少的内容，没办法实现真正的自动化。要想做到真正的自动化回复，机器人是少不了了，那么接下来讲解的就是如何接入一个第三方机器人，实现机器人自动回复。当然，代码内容也会稍显复杂，操作步骤也会稍显繁琐。

### 接入机器人代码示例

接入机器人时为了换种方式，先把群聊模式关闭，使用个人聊天监控模式（方便聊天内容的随意性，更能提现机器人的可用性）：
````python
@itchat.msg_register([TEXT])
````

还要导入网络请求相关的包：
````python
import requests
````

需要使用图灵机器人的核心配置（注册图灵机器人的过程不在此赘述，官网链接：http://www.tuling123.com ）：
````python
# 封装一个根据内容调用机器人接口,返回回复的方法
def get_response(msg):
    # 构造了要发送给服务器的数据
    apiUrl = 'http://www.tuling123.com/openapi/api'
    data = {
        'key'    : APIKEY,
        'info'   : msg,
        'userid' : 'wechat-robot',
    }
    try:
        r = requests.post(apiUrl, data=data).json()
        # 字典的get方法在字典没有'text'值的时候会返回None而不会抛出异常
        return r.get('text')
    # 为了防止服务器没有正常响应导致程序异常退出,这里用try-except捕获了异常
    # 如果服务器没能正常交互(返回非json或无法连接),那么就会进入下面的return
    except Exception,err:
        # 打印一下错误信息
        print(err)
        # 将会返回一个None
        return
````

完整代码示例（代码会封装的更好，格式更加规范，易读）：
````python
#-*-coding:utf-8 -*-
# 从python环境中导入itchat包,requests网络请求包
import itchat, requests
# 从itchat.content中导入所有类、常量(例如代码中的TEXT其实就是itchat.content.TEXT常量)
from itchat.content import *
# 导入时间包里面的sleep方法
from time import sleep
# 导入随机数包
import random
# 机器人的apikey
APIKEY = '376cb2ca51d542c6b2e660f3c9ea3754'

# 封装一个根据内容调用机器人接口,返回回复的方法
def get_response(msg):
    # 构造了要发送给服务器的数据
    apiUrl = 'http://www.tuling123.com/openapi/api'
    data = {
        'key'    : APIKEY,
        'info'   : msg,
        'userid' : 'wechat-robot',
    }
    try:
        r = requests.post(apiUrl, data=data).json()
        # 字典的get方法在字典没有'text'值的时候会返回None而不会抛出异常
        return r.get('text')
    # 为了防止服务器没有正常响应导致程序异常退出,这里用try-except捕获了异常
    # 如果服务器没能正常交互(返回非json或无法连接),那么就会进入下面的return
    except Exception,err:
        # 打印一下错误信息
        print(err)
        # 将会返回一个None
        return

# 注册消息类型为文本(即只监控文本消息,其它的例如语音/图片/表情包/文件都不会监控)
# 也就是说只有普通的文字微信消息才能触发以下的代码
# isGroupChat=True开启群聊模式,即只是监控群聊内容(如果不开启就监控个人聊天,不监控群聊)
# @itchat.msg_register([TEXT], isGroupChat=True)
@itchat.msg_register([TEXT])
def tuling_reply(msg):
    # msg是消息体,msg['Text']用来获取消息内容
    # 第一个单引号中的内容是关键词,使用正则匹配,可以自行更改(我使用.*表示任意内容),如果使用中文注意2.x版本的Python会报错,需要u前缀
    message = msg['Text']
    print(message)
	# 增加睡眠机制,随机等待一定的秒数(1-10秒)再回复,更像人类
    second = random.randint(1,10)
    sleep(second)
    # 为了保证在图灵 apikey 出现问题的时候仍旧可以回复,这里设置一个默认回复
    defaultReply = 'I received: ' + message
    # 如果图灵 apikey 出现问题,那么reply将会是None
    reply = get_response(message)
    # a or b的意思是,如果a有内容,那么返回a,否则返回b
    return reply or defaultReply
# 热启动,退出一定时间内重新登录不需要扫码(其实就是把二维码图片存下来,下次接着使用)
itchat.auto_login(hotReload=True)
# 开启命令行的二维码
itchat.auto_login(enableCmdQR=True)
# 运行
itchat.run()
````

代码截图（使用工具渲染了一下）：
![机器人接入代码](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/old/b7f2e3a3gy1fzzirq8uejj235s3xgu0x.jpg "机器人接入代码")

### 接入机器人演示

演示一下，随便聊了几句：
![图灵机器人聊天](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/old/b7f2e3a3gy1fzzislea0dj20u01mcgug.jpg "图灵机器人聊天")


# 备注


1、ItChat 项目 GitHub 地址：[https://github.com/littlecodersh/itchat](https://github.com/littlecodersh/itchat) ；

2、ItChat 项目说明文档：[https://itchat.readthedocs.io/zh/latest](https://itchat.readthedocs.io/zh/latest) ；

3、感谢微博科普博主 [灵光灯泡](https://weibo.com/u/6969849160) 的科普视频 [https://weibo.com/6969849160/HeLhjcKtA](https://weibo.com/6969849160/HeLhjcKtA) 以及文档参考 [石墨文档](https://shimo.im/docs/vCYHZ04LWTsugigR) ；

4、Python 下载官网：https://www.python.org/downloads/windows ，大家一定要选择与自己当前环境适配的版本（包括操作系统版本、Python 版本），环境变量最好配置一下；

5、图灵机器人官网：http://www.tuling123.com ；


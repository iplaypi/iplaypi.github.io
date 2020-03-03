---
title: IDEA 代理设置伪装激活信息
id: 2017101701
date: 2017-10-17 01:57:54
updated: 2017-10-17 01:57:54
categories: 知识改变生活
tags: [IDEA,agent]
keywords: IDEA,agent
---


首先声明，此内容并不是教大家破解 `IDEA`，而仅仅是供学习使用，我在偶然间发现这个方法，觉得很有趣，想探究一下背后的实现原理。因此我选择了一个低版本的 `IDEA`【`v2017.2`】进行测试，当然，据说这种方式也只能破解低版本的 `IDEA`。

建议读者购买正版 `IDEA`，或者使用社区版本、校园版本，功能是足够使用的，当然这仅限于个人开源项目开发、学习测试使用，如果是公司的项目开发，为了避免法律风险，还是购买正版 `IDEA`。

下文中使用的操作系统为 `Windows 10`。


<!-- more -->


# 准备工作


首先需要安装好 `IDEA v2017.2`，其它版本我没有使用过，不知道可行与否，所以还是建议读者使用我指定的版本测试，避免踩坑。

另外还要准备一个 `jar` 包文件，里面封装了相关激活逻辑，这个包文件很小，不到 `1MB`。包文件已经被我上传到 `GitHub`，读者可以下载使用：[JetbrainsCrack.jar](https://github.com/iplaypi/iplaypistudy/tree/master/iplaypistudy-normal/src/resource/20171017) 。


# 配置


配置内容很简单，即给 `IDEA` 设置一个代理，指向前面准备好的 `jar` 包。

配置文件在安装目录下的 `bin` 文件夹中，名称是 `idea64.exe.vmoptions`，但是要注意，这个是全局配置文件，影响比较大，不建议直接更改它，而且有些 `IDEA` 版本还不支持【更改了之后没有效果，而且激活时还报错】。

因此，建议在用户目录下更改，其实用户目录下面有一份 `IDEA` 的临时目录，会生成一些临时文件，只针对当前用户有效，例如我的 `Windows 10` 系统，在 `C:\Users\Perry\.IntelliJIdea2017.2\config` 里面。注意多了一个 `config` 子文件夹，`idea64.exe.vmoptions` 配置文件在里面。

如果读者寻找后发现没有这个配置文件，不要着急，有些时候或者某些版本默认是没有这个配置文件的，需要自己手动生成。注意，不是要自己创建，而是在 `IDEA` 中创建，依次选择 `Help`、`Edit Costum VM Options` 就可以了，会自动创建一份和全局配置文件一样内容的文件，并且保存在用户目录下【就是上面的那个目录】。

图。。

因为 `IDEA` 是运行在 `Java` 虚拟机之上的，其实就是更改一些 `JVM` 参数。

在文件最后一行加上

```
-javaagent:C:\Program Files\JetBrains\JetbrainsCrack.jar
```

表示给 `IDEA` 设置代理，`javaagent` 参数后面的值就是 `JetbrainsCrack.jar` 具体的存放位置。

图。。

注意看一下这个配置文件的位置，就是在用户目录下：`C:\Users\Perry\.IntelliJIdea2017.2\config`。

接着就开始填写激活信息，依次选择 `Help`、`Register`，在弹出的对话框中先选择 `Activation code` 方式，然后填写如下格式的内容【也称为激活码】：

```
{
	"licenseId": "ThisCrackLicenseId",
	"licenseeName": "your_name",
	"assigneeName": "your_name",
	"assigneeEmail": "your_email",
	"licenseRestriction": "Thanks Rover12421 Crack",
	"checkConcurrentUse": false,
	"products": [{
			"code": "II",
			"paidUpTo": "2099-12-31"
		},
		{
			"code": "DM",
			"paidUpTo": "2099-12-31"
		},
		{
			"code": "AC",
			"paidUpTo": "2099-12-31"
		},
		{
			"code": "RS0",
			"paidUpTo": "2099-12-31"
		},
		{
			"code": "WS",
			"paidUpTo": "2099-12-31"
		},
		{
			"code": "DPN",
			"paidUpTo": "2099-12-31"
		},
		{
			"code": "RC",
			"paidUpTo": "2099-12-31"
		},
		{
			"code": "PS",
			"paidUpTo": "2099-12-31"
		},
		{
			"code": "DC",
			"paidUpTo": "2099-12-31"
		},
		{
			"code": "RM",
			"paidUpTo": "2099-12-31"
		},
		{
			"code": "CL",
			"paidUpTo": "2099-12-31"
		},
		{
			"code": "PC",
			"paidUpTo": "2099-12-31"
		},
		{
			"code": "DB",
			"paidUpTo": "2099-12-31"
		},
		{
			"code": "GO",
			"paidUpTo": "2099-12-31"
		},
		{
			"code": "RD",
			"paidUpTo": "2099-12-31"
		}
	],
	"hash": "2911276/0",
	"gracePeriodDays": 7,
	"autoProlongated": false
}
```

图。。

注意，除了必须满足上面的 `JSON` 格式，这里面的个人信息可以任意更改，包含过期时间、证书名字、使用人、邮箱等等，更改后的信息会显示在 `Help`、`About` 里面【可以装逼使用】。

最后就是重启 `IDEA`，注意这个步骤很重要，不然没有效果。想想你如果更改了配置文件，填写了激活信息，然后发现无效，折腾了半天才发现是没有重启，多么折磨人。


# 备注


再次提醒读者，本方法仅供学习交流使用，不可用于商业开发，请购买正版，或者使用社区版、教育版。


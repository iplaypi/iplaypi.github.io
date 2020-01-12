---
title: 微博 url mid 相互转换算法实现-Java 版本
id: 2018122001
date: 2018-12-20 23:29:13
updated: 2018-12-20 23:29:13
categories: 基础技术知识
tags: [微博url,微博mid]
keywords: 微博url,微博mid,url与mid相互转换
---


对微博数据有了解的人都知道，一条微博内容对应有唯一的微博 `url`，同时对微博官方来说，又会生成一个 `mid`，`mid` 就是一条微博的唯一标识【就像 `uid` 是微博用户的唯一标识一样】，也类似于人的身份证号。其实，微博 `url` 里面有一串看起来无意义的字符【由字母、数字组成，6-9个字符长度，当然以后也可能会变长】，可以和 `mid` 互相转换，本文就根据理论以及 `Java` 版本的实现，讲解微博 `url` 与 `mid` 的互相转换过程。


<!-- more -->


注意，为了确保多个 `id` 字段的定义不混乱，本文先约束好 `mid`、`uid`、`url`、`id`、`murl` 的概念：
- `mid`，一条微博拥有一个独立的标识，由微博官方生成【也可以理解为 `mobile id`，可以和 `murl` 转换】，可以和 `id` 互相转换，例如：`4404101091169383`【由 `I1IGF4Ud1` 转换】
- `url`，指一条微博的链接，里面包含了 `uid`、`id`，格式如：`https://weibo.com/uid/id`，例如：`https://weibo.com/3086148515/I1IGF4Ud1`
- `uid`，指一个微博用户的唯一标识，由微博官方生成，通过 `https://weibo.com/u/uid` 可以打开微博个人主页，例如：`https://weibo.com/u/3086148515`
- `id`，指 `url` 中标识微博的那部分，可以和 `mid` 互相转换，例如：`I1IGF4Ud1`
- `murl`，即 `mobile url`，移动端 `url`，格式：`https://m.weibo.cn/status/id`、`https://m.weibo.cn/status/mid`，专为客户端设计，适合使用手机、平板的浏览器打开，排版显示友好，如果使用电脑的浏览器打开，排版显示不友好，例如：`https://m.weibo.cn/status/I1IGF4Ud1`、`https://m.weibo.cn/status/4404101091169383`


# 数据示例


为了让读者直观地了解这些概念的不同，下面我将列举一些微博链接、`id` 的示例，并且给出截图，希望读者看到后可以明白上面约束规范的含义。当然，对于对微博数据非常熟悉的读者来说，可以跳过这个小节，直接看下一小节的转换代码。

1、通过 `id`、`uid` 构造的 `url`，打开微博内容，示例：`https://weibo.com/3086148515/I1IGF4Ud1` ，其中，`3086148515` 是 `uid`，`I1IGF4Ud1` 是 `id`。

![通过微博 url 打开](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2018/20200112021749.png "通过微博 url 打开")

这种格式的 `url` 可以在网页端通过点击微博的发表时间获取，如下图。

![点击发表时间获取 url](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2018/20200112022115.png "点击发表时间获取 url")

2、通过 `uid` 打开微博用户的首页，示例：`https://weibo.com/u/3086148515`。

![uid 打开首页](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2018/20200112022621.png "uid 打开首页")

这里需要注意一点，有时候微博用户会设置个性名称，输入上述链接会跳转到另外一个链接，但是打开的内容一定是个人首页【当然也可以直接打开】，例如：`https://weibo.com/playpi`。

![uid 跳转打开首页](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2018/20200112022613.png "uid 跳转打开首页")

3、通过 `id`、`mid` 构造的 `murl` 打开微博内容，示例：`https://m.weibo.cn/status/I1IGF4Ud1`、`https://m.weibo.cn/status/4404101091169383`，当然这种内容不适合在 `PC` 端的浏览器打开，排版不好。

![通过 id 构造 murl](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2018/20200112022925.png "通过 id 构造 murl")

![通过 mid 构造 murl](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2018/20200112022938.png "通过 mid 构造 murl")


# 转换代码


提前说明，下文中涉及的代码已经被我上传至 `GitHub`：[WeiboUtil](https://github.com/iplaypi/iplaypistudy/tree/master/iplaypistudy-common-core/src/main/java/org/playpi/study/util) ，读者可以提前下载查看。

此外，还有一份 `Python` 版本的代码，读者可以参考我的另外一篇博客：[微博 id mid 相互转换算法实现-Python 版本](https://www.playpi.org/2018071801.html) 。

好，言归正传，下面开始讲述关于转换代码的部分，主要是关于 `id`、`mid` 转换的，其它的内容不会赘述，读者可以参考代码，使用单元测试用例进行测试也可以。

注意，涉及到的62进制表示从0到9、从 `a` 到 `z`、从 `A` 到 `Z` 一共62个字符。

1、`id` 转为 `mid` 的思路，例如：`I1IGF4Ud1`，有9个字符，从后开始以4个字符为单位进行拆分，拆分为：`I`、`1IGF`、`4Ud1`，然后再分别把它们转为62进制对应的10进制数值，得到：`44`、`0410109`【不足7位在前面补0】、`1169383`。紧接着再拼接所有的结果，得到最终的 `mid`：`4404101091169383`。

主要代码逻辑如下：

```
/**
     * id转化成mid的值
     *
     *
     * @param id
     * @return
     */
public static String id2mid(String id) {
	String mid = "";
	String k = id.toString().substring(3, 4);
	//用于第四位为0时的转换
	if (!k.equals("0")) {
		for (int i = id.length() - 4; i > -4; i = i - 4) {
			//分别以四个为一组
			int offset1 = i < 0 ? 0 : i;
			int offset2 = i + 4;
			String str = id.toString().substring(offset1, offset2);
			str = str62to10(str);
			//String类型的转化成十进制的数
			// 若不是第一组，则不足7位补0
			if (offset1 > 0) {
				while (str.length() < 7) {
					str = '0' + str;
				}
			}
			mid = str + mid;
		}
	} else {
		for (int i = id.length() - 4; i > -4; i = i - 4) {
			int offset1 = i < 0 ? 0 : i;
			int offset2 = i + 4;
			if (offset1 > -1 && offset1 < 1 || offset1 > 4) {
				String str = id.toString().substring(offset1, offset2);
				str = str62to10(str);
				// 若不是第一组，则不足7位补0
				if (offset1 > 0) {
					while (str.length() < 7) {
						str = '0' + str;
					}
				}
				mid = str + mid;
			} else {
				String str = id.toString().substring(offset1 + 1, offset2);
				str = str62to10(str);
				// 若不是第一组，则不足7位补0
				if (offset1 > 0) {
					while (str.length() < 7) {
						str = '0' + str;
					}
				}
				mid = str + mid;
			}
		}
	}
	return mid;
}
```

2、`mid` 转为 `id` 的思路，例如：`4404101091169383`，有18个字符，从后开始以7个字符为单位进行拆分，拆分为：`44`、`410109`【前面有0的直接去除】、`1169383`，然后再分别把它们转为10进制数值对应的62进制字符串，得到：`I`、`1IGF`、`4Ud1`。紧接着再拼接所有的结果，得到最终的 `id`：`I1IGF4Ud1`。

主要代码逻辑如下：

```
/**
     * mid转换成id
     *
     * @param mid
     * @return
     */
public static String mid2id(String mid) {
	String url = "";
	for (int j = mid.length() - 7; j > -7; j = j - 7) {
		//以7个数字为一个单位进行转换
		int offset3 = j < 0 ? 0 : j;
		int offset4 = j + 7;
		// String l = mid.substring(mid.length() - 14, mid.length() - 13);
		if ((j > 0 && j < 6) && (mid.substring(mid.length() - 14, mid.length() - 13).equals("0") && mid.length() == 19)) {
			String num = mid.toString().substring(offset3 + 1, offset4);
			num = int10to62(Integer.valueOf(num));
			//十进制转换成62进制
			url = 0 + num + url;
			if (url.length() == 9) {
				url = url.substring(1, url.length());
			}
		} else {
			String num = mid.toString().substring(offset3, offset4);
			num = int10to62(Integer.valueOf(num));
			url = num + url;
		}
	}
	return url;
}
```

3、以上内容运行单元测试后结果截图如下：

![单元测试结果](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2018/20200112031006.png "单元测试结果")


# 备注


## 微博图床

本站点一开始使用的图床工具就是微博图床，很好用，免费，速度快，可以上传高清图片，后来听说被黑产人员恶意使用，已经开启了防盗链，只留下了几个接口用来钓鱼。有兴趣的读者可以参考我的另外几篇博客：[解决微博图床防盗链的问题](https://www.playpi.org/2019042701.html) 、[使用 Java 代码迁移微博图床到 GitHub 图床](https://www.playpi.org/2019050201.html) 。

图片上传微博图床后，得到一个图片链接，根据这个微博图床链接，也可以提取用户的 `uid`，进一步就能找到这个用户。

提取的逻辑是：使用链接中文件名的前8个字符，将16进制转为10进制的数值，得到的数字就是 `uid`【当然，现在也有例外，应该是8位16进制存满了，所以出现了005、006、007等以00数字开头的文件名，那也不用着急，它们其实是62进制的字符，也同样转为10进制的数值即可】。

我这里有一份 `JavaScript` 示例代码，代码已经被我上传至 `GitHub`：[extractUid.js](https://github.com/iplaypi/iplaypistudy/tree/master/iplaypistudy-normal/src/bin/20181220) ，读者可以查看，内容如下：

```
function idx(c) {
    c = c.charCodeAt();
    if (c >= 48 && c <= 57) return c - 48;
    if (c >= 97 && c <= 122) return c - 97 + 10;
    return c - 56 + 36;
}

function extractUid(url) {
    url = url.replace(/\.\w+$/g, '');
    // 提取文件名
    var hash = url.match(/[0-9a-zA-Z]{32}$/);
    if (hash === null) return '';
    // 截取前8位
    hash = hash[0].slice(0, 8);
    var uid = 0;
    // 16进制或者62进制
    if (hash[0] == '0' && hash[1] == '0') k = 62;
    else k = 16;
    // 每一个数字都转为10进制
    for (i = 0; i < 8; i++) uid = uid * k + idx(hash[i]);
    return uid;
}
```

例如我这里上传一张图片到微博图床，链接：

```
https://wx3.sinaimg.cn/mw1024/b7f2e3a3gy1gakhzzxtmtj20fu0l4dku.jpg
```

然后使用上述转换代码可以获取上传图片对应的 `uid`，进而就可以找到这个微博用户。运行结果是：`3086148515`，那么这个微博用户的微博首页就是：`https://weibo.com/u/3086148515`。

![微博图床链接抽取 uid](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2018/20200112193012.png "微博图床链接抽取 uid")

简单分析一下，文件名是：`b7f2e3a3gy1gakhzzxtmtj20fu0l4dku.jpg`，前8个字符是：`b7f2e3a3`，把它由16进制转为10进制，得到：`3086148515`，与上面的结果一致。

不过微博图床在2019年9月份已经开启防盗链了，即图片链接通过外站打不开，只能在新浪站内打开。

## 微博短链接

微博短链接是微博官方提供的网址压缩功能产生的一种只包含少量字符的短网址，例如：[http://finance.sina.com.cn](http://finance.sina.com.cn) ，压缩后为：[http://t.cn/RnM1Uti](http://t.cn/RnM1Uti) 。这样的话，发微博时链接占用更少的字符长度。如果发微博时，内容中带了链接，例如视频地址、淘宝店地址，会被自动压缩为短链接。微博短链接可以直接在浏览器中访问，会被微博的网址解析服务器转换为原来的正常链接再访问。

各大公司都已经提供短链接服务，例如百度、新浪、谷歌，短链接的优点是字符个数比较少，一般在10个以内，例如新浪的短网址可以把字符个数控制在8个以内。

日常大家见到的应用主要有2个地方：一个是微博内容中的网址，例如视频网址、电商商品网址，都会被压缩为8个字符以内，这样可以减少微博内容的长度【当然微博内容已经不再限制140个字符的长度，但是微博评论还是限制的，使用短网址减少字符的使用，何乐而不为】；另外一个就是邮件中的附件网址、图片网址，一般也都是短链接的形式。

有兴趣的读者可以参考我的另外一篇博客：[微博 URL 短网址生成算法 - Java 版本](https://www.playpi.org/2018101501.html) 。


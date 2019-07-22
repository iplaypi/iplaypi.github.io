---
title: GitHub 个人站点绑定独立的域名
id: 2018112701
date: 2018-11-27 11:55:57
updated: 2018-11-27 11:55:57
categories: 建站
tags: [GitHub,个人站点,绑定域名]
keywords: GitHub,个人站点,绑定域名,GitHub 独立域名
---


随着越来越多的人使用 GitHub，都在里面创建了自己的仓库，或者 clone 了别人的优秀项目，也有很多人想利用 GitHub 自带的 GitHub Pages 来搭建个人博客，此时就可以使用独立的域名 [https://www.username.github.io](https://www.username.github.io) 访问自己的博客，全部的资源都来自于 GitHub，并且是免费的，不需要其它任何配置或者购买，这里面包含域名、流量、带宽、存储空间、Htpps 认证等服务。但是，有的人可能购买了自己的独立域名，例如： [https://www.abc.com](https://www.abc.com) ，并且想把域名直接绑定到 GitHub 免费的域名上面，这样以后访问博客的时候更容易辨识，本文就描述 GitHub Pages 绑定独立域名的操作过程，前提是 GitHub Pages 已经创建完成。


<!-- more -->


我在 Godaddy 上面购买了域名：playpi.org，选择 Godaddy 主要是不想备案，国内的域名服务商都要求备案，我以前在阿里云上面买过一个，后来没按照要求备案就不能用了，我也放弃了。


# 购买域名

当然，大家可以选择自己喜欢的域名服务商，例如腾讯云、阿里云等，但是这些域名服务商需要给域名备案，有点麻烦【当然不是所有的域名都需要备案】。所以我选择的域名服务商是 Godaddy，主页地址：[https://sg.godaddy.com/zh](https://sg.godaddy.com/zh) ，在主页中点击左上角的**域名**，开始搜索域名。
![Godaddy主页](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/old/b7f2e3a3gy1g0sbcstwqoj21hc0rfe4y.jpg "Godaddy主页")

我这里输入域名 **playpi.org**，可以看到被占用了，已经已经被我购买了，可以看到右侧显示出了可以购买的域名列表，并且带有报价。在左侧，可以添加筛选条件，过滤掉自己不想要的域名。如果找到了满意的域名，加入购物车购买就行了。
![Godaddy域名搜索](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/old/b7f2e3a3gy1g0sbcjq2a0j21hc0q9q5x.jpg "Godaddy域名搜索")


# 选择域名服务器


有了域名，还没有用，因为还没有把域名用起来，所以接下来需要找域名服务器，把你的域名解析到 GitHub Pages 去。这样，才能保证访问你的域名，自动跳转到 GitHub Pages 去。

我一开始选择的 Godaddy 自己的域名服务器，只需要在**我的产品**->**域名**->**DNS**，设置一些解析记录即可。Godaddy 的配置解析规则可以参考下图【可以先忽略解析规则，后面会讲到的】：
![Godaddy原有的解析记录](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/old/b7f2e3a3gy1g0ovn10ghwj20wt0mvgm6.jpg "Godaddy原有的解析记录")

后来由于 GitHub Pages 屏蔽百度爬虫的问题，我必须设置一条专门的解析规则去解析百度爬虫的请求，引入到我自己的 Web 服务器上面，但是 Godaddy 不支持线路的自定义，比较笼统，所以我就放弃了。转而选择了腾讯的 DNSPod，还是比较好用的，虽然前不久刚出过问题，大量的网络瘫痪，但是解析速度还是挺快的。

先在 DNSPod 中添加域名，也就是在 Godaddy 中购买的域名【如果是直接在腾讯云中购买的，就不用配置了，默认就有】。
![在DNSPod中添加域名](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/old/b7f2e3a3gy1g0oviygtn3j21hc0qxgnz.jpg "在DNSPod中添加域名")

添加完成后，可以看到提示我 NS 地址还未修改，也就是目前仍旧是 Godaddy 负责解析这个域名，所以要把域名服务器给切换过来。如果不知道是什么意思，可以点击提示链接查看帮助手册【其实就是去购买域名的服务商那里绑定 DNSPod 的域名服务器】

提示我们修改 NS 地址
![提示我们修改 NS 地址](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/old/b7f2e3a3gy1g0ovkf6k08j21hc0qxtb9.jpg "提示我们修改 NS 地址")

帮助手册
![帮助手册](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/old/b7f2e3a3gy1g0ovkoigmaj20s60lymyk.jpg "帮助手册")

我在这就直接查看当前的域名的 NS 地址，选择域名，进入配置页面查看。
![查看NS地址](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/old/b7f2e3a3gy1g0safaacorj21190i4gmy.jpg "查看NS地址")

去 Godaddy 中配置域名服务器，替换掉原本默认的。在**我的产品**->**域名**->**DNS**：
![Godaddy原有的域名服务器](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/old/b7f2e3a3gy1g0ovncqfzuj20ww0atdfw.jpg "Godaddy原有的域名服务器")

我把它修改为我在 DNSPod 中查到的属于我的域名的域名服务器，一般都会有2个，保证可靠性。配置完成新的域名服务器【以前的解析记录都消失了】：
![配置完成新的域名服务器](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/old/b7f2e3a3gy1g0ovnq0lhgj20yi0m7q3i.jpg "配置完成新的域名服务器")

配置完成，域名解析的工作就完全交给 DNSPod 了，我们可以退出 Godaddy 了【只是在这里买了一个域名】，接下来全程都要在 DNSPod 中配置其它信息。


# 配置域名的解析规则

上一步骤我已经配置完成了域名的基本信息，接下来需要配置的就非常关键了，是域名的解析规则，它会指引着访问域名的请求怎么跳转。这里先提前说一下配置规则：
- **主机记录**为@表示直接访问域名，例如访问 playpi.org
- **主机记录**为其它字符表示访问二级域名，例如访问 www.playpi.org 、blog.playpi.org
- **记录类型**为A表示跳转到 ip 地址，后面的**记录值**就需要填 ip，例如66.32.122.18
- **记录类型**为CNAME 表示跳转到域名，后面的**记录值**就需要填域名，例如 blog.playpi.org
- **线路类型**是 DNSPod 自定义的逻辑分类，给访问的请求分类，例如百度爬虫、搜狗爬虫，这个选项对于我来说很有用，可以解决 GitHub Pages 屏蔽爬虫的问题

我把 Godaddy 中的解析记录直接抄过来就行，不同的是由于使用的是 DNSPod 免费版本，A 记录会少配置2个，基本不会有啥影响**【其实不配置 A 记录最好，直接配置 CNAME 就行了，会根据域名自动寻找 ip，以前我不懂】**。另外还有一个就是需要针对百度爬虫专门配置一条 www 的 A 记录，针对百度的线路指向自己服务器的 ip【截图只是演示，其中 CNAME 记录应该配置域名，A 记录才是配置 ip】。如果使用的是第三方托管服务，直接添加 CNAME 记录，配置域名就行【例如 yoursite.gitcafe.io】。
![添加域名解析记录](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/old/b7f2e3a3gy1g0ovjinxzvj21hc0qxac2.jpg "添加域名解析记录")

上面的配置里面的 A 记录明显是多余的，而且还要通过 ping 去寻找那几个 ip【我这里是 **ping iplaypi.github.io** 得到，大家换为自己的 GitHub 用户名即可，每个用户之间的 ip 应该有差别，不会完全一样】。所以建议大家不使用A记录的配置方式，直接使用 CNAME 配置。
![不使用A记录的配置方式](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/old/b7f2e3a3gy1g0ovk0xljij21hc0qxta3.jpg "不使用A记录的配置方式")

配置完成后使用**域名设置**里面的**自助诊断**功能，可以看到域名存在异常，主要是因为更改配置后的时间太少了，要耐心等待全球递归DNS服务器刷新【最多72小时】，不过一般10分钟就可以访问主页了。
![自助诊断](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/old/b7f2e3a3gy1g0ovl23kqbj20tl0lfabk.jpg "自助诊断")

但是后来我发现，那个 GitHub 的域名【iplaypi.github.io】被墙了而 ip 没被墙，表现为每天总会有一段时间访问不了【DNSPod 也会给我发告警邮件，说宕机了，当然是他们的域名测试服务器连不上这个域名】，而且我用自己的浏览器也访问不了。而 blog 那个二级域名却可以正常访问，这就说明 GitHub 的那个域名不好使，而我自己给 blog 专门部署 Web 服务是正常的。因此，在主机记录为 @ 的解析规则里面还是配置 A 记录吧，把几个 ip 都配置上去【免费版本的 DNSPod 只能添加2条，可怜】。
![我目前的配置](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/old/b7f2e3a3gy1g0sbad2ia9j215c0h2myv.jpg "我目前的配置")

这样做还会引起 GitHub 的警告，因为这个 ip 地址可能会变化，所以 GitHub 建议配置域名。
![来自GitHub的警告](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/old/b7f2e3a3gy1g0scgaveyhj20vl0mlta4.jpg "来自GitHub的警告")

如果想知道域名对应的 ip 地址，除了使用 ping 之外，还有更快捷的方法：dig 命令。
![2-dig快速获取ip地址](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/old/b7f2e3a3gy1g0sbqoihqxj20ju0cndg9.jpg "2-dig快速获取ip地址")


# 在 GitHub 中设置 CNAME

关于域名的配置都完成了，最后还有一个重要的步骤，需要在 GitHub 的项目中添加一个文件，文件名称是 CNAME，文件内容就是域名【我这里使用的是二级域名，也可以，就是在直接访问域名的时候多了一次转换】。
![查看我的CNAME文件](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/old/b7f2e3a3gy1g0sc5i982jj211o0djdgd.jpg "查看我的CNAME文件")

那这个文件的作用是什么呢，为什么要这么配置呢？其实，CNAME 是一个别名记录，它允许你将多个名字映射到同一台计算机，还决定着主页的链接最终展示的样子，直接是域名【https://playpi.org 】还是带二级域名【https://www.playpi.org 】。这里有 GitHub 的官方说明：[https://help.github.com/en/articles/using-a-custom-domain-with-github-pages](https://help.github.com/en/articles/using-a-custom-domain-with-github-pages) 。

此外，在 GitHub 中还可以开启 https 认证，这样你的每一个文档链接都会有把小绿锁了，GitHub 使用的是 Lets Encrypt 的证书，有效期3个月，不过别担心过期问题，GitHub 会自动更新的。开启了 https 认证后，哪怕使用 http 的链接访问，也会自动跳转的。
![开启https](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/old/b7f2e3a3gy1g0sce6tflfj20tp09gaac.jpg "开启https")

那如果有人想把我的域名访问指向自己的 GitHub，是不是他在自己的仓库里面新建一个 CNAME 文件，并且填上我的域名就行了呢？其实不行，GitHub 是禁止这样做的。即使有人真的在自己的仓库里面新建了 CNAME 文件并且填写了我的域名，GitHub 是不认可的并且会给出警告。当然，如果我自己在 GitHub 中没有使用这个域名，别人当然可以使用。

现在突然想到一个问题，我把自己的域名和域名服务器都暴漏了，会不会有人在 DNSPod 中把我的域名解析到其它地方去了【看起来所有的 DNSPod 的域名服务器都是一样的2台机器】，然后我就访问不了自己网站了，或者说流量变小了。

我觉得 DNSPod 一定会禁止这种行为，否则岂不是乱套了，所以不同担心。经过实际测试，DNSPod 是不会允许这个现象发生的，如果别人要配置你的域名，DNSPod 检测到有第二个人配置同一个域名，会拒绝。如果你想主动给别人使用，需要第一个人解除绑定，然后第二个人才能继续使用，所以可以放心操作。


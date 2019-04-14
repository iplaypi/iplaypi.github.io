---
title: 参加 Elastic 社区第三次线下活动广州站
id: 2019033001
date: 2019-03-30 00:41:05
updated: 2019-04-07 00:41:05
categories: 游玩
tags: [Elastic,线下活动,广州]
keywords: Elastic,线下活动,广州
---


在2019年3月30日，我去参加了 Elastic 社区第三次线下活动广州站的分享会，活动简介：[Elastic 社区第三次线下活动广州站](https://meetup.elasticsearch.cn/event/guangzhou/1001.html) 。看到各位行业顶尖分享者的分享，不能说受益匪浅，至少给我打开了一些思路，拓展了我的知识面，同时我也学到了一些知识，既包括技术方面的，也包括处事方面的。这篇博文就简单记录一下这个过程。


<!-- more -->


# 出发


先看一下地图指引
![地图指引](https://ws1.sinaimg.cn/large/b7f2e3a3gy1g1tf2ls1z3j214q0u0djy.jpg "地图指引")

到达公交站，上冲南站，天气不错
![上冲南站](https://ws1.sinaimg.cn/large/b7f2e3a3gy1g1tf2vj7mlj229s29sb2c.jpg "上冲南站")

走路路过特斯拉服务站，听说最近交付的特斯拉电动车有很多问题
![路过特斯拉服务站](https://ws1.sinaimg.cn/large/b7f2e3a3gy1g1tf33253ij229s29shdt.jpg "路过特斯拉服务站")

# 到达


到达的比较早，因为要帮忙安排桌子凳子，一切准备就绪后，一起吃了个午饭。
![吃了个午饭](https://ws1.sinaimg.cn/large/b7f2e3a3gy1g1tf3jejrej229s29s1ky.jpg "吃了个午饭")

13:30开始签到，签到现场
![签到现场](https://ws1.sinaimg.cn/large/b7f2e3a3gy1g1tf3of8qlj229s29sb2a.jpg "签到现场")

我充当了一会儿签到员，坐着的那个是我
![坐着的那个是我](https://ws1.sinaimg.cn/large/b7f2e3a3gy1g1tf3sy1ylj20m80cimyt.jpg "坐着的那个是我")

各种各样的 Elasticsearch 贴纸
![各种各样的 Elasticsearch 贴纸](https://ws1.sinaimg.cn/large/b7f2e3a3gy1g1tf3ydx4cj229s29s4qq.jpg "各种各样的 Elasticsearch 贴纸")

这是一种比较特殊的 Elasticsearch 贴纸
![特殊的 Elasticsearch 贴纸](https://ws1.sinaimg.cn/large/b7f2e3a3gy1g1tf427iykj20qo1hcq74.jpg "特殊的 Elasticsearch 贴纸")


# 静听分享


先简单看一下这个分享会的大概流程与分享内容
![分享内容](https://ws1.sinaimg.cn/large/b7f2e3a3gy1g1tf471eb8j21830o9gnw.jpg "分享内容")

## 分享一

Elasticsearch 在数说全量库的应用实践

现场场景一
![场景一](https://ws1.sinaimg.cn/large/b7f2e3a3gy1g1tf5ceaqtj21kw0w0as5.jpg "场景一")

现场场景二
![场景二](https://ws1.sinaimg.cn/large/b7f2e3a3gy1g1tf58jqs2j20zk0k0ta7.jpg "场景二")

现场场景三
![场景三](https://ws1.sinaimg.cn/large/b7f2e3a3gy1g1tf54mc76j21hc0u0q84.jpg "场景三")

## 分享二

Elasticsearch 在慧算账技术运营中的应用

现场场景
![现场](https://ws1.sinaimg.cn/large/b7f2e3a3gy1g1tf4yz5k5j20m80ciac7.jpg "现场")

## 分享三

Elasticsearch 在大数据可视化分析中的应用

现场场景
![现场](https://ws1.sinaimg.cn/large/b7f2e3a3gy1g1tf4twfafj20m80cit9r.jpg "现场")

## 分享四

打造云原生的 Elasticsearch 服务

现场场景
![现场](https://ws1.sinaimg.cn/large/b7f2e3a3gy1g1tf4p52q6j20m80cit9u.jpg "现场")

## 分享五

Elasticsearch 集群在雷达大数据平台的演进

现场场景
![现场](https://ws1.sinaimg.cn/large/b7f2e3a3gy1g1tf4kjqsjj20m80ciq4f.jpg "现场")


## 分享者合影留念

认真的观众
![认真的观众](https://ws1.sinaimg.cn/large/b7f2e3a3gy1g1tf4c5u0oj21400u00x8.jpg "认真的观众")

分享者合影留念
![分享者合影留念](https://ws1.sinaimg.cn/large/b7f2e3a3gy1g1tf4ftxkrj20m80cizlx.jpg "分享者合影留念")


# 我的思考以及学到的东西


0、虽然有一些分享听不懂，例如腾讯云的 Elasticsearch 云服务，做了什么优化、达到了什么效果，或者是数说雷达的架构演进，这些目前对于我来说都太不切实际，因为还没接触到这么高深的知识，平时也使用不到，所以听起来云里雾里。但是，能从中提取1-2个重要知识点也是有用的，例如腾讯云的索引碎片化，导致读写速度严重下降，这与我在工作当中遇到的问题一模一样。再例如数说雷达演进过程中遇到的坑，某个字段没有做 doc_values，导致不支持 aggregation 查询，这与我很久之前遇到的问题一模一样，此时又加深了我的认知。

1、多版本 Elasticsearch 的兼容解决办法，需要设置拦截器，把请求的不兼容参数部分替换掉，可以使用 SpringBoot 整合，需要注意已知版本的种类。

2、针对 long 类型字段的聚合【即 aggregation】请求根据自己的业务场景，如果判断为实际上没有必要【例如只是对年份、月份、日做聚合，并不考虑时区、毫秒时间戳的问题】，可以换一种思路，转化为字符串存储，针对字符串做聚合操作效率就高多了。

3、在现场提问时，有的人是带着自己业务实际遇到的问题来提问探讨的，提问时描述问题已经消耗了将近10分钟。接下来如果真的探讨起来，估计没有半个小时一个小时搞不定，这显然是在浪费大家的时间。所以分享者也及时打断了提问，并留下联系方式，分享会后线下接着再讨论。这种做法很得体，虽然不能在现场解答【为了节约大家的时间】，但是会后讨论也是一样，有时候根据实际情况就是需要这样的取舍。

4、在 Elasticsearch 中，字段类型是可以节约存储空间与请求耗时的，例如 integer、long、short 的合理使用，但是切记存储的目的最终都是为了使用。


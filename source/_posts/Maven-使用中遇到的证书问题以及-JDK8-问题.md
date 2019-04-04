---
title: Maven 使用中遇到的证书问题以及 JDK8 问题
id: 2018082501
date: 2018-08-25 23:06:32
updated: 2019-04-04 23:06:32
categories: 基础技术知识
tags: [Maven,JDK,证书]
keywords: Maven,JDK,证书
---


在 Java 开发过程中，使用 Maven 往私服 deploy 构件【Java 打成的 jar 包】的时候，原本正常的流程突然出问题了，报错信息：

```
[WARNING] Could not transfer metadata org.leapframework:leap:0.4.0b-SNAPSHOT/maven-metadata.xml from/to bingo-maven-repository-hosted ($bingo.maven$): sun.security.validator.ValidatorException: PKIX path building failed: sun.security.provider.certpath.SunCertPathBuilderException: unable to find valid certification path to requested target
```

看到里面的 **security** 和 **certification** 关键词就猜测是安全与证书的问题。恰好最近私服的域名访问从 http 升级为了 https，也就是增加了 SSL 证书，我想可能和这个有关。本文就记录解决这个问题的流程，以及后续由此又引发了其它的问题，例如 JDK8 导致的注解问题、IDEA 的乱码问题。


<!-- more -->


# 问题出现


待整理。


# 问题解决


待整理。


# 问题总结


待整理。

1、通过手动导入证书的方式，一开始解决了问题，后来过了一段时间突然又不能使用，这时候我很是疑惑的。问了问同事却都能正常使用，我还以为是我的 Maven 的版本问题，换了 Maven 版本也不行，最后折腾了很久发现是私服域名的 SSL 证书失效了，再重新导入一份就行了。因为私服域名的 **Let's Encrypt** 证书有效期只有三个月，所以每次证书续期或者更换的时候，都要手动重新导入，旧证书会自动失效。这样多麻烦，所以还是直接升级 JDK 比较好，一劳永逸。

2、在与同事的开发环境对比的过程中，仔细对比了 Maven 的版本和 JDK 的版本，发现都是 Maven 3.5 与 JDK1.7，但是别人能用我的就不能用，一度怀疑人生。最终才发现根本原因是没有对比小版本号，同样是 JDK1.7，没有 **>=7u111** 也不行。


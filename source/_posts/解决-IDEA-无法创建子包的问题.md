---
title: 解决 IDEA 无法创建子包的问题
id: 2017042201
date: 2017-04-22 23:50:44
updated: 2019-04-22 23:50:44
categories: 基础技术知识
tags: [IDEA,package]
keywords: IDEA,package
---


最近在使用 IDEA 的时候，发现一个奇怪的问题，如果新建了一个多层的包，再想新建一个和除第一层包之外的包等级别的子包就不行。说的这么绕口，什么意思呢？举例来说，比如我新建了一个包，完整路径为：a.b.c.d，如果再想新建一个和 d 等级别的子包 e：a.b.c.e，就不行，IDEA 会默认在 d 下面新建一个子包，那整个包就变成了：a.b.c.d.e，这显然是不合常理的，也不是我需要的。本文记录这个问题的解决方案。


<!-- more -->


# 问题出现


当在 IDEA 中新建一个 Java 项目的包时，完整路径为：org.playpi.blog，再想新建一个和 blog 等级别的包：www，结果发现 www 是建在了 blog 下面，那就变成了 org.playpi.blog.www，这不是我想要的结果。

新建一个包
![新建一个包](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/old/b7f2e3a3gy1g2czihdz8nj20c209wq32.jpg "新建一个包")

新建一个子包
![新建一个子包](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/old/b7f2e3a3gy1g2czimvkzsj20cx09zwem.jpg "新建一个子包")

注意，上面的现象是在包只有一个的情况下，还没有创建等级别的其它包，如果创建了等级别的其它包就不会有这种现象了。例如如果已经有了 org.playpi.blog、org.playpi.www，再想创建一个 org.playpi.doc，是可以做到的。


# 问题解决


有一种粗暴并且略微繁琐的方法，那就是在新建多层的包时，不要单独创建，而是一层一层创建，并且和类文件【或者其它类型的文件也行，只要不是单纯的包即可】一起创建，这样就可以稳妥地创建多个等级别的包了。但是这种做法显然很傻，而且有时候根本不需要每个包都有等级别的包存在。

其实，IDEA 有自己的设置方式，可以看到在项目树形结构的右上方，有一个设置按钮【齿轮形状】，点开，可以看到 **Hide Empty Middle Packages**，意思就是**隐藏空白的中间包**，这个选项默认是开启的。
![隐藏空白包设置](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/old/b7f2e3a3gy1g2cziytewrj20iz0in75p.jpg "隐藏空白包设置")

注意，这里的 **Empty Packages** 并不是严格意义上的空包【对应对操作系统的空文件夹】，而是指包里面只有一个子包，并没有其它的类文件或者任意文件。

所以，新建的多层的包都会被隐藏，再新建子包时，默认是从最深处的包下面创建，这样也就发生了问题出现的那一幕。

解决起来就很容易，把这个选项去掉，不要隐藏，全部的包都显示，这样就可以轻松地新建多个子包了。
![轻松创建同级别的子包](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/old/b7f2e3a3gy1g2czj69uxcj20d70co74j.jpg "轻松创建同级别的子包")

这样做有一个缺点，对于那些有多个空白包的情况， 都显示出来很难看，不友好，所以最好还是在需要时临时关闭这个选项，等不需要了再打开，毕竟隐藏空白包的效果看起来还是很清爽的。

注意，当去掉隐藏选项时，选项的名字会变为 **Compact Empty Middle Packages**，收起空白包，其实意思和隐藏空白包一样。
![Compact收起空白包设置](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/old/b7f2e3a3gy1g2czm384wyj20cw05v74b.jpg "Compact收起空白包设置")


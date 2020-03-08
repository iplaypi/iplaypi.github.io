---
title: 使用 IDEA 自动生成 serialVersionUID
id: 2016060801
date: 2016-06-08 11:42:02
updated: 2016-06-08 11:42:02
categories: 基础技术知识
tags: IDEA,Java,serialVersionUID,Serializable,InvalidCastException,Inspections
keywords: [IDEA,Java,serialVersionUID,Serializable,InvalidCastException,Inspections]
---


今天在一个 `Java Web` 项目中，遇到反序列化的问题，在前端生成的参数列表以 `JSON` 格式保存，然后在后端需要提取参数，并反序列化为指定的实体类使用，结果反序列化失败，失败异常是 `InvalidCastException`，根本原因还是 `serialVersionUID` 不一致。本文简述一下这个知识点，也是自己复习使用。


<!-- more -->


# 自动生成


众所周知，`InelliJ IDEA` 是一款非常优秀的 `IDE` 工具，其中它包含很多自动检查工具，`Serialzable` 检查就是其中一项。

默认的序列化检查项是关闭的，所以不存在自动检查之说，也就无法自动生成。可以去 `IDEA` 中设置自动检查，依次找到 `Settings`、`Inspections`，在里面搜索 `Serializable` 关键词，就可以发现与之有关的多项设置，其中 `Serializable class without serialVersionUID` 就是自动检查序列化缺失 `serialVersionUID` 的场景，在右侧打勾选中即可，以后 `IDEA` 就会自动检查需要序列化的 `Java` 类是否缺失 `serialVersionUID` 了。

注意右侧还有一个 `Severity` 选项，用来设置检查的级别，建议设置为 `Warning`，如果对序列化特别看重的话，可以选择 `Error` 级别，我在这里使用了 `Warning` 级别。

![设置自动检查](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2016/20200308180911.png "设置自动检查")

如果设置了 `Inspections` 的检查项，`IDEA` 就会自动检查 `Java` 类是否带有 `serialVersionUID`，如果没有则会提示，然后可以使用快捷方式来设置。

具体操作：在已经实现 `Serialzable` 接口的 `Java` 类上【即可以序列化的类】，选中类名，使用 `ALT + ENTER` 快捷键即可弹出选择列表，选择 `Add serialVersionUID field`，再使用 `ENTER` 即可生成 `serialVersionUID`。

![快捷键添加](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2016/20200308180956.png "快捷键添加")

如果在弹出的选择列表中，展开 `Add serialVersionUID field`，可以看到更多的选择项，此时可以选择 `Edit inspection profile setting` 进入 `Inspections` 设置，也可以选择 `Disable inspection` 关闭自动检查。

![快捷设置选项](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2016/20200308181011.png "快捷设置选项")


# 作用简介


`Java` 类进行序列化有两个主要目的，分别为：

- 把对象的字节序列永久地保存到硬盘上，通常存放在一个文件中
- 在网络上传输对象的字节序列，发送方、接收方使用的 `Java` 类版本可能不一致

`serialVersionUID` 适用于 `Java` 的序列化机制，简单来说，`Java` 的序列化机制是通过判断类的 `serialVersionUID` 取值来验证版本一致性的。在进行反序列化时，`JVM` 会把传来的字节流中的 `serialVersionUID` 与本地相应实体类的 `serialVersionUID` 进行比较，如果相同就认为版本是一致的，可以进行反序列化，否则就会出现序列化版本不一致的异常，即 `InvalidCastException`，这样也就无法反序列化了。

这种做法可以避免 `Java` 类改动过大引起的未知问题，例如变量类型变了，或者含义变了，如果 `Java` 类在传输前后的版本差异过大，就会有未知的问题。而只要指定了 `serialVersionUID` 的不同值，则直接抛出异常，无法进行反序列化，就会直接强制用户升级匹配的版本，从而避免未知的问题。

具体的序列化过程是这样的：序列化操作的时候系统会把当前类的 `serialVersionUID` 写入到序列化文件中，当反序列化的时候系统会去检测文件中的 `serialVersionUID`，判断它是否与当前类的 `serialVersionUID` 一致，如果一致就说明反序列化类的版本与当前类的版本是一致的，可以反序列化成功，否则反序列化失败。

`serialVersionUID` 有两种显示的生成方式：

- 第一种是设置一个常量值，例如1L，比如 `private static final long serialVersionUID = 1L`
- 第二种是根据类名、接口名、成员方法及属性等来生成一个64位的哈希字段，比如：`private static final long serialVersionUID = xxxxL`【很长的值，可以利用 `IDEA` 自动生成】

当一个类实现了 `Serializable` 接口，如果没有显式定义 `serialVersionUID`，`IDEA` 会提供相应的检查，面对这种情况，我们只需要按照上面的步骤，自动生成 `serialVersionUID` 即可。

但是如果我们不顾警告，没有手动指定同时也没有使用 `IDEA` 自动生成，那这个实现 `java.io.Serializable` 接口的类会有 `serialVersionUID` 变量吗？当然有，并且是在编译阶段产生的，`Java` 序列化机制会根据编译的 `class` 自动生成一个 `serialVersionUID` 作为序列化版本比较使用。

在这种情况下，如果 `class` 文件【类名、方法名等等】没有发生变化【增加空格、换行、增加注释等等】，就算使用同一个版本的 `JDK` 编译多次，`serialVersionUID` 也不会变化的。但是只要变更了类，哪怕加一行注释，`serialVersionUID` 就会变化，所以这种方式是不被建议的。

因此，如果我们不希望通过编译来强制划分软件版本，即实现 `Serializable` 接口的实体类能够兼容先前的版本，就需要显式地定义一个名为 `serialVersionUID`、类型为 `long` 的变量，不修改这个变量值的实体类都可以相互进行序列化、反序列化。

## 注意事项

- 切记对于实现 `Serializable` 接口的类，要显式地指定 `serialVersionUID` 的值
- 如果没有指定 `serialVersionUID` 的值，并且类的内容不再变化，也可能由于 `JDK` 版本的不同，导致编译产生的 `serialVersionUID` 值不一致，所以这也是一个潜在的坑
- `serialVersionUID` 的修饰符最好是 `private`，因为 `serialVersionUID` 不能被继承，所以建议使用 `private` 修饰


# 备注


1、`IDEA` 官网：[jetbrains](https://www.jetbrains.com/idea) 。

2、在软件开发中，我们一般不希望使用 `serialVersionUID` 来控制 `Java` 类的版本，因为这可能会导致未知的异常，而且存在强制兼容的难点【需要让所有的用户强制升级】，所以可以手动指定 `serialVersionUID` 的值为一个固定值，例如 -1。

当然，有时候希望在大版本发布时【变更比较大，`Java` 类无法兼容，为了避免未知的异常】，把 `serialVersionUID` 也做升级，这时候可以强制改变 `serialVersionUID` 的值。例如做第三方的 `SDK` 工具包，或者一些通用工具类【例如网络传输、格式转换】，涉及到序列化、反序列化，当需要强制把低版本变得不可用时，就可以改变 `serialVersionUID` 的值【如果用户恰好混合使用高、低版本，就会影响到业务，可以选择一点不做升级，或者所有依赖一同升级】。

3、关于 `Serializable` 的官方文档：[Serializable](https://docs.oracle.com/javase/7/docs/api/java/io/Serializable.html) 。


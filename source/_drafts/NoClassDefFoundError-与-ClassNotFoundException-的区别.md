---
title: NoClassDefFoundError 与 ClassNotFoundException 的区别
id: 2020-02-07 01:42:31
date: 2020-02-07 01:42:31
updated: 2020-02-07 01:42:31
categories:
tags:
keywords:
---


2020020501
基础技术知识
Java,Error,Exception



<!-- more -->


问题现象，异常分类，能否捕捉重试，尝试恢复。

NoClassDefFoundError是一个错误(Error)，而ClassNOtFoundException是一个异常，在Java中对于错误和异常的处理是不同的，我们可以从异常中恢复程序但却不应该尝试从错误中恢复程序。

ClassNotFoundException的产生原因主要是：

Java支持使用反射方式在运行时动态加载类，例如使用Class.forName方法来动态地加载类时，可以将类名作为参数传递给上述方法从而将指定类加载到JVM内存中，如果这个类在类路径中没有被找到，那么此时就会在运行时抛出ClassNotFoundException异常。

解决该问题需要确保所需的类连同它依赖的包存在于类路径中，常见问题在于类名书写错误。
另外还有一个导致ClassNotFoundException的原因就是：当一个类已经某个类加载器加载到内存中了，此时另一个类加载器又尝试着动态地从同一个包中加载这个类。通过控制动态类加载过程，可以避免上述情况发生。

NoClassDefFoundError 产生的原因在于：

如果JVM或者ClassLoader实例尝试加载（可以通过正常的方法调用，也可能是使用new来创建新的对象）类的时候却找不到类的定义。要查找的类在编译的时候是存在的，运行的时候却找不到了。这个时候就会导致NoClassDefFoundError。

造成该问题的原因可能是打包过程漏掉了部分类，或者jar包出现损坏或者篡改。解决这个问题的办法是查找那些在开发期间存在于类路径下但在运行期间却不在类路径下的类。

这种问题常见的地方在于项目的依赖冲突时【同一个依赖的不同版本之间冲突】，没有发现，编译、打包都可以正常通过【加载了某个版本的依赖】，但是运行时就会出现 `NoClassDefFoundError`【有时候如果类存在，但是方法不兼容，也会有 `NoSuchMethodError` 出现】。


---
title: JNI 字段描述符基础知识
id: 2019041301
date: 2019-04-13 17:12:45
updated: 2019-04-14 17:12:45
categories: 基础技术知识
tags: [JNI,字段描述符]
keywords: JNI,字段描述符,FieldDescriptors
---


平时在做 Java 开发的时候，难免遇到异常信息中包含一种特殊的表达字符串，例如：

```
method: createWorker signature: (Ljava/util/concurrent/Executor;) Lorg/jboss/netty/channel/socket/nio/AbstractNioWorker;
```

或者

```
java.lang.NoSuchMethodError: com.fasterxml.jackson.databind.JavaType.isReferenceType () Z
```

可以看到，异常信息中有一种特殊的字符串出现了：**L 后面跟着类名**、**方法后面跟了一个 Z**。其实，这就是 **JNI 字段描述符【Java Native Interface FieldDescriptors】**，它是一种对 Java 数据类型、数组、方法的编码。此外，在 Android 逆向分析中，通过反汇编得到的 smali 文件，里面的代码也会遵循这种方式，即 Dalvik 字节码。本文就记录一些数据类型、数组、方法的编码方式以及解释说明，方便以后查阅。


<!-- more -->


# 基本概念


这种编码方式把 Java 中的基本数据类型、数组、对象都使用一种规范来表示：

- 八种基本数据类型都使用一个大写字母表示
- void 使用 V 表示
- 数组使用左方括号表示
- 方法使用一组圆括号表示，参数在括号里，返回类型在括号右侧
- 对象使用 L 开头，分号结束，中间是类的完整路径，包名使用正斜杠分隔


# 基本编码


基本编码如下表格，并配有解释说明：

| Java 类型 | JNI 字段描述符 |
| :------: | :------: |
|boolean|Z|
|byte|B|
|char|C|
|short|S|
|int|I|
|long|J|
|float|F|
|double|D|
|void|V|
|Object|以 L 开头，以 ; 结尾，中间是使用/隔开的完整包名、类型。例如：Ljava/lang/String;。如果是内部类，添加 $ 符号分隔，例如：Landroid/os/FileUtils$FileStatus;。|
|数组|[|
|方法|使用()表示，参数在圆括号里，返回类型在圆括号右侧，例如：(II)Z，表示 boolean func(int i,int j)。|


# 举例说明


## 数据类型

1、**[I**：表示 int 一维数组，即 **int []**。
2、**Ljava/lang/String;**：表示 String 类型，即 **java.lang.String**。
3、**[Ljava/lang/Object;**：表示 Object 一维数组，即 **java.lang.Object []**。
4、**Z**：表示 boolean 类型。
5、**V**：表示 void 类型。

## 方法

1、**()V**：表示参数列表为空，返回类型为 void 的方法，即 **void func()**。
2、**(II)V**：表示参数列表为 int、int，返回类型为 void 的方法，即 **void func(int i,int j)**。
3、**(Ljava/lang/String;Ljava/lang/String;)I**：表示参数列表为 String、String，返回类型为 int 的方法，即 **int func(String i,String j)**。
4、**([B)V**：表示参数列表为 byte []，返回类型为 void 的方法，即 **void func(byte [] bytes)**。
5、**(ILjava/lang/Class;)J**：表示参数列表为 int、Class，返回类型为 long 的方法，即 **long func(int i,Class c)**。


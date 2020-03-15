---
title: Spark 序列化的一些事
id: 2017071701
date: 2017-07-17 00:23:05
updated: 2017-07-17 00:23:05
categories: 大数据技术知识
tags: [NotSerializableException,serializable,Spark]
keywords: NotSerializableException,serializable,Spark
---


在 `Spark` 任务中，大家经常遇到的一个异常恐怕就是 `Task not serializable: java.io.NotSerializableException` 了，只要稍不注意，就会忘记了序列化这件事，当然解决方法也是很简单。

但是，对于初学者来说，恐怕会有一些疑惑，或者稀里糊涂把问题解决了，但是不知道根本原因。


<!-- more -->


# 问题分析


常见的序列化错误：

```
Exception in thread "main" org.apache.spark.SparkException: Task not serializable
at org.apache.spark.util.ClosureCleaner$.ensureSerializable(ClosureCleaner.scala:166)
at org.apache.spark.util.ClosureCleaner$.clean(ClosureCleaner.scala:158)
at org.apache.spark.SparkContext.clean(SparkContext.scala:1242)
at org.apache.spark.rdd.RDD.map(RDD.scala:270)
at org.apache.spark.api.java.JavaRDDLike$class.mapToPair(JavaRDDLike.scala:99)
at org.apache.spark.api.java.JavaRDD.mapToPair(JavaRDD.scala:32)
```

由于 `Spark` 任务在分发的过程中，需要对必要的对象进行序列化传输，在 `executor` 端接收到数据后再反序列化，如果没有控制好需要序列化的类，可能会出现 `NotSerializableException` 异常。这种情况还算好的，直接修改对应的类，就可以解决问题。

有时候如果使用了类成员，不小心使用 `static` 修饰，而且初始化为 `null`，再在初始化 `Spark` 任务时对它进行赋值，实际上在 `executor` 端执行进程时是接收不到这个变量的值的，因为对 `static` 变量的修改是归于本地 `JVM` 管理的，不会序列化传输【传输的只是默认值】。

对于常见的不会经过序列化的四种场景【注意 `static` 变量的初始值很重要】：

- 加上临时修饰符 `transient`，不会参与序列化
- `static` 变量，属于类属性，不会参与序列化
- `static` 方法，属于类属性，不会参与序列化
- `SparkContext` 对象不需要序列化

对于常见的需要序列化的三种场景：

- 普通的变量，如果在算子中使用到，则这个变量所属的类以及所有成员都需要支持序列化
- 普通的方法，如果在算子中使用到，则这个变量所属的类以及所有成员都需要支持序列化
- 类引用，如果在算子中使用到某个类，则这个类需要支持序列化


# 建议


1、对于需要在算子中使用的方法、变量，全部使用 `static` 修饰，避免序列化整个类。

2、对于需要在算子中使用的变量，最好使用 `SparkContext` 传输，或者使用广播变量。

3、对于确实需要实例化的类【整个类】，把类定义放在算子内部，也就是内部类，减少序列化的网络传输。

4、对于需要在算子中使用的方法，可以使用函数式方法，这样就可以避免序列化方法所属的整个类了。


# 备注


记录一次踩坑记录：

业务中需要传输一个集合列表，里面包含十几个字符串元素，在代码中使用 `static` 修饰集合，并且初始值为 `null`，而在 `driver` 端 `Spark` 任务启动初始化类后，再进行赋值，序列化分发到集群各台 `executor` 上，集合对象的取值会丢失【`static` 修饰的变量属于类成员，不属于对象成员，没有序列化流程，`static` 修饰的对象由本地 `jvm` 管理，`executor` 端无法接收，取值为对象的默认值 `null`。尽管在 `driver` 端进行初始化为 `null`，再把它二次更改，但是对 `executor` 端无效】，而后在 `map`、`foreachPartition` 等算子中直接使用此变量时，执行过程中会抛出 `NullPointException`。

而如果直接使用的是 `local` 模式，和 `yarn` 集群无交互，所以不会有多台节点，全程都在本地单进程执行，这样的测试结果显然是不能作为成功与否的依据。

修复思路：取消 `static` 修饰集合变量，这样变量在初始化时就是对象的成员了，并在初始化类后检查配置加载情况，异常时自动退出，保证序列化传输前的配置信息有值。这样操作后，一切配置信息在 `driver` 端初始化并检查完成，然后才会提交 `Spark` 任务，而所有的配置信息都会经过序列化分发的过程，不会丢失，可以准确到达 `executor` 端。

上述解决方法显然不够优雅，其实对于参数的传递，最好使用 `SparkContext` 上下文进行传输【小参数】，或者使用广播变量传输【大参数】，比使用序列化的方式更为正式可靠，也符合 `Spark` 的设计初衷。


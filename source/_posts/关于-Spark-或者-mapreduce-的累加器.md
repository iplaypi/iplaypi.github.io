---
title: 关于 Spark 或者 mapreduce 的累加器
id: 2017043001
date: 2017-04-30 23:34:26
updated: 2019-04-23 23:34:26
categories: 大数据技术知识
tags: [Spark,MapReduce,Accumulator,Java,Hadoop]
keywords: Spark,MapReduce,Accumulator,Java,Hadoop
---


在 `Spark` 和 `Hadoop` 的 `MapReduce` 中都有累加器的概念，顾名思义，累加器就是用来做累加【或者累减】使用的，有时候为了统计某些值，在程序中埋入指标，这样在程序运行中、运行后都可以清晰观察到统计指标，还能辅助检查程序的问题。在 `Spark`、`MapReduce` 中，它们的使用方式尽管有一点点不同的地方，甚至在 `Spark` 的不同版本中使用方式也会不一致，但也算是大同小异。本文简单记录在 `Spark`、`MapReduce` 中累加器的使用，并补充说明一些重要的坑，`Spark` 环境基于 v1.6.2，`Hadoop` 环境基于 v2.7.1 。


<!-- more -->


# 累加器基础概念


在 `Spark` 任务中，如果想要在 `Task` 运行的过程中统计某些指标，例如处理了多少数据量、过滤了多少数据量，使用普通的变量是不行的，会有并发的问题。此时，累加器就可以出场了，使用方式简单，统计结果准确。

只要在代码中指定了累加器，并在 `Task` 中使用它，通过 `Action` 算子触发后，在 `Spark` 任务运行中或者运行完成后，都可以观察到累计器的值。

例如在 `Spark` 任务运行的过程中，通过 `SparkUI` 可以观察累加器的取值变化，在 `Stages` 标签页中选择带有累加器的某一个 `Stage`，查看详情，就可以看到在 `Accumulators` 指标列表中，列出了所有累加器的名字和取值。
![在 SparkUI 中查看任务的累加器](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2017/20190714001039.png "在 SparkUI 中查看任务的累加器")

而在 `Hadoop` 的 `MapReduce` 中，累加器的用法也是一样，不同的是，在 `MapReduce` 的调度系统 `Yarn` 中，无法观察到累加器的取值变化，只能等待 `MapReduce` 运行完成，才能在输出日志中查看累加器的最终取值。而且这是自动统计打印出来的，不需要手动输出。

下面详细介绍累加器的使用方式。


# 累加器的使用


## 在 Spark 中的使用

首先说明一下，注意不同版本的影响，使用方式会不一致，我下面列出的例子都是基于 `Spark` v1.6.2，例如在 `Spark` v2.x 的版本中，初始化累加器的方式就改变了一些，在此不再赘述。

`Spark` 提供的 `Accumulator`，主要用于多个节点【Excutor】对同一个变量进行共享性的操作。`Accumulator` 只提供了累加的功能【调用 add() 方法】，给我们提供了多个 `Task` 对一个变量并行操作的功能。但是 `Task` 只能对 `Accumulator` 进行累加操作，不能读取它的值，只有 `Driver` 端的程序可以读取 `Accumulator` 的值【调用 value() 方法】。

### 代码接口

为了使用累加器，首先要有上下文对象，对于 `Java` 的接口来说就是 `JavaSparkContext`，然后利用上下文对象创建累加器。下面列出几个简单的示例：

```
JavaSparkContext jsc = initJsc();
final Accumulator<Integer> totalAcc = jsc.accumulator(0, "total");
final Accumulator<Integer> saveTotalAcc = jsc.accumulator(0, "saveTotal");
final Accumulator<Integer> defaultAcc = jsc.accumulator(0);
final Accumulator<Double> doubleAcc = jsc.doubleAccumulator(0);
final Accumulator<Integer> intAcc = jsc.intAccumulator(0);
```

代码片段截图如下：
![创建累加器代码片段](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2017/20190714002724.png "创建累加器代码片段")

这里把累加器的修饰符定义为 `final` 是有必要的，因为在 `Spark` 的 `Function` 中使用时，内部匿名类会要求变量必须为 `final` 类型的。

应该尽量为累加器命名【唯一标识】，这样在查看时才能区分是哪个累加器。

此外，除了普通的数值型累加器，还有集合型累加器，或者用户可以自定义累加器，只要实现特定的接口即可：`Accumulator`，然后通过 `JavaSparkContext` 对象进行注册，在此不再赘述。

创建完成后，就可以使用了，在自定义实现的 `Function` 中，可以使用累加器进行累加操作，代码片段如下：

```
totalAcc.add(1);
saveTotalAcc.add(1);
```

代码片段截图如下：
![使用累加器代码片段](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2017/20190714003706.png "使用累加器代码片段")

注意一点，在 `Function` 中对累加器只能增加，不能取值，如果在 `Spark` 的 `RDD` 中试图取出累加器的值，`Spark` 任务会抛出异常而失败。

因为累加器，顾名思义，就是用来累加的，只能在 `Spark` 任务运行中【Task 端】进行累加，而且用户不用担心并发的问题，但是想要使用代码获取累加器的取值，只能等待 `Spark` 任务运行完成后，才能在 `Driver` 端进行取值操作。使用代码取值代码片段如下：

```
System.out.println("====total:" + totalAcc.value());
System.out.println("====saveTotal:" + saveTotalAcc.value());
```

代码片段截图如下：
![累加器取值代码片段](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2017/20190714004227.png "累加器取值代码片段")

### 前端界面查看

而如果有一个需求就是要在某时刻查看累加器的值，或者说需要实时查看累加器的值，能不能实现呢，当然可以，这就需要 SparkUI 出场了。

在提交 `Spark` 任务时，创建 `JavaSparkContext` 对象成功后，注意观察输出日志，会发现有一个重要的链接信息出现：SparkUI 的地址。当然，如果已经知道了自己所使用的 `Yarn` 或者 `Standalone` 集群的信息，就不需要关心这个日志了，直接打开浏览器就可以查看了。

![在日志中查看 SparkUI 的地址](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2017/20190714004850.png "在日志中查看 SparkUI 的地址")

在上面的截图中，可以看到重要的一行信息：

```
16:50:10 [main] INFO ui.SparkUI:58: Started SparkUI at http://192.168.10.99:4041 
```

这个就是 SparkUI 的地址，直接在浏览器中打开，就可以看到这个 `Spark` 任务的运行状态，其它的信息我在这里不关心，直接选择 `Stages` 标签页，可以看到下面有一个 `Stages` 列表，里面是运行中或者运行完成的 `Stage`：

![在 SparkUI 中查看 Stages](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2017/20190714005348.png "在 SparkUI 中查看 Stages")

选择一个带有累加器的 `Stage`，查看详细信息，可以看到 `Executor`、`Tasks`、`Accumulators` 等信息，在这里重点关注 `Accumulators` 的信息：

![在 SparkUI 中查看 Accumulators](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2017/20190714005708.png "在 SparkUI 中查看 Accumulators")

可以看到，我这里有2个累加器：`total`、`saveTotal`，它们的取值分别为70552、70552。根据我的代码逻辑，这表示我的 `Spark` 任务已经处理了70552条数据，并且没有过滤掉1条数据，全部写出到文件。

### 奇技淫巧

如果需要使用累加器进行减法操作，可行吗，当然，把累加器的累加数值改为负数即可。

```
totalAcc.add(-1);
saveTotalAcc.add(-1);
```

## 在 MapReduce 中的使用

在 `MapReduce` 中使用累加器的方法就很简单了，不需要初始化，直接通过枚举类型 `Enum` 定义累加器的唯一标识，然后在 `Map` 或者 `Reduce` 中，利用 `Context` 上下文对象对累加器进行操作，例如增加指定数值。代码示例如下：

```
context.getCounter(MREnum.MAP_READ).increment(1);
if (result == null || result.isEmpty()) {
	context.getCounter(MREnum.MAP_FILTER).increment(1);
	return;
}
String pk = new String(result.getRow());
if (StringUtil.isNullOrEmpty(pk)) {
	context.getCounter(MREnum.MAP_FILTER).increment(1);
	return;
}
```

代码片段截图如下：
![使用累加器代码片段](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2017/20190714013323.png "使用累加器代码片段")

使用累加器的核心代码就是：

```
context.getCounter(MREnum.MAP_FILTER).increment(1);
```

其中，`Context` 就是 `MapReduce` 中的上下文对象，`MREnum.MAP_FILTER` 是自定义的枚举类型，每个累加器对应一个。

`MapReduce` 任务完成后，不需要手动输出累加器的取值，`Hadoop` 框架会自动统计输出各种指标，当然也包括累加器的取值。
![累加器取值输出](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2017/20190714013755.png "累加器取值输出")

可以从上图中看到有5个累加器：DONE、READ、REDUCE、SHUFFLE、WRITE，它们的取值都是千万级别的数字。

此外，在 `Yarn` 等调度系统中无法查看 `MapReduce` 任务的累加器取值变化，这是一个遗憾。


# 注意踩坑

1、前面已经说过，使用累加器时，只能在 `Spark` 任务运行中【Task 端】进行累加，然后等待 `Spark` 任务运行完成后，才能在 `Driver` 端进行取值操作。如果强行在 `Task` 中对累加器进行取值，`Spark` 任务会抛出异常而失败。

2、在 `Spark` 中，由于累加器是在 `Task` 中进行的，所以针对 `RDD` 的 `Transform` 操作【例如 map、filter】是不会触发累加器的执行的，必须是 `Action` 操作【例如 count】才会触发。所以如果读者发现自己的程序中输出的累加器取值不正确，看看是不是这个原因。

3、正是因为2的原因，用户可能会进行多次 `Action` 操作后，发现累加器的数值不对，远远大于正确的数值，然后懵了。这种现象是正常的，属于人为误操作，因此用户一定要正确使用累加器，控制好 `Action` 操作，或者及时使用 `cache()` 方法，这样可以断开与前面 `DataSet` 的血缘关系，保证累加器只被执行一次。

4、通过2也可以发现一个问题，如果 `Spark` 任务的某个 `Task` 反复执行了多次【Spark 的容错性，例如某个 Task 失败重试了多次之后才成功】，那累加器进行累加时会不会重复计算。当然会重复计算，这也是一个坑，为了避免这个坑，尽量把对累加器的操作放在 `Action` 算子中，这样就可以保证累加器被操作一次。

5、在创建累加器时，如果没有指定累加器的名字，那么只能在程序中通过代码操作累加器，而在 sparkUI 中无法看到累加器的取值。


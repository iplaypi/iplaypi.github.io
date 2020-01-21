---
title: Spark 警告：Not enough space to cache rdd in memory
id: 2020012201
date: 2020-01-22 01:58:33
updated: 2020-01-22 01:58:33
categories: 大数据技术知识
tags: [Spark,cache]
keywords: Spark,cache
---


在常规的 `Spark` 任务中，出现警告：`Not enough space to cache rdd_0_255 in memory! (computed 8.3 MB so far)`，接着任务就卡住，等了很久最终 `Spark` 任务失败。排查到原因是 `RDD` 缓存的时候内存不够，无法继续处理数据，等待资源释放，最终导致假死现象。本文中的开发环境基于 `Spark v1.6.2`。


<!-- more -->


# 问题出现


在服务器上面执行一个简单的 `Spark` 任务，代码逻辑里面有 `rdd.cache()` 操作，结果在日志中出现类似如下的警告：

```
01:35:42.207 [Executor task launch worker-4] INFO  org.apache.spark.storage.MemoryStore - Will not store rdd_0_28 as it would require dropping another block from the same RDD
01:35:42.211 [Executor task launch worker-4] WARN  org.apache.spark.storage.MemoryStore - Not enough space to cache rdd_0_28 in memory! (computed 340.2 MB so far)
01:35:42.213 [Executor task launch worker-4] INFO  org.apache.spark.storage.MemoryStore - Memory use = 8.3 KB (blocks) + 4.9 GB (scratch space shared across 106 tasks(s)) = 4.9 GB. Storage limit = 5.0 GB.
01:35:49.104 [Executor task launch worker-0] INFO  org.apache.spark.storage.MemoryStore - Will not store rdd_0_15 as it would require dropping another block from the same RDD
01:35:49.105 [Executor task launch worker-0] WARN  org.apache.spark.storage.MemoryStore - Not enough space to cache rdd_0_15 in memory! (computed 341.4 MB so far)
01:35:49.105 [Executor task launch worker-0] INFO  org.apache.spark.storage.MemoryStore - Memory use = 8.3 KB (blocks) + 4.9 GB (scratch space shared across 106 tasks(s)) = 4.9 GB. Storage limit = 5.0 GB.
01:35:51.375 [Executor task launch worker-11] INFO  org.apache.spark.storage.MemoryStore - Will not store rdd_0_33 as it would require dropping another block from the same RDD
01:35:51.375 [Executor task launch worker-11] WARN  org.apache.spark.storage.MemoryStore - Not enough space to cache rdd_0_33 in memory! (computed 341.4 MB so far)
01:35:51.376 [Executor task launch worker-11] INFO  org.apache.spark.storage.MemoryStore - Memory use = 8.3 KB (blocks) + 4.9 GB (scratch space shared across 106 tasks(s)) = 4.9 GB. Storage limit = 5.0 GB.
01:35:52.188 [Executor task launch worker-12] INFO  org.apache.spark.storage.MemoryStore - Will not store rdd_0_48 as it would require dropping another block from the same RDD
01:35:52.188 [Executor task launch worker-12] WARN  org.apache.spark.storage.MemoryStore - Not enough space to cache rdd_0_48 in memory! (computed 341.4 MB so far)
01:35:52.189 [Executor task launch worker-12] INFO  org.apache.spark.storage.MemoryStore - Memory use = 8.3 KB (blocks) + 4.9 GB (scratch space shared across 106 tasks(s)) = 4.9 GB. Storage limit = 5.0 GB.
01:35:52.213 [Executor task launch worker-6] INFO  org.apache.spark.storage.MemoryStore - Will not store rdd_0_58 as it would require dropping another block from the same RDD
01:35:52.213 [Executor task launch worker-6] WARN  org.apache.spark.storage.MemoryStore - Not enough space to cache rdd_0_58 in memory! (computed 342.6 MB so far)
01:35:52.214 [Executor task launch worker-6] INFO  org.apache.spark.storage.MemoryStore - Memory use = 8.3 KB (blocks) + 4.9 GB (scratch space shared across 106 tasks(s)) = 4.9 GB. Storage limit = 5.0 GB.
01:35:56.619 [Executor task launch worker-2] INFO  org.apache.spark.storage.MemoryStore - Block rdd_0_41 stored as values in memory (estimated size 378.7 MB, free 378.7 MB)
```

![Storage 内存不足警告](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2020/20200122021258.png "Storage 内存不足警告")

看起来这只是一个警告，显示 `Storage` 内存不足，无法进行 `rdd.cache()`，等待一段时间之后，`Spark` 任务的部分 `Task` 可以接着运行。

但是后续还是会发生同样的事情：内存不足，导致 `Task` 一直在等待，最后假死【或者说 `Spark` 任务基本卡住不动】。

里面有一个明显的提示：`Storage limit = 5.0 GB.`，也就是 `Storage` 的上限是 `5GB`。


# 问题分析解决


查看业务代码，里面有一个：`rdd.cache();` 操作，显然会占用大量的内存。

查看官方文档的配置：[1.6.2-configuration](https://spark.apache.org/docs/1.6.2/configuration.html) ，里面有一个重要的参数：`spark.storage.memoryFraction`，它是一个系数，决定着缓存上限的大小。

> (deprecated) This is read only if spark.memory.useLegacyMode is enabled. Fraction of Java heap to use for Spark's memory cache. This should not be larger than the "old" generation of objects in the JVM, which by default is given 0.6 of the heap, but you can increase it if you configure your own old generation size.

![memoryFraction 参数](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2020/20200122023358.png "memoryFraction 参数")

另外还有2个相关的参数，读者也可以了解一下。

读者可以注意到，官方是不建议使用这个参数的，也就是不建议变更。当然如果你非要使用也是可以的，可以提高系数的值，这样的话缓存的空间就会变多。显然这样做不合理。

那有没有别的方法了呢？有！当然有。

主要是从缓存的方式入手，不要直接使用 `rdd.cache()`，而是通过序列化 `RDD` 数据：`rdd.persist(StorageLevel.MEMORY_ONLY_SER)`，减少空间的占用，或者直接缓存一部分数据到磁盘：`rdd.persist(StorageLevel.MEMORY_AND_DISK)`，避免内存不足。

我下面演示使用后者，即直接缓存一部分数据到磁盘，当然，使用这种方式，`Spark` 任务执行速度肯定是慢了不少。

我这里测试后，得到的结果：耗时是以前的3倍【可以接受】。

再接着执行 `Spark` 任务，日志中还是会出现上述警告：`Not enough space to cache rdd in memory!`，但是接着会提示数据被缓存到磁盘了：`Persisting partition rdd_0_342 to disk instead.`。

```
01:55:24.414 [Executor task launch worker-3] INFO  org.apache.spark.storage.MemoryStore - Will not store rdd_0_342 as it would require dropping another block from the same RDD
01:55:24.414 [Executor task launch worker-3] WARN  org.apache.spark.storage.MemoryStore - Not enough space to cache rdd_0_342 in memory! (computed 96.8 MB so far)
01:55:24.414 [Executor task launch worker-3] INFO  org.apache.spark.storage.MemoryStore - Memory use = 3.0 GB (blocks) + 2.0 GB (scratch space shared across 339 tasks(s)) = 5.0 GB. Storage limit = 5.0 GB.
01:55:24.414 [Executor task launch worker-3] WARN  org.apache.spark.CacheManager - Persisting partition rdd_0_342 to disk instead.
01:55:33.262 [Executor task launch worker-12] INFO  org.apache.spark.storage.MemoryStore - Will not store rdd_0_229 as it would require dropping another block from the same RDD
01:55:33.262 [Executor task launch worker-12] WARN  org.apache.spark.storage.MemoryStore - Not enough space to cache rdd_0_229 in memory! (computed 342.6 MB so far)
01:55:33.262 [Executor task launch worker-12] INFO  org.apache.spark.storage.MemoryStore - Memory use = 3.0 GB (blocks) + 2.0 GB (scratch space shared across 339 tasks(s)) = 5.0 GB. Storage limit = 5.0 GB.
01:55:33.262 [Executor task launch worker-12] WARN  org.apache.spark.CacheManager - Persisting partition rdd_0_229 to disk instead.
01:55:40.247 [Executor task launch worker-13] INFO  org.apache.spark.storage.MemoryStore - Will not store rdd_0_254 as it would require dropping another block from the same RDD
01:55:40.248 [Executor task launch worker-13] WARN  org.apache.spark.storage.MemoryStore - Not enough space to cache rdd_0_254 in memory! (computed 18.0 MB so far)
01:55:40.248 [Executor task launch worker-13] INFO  org.apache.spark.storage.MemoryStore - Memory use = 3.0 GB (blocks) + 2.0 GB (scratch space shared across 339 tasks(s)) = 5.0 GB. Storage limit = 5.0 GB.
01:55:40.248 [Executor task launch worker-13] WARN  org.apache.spark.CacheManager - Persisting partition rdd_0_254 to disk instead.
01:56:28.062 [dispatcher-event-loop-9] INFO  o.a.spark.storage.BlockManagerInfo - Added rdd_0_255 on disk on localhost:55066 (size: 146.4 MB)
01:56:28.194 [Executor task launch worker-1] INFO  org.apache.spark.storage.MemoryStore - Will not store rdd_0_255 as it would require dropping another block from the same RDD
01:56:28.194 [Executor task launch worker-1] WARN  org.apache.spark.storage.MemoryStore - Not enough space to cache rdd_0_255 in memory! (computed 8.3 MB so far)
01:56:28.194 [Executor task launch worker-1] INFO  org.apache.spark.storage.MemoryStore - Memory use = 3.0 GB (blocks) + 2.0 GB (scratch space shared across 339 tasks(s)) = 5.0 GB. Storage limit = 5.0 GB.
01:56:28.194 [Executor task launch worker-1] INFO  o.apache.spark.storage.BlockManager - Found block rdd_0_255 locally
```

![一部分数据被缓存到磁盘](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2020/20200122024437.png "一部分数据被缓存到磁盘")


# 备注


综上所述，有三种方式可以解决这个问题：

- 提高缓存空间系数：`spark.storage.memoryFraction`【不建议】
- 使用序列化 `RDD` 数据的方式：`rdd.persist(StorageLevel.MEMORY_ONLY_SER)`
- 使用磁盘缓存的方式：`rdd.persist(StorageLevel.MEMORY_AND_DISK)`


---
title: mapreduce 错误之 bin bash-line 0-fg-no job control
id: 2019042401
date: 2019-04-24 22:50:17
updated: 2019-04-24 22:50:17
categories: 踩坑系列
tags: [mapreduce]
keywords: mapreduce
---


今天在开发 mapreduce 程序的过程中，为了快速开发，程序的整体框架是从别的业务复制过来的，自己增加一些数据处理逻辑以及环境的参数配置。接着就遇到问题，在本地本机测试的时候，Job 作业无法启动，总是抛出异常，然后进程退出。本机系统为 Windows 7 X64。

异常错误信息简略如下：

```
Exit code: 1
Exception message: /bin/bash: line 0: fg: no job control
```

本文记录这个现象以及解决方案。


<!-- more -->


# 问题出现


在本地本机启动 Job 时无法正常运行作业，直接抛出异常后退出进程，完整错误信息如下：

```
Diagnostics: Exception from container-launch.
Container id: container_e18_1550055564059_0152_02_000001
Exit code: 1
Exception message: /bin/bash: line 0: fg: no job control

Stack trace: ExitCodeException exitCode=1: /bin/bash: line 0: fg: no job control

	at org.apache.hadoop.util.Shell.runCommand(Shell.java:576)
	at org.apache.hadoop.util.Shell.run(Shell.java:487)
	at org.apache.hadoop.util.Shell$ShellCommandExecutor.execute(Shell.java:753)
	at org.apache.hadoop.yarn.server.nodemanager.DefaultContainerExecutor.launchContainer(DefaultContainerExecutor.java:212)
	at org.apache.hadoop.yarn.server.nodemanager.containermanager.launcher.ContainerLaunch.call(ContainerLaunch.java:303)
	at org.apache.hadoop.yarn.server.nodemanager.containermanager.launcher.ContainerLaunch.call(ContainerLaunch.java:82)
	at java.util.concurrent.FutureTask.run(FutureTask.java:266)
	at java.util.concurrent.ThreadPoolExecutor.runWorker(ThreadPoolExecutor.java:1149)
	at java.util.concurrent.ThreadPoolExecutor$Worker.run(ThreadPoolExecutor.java:624)
	at java.lang.Thread.run(Thread.java:748)


Container exited with a non-zero exit code 1
Failing this attempt. Failing the application.
2019-04-22_22:46:04 [main] INFO mapreduce.Job:1385: Counters: 0
```

其中的重点在于：**Exception message: /bin/bash: line 0: fg: no job control**，由于我不了解这种错误，只能靠搜索引擎解决了。


# 问题解决


问题解决很容易，在 Job 的配置中增加一项：mapreduce.app-submission.cross-platform，取值为 true，截取代码片段如下：

```
Configuration conf = job.getConfiguration();
conf.set("mapreduce.job.running.map.limit", "50");
// 本机环境测试加上配置,否则会抛出异常退出:ExitCodeException: /bin/bash: line 0: fg: no job control
conf.set("mapreduce.app-submission.cross-platform", "true");
```

这个配置的含义就是跨平台，保障 Job 作业可以在 Windows 平台顺利运行。


# 备注


参考：[stackoverflow讨论一例](https://stackoverflow.com/questions/24075669/mapreduce-job-fail-when-submitted-from-windows-machine) 。


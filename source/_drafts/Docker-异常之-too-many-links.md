---
title: Docker 异常之 too many links
id: 2020-04-13 00:31:39
date: 2020-02-15 00:31:39
updated: 2020-04-13 00:31:39
categories:
tags:
keywords:
---


2020021501
基础技术知识
Docker,Kubernetes



这周日常发布时，遇到一个关于 `Docker` 的问题，在周末时间总结一下。事情是这样的：通过 `Kubernetes` 来发布项目时，在**镜像打包及推送**过程中出现异常，`xx/checksum_type: too many links`，导致发布流程中断，而在以前是没有遇到过这个问题的。

重试了几次之后，发现部分项目可以发布成功，而仍旧有几个无法发布成功，通过对比观察，发现发布失败的项目都是分配在某一台机器上面执行**镜像打包及推送**，所以可以推测这台机器的 `Docker` 环境有问题。下面就记录一下排查过程以及总结。


<!-- more -->



# 问题出现

从


```
+ ...
Sending build context to Docker daemon 16.23 GB
Step 1/13 : FROM centos:centos6.9
 ---> 2199b8eb8390
Step 2/13 : ENV LANG en_US.UTF-8
 ---> Using cache
 ---> 5993d85467de
Step 3/13 : ENV LANGUAGE en_US:en
 ---> Using cache
 ---> 8f883870be1e
Step 4/13 : RUN cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
 ---> Using cache
 ---> 8dd3e0434327
Step 5/13 : ENV JDK_VERSION 1.8.0_161
 ---> Using cache
 ---> 85e1d45fc6bb
Step 6/13 : ENV JDK_DOWNLOAD_URL http://xxx.yyy.com/rpms/RPMS/jdk-8u161-linux-x64.tar.gz
 ---> Using cache
 ---> 50154232528f
Step 7/13 : RUN yum install -y wget   && wget -q $JDK_DOWNLOAD_URL -O /jdk-$JDK_VERSION.tar.gz   && tar zxf /jdk-$JDK_VERSION.tar.gz -C /   && chown root:root -R /jdk$JDK_VERSION   && mkdir -p /opt/package   && ln -s /jdk$JDK_VERSION /opt/package/jdk1.8   && rm -f /jdk-$JDK_VERSION.tar.gz
 ---> Using cache
 ---> 32f265317b78
Step 8/13 : RUN useradd dota
 ---> Using cache
 ---> ce75719174b0
Step 9/13 : ADD __jenkins_workspace.tar.gz /workspace/
link /cloud/data2/docker/overlay/26c56abde73e41e94e0fe5fab13f72c165f93ed0d52ae95bc61b377b55f7dfce/root/var/lib/yum/yumdb/m/c76341d742e3092e98eba8b9b446332aa982c779-module-init-tools-3.9-26.el6-x86_64/checksum_type /cloud/data2/docker/overlay/5e5c44bd0ab018579bcd9bcecc610fff8f3bda34caa323a3f8460c5a0ea76907/tmproot107212046/var/lib/yum/yumdb/m/c76341d742e3092e98eba8b9b446332aa982c779-module-init-tools-3.9-26.el6-x86_64/checksum_type: too many links
script returned exit code 1
```

图。。


# 问题排查

从

# 问题解决


这个问题类似，可以参考：https://www.ffutop.com/posts/2019-08-20-too-many-links/ 。


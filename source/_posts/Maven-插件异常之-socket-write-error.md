---
title: Maven 插件异常之 socket write error
id: 2019011101
date: 2019-01-11 22:09:10
updated: 2019-01-12 22:09:10
categories: 基础技术知识
tags: [Maven,deploy]
keywords: Maven,deploy,socket write error
---


今天在整理代码的时候，在本机（自己的电脑）通过 Maven 的 deploy 插件（org.apache.maven.plugins:maven-deploy-plugin:2.7）进行发布，把代码打包成构件发布到远程的 Maven 仓库（公司的私服），这样方便大家调用。可是，其中有一个项目发布不了（其它类似的2个项目都可以，排除了环境的原因），总是报错：
````java
Failed to deploy artifacts: Could not transfer artifact xxx.yyy.zzz:dt-x-y-z:jar:0.0.6-20190112.081518-1 from/to snapshots (http://maven.myself.com/nexus/content/repositories/snapshots): Connection reset by peer: socket write error
````
以上错误日志中的项目名称、包名称均被替换。本文就记录从发现问题到解决问题的过程。环境所使用的 Maven 版本为：3.5.0。


<!-- more -->


# 问题出现


对一个公共项目进行打包发布，部署到公司私服（已经排除环境因素），出现异常；

使用命令 Maven：
````bash
mvn deploy
````

出现异常：

````java
[INFO] ------------------------------------------------------------------------
[INFO] BUILD FAILURE
[INFO] ------------------------------------------------------------------------
[INFO] Total time: 02:49 min
[INFO] Finished at: 2019-01-12T16:17:21+08:00
[INFO] Final Memory: 68M/1253M
[INFO] ------------------------------------------------------------------------
[ERROR] Failed to execute goal org.apache.maven.plugins:maven-deploy-plugin:2.7:deploy (default-deploy) on project dt-x-y-z: Failed to deploy artifacts: Could not transfer artifact xxx.yyy.zzz:dt-x-y-z:jar:0.0.6-20190112.081518-1 from/to snapshots (http://maven.myself.com/nexus/content/repositories/snapshots): Connection reset by peer: socket write error -> [Help 1]
[ERROR]
[ERROR] To see the full stack trace of the errors, re-run Maven with the -e switch.
[ERROR] Re-run Maven using the -X switch to enable full debug logging.
[ERROR]
[ERROR] For more information about the errors and possible solutions, please read the following articles:
[ERROR] [Help 1] http://cwiki.apache.org/confluence/display/MAVEN/MojoExecutionException
````

如果使用 -X 参数（完整命令：mvn deploy -X），可以稍微看到更详细的 Maven 部署日志信息：

````java
[INFO] ------------------------------------------------------------------------
[INFO] BUILD FAILURE
[INFO] ------------------------------------------------------------------------
[INFO] Total time: 02:49 min
[INFO] Finished at: 2019-01-12T16:17:21+08:00
[INFO] Final Memory: 68M/1253M
[INFO] ------------------------------------------------------------------------
[ERROR] Failed to execute goal org.apache.maven.plugins:maven-deploy-plugin:2.7:deploy (default-deploy) on project dt-x-y-z: Failed to deploy artifacts: Could not transfer artifact xxx.yyy.zzz:dt-x-y-z:jar:0.0.6-20190112.081518-1 from/to snapshots (http://maven.myself.com/nexus/content/repositories/snapshots): Connection reset by peer: socket write error -> [Help 1]
org.apache.maven.lifecycle.LifecycleExecutionException: Failed to execute goal org.apache.maven.plugins:maven-deploy-plugin:2.7:deploy (default-deploy) on project dt-x-y-z: Failed to deploy artifacts: Could not transfer artifact xxx.yyy.zzz:dt-x-y-z:jar:0.0.6-20190112.081518-1 from/to snapshots (http://maven.myself.com/nexus/content/repositories/snapshots): Connection reset by peer: socket write error
        at org.apache.maven.lifecycle.internal.MojoExecutor.execute(MojoExecutor.java:213)
        at org.apache.maven.lifecycle.internal.MojoExecutor.execute(MojoExecutor.java:154)
        at org.apache.maven.lifecycle.internal.MojoExecutor.execute(MojoExecutor.java:146)
        at org.apache.maven.lifecycle.internal.LifecycleModuleBuilder.buildProject(LifecycleModuleBuilder.java:117)
        at org.apache.maven.lifecycle.internal.LifecycleModuleBuilder.buildProject(LifecycleModuleBuilder.java:81)
        at org.apache.maven.lifecycle.internal.builder.singlethreaded.SingleThreadedBuilder.build(SingleThreadedBuilder.java:51)
        at org.apache.maven.lifecycle.internal.LifecycleStarter.execute(LifecycleStarter.java:128)
        at org.apache.maven.DefaultMaven.doExecute(DefaultMaven.java:309)
        at org.apache.maven.DefaultMaven.doExecute(DefaultMaven.java:194)
        at org.apache.maven.DefaultMaven.execute(DefaultMaven.java:107)
        at org.apache.maven.cli.MavenCli.execute(MavenCli.java:993)
        at org.apache.maven.cli.MavenCli.doMain(MavenCli.java:345)
        at org.apache.maven.cli.MavenCli.main(MavenCli.java:191)
        at sun.reflect.NativeMethodAccessorImpl.invoke0(Native Method)
        at sun.reflect.NativeMethodAccessorImpl.invoke(NativeMethodAccessorImpl.java:62)
        at sun.reflect.DelegatingMethodAccessorImpl.invoke(DelegatingMethodAccessorImpl.java:43)
        at java.lang.reflect.Method.invoke(Method.java:498)
        at org.codehaus.plexus.classworlds.launcher.Launcher.launchEnhanced(Launcher.java:289)
        at org.codehaus.plexus.classworlds.launcher.Launcher.launch(Launcher.java:229)
        at org.codehaus.plexus.classworlds.launcher.Launcher.mainWithExitCode(Launcher.java:415)
        at org.codehaus.plexus.classworlds.launcher.Launcher.main(Launcher.java:356)
Caused by: org.apache.maven.plugin.MojoExecutionException: Failed to deploy artifacts: Could not transfer artifact xxx.yyy.zzz:dt-x-y-z:jar:0.0.6-20190112.081518-1 from/to snapshots (http://maven.myself.com/nexus/content/repositories/snapshots): Connection reset by peer: socket write error
        at org.apache.maven.plugin.deploy.DeployMojo.execute(DeployMojo.java:193)
        at org.apache.maven.plugin.DefaultBuildPluginManager.executeMojo(DefaultBuildPluginManager.java:134)
        at org.apache.maven.lifecycle.internal.MojoExecutor.execute(MojoExecutor.java:208)
        ... 20 more
Caused by: org.apache.maven.artifact.deployer.ArtifactDeploymentException: Failed to deploy artifacts: Could not transfer artifact xxx.yyy.zzz:dt-x-y-z:jar:0.0.6-20190112.081518-1 from/to snapshots (http://maven.myself.com/nexus/content/repositories/snapshots): Connection reset by peer: socket write error
        at org.apache.maven.artifact.deployer.DefaultArtifactDeployer.deploy(DefaultArtifactDeployer.java:143)
        at org.apache.maven.plugin.deploy.AbstractDeployMojo.deploy(AbstractDeployMojo.java:167)
        at org.apache.maven.plugin.deploy.DeployMojo.execute(DeployMojo.java:157)
        ... 22 more
Caused by: org.eclipse.aether.deployment.DeploymentException: Failed to deploy artifacts: Could not transfer artifact xxx.yyy.zzz:dt-x-y-z:jar:0.0.6-20190112.081518-1 from/to snapshots (http://maven.myself.com/nexus/content/repositories/snapshots): Connection reset by peer: socket write error
        at org.eclipse.aether.internal.impl.DefaultDeployer.deploy(DefaultDeployer.java:326)
        at org.eclipse.aether.internal.impl.DefaultDeployer.deploy(DefaultDeployer.java:254)
        at org.eclipse.aether.internal.impl.DefaultRepositorySystem.deploy(DefaultRepositorySystem.java:422)
        at org.apache.maven.artifact.deployer.DefaultArtifactDeployer.deploy(DefaultArtifactDeployer.java:139)
        ... 24 more
Caused by: org.eclipse.aether.transfer.ArtifactTransferException: Could not transfer artifact xxx.yyy.zzz:dt-x-y-z:jar:0.0.6-20190112.081518-1 from/to snapshots (http://maven.myself.com/nexus/content/repositories/snapshots): Connection reset by peer: socket write error
        at org.eclipse.aether.connector.basic.ArtifactTransportListener.transferFailed(ArtifactTransportListener.java:52)
        at org.eclipse.aether.connector.basic.BasicRepositoryConnector$TaskRunner.run(BasicRepositoryConnector.java:364)
        at org.eclipse.aether.connector.basic.BasicRepositoryConnector.put(BasicRepositoryConnector.java:283)
        at org.eclipse.aether.internal.impl.DefaultDeployer.deploy(DefaultDeployer.java:320)
        ... 27 more
Caused by: org.apache.maven.wagon.TransferFailedException: Connection reset by peer: socket write error
        at org.apache.maven.wagon.providers.http.AbstractHttpClientWagon.put(AbstractHttpClientWagon.java:650)
        at org.apache.maven.wagon.providers.http.AbstractHttpClientWagon.put(AbstractHttpClientWagon.java:553)
        at org.apache.maven.wagon.providers.http.AbstractHttpClientWagon.put(AbstractHttpClientWagon.java:535)
        at org.apache.maven.wagon.providers.http.AbstractHttpClientWagon.put(AbstractHttpClientWagon.java:529)
        at org.apache.maven.wagon.providers.http.AbstractHttpClientWagon.put(AbstractHttpClientWagon.java:509)
        at org.eclipse.aether.transport.wagon.WagonTransporter$PutTaskRunner.run(WagonTransporter.java:653)
        at org.eclipse.aether.transport.wagon.WagonTransporter.execute(WagonTransporter.java:436)
        at org.eclipse.aether.transport.wagon.WagonTransporter.put(WagonTransporter.java:419)
        at org.eclipse.aether.connector.basic.BasicRepositoryConnector$PutTaskRunner.runTask(BasicRepositoryConnector.java:519)
        at org.eclipse.aether.connector.basic.BasicRepositoryConnector$TaskRunner.run(BasicRepositoryConnector.java:359)
        ... 29 more
Caused by: java.net.SocketException: Connection reset by peer: socket write error
        at java.net.SocketOutputStream.socketWrite0(Native Method)
        at java.net.SocketOutputStream.socketWrite(SocketOutputStream.java:111)
        at java.net.SocketOutputStream.write(SocketOutputStream.java:155)
        at org.apache.maven.wagon.providers.http.httpclient.impl.io.SessionOutputBufferImpl.streamWrite(SessionOutputBufferImpl.java:126)
        at org.apache.maven.wagon.providers.http.httpclient.impl.io.SessionOutputBufferImpl.flushBuffer(SessionOutputBufferImpl.java:138)
        at org.apache.maven.wagon.providers.http.httpclient.impl.io.SessionOutputBufferImpl.write(SessionOutputBufferImpl.java:169)
        at org.apache.maven.wagon.providers.http.httpclient.impl.io.ContentLengthOutputStream.write(ContentLengthOutputStream.java:115)
        at org.apache.maven.wagon.providers.http.AbstractHttpClientWagon$RequestEntityImplementation.writeTo(AbstractHttpClientWagon.java:209)
        at org.apache.maven.wagon.providers.http.httpclient.impl.DefaultBHttpClientConnection.sendRequestEntity(DefaultBHttpClientConnection.java:158)
        at org.apache.maven.wagon.providers.http.httpclient.impl.conn.CPoolProxy.sendRequestEntity(CPoolProxy.java:162)
        at org.apache.maven.wagon.providers.http.httpclient.protocol.HttpRequestExecutor.doSendRequest(HttpRequestExecutor.java:237)
        at org.apache.maven.wagon.providers.http.httpclient.protocol.HttpRequestExecutor.execute(HttpRequestExecutor.java:122)
        at org.apache.maven.wagon.providers.http.httpclient.impl.execchain.MainClientExec.execute(MainClientExec.java:271)
        at org.apache.maven.wagon.providers.http.httpclient.impl.execchain.ProtocolExec.execute(ProtocolExec.java:184)
        at org.apache.maven.wagon.providers.http.httpclient.impl.execchain.RetryExec.execute(RetryExec.java:88)
        at org.apache.maven.wagon.providers.http.httpclient.impl.execchain.RedirectExec.execute(RedirectExec.java:110)
        at org.apache.maven.wagon.providers.http.httpclient.impl.client.InternalHttpClient.doExecute(InternalHttpClient.java:184)
        at org.apache.maven.wagon.providers.http.httpclient.impl.client.CloseableHttpClient.execute(CloseableHttpClient.java:82)
        at org.apache.maven.wagon.providers.http.AbstractHttpClientWagon.execute(AbstractHttpClientWagon.java:834)
        at org.apache.maven.wagon.providers.http.AbstractHttpClientWagon.put(AbstractHttpClientWagon.java:596)
        ... 38 more
[ERROR]
[ERROR]
[ERROR] For more information about the errors and possible solutions, please read the following articles:
[ERROR] [Help 1] http://cwiki.apache.org/confluence/display/MAVEN/MojoExecutionException
````

由于对 Maven 构件的原理不清楚，通过日志报错也看不出根本原因是什么，根据最后一行日志的链接：[http://cwiki.apache.org/confluence/display/MAVEN/MojoExecutionException](http://cwiki.apache.org/confluence/display/MAVEN/MojoExecutionException) ，我看到描述：
````bash
Unlike many other errors, this exception is not generated by the Maven core itself but by a plugin. As a rule of thumb, plugins use this error to signal a problem in their configuration or the information they retrieved from the POM.

The concrete meaning of the exception depends on the plugin so please have a look at its documentation. The documentation for many common Maven plugins can be reached via our plugin index.
````

大致意思也就是说这种类型的错误一般不是 Maven 的问题，而是所使用的 Maven 构件的问题，在这里我使用了 deploy 构件，我也知道和 deploy 构件有关，但是具体原因是什么也没说明；

于是接下来使用 -e 参数（完整命令：mvn deploy -e），除了上述的报错日志外，还可以打印更为详细的错误日志追踪信息，然后发现一直会有下面的错误输入，而且一直重复，没有要停的迹象，我只能手动停掉 mvn 进程：

````java
java.lang.IllegalArgumentException: progressed file size cannot be greater than size: 59156480 > 58029604
````

异常图

换算一下单位：
59156480KB=56.42M（正是需要发布的构件的大小）；
58029604KB=55.34M；

1、通过搜索引擎对异常信息的搜索，大部分结果显示和 Maven 后台的 Web 服务有关，如果使用的是 Nginx，会有一个参数用来限制上传文件的大小，上传文件的大小超过最大限制，就会上传失败，并且抛出异常。我部署其它的小构件没有问题，怀疑是这个原因，于是我询问运维人员公司的 Maven 私服对上传的公共构件有没有大小限制（即 Nginx 服务有没有限制上传文件的大小），运维说不会。但是我还是怀疑，于是想通过 Web 端的界面来手动上传我的构件，发现 Web 端的界面没有开放，无法完成上传操作，接下来我就想看看 Maven 后台服务的对应参数配置的值是多大（也可能使用的是默认值），但是不知道后台采用的是什么服务（Nginx 还是 Netty 不确定），先放弃这条路；

2、也有结果显示是 Maven 的版本问题，有些版本有 bug，所以造成了这个问题。


# 问题解决


既然没有分析出来具体的原因，只能尝试每一种解决方案了。

1、既然怀疑是 Maven 私服限制了构件的大小，那就想办法减小构件。先在本地 install，然后去本地仓库看一下生成的构件的大小，结果我惊讶地发现构件居然有330M 之大，吓死人了，这个打包发布配置肯定有问题，肯定把第三方依赖全部打进去了。我查看了以前生成的正常的构件，也就60M 左右。

对比图2个

这一看就是把第三方各种依赖包都一起发布了，才会造成构件有这么大，于是更改 pom.xml 文件，把第三方依赖去除，deploy 的时候是不需要的，同时也删除了一些 resources 资源文件夹里面的文本文件，删除时发现文本文件竟然有几十 M，怪不得以前发布的构件大小有60M 左右，原来都是文本文件在占用空间；

更新了之后，直接重新 deploy，不报错了，直接 deploy 成功，去仓库搜索查看；

仓库图一张

2、问题使用方法一已经解决了，也就是和 Maven 版本没有关系了，而且，在我的当前 Maven 环境下，我去 deploy 其它构件也是成功的，不会有任务报错，所以也从侧面反映了这个问题和 Mave 版本无关，和 Maven 环境也无关；


# 问题总结


参考：[http://cwiki.apache.org/confluence/display/MAVEN/MojoExecutionException](http://cwiki.apache.org/confluence/display/MAVEN/MojoExecutionException) ；

apache 的官方 jira：
[http://mail-archives.apache.org/mod_mbox/maven-issues/201808.mbox/%3CJIRA.13182024.1535592594000.205524.1535738700211@Atlassian.JIRA%3E](http://mail-archives.apache.org/mod_mbox/maven-issues/201808.mbox/%3CJIRA.13182024.1535592594000.205524.1535738700211@Atlassian.JIRA%3E) ；

[https://issues.apache.org/jira/browse/MNG-6469?page=com.atlassian.jira.plugin.system.issuetabpanels%3Aall-tabpanel](https://issues.apache.org/jira/browse/MNG-6469?page=com.atlassian.jira.plugin.system.issuetabpanels%3Aall-tabpanel) ；

这个问题去网上搜索不到资料，很痛苦，问人也没有能帮到我的，只能自己去慢慢摸索试验，整个过程比较艰难；


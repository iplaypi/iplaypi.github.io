---
title: HBase 错误之 NoClassDefFoundError：ProtobufUtil
id: 2019-09-30 20:34:04
date: 2019-09-30 20:34:04
updated: 2019-09-30 20:34:04
categories:
tags:
keywords:
---

HBase 错误之 NoClassDefFoundError：ProtobufUtil
2019093001
HBase,Zookeeper,Hadoop


背景说明：通过 `dubbo` 部署一个服务，服务中的业务逻辑会查询 `HBase` 表的数据，但是 `dubbo` 服务在注册时，`HBase` 初始化的过程中会报错：

```
java.lang.NoClassDefFoundError: Could not initialize class org.apache.hadoop.hbase.protobuf.ProtobufUtil
```

本文涉及的开发环境，基于 `HBase v1.1.2`、`Zookeeper v3.4.6`、`dubbo v2.8.4`、`Hadoop v2.7.1`。


<!-- more -->


# 问题出现


通过 `k8s` 多节点发布服务，但是只有在某一台机器上面出现错误，发布后 `dubbo` 服务注册时出现的错误如下：

```
2019-09-19_18:03:49 [http-nio-28956-exec-2-SendThread(192.168.20.101:2181)] INFO zookeeper.ClientCnxn:852: Socket connection established to 192.168.20.101/192.168.20.101:2181, initiating session
2019-09-19_18:03:49 [http-nio-28956-exec-2-SendThread(192.168.20.101:2181)] INFO zookeeper.ClientCnxn:1235: Session establishment complete on server 192.168.20.101/192.168.20.101:2181, sessionid = 0x36af032f505e830, negotiated timeout = 90000
2019-09-19_18:03:50 [http-nio-28956-exec-2] WARN hdfs.DFSUtil:689: Namenode for hdfs-cluster remains unresolved for ID nn1.  Check your hdfs-site.xml file to ensure namenodes are configured properly.
2019-09-19_18:03:50 [http-nio-28956-exec-9] ERROR filter.ExceptionFilter:87:  [DUBBO] Got unchecked and undeclared exception which called by 10.200.0.2. service: com.yyy.zzz.service.es.weibo.IXxxService, method: search, exception: java.lang.NoClassDefFoundError: Could not initialize class org.apache.hadoop.hbase.protobuf.ProtobufUtil, dubbo version: 2.8.4, current host: 127.0.0.1
java.lang.NoClassDefFoundError: Could not initialize class org.apache.hadoop.hbase.protobuf.ProtobufUtil
	at org.apache.hadoop.hbase.zookeeper.MetaTableLocator.getMetaRegionState(MetaTableLocator.java:482)
	at org.apache.hadoop.hbase.zookeeper.MetaTableLocator.getMetaRegionLocation(MetaTableLocator.java:167)
	at org.apache.hadoop.hbase.zookeeper.MetaTableLocator.blockUntilAvailable(MetaTableLocator.java:598)
	at org.apache.hadoop.hbase.zookeeper.MetaTableLocator.blockUntilAvailable(MetaTableLocator.java:579)
	at org.apache.hadoop.hbase.zookeeper.MetaTableLocator.blockUntilAvailable(MetaTableLocator.java:558)
	at org.apache.hadoop.hbase.client.ZooKeeperRegistry.getMetaRegionLocation(ZooKeeperRegistry.java:61)
	at org.apache.hadoop.hbase.client.ConnectionManager$HConnectionImplementation.locateMeta(ConnectionManager.java:1192)
	at org.apache.hadoop.hbase.client.ConnectionManager$HConnectionImplementation.locateRegion(ConnectionManager.java:1159)
	at org.apache.hadoop.hbase.client.ConnectionManager$HConnectionImplementation.relocateRegion(ConnectionManager.java:1133)
	at org.apache.hadoop.hbase.client.ConnectionManager$HConnectionImplementation.locateRegionInMeta(ConnectionManager.java:1338)
	at org.apache.hadoop.hbase.client.ConnectionManager$HConnectionImplementation.locateRegion(ConnectionManager.java:1162)
	at org.apache.hadoop.hbase.client.AsyncProcess$AsyncRequestFutureImpl.findAllLocationsOrFail(AsyncProcess.java:940)
	at org.apache.hadoop.hbase.client.AsyncProcess$AsyncRequestFutureImpl.groupAndSendMultiAction(AsyncProcess.java:857)
	at org.apache.hadoop.hbase.client.AsyncProcess$AsyncRequestFutureImpl.access$100(AsyncProcess.java:575)
	at org.apache.hadoop.hbase.client.AsyncProcess.submitAll(AsyncProcess.java:557)
	at org.apache.hadoop.hbase.client.HTable.batch(HTable.java:933)
	at org.apache.hadoop.hbase.client.HTable.batch(HTable.java:950)
	at org.apache.hadoop.hbase.client.HTable.get(HTable.java:911)
	at com.yyy.zzz.commons.search.reader.hbase.BaseHBaseReader.batchGet(BaseHBaseReader.java:94)
	at com.yyy.zzz.commons.search.reader.hbase.weibo.WeiboContentHbaseReader.batchGet(WeiboContentHbaseReader.java:98)
	at com.yyy.zzz.commons.search.searcher.AbstractBaseSearcher.getContent(AbstractBaseSearcher.java:269)
	at com.yyy.zzz.commons.search.searcher.AbstractBaseSearcher.getInfo(AbstractBaseSearcher.java:188)
	at com.yyy.zzz.runner.search.BaseSearchRunner.search(BaseSearchRunner.java:89)
	at com.yyy.zzz.api.weibo.WeiboContentServiceImpl.search(WeiboContentServiceImpl.java:33)
	at com.alibaba.dubbo.common.bytecode.Wrapper3.invokeMethod(Wrapper3.java)
	at com.alibaba.dubbo.rpc.proxy.javassist.JavassistProxyFactory$1.doInvoke(JavassistProxyFactory.java:46)
	at com.alibaba.dubbo.rpc.proxy.AbstractProxyInvoker.invoke(AbstractProxyInvoker.java:72)
	at com.alibaba.dubbo.rpc.protocol.InvokerWrapper.invoke(InvokerWrapper.java:53)
	at com.alibaba.dubbo.rpc.filter.ExceptionFilter.invoke(ExceptionFilter.java:64)
	at com.alibaba.dubbo.rpc.protocol.ProtocolFilterWrapper$1.invoke(ProtocolFilterWrapper.java:91)
	at com.alibaba.dubbo.monitor.support.MonitorFilter.invoke(MonitorFilter.java:75)
	at com.alibaba.dubbo.rpc.protocol.ProtocolFilterWrapper$1.invoke(ProtocolFilterWrapper.java:91)
	at com.alibaba.dubbo.rpc.filter.TimeoutFilter.invoke(TimeoutFilter.java:42)
	at com.alibaba.dubbo.rpc.protocol.ProtocolFilterWrapper$1.invoke(ProtocolFilterWrapper.java:91)
	at com.alibaba.dubbo.rpc.protocol.dubbo.filter.TraceFilter.invoke(TraceFilter.java:78)
	at com.alibaba.dubbo.rpc.protocol.ProtocolFilterWrapper$1.invoke(ProtocolFilterWrapper.java:91)
	at com.alibaba.dubbo.rpc.filter.ContextFilter.invoke(ContextFilter.java:70)
	at com.alibaba.dubbo.rpc.protocol.ProtocolFilterWrapper$1.invoke(ProtocolFilterWrapper.java:91)
	at com.alibaba.dubbo.rpc.filter.GenericFilter.invoke(GenericFilter.java:132)
	at com.alibaba.dubbo.rpc.protocol.ProtocolFilterWrapper$1.invoke(ProtocolFilterWrapper.java:91)
	at com.alibaba.dubbo.rpc.filter.ClassLoaderFilter.invoke(ClassLoaderFilter.java:38)
	at com.alibaba.dubbo.rpc.protocol.ProtocolFilterWrapper$1.invoke(ProtocolFilterWrapper.java:91)
	at com.alibaba.dubbo.rpc.filter.EchoFilter.invoke(EchoFilter.java:38)
	at com.alibaba.dubbo.rpc.protocol.ProtocolFilterWrapper$1.invoke(ProtocolFilterWrapper.java:91)
	at com.alibaba.dubbo.rpc.proxy.InvokerInvocationHandler.invoke(InvokerInvocationHandler.java:52)
	at com.alibaba.dubbo.common.bytecode.proxy1.search(proxy1.java)
	at sun.reflect.NativeMethodAccessorImpl.invoke0(Native Method)
	at sun.reflect.NativeMethodAccessorImpl.invoke(NativeMethodAccessorImpl.java:62)
	at sun.reflect.DelegatingMethodAccessorImpl.invoke(DelegatingMethodAccessorImpl.java:43)
	at java.lang.reflect.Method.invoke(Method.java:498)
	at org.jboss.resteasy.core.MethodInjectorImpl.invoke(MethodInjectorImpl.java:137)
	at org.jboss.resteasy.core.ResourceMethodInvoker.invokeOnTarget(ResourceMethodInvoker.java:288)
	at org.jboss.resteasy.core.ResourceMethodInvoker.invoke(ResourceMethodInvoker.java:242)
	at org.jboss.resteasy.core.ResourceMethodInvoker.invoke(ResourceMethodInvoker.java:229)
	at org.jboss.resteasy.core.SynchronousDispatcher.invoke(SynchronousDispatcher.java:356)
	at org.jboss.resteasy.core.SynchronousDispatcher.invoke(SynchronousDispatcher.java:179)
	at org.jboss.resteasy.plugins.server.servlet.ServletContainerDispatcher.service(ServletContainerDispatcher.java:220)
	at org.jboss.resteasy.plugins.server.servlet.HttpServletDispatcher.service(HttpServletDispatcher.java:56)
	at org.jboss.resteasy.plugins.server.servlet.HttpServletDispatcher.service(HttpServletDispatcher.java:51)
	at javax.servlet.http.HttpServlet.service(HttpServlet.java:790)
	at com.alibaba.dubbo.rpc.protocol.rest.DubboHttpServer$RestHandler.handle(DubboHttpServer.java:86)
	at com.alibaba.dubbo.remoting.http.servlet.DispatcherServlet.service(DispatcherServlet.java:64)
	at javax.servlet.http.HttpServlet.service(HttpServlet.java:790)
	at org.apache.catalina.core.ApplicationFilterChain.internalDoFilter(ApplicationFilterChain.java:291)
	at org.apache.catalina.core.ApplicationFilterChain.doFilter(ApplicationFilterChain.java:206)
	at org.apache.catalina.core.StandardWrapperValve.invoke(StandardWrapperValve.java:219)
	at org.apache.catalina.core.StandardContextValve.invoke(StandardContextValve.java:106)
	at org.apache.catalina.authenticator.AuthenticatorBase.invoke(AuthenticatorBase.java:504)
	at org.apache.catalina.core.StandardHostValve.invoke(StandardHostValve.java:142)
	at org.apache.catalina.valves.ErrorReportValve.invoke(ErrorReportValve.java:79)
	at org.apache.catalina.core.StandardEngineValve.invoke(StandardEngineValve.java:88)
	at org.apache.catalina.connector.CoyoteAdapter.service(CoyoteAdapter.java:534)
	at org.apache.coyote.http11.AbstractHttp11Processor.process(AbstractHttp11Processor.java:1081)
	at org.apache.coyote.AbstractProtocol$AbstractConnectionHandler.process(AbstractProtocol.java:658)
	at org.apache.coyote.http11.Http11NioProtocol$Http11ConnectionHandler.process(Http11NioProtocol.java:222)
	at org.apache.tomcat.util.net.NioEndpoint$SocketProcessor.doRun(NioEndpoint.java:1566)
	at org.apache.tomcat.util.net.NioEndpoint$SocketProcessor.run(NioEndpoint.java:1523)
	at java.util.concurrent.ThreadPoolExecutor.runWorker(ThreadPoolExecutor.java:1149)
	at java.util.concurrent.ThreadPoolExecutor$Worker.run(ThreadPoolExecutor.java:624)
	at org.apache.tomcat.util.threads.TaskThread$WrappingRunnable.run(TaskThread.java:61)
	at java.lang.Thread.run(Thread.java:748)
```

注意查看重点内容：

```
2019-09-19_18:03:50 [http-nio-28956-exec-2] WARN hdfs.DFSUtil:689: Namenode for hdfs-cluster remains unresolved for ID nn1.  Check your hdfs-site.xml file to ensure namenodes are configured properly.
java.lang.NoClassDefFoundError: Could not initialize class org.apache.hadoop.hbase.protobuf.ProtobufUtil

```

第一行是 `hdfs` 无法解析 `HA` 的域名，应该是系统环境问题；第二行是 `HBase` 初始化环境失败，看起来像是缺失依赖包或者依赖包冲突。

同时还出现了未知主机名错误：

```
com.yyy.zzz.exception.es.EsConnException: java.net.UnknownHostException: host40: Temporary failure in name resolution
	at com.yyy.zzz.commons.infrastructure.client.EsClient.<init>(EsClient.java:46)
	at com.yyy.zzz.commons.infrastructure.client.EsClient.getInstance(EsClient.java:57)
	at com.yyy.zzz.commons.search.searcher.AbstractBaseSearcher.<init>(AbstractBaseSearcher.java:69)
	at com.yyy.zzz.commons.search.searcher.weibo.WeiboContentSearcher.<init>(WeiboContentSearcher.java:14)
	at com.yyy.zzz.commons.search.searcher.weibo.WeiboContentSearcher.getInstance(WeiboContentSearcher.java:22)
	at com.yyy.zzz.runner.search.weibo.WeiboContentSearchRunner.<init>(WeiboContentSearchRunner.java:26)
	at com.yyy.zzz.runner.search.weibo.WeiboContentSearchRunner.<init>(WeiboContentSearchRunner.java:20)
	at com.yyy.zzz.api.weibo.WeiboContentServiceImpl.search(WeiboContentServiceImpl.java:32)
	at com.alibaba.dubbo.common.bytecode.Wrapper3.invokeMethod(Wrapper3.java)
	at com.alibaba.dubbo.rpc.proxy.javassist.JavassistProxyFactory$1.doInvoke(JavassistProxyFactory.java:46)
	at com.alibaba.dubbo.rpc.proxy.AbstractProxyInvoker.invoke(AbstractProxyInvoker.java:72)
	at com.alibaba.dubbo.rpc.protocol.InvokerWrapper.invoke(InvokerWrapper.java:53)
	at com.alibaba.dubbo.rpc.filter.ExceptionFilter.invoke(ExceptionFilter.java:64)
	at com.alibaba.dubbo.rpc.protocol.ProtocolFilterWrapper$1.invoke(ProtocolFilterWrapper.java:91)
	at com.alibaba.dubbo.monitor.support.MonitorFilter.invoke(MonitorFilter.java:75)
	at com.alibaba.dubbo.rpc.protocol.ProtocolFilterWrapper$1.invoke(ProtocolFilterWrapper.java:91)
	at com.alibaba.dubbo.rpc.filter.TimeoutFilter.invoke(TimeoutFilter.java:42)
	at com.alibaba.dubbo.rpc.protocol.ProtocolFilterWrapper$1.invoke(ProtocolFilterWrapper.java:91)
	at com.alibaba.dubbo.rpc.protocol.dubbo.filter.TraceFilter.invoke(TraceFilter.java:78)
	at com.alibaba.dubbo.rpc.protocol.ProtocolFilterWrapper$1.invoke(ProtocolFilterWrapper.java:91)
	at com.alibaba.dubbo.rpc.filter.ContextFilter.invoke(ContextFilter.java:70)
	at com.alibaba.dubbo.rpc.protocol.ProtocolFilterWrapper$1.invoke(ProtocolFilterWrapper.java:91)
	at com.alibaba.dubbo.rpc.filter.GenericFilter.invoke(GenericFilter.java:132)
	at com.alibaba.dubbo.rpc.protocol.ProtocolFilterWrapper$1.invoke(ProtocolFilterWrapper.java:91)
	at com.alibaba.dubbo.rpc.filter.ClassLoaderFilter.invoke(ClassLoaderFilter.java:38)
	at com.alibaba.dubbo.rpc.protocol.ProtocolFilterWrapper$1.invoke(ProtocolFilterWrapper.java:91)
	at com.alibaba.dubbo.rpc.filter.EchoFilter.invoke(EchoFilter.java:38)
	at com.alibaba.dubbo.rpc.protocol.ProtocolFilterWrapper$1.invoke(ProtocolFilterWrapper.java:91)
	at com.alibaba.dubbo.rpc.proxy.InvokerInvocationHandler.invoke(InvokerInvocationHandler.java:52)
	at com.alibaba.dubbo.common.bytecode.proxy1.search(proxy1.java)
	at sun.reflect.NativeMethodAccessorImpl.invoke0(Native Method)
	at sun.reflect.NativeMethodAccessorImpl.invoke(NativeMethodAccessorImpl.java:62)
	at sun.reflect.DelegatingMethodAccessorImpl.invoke(DelegatingMethodAccessorImpl.java:43)
	at java.lang.reflect.Method.invoke(Method.java:498)
	at org.jboss.resteasy.core.MethodInjectorImpl.invoke(MethodInjectorImpl.java:137)
	at org.jboss.resteasy.core.ResourceMethodInvoker.invokeOnTarget(ResourceMethodInvoker.java:288)
	at org.jboss.resteasy.core.ResourceMethodInvoker.invoke(ResourceMethodInvoker.java:242)
	at org.jboss.resteasy.core.ResourceMethodInvoker.invoke(ResourceMethodInvoker.java:229)
	at org.jboss.resteasy.core.SynchronousDispatcher.invoke(SynchronousDispatcher.java:356)
	at org.jboss.resteasy.core.SynchronousDispatcher.invoke(SynchronousDispatcher.java:179)
	at org.jboss.resteasy.plugins.server.servlet.ServletContainerDispatcher.service(ServletContainerDispatcher.java:220)
	at org.jboss.resteasy.plugins.server.servlet.HttpServletDispatcher.service(HttpServletDispatcher.java:56)
	at org.jboss.resteasy.plugins.server.servlet.HttpServletDispatcher.service(HttpServletDispatcher.java:51)
	at javax.servlet.http.HttpServlet.service(HttpServlet.java:790)
	at com.alibaba.dubbo.rpc.protocol.rest.DubboHttpServer$RestHandler.handle(DubboHttpServer.java:86)
	at com.alibaba.dubbo.remoting.http.servlet.DispatcherServlet.service(DispatcherServlet.java:64)
	at javax.servlet.http.HttpServlet.service(HttpServlet.java:790)
	at org.apache.catalina.core.ApplicationFilterChain.internalDoFilter(ApplicationFilterChain.java:291)
	at org.apache.catalina.core.ApplicationFilterChain.doFilter(ApplicationFilterChain.java:206)
	at org.apache.catalina.core.StandardWrapperValve.invoke(StandardWrapperValve.java:219)
	at org.apache.catalina.core.StandardContextValve.invoke(StandardContextValve.java:106)
	at org.apache.catalina.authenticator.AuthenticatorBase.invoke(AuthenticatorBase.java:504)
	at org.apache.catalina.core.StandardHostValve.invoke(StandardHostValve.java:142)
	at org.apache.catalina.valves.ErrorReportValve.invoke(ErrorReportValve.java:79)
	at org.apache.catalina.core.StandardEngineValve.invoke(StandardEngineValve.java:88)
	at org.apache.catalina.connector.CoyoteAdapter.service(CoyoteAdapter.java:534)
	at org.apache.coyote.http11.AbstractHttp11Processor.process(AbstractHttp11Processor.java:1081)
	at org.apache.coyote.AbstractProtocol$AbstractConnectionHandler.process(AbstractProtocol.java:658)
	at org.apache.coyote.http11.Http11NioProtocol$Http11ConnectionHandler.process(Http11NioProtocol.java:222)
	at org.apache.tomcat.util.net.NioEndpoint$SocketProcessor.doRun(NioEndpoint.java:1566)
	at org.apache.tomcat.util.net.NioEndpoint$SocketProcessor.run(NioEndpoint.java:1523)
	at java.util.concurrent.ThreadPoolExecutor.runWorker(ThreadPoolExecutor.java:1149)
	at java.util.concurrent.ThreadPoolExecutor$Worker.run(ThreadPoolExecutor.java:624)
	at org.apache.tomcat.util.threads.TaskThread$WrappingRunnable.run(TaskThread.java:61)
	at java.lang.Thread.run(Thread.java:748)
Caused by: java.net.UnknownHostException: host40: Temporary failure in name resolution
	at java.net.Inet6AddressImpl.lookupAllHostAddr(Native Method)
	at java.net.InetAddress$2.lookupAllHostAddr(InetAddress.java:928)
	at java.net.InetAddress.getAddressesFromNameService(InetAddress.java:1323)
	at java.net.InetAddress.getAllByName0(InetAddress.java:1276)
	at java.net.InetAddress.getAllByName(InetAddress.java:1192)
	at java.net.InetAddress.getAllByName(InetAddress.java:1126)
	at java.net.InetAddress.getByName(InetAddress.java:1076)
	at com.yyy.zzz.commons.infrastructure.client.EsClient.<init>(EsClient.java:43)
	... 64 more
```

同时，在之后的请求中，只要是转发到这个服务节点的请求，就会出现如下错误：

```
com.yyy.zzz.exception.hbase.HBaseException: java.lang.reflect.InvocationTargetException
Caused by: java.io.IOException: java.lang.reflect.InvocationTargetException
    at org.apache.hadoop.hbase.client.ConnectionFactory.createConnection(ConnectionFactory.java:240)
    at org.apache.hadoop.hbase.client.ConnectionManager.createConnection(ConnectionManager.java:433)
    at org.apache.hadoop.hbase.client.ConnectionManager.createConnection(ConnectionManager.java:426)
    at org.apache.hadoop.hbase.client.ConnectionManager.getConnectionInternal(ConnectionManager.java:304)
    at org.apache.hadoop.hbase.client.HTable.<init>(HTable.java:185)
    at org.apache.hadoop.hbase.client.HTableFactory.createHTableInterface(HTableFactory.java:41)
    ... 18 more
```

通过排查代码，这个异常是在业务逻辑代码连接 `HBase` 表取数时出现的：

```

hTableInterface.get(List<Get>)

```


# 问题排查


首先怀疑的是 `protobuf` 版本冲突问题，但是通过对比，只有一个 `jar` 包，而且其它节点没有问题，否定了这个猜测。

接着发送多次请求，查看日志，以下错误不再出现：

```
java.lang.NoClassDefFoundError: Could not initialize class org.apache.hadoop.hbase.protobuf.ProtobufUtil
com.yyy.zzz.exception.es.EsConnException: java.net.UnknownHostException: host40: Temporary failure in name resolution
```

反而出现的全部是 `HBase` 取数异常：

```
com.yyy.zzz.exception.hbase.HBaseException: java.lang.reflect.InvocationTargetException
Caused by: java.io.IOException: java.lang.reflect.InvocationTargetException
    at org.apache.hadoop.hbase.client.ConnectionFactory.createConnection(ConnectionFactory.java:240)
    at org.apache.hadoop.hbase.client.ConnectionManager.createConnection(ConnectionManager.java:433)
    at org.apache.hadoop.hbase.client.ConnectionManager.createConnection(ConnectionManager.java:426)
    at org.apache.hadoop.hbase.client.ConnectionManager.getConnectionInternal(ConnectionManager.java:304)
    at org.apache.hadoop.hbase.client.HTable.<init>(HTable.java:185)
    at org.apache.hadoop.hbase.client.HTableFactory.createHTableInterface(HTableFactory.java:41)
    ... 18 more
```

更神奇的是，只在一台节点上面有问题，其它相同功能的节点没问题。

通过运维排查，从 `NoClassDefFoundError` 以及 `UnknownHostException` 发现了异常原因：在某个时间点发布了服务，恰好此时机器负载过高，导致 `DNS` 解析异常，于是 `dubbo` 服务在注册时无法获取 `hdfs` 信息。而 `HBase` 在初始化时需要依赖 `hdfs` 上面的某个 `hbase.version` 文件【用来确定 `HBase` 的版本】，导致 `HBase` 在初始化时无法找到这个文件，也就无法确定版本，最终没有加载 `ProtobufUtil` 类文件。

`hdfs-site.xml` 配置文件中的重要内容如下，`nn1` 节点无法被识别：

```
<property>
    <name>dfs.ha.namenodes.hdfs-cluster</name>
    <value>nn1,nn2</value>
</property>
```

`hbase-site.xml` 配置文件中的重要内容如下，对于 `HBase` 来说，这个 `hdfs` 路径里面存放着重要的信息：

```
<property>
    <name>hbase.rootdir</name>
    <value>hdfs://hdfs-cluster/apps/hbase/data</value>
</property>
```

所以此后所有的请求需要连接 `HBase` 取数时，都会出现 `java.lang.reflect.InvocationTargetException` 异常。

这里会进一步引发一个严重的问题，由于 `dubbo` 服务在注册时出现问题没有退出，仍旧提供服务，但是这个服务是有问题的，每次需要连接 `HBase` 取数时都会出现异常，由于没有处理好异常，导致大量的 `Zookeeper` 连接没有关闭。

进一步导致当前机器的 `Zookeeper` 连接数接近10000个，严重影响了其它业务连接 `Zookeeper`，一律时超时重试。


# 问题解决


找到问题，就很容易解决了，重启对应的服务，观察初始化日志，一切正常。


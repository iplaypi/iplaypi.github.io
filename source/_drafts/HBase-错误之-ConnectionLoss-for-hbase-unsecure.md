---
title: HBase 错误之 ConnectionLoss for hbase-unsecure
id: 2019-09-30 21:11:53
date: 2019-09-30 21:11:53
updated: 2019-09-30 21:11:53
categories:
tags:
keywords:
---
在当前的业务中，需要连接 `HBase` 获取数据，但是最近在某一台节点上面的进程总是出现连接异常：

```
2019-09-20_18:54:44 [http-nio-28956-exec-5] WARN zookeeper.ZKUtil:629: hconnection-0x8a9f6680x0, quorum=host1:2181,host10:2181,host11:2181,host61:2181,host62:2181, baseZNode=/hbase-unsecure Unable to get data of znode /hbase-unsecure/meta-region-server
org.apache.zookeeper.KeeperException$ConnectionLossException: KeeperErrorCode = ConnectionLoss for /hbase-unsecure/meta-region-server
	at org.apache.zookeeper.KeeperException.create(KeeperException.java:99)
```

看起来是连接超时，然后重试，持续了多次。本文开发环境基于 `HBase v1.1.2`、`Zookeeper v3.4.6`、`Hadoop v2.7.1`。


<!-- more -->

2019092901
HBase,Zookeeper,Hadoop


# 问题出现


一个正常的连接 `HBase` 取数的服务，在某个节点上出现大量的异常日志，无法连接到 `HBase`，一直在重试。同时观察到在其它节点则正常。

```
2019-09-20_18:54:44 [http-nio-28956-exec-5] ERROR zookeeper.RecoverableZooKeeper:277: ZooKeeper getData failed after 4 attempts
2019-09-20_18:54:44 [http-nio-28956-exec-5] WARN zookeeper.ZKUtil:629: hconnection-0x8a9f6680x0, quorum=host1:2181,host10:2181,host11:2181,host61:2181,host62:2181, baseZNode=/hbase-unsecure Unable to get data of znode /hbase-unsecure/meta-region-server
org.apache.zookeeper.KeeperException$ConnectionLossException: KeeperErrorCode = ConnectionLoss for /hbase-unsecure/meta-region-server
	at org.apache.zookeeper.KeeperException.create(KeeperException.java:99)
	at org.apache.zookeeper.KeeperException.create(KeeperException.java:51)
	at org.apache.zookeeper.ZooKeeper.getData(ZooKeeper.java:1155)
	at org.apache.hadoop.hbase.zookeeper.RecoverableZooKeeper.getData(RecoverableZooKeeper.java:359)
	at org.apache.hadoop.hbase.zookeeper.ZKUtil.getData(ZKUtil.java:621)
	at org.apache.hadoop.hbase.zookeeper.MetaTableLocator.getMetaRegionState(MetaTableLocator.java:481)
	at org.apache.hadoop.hbase.zookeeper.MetaTableLocator.getMetaRegionLocation(MetaTableLocator.java:167)
	at org.apache.hadoop.hbase.zookeeper.MetaTableLocator.blockUntilAvailable(MetaTableLocator.java:598)
	at org.apache.hadoop.hbase.zookeeper.MetaTableLocator.blockUntilAvailable(MetaTableLocator.java:579)
	at org.apache.hadoop.hbase.zookeeper.MetaTableLocator.blockUntilAvailable(MetaTableLocator.java:558)
	at org.apache.hadoop.hbase.client.ZooKeeperRegistry.getMetaRegionLocation(ZooKeeperRegistry.java:61)
	at org.apache.hadoop.hbase.client.ConnectionManager$HConnectionImplementation.locateMeta(ConnectionManager.java:1192)
	at org.apache.hadoop.hbase.client.ConnectionManager$HConnectionImplementation.locateRegion(ConnectionManager.java:1159)
	at org.apache.hadoop.hbase.client.RpcRetryingCallerWithReadReplicas.getRegionLocations(RpcRetryingCallerWithReadReplicas.java:300)
	at org.apache.hadoop.hbase.client.ScannerCallableWithReplicas.call(ScannerCallableWithReplicas.java:152)
	at org.apache.hadoop.hbase.client.ScannerCallableWithReplicas.call(ScannerCallableWithReplicas.java:60)
	at org.apache.hadoop.hbase.client.RpcRetryingCaller.callWithoutRetries(RpcRetryingCaller.java:200)
	at org.apache.hadoop.hbase.client.ClientSmallReversedScanner.loadCache(ClientSmallReversedScanner.java:211)
	at org.apache.hadoop.hbase.client.ClientSmallReversedScanner.next(ClientSmallReversedScanner.java:185)
	at org.apache.hadoop.hbase.client.ConnectionManager$HConnectionImplementation.locateRegionInMeta(ConnectionManager.java:1256)
	at org.apache.hadoop.hbase.client.ConnectionManager$HConnectionImplementation.locateRegion(ConnectionManager.java:1162)
	at org.apache.hadoop.hbase.client.ConnectionManager$HConnectionImplementation.locateRegion(ConnectionManager.java:1146)
	at org.apache.hadoop.hbase.client.ConnectionManager$HConnectionImplementation.locateRegion(ConnectionManager.java:1103)
	at org.apache.hadoop.hbase.client.ConnectionManager$HConnectionImplementation.getRegionLocation(ConnectionManager.java:938)
	at org.apache.hadoop.hbase.client.HRegionLocator.getRegionLocation(HRegionLocator.java:83)
	at org.apache.hadoop.hbase.client.RegionServerCallable.prepare(RegionServerCallable.java:79)
	at org.apache.hadoop.hbase.client.RpcRetryingCaller.callWithRetries(RpcRetryingCaller.java:124)
	at org.apache.hadoop.hbase.client.HTable.get(HTable.java:889)
	at org.apache.hadoop.hbase.client.HTable.get(HTable.java:855)
	at org.apache.hadoop.hbase.client.HTable.get(HTable.java:908)
	at com.xxx.yyy.commons.search.reader.hbase.BaseHBaseReader.batchGet(BaseHBaseReader.java:94)
	at com.xxx.yyy.commons.search.searcher.AbstractBaseSearcher.getContent(AbstractBaseSearcher.java:269)
	at com.xxx.yyy.commons.search.searcher.AbstractBaseSearcher.getInfo(AbstractBaseSearcher.java:194)
	at com.xxx.yyy.runner.search.BaseSearchRunner.combinaSearch(BaseSearchRunner.java:139)
	at com.xxx.yyy.api.newsforum.NewsForumPostServiceImpl.combinaSearch(NewsForumPostServiceImpl.java:53)
	at com.alibaba.dubbo.common.bytecode.Wrapper9.invokeMethod(Wrapper9.java)
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
	at com.alibaba.dubbo.common.bytecode.proxy4.combinaSearch(proxy4.java)
	at sun.reflect.GeneratedMethodAccessor87.invoke(Unknown Source)
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
2019-09-20_18:54:45 [http-nio-28956-exec-5] ERROR zookeeper.ZooKeeperWatcher:655: hconnection-0x8a9f6680x0, quorum=host1:2181,host10:2181,host11:2181,host61:2181,host62:2181, baseZNode=/hbase-unsecure Received unexpected KeeperException, re-throwing exception
org.apache.zookeeper.KeeperException$ConnectionLossException: KeeperErrorCode = ConnectionLoss for /hbase-unsecure/meta-region-server
	at org.apache.zookeeper.KeeperException.create(KeeperException.java:99)
	at org.apache.zookeeper.KeeperException.create(KeeperException.java:51)
	at org.apache.zookeeper.ZooKeeper.getData(ZooKeeper.java:1155)
	at org.apache.hadoop.hbase.zookeeper.RecoverableZooKeeper.getData(RecoverableZooKeeper.java:359)
	at org.apache.hadoop.hbase.zookeeper.ZKUtil.getData(ZKUtil.java:621)
	at org.apache.hadoop.hbase.zookeeper.MetaTableLocator.getMetaRegionState(MetaTableLocator.java:481)
	at org.apache.hadoop.hbase.zookeeper.MetaTableLocator.getMetaRegionLocation(MetaTableLocator.java:167)
	at org.apache.hadoop.hbase.zookeeper.MetaTableLocator.blockUntilAvailable(MetaTableLocator.java:598)
	at org.apache.hadoop.hbase.zookeeper.MetaTableLocator.blockUntilAvailable(MetaTableLocator.java:579)
	at org.apache.hadoop.hbase.zookeeper.MetaTableLocator.blockUntilAvailable(MetaTableLocator.java:558)
	at org.apache.hadoop.hbase.client.ZooKeeperRegistry.getMetaRegionLocation(ZooKeeperRegistry.java:61)
	at org.apache.hadoop.hbase.client.ConnectionManager$HConnectionImplementation.locateMeta(ConnectionManager.java:1192)
	at org.apache.hadoop.hbase.client.ConnectionManager$HConnectionImplementation.locateRegion(ConnectionManager.java:1159)
	at org.apache.hadoop.hbase.client.RpcRetryingCallerWithReadReplicas.getRegionLocations(RpcRetryingCallerWithReadReplicas.java:300)
	at org.apache.hadoop.hbase.client.ScannerCallableWithReplicas.call(ScannerCallableWithReplicas.java:152)
	at org.apache.hadoop.hbase.client.ScannerCallableWithReplicas.call(ScannerCallableWithReplicas.java:60)
	at org.apache.hadoop.hbase.client.RpcRetryingCaller.callWithoutRetries(RpcRetryingCaller.java:200)
	at org.apache.hadoop.hbase.client.ClientSmallReversedScanner.loadCache(ClientSmallReversedScanner.java:211)
	at org.apache.hadoop.hbase.client.ClientSmallReversedScanner.next(ClientSmallReversedScanner.java:185)
	at org.apache.hadoop.hbase.client.ConnectionManager$HConnectionImplementation.locateRegionInMeta(ConnectionManager.java:1256)
	at org.apache.hadoop.hbase.client.ConnectionManager$HConnectionImplementation.locateRegion(ConnectionManager.java:1162)
	at org.apache.hadoop.hbase.client.ConnectionManager$HConnectionImplementation.locateRegion(ConnectionManager.java:1146)
	at org.apache.hadoop.hbase.client.ConnectionManager$HConnectionImplementation.locateRegion(ConnectionManager.java:1103)
	at org.apache.hadoop.hbase.client.ConnectionManager$HConnectionImplementation.getRegionLocation(ConnectionManager.java:938)
	at org.apache.hadoop.hbase.client.HRegionLocator.getRegionLocation(HRegionLocator.java:83)
	at org.apache.hadoop.hbase.client.RegionServerCallable.prepare(RegionServerCallable.java:79)
	at org.apache.hadoop.hbase.client.RpcRetryingCaller.callWithRetries(RpcRetryingCaller.java:124)
	at org.apache.hadoop.hbase.client.HTable.get(HTable.java:889)
	at org.apache.hadoop.hbase.client.HTable.get(HTable.java:855)
	at org.apache.hadoop.hbase.client.HTable.get(HTable.java:908)
	at com.xxx.yyy.commons.search.reader.hbase.BaseHBaseReader.batchGet(BaseHBaseReader.java:94)
	at com.xxx.yyy.commons.search.searcher.AbstractBaseSearcher.getContent(AbstractBaseSearcher.java:269)
	at com.xxx.yyy.commons.search.searcher.AbstractBaseSearcher.getInfo(AbstractBaseSearcher.java:194)
	at com.xxx.yyy.runner.search.BaseSearchRunner.combinaSearch(BaseSearchRunner.java:139)
	at com.xxx.yyy.api.newsforum.NewsForumPostServiceImpl.combinaSearch(NewsForumPostServiceImpl.java:53)
	at com.alibaba.dubbo.common.bytecode.Wrapper9.invokeMethod(Wrapper9.java)
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
	at com.alibaba.dubbo.common.bytecode.proxy4.combinaSearch(proxy4.java)
	at sun.reflect.GeneratedMethodAccessor87.invoke(Unknown Source)
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
2019-09-20_18:54:45 [http-nio-28956-exec-10-SendThread(host1:2181)] INFO zookeeper.ClientCnxn:975: Opening socket connection to server host1/192.168.20.101:2181. Will not attempt to authenticate using SASL (unknown error)
2019-09-20_18:54:45 [http-nio-28956-exec-10-SendThread(host1:2181)] INFO zookeeper.ClientCnxn:852: Socket connection established to host1/192.168.20.101:2181, initiating session
2019-09-20_18:54:45 [http-nio-28956-exec-10-SendThread(host1:2181)] WARN zookeeper.ClientCnxn:1102: Session 0x0 for server host1/192.168.20.101:2181, unexpected error, closing socket connection and attempting reconnect
java.io.IOException: Connection reset by peer
	at sun.nio.ch.FileDispatcherImpl.read0(Native Method)
	at sun.nio.ch.SocketDispatcher.read(SocketDispatcher.java:39)
	at sun.nio.ch.IOUtil.readIntoNativeBuffer(IOUtil.java:223)
	at sun.nio.ch.IOUtil.read(IOUtil.java:192)
	at sun.nio.ch.SocketChannelImpl.read(SocketChannelImpl.java:380)
	at org.apache.zookeeper.ClientCnxnSocketNIO.doIO(ClientCnxnSocketNIO.java:68)
	at org.apache.zookeeper.ClientCnxnSocketNIO.doTransport(ClientCnxnSocketNIO.java:366)
	at org.apache.zookeeper.ClientCnxn$SendThread.run(ClientCnxn.java:1081)

```

注意查看重点内容：

```
2019-09-20_18:54:44 [http-nio-28956-exec-5] ERROR zookeeper.RecoverableZooKeeper:277: ZooKeeper getData failed after 4 attempts
2019-09-20_18:54:44 [http-nio-28956-exec-5] WARN zookeeper.ZKUtil:629: hconnection-0x8a9f6680x0, quorum=host1:2181,host10:2181,host11:2181,host61:2181,host62:2181, baseZNode=/hbase-unsecure Unable to get data of znode /hbase-unsecure/meta-region-server
org.apache.zookeeper.KeeperException$ConnectionLossException: KeeperErrorCode = ConnectionLoss for /hbase-unsecure/meta-region-server
...
2019-09-20_18:54:45 [http-nio-28956-exec-10-SendThread(host1:2181)] WARN zookeeper.ClientCnxn:1102: Session 0x0 for server host1/192.168.20.101:2181, unexpected error, closing socket connection and attempting reconnect
```

看起来是当前节点网络有问题，或者 `Zookeeper` 连接资源紧张。

与此同时，还有大量下面这种连接重试：

```
2019-09-30_00:24:56 [http-nio-28956-exec-8-SendThread(alps61:2181)] INFO zookeeper.ClientCnxn:1098: Unable to read additional data from server sessionid 0x16af866e055f894, likely server has closed socket, closing socket connection and 
attempting reconnect
2019-09-30_00:24:56 [http-nio-28956-exec-2-SendThread(alps61:2181)] INFO zookeeper.ClientCnxn:1098: Unable to read additional data from server sessionid 0x16af866e040a3c2, likely server has closed socket, closing socket connection and 
attempting reconnect
2019-09-30_00:24:56 [http-nio-28956-exec-8-SendThread(alps61:2181)] INFO zookeeper.ClientCnxn:1098: Unable to read additional data from server sessionid 0x16af866e040a720, likely server has closed socket, closing socket connection and 
attempting reconnect
2019-09-30_00:24:56 [http-nio-28956-exec-6-SendThread(alps61:2181)] INFO zookeeper.ClientCnxn:1098: Unable to read additional data from server sessionid 0x46d5ce1483b88cf, likely server has closed socket, closing socket connection and 
attempting reconnect
2019-09-30_00:24:56 [http-nio-28956-exec-2-SendThread(alps61:2181)] INFO zookeeper.ClientCnxn:1098: Unable to read additional data from server sessionid 0x16af866e040a349, likely server has closed socket, closing socket connection and 
attempting reconnect
2019-09-30_00:24:56 [http-nio-28956-exec-6-SendThread(alps61:2181)] INFO zookeeper.ClientCnxn:1098: Unable to read additional data from server sessionid 0x16af866e03f75aa, likely server has closed socket, closing socket connection and 
attempting reconnect
2019-09-30_00:24:56 [http-nio-28956-exec-4-SendThread(alps61:2181)] INFO zookeeper.ClientCnxn:1098: Unable to read additional data from server sessionid 0x16af866e040a8f0, likely server has closed socket, closing socket connection and 
attempting reconnect
```

其实就是有进程在占用过多的 `Zookeeper` 连接，导致 `Zookeeper` 的 `Server` 端拒绝响应。


# 问题排查


由于没有 `root` 权限，只能请运维帮忙排查，通过排查，发现当前主机创建的 `Zookeeper` 连接数过多，超过了设置的最大值。

使用 `netstat -antp | grep 2181 | wc -l` 命令，注意需要 `root` 用户的权限。这个命令统计的是所有连接，包含等待的和正在通信的，如果查看正在通信的，加上一个 `grep ESTABLISHED` 过滤即可。

局部截图如下：

![zk 连接进程查看](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20190930214400.png "zk 连接进程查看")

直接发现了问题，所以也不用进一步查看 `Zookeeper` 的日志了。

至于为什么 `Zookeeper` 的连接数会这么多，罪魁祸首请读者参考另外一篇博客：[HBase 错误之 NoClassDefFoundError：ProtobufUtil](https://www.playpi.org/2019093001.html) 。

由于当前节点创建的 `Zookeeper` 连接数过多，所以再创建新连接时无法顺利连接通信，一直等待。


# 问题解决


问题排查出来，解决就简单了，直接找到问题程序，修复资源泄漏问题，然后重启，保证合理的 `Zookeeper` 连接数量，不要影响到其它业务。

另外需要特别留意 `Zookeeper` 查看日志的方法，日志文件时不能被直接打开的，需要工具转换为文本日志。


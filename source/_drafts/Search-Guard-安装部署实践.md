---
title: Search Guard 安装部署实践
id: 2020-05-02 17:30:52
date: 2020-05-02 17:30:52
updated: 2020-05-02 17:30:52
categories:
tags:
keywords:
---



2020042701
大数据技术知识
SearchGuard,Elasticsearch,HTTP,TSL


最近 `Elasticsearch` 集群出了一个小事故，根本原因在于对集群请求的监控不完善，以及对 `Elasticsearch` 访问权限无监控【目前是使用 `LDAP` 账号就可以登录访问，而且操作权限很大，这有很大的隐患】。因此，最近准备上线 `Search Guard`，先在测试环境部署安装了一遍，并测试了相关服务，整理了如下安装部署文档，以供读者参考。

开发环境基于 `Elasticsearch v5.6.8`、`Search Guard v5.6.8-19.1`、`Java v1.8` 。


<!-- more -->


# 相关包、文档参考





# 回滚

安装部署过程中，避免不了小概率的异常，所以需要考虑回滚操作。



# 部署操作


不支持单台停机滚动安装，需要重启所有 `Elasticsearch` 节点，当然，停机时间很短暂。


## 准备证书

xx

### 下载解压



### 准备配置文件



### 生成证书文件



### 检查证书文件

xx

## 安装 Search Guard

### 禁止重分配

防止停掉 `` 节点时自动重分配。

### 停止集群



### 每个节点安装插件



### 拷贝证书文件



### 修改集群配置

Elasticsearch

### 重启集群



### 简单验证

Elasticsearch

### 部分配置信息

Elasticsearch


# 备注


## 用户配置



## 角色配置



## 关联权限配置



## Elasticsearch配置



## 一些问题

1、嗅探问题，不能开启，集群节点无法自动嗅探，会抛出超时异常。

`TransportClient` 方式有参数 `client.transport.sniff` 对应，设置为 `false` 即可。

`HTTP` 方式有 `Sniffer.builder()` 方法，不使用即可：

```
RestClientBuilder builder = RestClient.builder(hosts);
RestHighLevelClient restHighLevelClient = new RestHighLevelClient(builder);
Sniffer sniffer = Sniffer.builder(restHighLevelClient.getLowLevelClient()).build();
```

2、`TransportClient` 方式使用起来比较麻烦，需要证书文件，以及很多配置【类似于 `Search Guard` 在 `Elasticsearch` 中的那些配置】，本质是通过 `tcp` 与 `Elasticsearch` 进行连接【所以不需要密码了，证书已经表明了合法用户】。详细使用方式以及权限管理参考：[transport-clients](https://search-guard.com/searchguard-elasicsearch-transport-clients) 。

条件描述：

> The Transport Client needs to identify itself against the cluster by sending a trusted TLS certificate
> For that, you need to specify the location of your keystore and truststore containing the respective certificates
> A role with appropriate permissions has to be configured in Search Guard, either based on the hostname of the client, or the DN of the certificate

当然，集群层面也需要开启相应的配置。

首先在配置文件 `sgconfig/sg_config.yml` 中开启认证方式：

```
transport_auth_domain:
  enabled: true
  order: 2
  http_authenticator:
  authentication_backend:
    type: internal
```

其次需要证书完整的DN信息，配置在 `sgconfig/sg_internal_users.yml` 文件中：

```
CN=root-ca.playpi.com, OU=Ops, O="Playpi Com, Inc.", DC=playpi, DC=com
    hash: $2a$12$1HqHxm3QTfzwkse7vwzhFOV4gDv787cZ8BwmCwNEyJhn0CZoo8VVu
```

当然，如果忘记了 `DN` 信息，可以使用 `Java` 自带的工具获取：

```
keytool -printcert -file ./config/client-custom.pem
```

同样，需要在角色映射文件 `sgconfig/sg_roles_mapping.yml` 中配置：

```
client-custom:
    users:
        - banyan-custom
        - 'root-ca.datatub.com, OU=Ops, O="Datatub Com, Inc.", DC=datatub, DC=com'

注意单引号的使用
```


---
title: es-hadoop 读取中文字段丢失问题
id: 2020-02-15 19:30:07
date: 2017-10-23 19:30:07
updated: 2020-02-15 19:30:07
categories:
tags:
keywords:
---


2017102301
踩坑系列
Hadoop,Elasticsearch,Spark

在使用 `elasticsearch-hadoop` 包时遇到一个坑：读取 `Elasticsearch` 数据时会过滤掉中文名称的字段，影响了数据处理流程，排查、测试了一整天才找到根本原因，本文记录这个问题。涉及到的开发环境基于 `Elasticsearch 2.4.5`，源码分析演示基于 `elasticsearch-hadoop v2.4.5`，当然，`elasticsearch-hadoop v2.3.x` 也是有这个问题的。


<!-- more -->


# 问题出现


首先简单描述一下业务场景：利用 `elasticsearch-hadoop` 包提供的工具，从 `Elasticsearch` 中读取数据，经过一系列的中间 `ETL` 处理，增加部分字段，最终再以 `index` 的方式【没有使用 `update` 的方式】写回原来的索引。

由于以前使用的 `Elasticsearch` 版本比较低，所以使用的 `elasticsearch-hadoop` 版本也比较低，这次临时需要处理 `v2.4.5` 版本的 `Elasticsearch` 数据，所以也升级了 `elasticsearch-hadoop`，于是就发生了问题。

问题现象是：对于一批数据，处理完成之后，再写回原来的索引，发现数据中的中文字段全部消失，而 `ETL` 处理产生的中文字段还在，这就导致这批数据废了，没有用处了。

先检查了 `ETL` 逻辑，没有发现任何问题，不会造成中文字段丢失。又检查了读取数据的配置，有没有设置只是读取部分字段【参数 `es.read.field.include`】，发现并没有单独设置，也就是全部字段都读取。

接着又回退到低版本 `elasticsearch-hadoop v2.1.0`，处理低版本的 `Elasticsearch v1.7.5` 数据，发现正常，处理 `Elasticsearch v2.4.5` 也是正常。

此时就可以严重怀疑是 `elasticsearch-hadoop v2.4.5` 包的问题了，话不多说，直接打开源码排查。


# 源码分析解读


首先需要下载源码，从 `GitHub` 上面下载，下载后记得要切换 `tag`，也就是切换到指定的版本，例如我这里切换到 `tag v2.5.4`【使用命令：`git checkout v2.4.5`】。

`elasticsearch-hadoop` 使用的构建工具是 `Gradle`，导入 `IDEA` 需要注意【另外 `Elasticsearch` 从 `v5.0` 开始也将构建工具由 `Maven` 切换为 `Gradle` 了】。所以还需要提前安装好 `Gradle`，安装流程和 `Maven` 类似，比较简单，在此不再赘述，读者可以参考官网【最好配置一下 `GRADLE_HOME` 环境变量】。

但是配置时需要注意，如果遇到依赖包下载很慢卡住的现象，一般是网络问题，毕竟中央仓库在国外，地址：[http://repo1.maven.org/maven2](http://repo1.maven.org/maven2) ，所以需要更改仓库的镜像地址，类似于 `Maven` 那样。

当然，如果不配置环境变量，给每个项目都单独配置国内的镜像也可以，需要在项目的 `build.gradle` 文件中配置。

```
repositories {
    maven {
        url 'http://maven.aliyun.com/nexus/content/groups/public/'
    }
    mavenCentral()
}
```

但是如果项目多了需要改镜像地址则稍显麻烦，不如全局变量方便。如果是配置全局的仓库镜像，需要在安装目录下的 `.gradle` 目录中新建 `init.gradle` 文件【其实是一个 `Groovy` 脚本】，填写如下内容：

```
allprojects {
    repositories {
        maven {
            url 'http://maven.aliyun.com/nexus/content/groups/public/'
        }
    }
}
```

以上内容表示给所有的项目都指定了仓库镜像，当然，也可以给部分项目指定【写脚本只处理指定的仓库地址，被替换为我们自己的镜像】：

```
allprojects{
    repositories {
        def REPOSITORY_URL = 'http://maven.aliyun.com/nexus/content/groups/public/'
        all { ArtifactRepository repo ->
            if(repo instanceof MavenArtifactRepository){
                def url = repo.url.toString()
                if (url.startsWith('https://repo1.maven.org/maven2') || url.startsWith('https://jcenter.bintray.com/')) {
                    project.logger.lifecycle "Repository ${repo.url} replaced by $REPOSITORY_URL."
                    remove repo
                }
            }
        }
        maven {
            url REPOSITORY_URL
        }
    }
}
```

此外，别忘记设置**本地仓库**目录，但是 `Gradle` 并没有提供全局的配置文件，只能通过配置环境变量来解决这个问题，使用 `GRADLE_USER_HOME` 环境变量来标记 `Gradle` 的全局变量。如果不设置，默认为用户目录下的 `.gradle` 目录，所以还是设置一下好，例如指定为 `Gradle` 安装目录下的 `.gradle` 目录。

除了通过环境变量来设置，也可以使用 `Gradle` 原生的命令设置：`gradle -g 目录`，`-g` 是 `--gradle-user-home` 的简写。

如果在 `Build` 过程中发现还是卡住：`Gradle: Resolve dependencies ':classpath'`，肯定是镜像的仓库没有设置好，确保设置好后关掉项目重新打开，不要无谓地等待。

另外，如果实在不行可以设置代理，在项目的 `gradle.properties` 文件中配置【如果放在 `.gradle` 目录下就是全局生效了】：

```
org.gradle.jvmargs=-DsocksProxyHost=127.0.0.1 -DsocksProxyPort=1080
```

由于 `elasticsearch-hadoop` 中与 `Elasticsearch` 相关的代码大部分是用 `scala` 写的，所以需要 `IDEA` 安装 `scala` 模块。

顺利使用 `IDEA` 打开项目后，就可以开始查看源码了。

xxx


# 备注

版本问题，导致丢失中文字段；

如果是使用 `index` 方式把数据写回原始索引，那么这些字段就彻底丢失了。

建议不要使用中文字段名称，虽然 `Elasticsearch` 官方支持，但还是要提防一些未知的坑，哪怕不全是英文字段名称，退一步使用拼音、数字都可以【合法的字母、数字】。

使用 jdk 版本问题，需要适配；


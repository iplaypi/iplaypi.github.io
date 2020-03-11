---
title: Maven 使用中遇到的证书问题以及 JDK8 问题
id: 2018082501
date: 2018-08-25 23:06:32
updated: 2019-04-04 23:06:32
categories: 基础技术知识
tags: [Maven,JDK,证书]
keywords: Maven,JDK,证书
---


在 Java 开发过程中，使用 Maven 往私服 deploy 构件【Java 打成的 jar 包】的时候，原本正常的流程突然出问题了，报错信息：

```
[WARNING] Could not transfer metadata org.leapframework:leap:0.4.0b-SNAPSHOT/maven-metadata.xml from/to bingo-maven-repository-hosted ($bingo.maven$): sun.security.validator.ValidatorException: PKIX path building failed: sun.security.provider.certpath.SunCertPathBuilderException: unable to find valid certification path to requested target
```

看到里面的 **security** 和 **certification** 关键词就猜测是安全与证书的问题。恰好最近私服的域名访问从 http 升级为了 https，也就是增加了 SSL 证书，我想可能和这个有关。本文就记录解决这个问题的流程，以及后续由此又引发了其它的问题，例如 JDK8 导致的注解问题、IDEA 的乱码问题。


<!-- more -->


# 问题出现


在分析问题现象之前，首先需要了解一个基本事实，Maven 是依赖于 JDK 环境运行的，所以使用 Maven 之前必须安装 JDK，并且配置好 **JAVA_HOME** 。在使用 Maven 过程中遇到的一些问题可能会和 JDK 环境有关，例如 SSL 证书问题、JDK 版本问题。

以下内容现象基于 Windoes7 X64 操作系统，JDK 版本为1.7u89，Maven 版本为3.5。

好，言归正传，继续关注遇到的问题。在某一天，发现公司的 Maven 私服仓库更新了管理系统，并且增加了 SSL 证书【证书类型是 **Let's Encrypt** ，有效期三个月，这为后续的各种问题埋下了伏笔】，这样访问的链接全部变为 https 开头的了。但是我又注意到一个现象，我发现仓库里的很多 SNAPSHOT 类型的 jar 包消失了，这应该是管理系统设置了自动清除机制，把没用的快照版本的 jar 包全部清除，节约空间。但是，其中有一些 jar 包对于我来说是有用的，更麻烦的是这些 jar 包根本没有 RELEASE 正式版，都是前人留下的坑，为了图方便临时打了一个快照版本 jar 包给别人使用，竟然把资源文件也打进去，导致一个 jar 包有将近100M大小。这种操作显然是违背 Maven 的理念的，面对这种情况，再想申请发布一个 RELEASE 版本的 jar 包也麻烦，而且这种业务类型的代码就不应该打成 jar 包给别人使用。

思考了半天，我决定采用一个折中的办法：取得代码阅读权限，移除没用的资源文件，仅仅发布代码，仍旧发布 SNAPSHOT 版本，以后有时间再把业务代码复制出来，不再使用 jar 的形式。思路确定了，就开始行动。

一开始我发现开发环境本地仓库有这些 jar 包，还想手动上传到 Maven 私服仓库的，把坐标定义准确就行了。但是后续发现 Maven 私服仓库的管理系统不支持手动上传 jar 包，只支持通过账号、密码认证的方式，从源代码发布 jar 包到仓库，而且个人账号只能发布 SNAPSHOT 版本的，管理员账号才能发布 RELEASE 版本的。

路走到了这里，那我只能先获取项目代码的权限，然后新开分支，删掉无用的配置文件，仅仅发布源代码到私服仓库，先发布 SNAPSHOT 版本使用。

准备工作做好后，接着开始 deploy，就遇到了一连串的问题，在确认账号密码没有问题的前提下，deploy 失败，错误信息如下：

```
[WARNING] Could not transfer metadata org.leapframework:leap:0.4.0b-SNAPSHOT/maven-metadata.xml from/to bingo-maven-repository-hosted ($bingo.maven$): sun.security.validator.ValidatorException: PKIX path building failed: sun.security.provider.certpath.SunCertPathBuilderException: unable to find valid certification path to requested target
```

看到里面的 **security** 和 **certification** 关键词就猜测是安全与证书的问题，公司私服的其它环境并没有变化，只能从 SSL 证书入手解决问题，然而一开始没有头绪。 但是又问了同事，发现他们可以正常 deploy，又测试了一下线上的发布系统，也可以正常发布 jar 包到公司私服仓库。那只有2个怀疑方向了，一个是本地 Maven 的版本问题，一个是本地 JDK 的版本问题。后来通过对比发现，的确是 JDK 版本的问题，某些低版本的 JDK 不会自动导入 Let's Encrypt 的证书，才会导致 Maven 进行 deploy 时认证失败【Maven 底层是依赖于 JDK 的】，自然而然 delpoy 也就失败了。

参考：[stackoverflow讨论一例](https://stackoverflow.com/questions/34110426/does-java-support-lets-encrypt-certificates) 。

> The Let's Encrypt certificate is just a regular public key certificate. Java supports it (according to [Let's Encrypt Certificate Compatibility](https://letsencrypt.org/docs/certificate-compatibility/) , for Java 7 >= 7u111 and Java 8 >= 8u101).

在找原因的过程中还一度怀疑是公司私服仓库的 SSL 证书问题，后面发现是本地环境的问题，但是背后的根本原因还是 SSL 证书的问题。恰好遇到了 Let's Encrypt 类型的证书，又恰好 JDK 版本过低，引起一系列连锁反应。


# 问题解决


既然找到了问题，那就容易解决了，直接升级 JDK 即可，JDK7需要升级到 >=7u111，JDK8需要升级到 >=8u101。

## 手动导入证书

其实，如果不升级 JDK，还有一种繁琐的解决办法，那就是手动导入证书。解决思路就是从需要访问的 https 站点下载证书，然后导入本地的 Java 环境证书库，缺点就是每次证书更新都需要重新导入，显得麻烦。其实这种做法更有助于我们理解这个问题的核心所在，高版本的 JDK 会自动帮我们导入 Let's Encrypt 证书，但是低版本的不会，我们不仅能知其然，也知其所以然。

### 下载证书

证书可以在访问网站时，在 url 文本框的左侧，有一把小绿锁，选中点击，接着查看证书，下载即可。

点击小绿锁
![点击小绿锁](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/old/b7f2e3a3gy1g1tan4wr2ij20cm0aqwel.jpg "点击小绿锁")

下载证书
![下载证书](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/old/b7f2e3a3gy1g1taned34lj20d60i9wes.jpg "下载证书")

此外也可以通过浏览器调试工具的 Security 标签查看下载证书，下图是使用 Chrome 浏览器的效果，其它浏览器可能会略有不同。
![浏览器调试工具的 Security 标签](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/old/b7f2e3a3gy1g1tanr9da2j20l40mjdgo.jpg "浏览器调试工具的 Security 标签")

### 把证书文件导入证书库

先要清楚本地 Java 的证书库的位置，一般在 **{JAVA_HOME}/jre/lib/security/** 目录下面，里面有一个 **cacerts** 文件，它就是所有证书的集合组成的文件。另外还要清楚 **keytool** 工具，它是 JDK 提供的可以操作证书的工具，可以直接使用。

Java 证书库的位置
![Java证书库的位置](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/old/b7f2e3a3gy1g1tasd88jdj20rt0ffab4.jpg "Java证书库的位置")

以下命令供参考，特别需要注意**命令执行权限**、**文件写权限**：

```
-- 把证书文件 maven.datastory.cer 导入 Java 证书库 cacerts 中，别名为 maven.datastory，密码是 changeit
keytool -import -alias maven.datastory -keystore cacerts -file  maven.datastory.cer -trustcacerts -storepass changeit

-- 在证书库中查看指定别名的证书信息，需要输入密码
keytool -list -keystore cacerts -alias maven.datastory

--删除证书库中指定别名的证书
keytool -delete -keystore cacerts -alias maven.datastory
```

### 后续维护问题

这种手动导入证书的方式，只能确保一时可以使用，因为证书是会过期的，特别是 Let's Encrypt 证书，有效期只有3个月。所以后期维护起来会很麻烦，如果某一天发现 deploy 又报一样的错，那估计是证书过期了，也有可能是站点的证书被更换了。因此，还是升级高版本的 JDK 比较好，把证书的维护更新工作都交给 JDK 来执行，自己安心写代码就行了。

我后期就经历了这一过程，用了没多久发现 deploy 还是失败，只好把证书下载下来重复了导入的过程。而且一开始没有往证书过期上面怀疑，浪费了一些找问题的时间。

## 自定义证书库

其实还有一种更为繁琐的做法，那就是自定义证书库，思路就是把 Java 的证书库复制一份，并且把自己的证书添加进去，然后为 Maven 指定这个自己的证书库。指定证书库的参数【例如路径、密码、证书库类型】需要在 Maven 命令执行之前配置，就像设置一些环境变量一样。

更为详细的做法就不演示了，毕竟一般都没有必要这样做，可以参考：[自定义Maven证书库](http://kael-aiur.com/%E5%B7%A5%E5%85%B7%E4%BD%BF%E7%94%A8/maven%E6%B7%BB%E5%8A%A0%E4%BF%A1%E4%BB%BB%E8%AF%81%E4%B9%A6.html) 。

## 题外话

如果 IDEA 因为 Maven 的依赖问题，有红色的线条提醒，可能是没有及时更新 UI 界面导致的，其实依赖都完整了，此时重新启动 IDEA 即可，我一直怀疑这是 IDEA 的 bug，有时候明明缺少依赖，IDEA 也不提示错误。

而判断是否真的缺失 Maven 依赖，应该使用 Maven 命令编译、打包【mvn compile package】，看看日志是否正常，不能以 IDEA 的显示为依据【有时候 IDEA 会抽风】。如果真的缺少 Maven 依赖，使用 Maven 命令编译、打包是会失败的，并且有提示。而如果明明不缺少依赖，但是代码中报错一大堆，此时强制更新【reimport 重新导入】 Maven 依赖即可，必要时也需要重启 IDEA。

另外有一个很好用的小技巧，如果本地仓库存在一个可以使用的 jar 包，可以直接复制给别人使用，按照相同的目录放在指定的路径下面即可，这样 Maven 就会认为本地已经存在 jar 包了，不再去私服仓库下载。这种做法虽然很低级，但是却实用，可以快速解决私服仓库没有 jar 包，初始化环境时无法下载依赖的情况。

## 其它问题记录

在同一时期，同事的环境已经升级到 `JDK8` 以上，并且 `>=8u101`，`Maven` 版本是 `v3.2.1`，可以正常 `deploy` 构件。但是突然有一天就出错，从日志来看是认证问题，切换为别人的账号密码就正常，使用他自己的账号密码却报错，我猜测是账号的问题，找运维解决。

报错信息如下，留意关键部分：`Not authorized , ReasonPhrase:Unauthorized.`：

```
[INFO] --- maven-install-plugin:2.4:install (default-install) @ project-name ---
[INFO] Installing D:\datastory\workspace\study\project-name\target\project-name-1.1.11-SNAPSHOT.jar to D:\pro\env\maven\repository\com\datastory\radar\project-name\1.1.11-SNAPSHOT\project-name-1.1.11-SNAPSHOT.jar
[INFO] Installing D:\datastory\workspace\study\project-name\pom.xml to D:\pro\env\maven\repository\com\datastory\radar\project-name\1.1.11-SNAPSHOT\project-name-1.1.11-SNAPSHOT.pom
[INFO] 
[INFO] --- maven-deploy-plugin:2.7:deploy (default-deploy) @ project-name ---
Downloading: http://maven.domain/nexus/content/repositories/snapshots/com/datastory/radar/project-name/1.1.11-SNAPSHOT/maven-metadata.xml
[WARNING] Could not transfer metadata com.datastory.radar:project-name:1.1.11-SNAPSHOT/maven-metadata.xml from/to snapshots (http://maven.domain/nexus/content/repositories/snapshots): Not authorized , ReasonPhrase:Unauthorized.
[INFO] ------------------------------------------------------------------------
[INFO] BUILD FAILURE
[INFO] ------------------------------------------------------------------------
[INFO] Total time: 5.860 s
[INFO] Finished at: 2018-08-10T21:48:24+08:00
[INFO] Final Memory: 24M/326M
[INFO] ------------------------------------------------------------------------
[ERROR] Failed to execute goal org.apache.maven.plugins:maven-deploy-plugin:2.7:deploy (default-deploy) on project project-name: Failed to retrieve remote metadata com.datastory.radar:project-name:1.1.11-SNAPSHOT/maven-metadata.xml: Could not transfer metadata com.datastory.radar:project-name:1.1.11-SNAPSHOT/maven-metadata.xml from/to snapshots (http://maven.domain/nexus/content/repositories/snapshots): Not authorized , ReasonPhrase:Unauthorized. -> [Help 1]
[ERROR] 
[ERROR] To see the full stack trace of the errors, re-run Maven with the -e switch.
[ERROR] Re-run Maven using the -X switch to enable full debug logging.
[ERROR] 
[ERROR] For more information about the errors and possible solutions, please read the following articles:
[ERROR] [Help 1] http://cwiki.apache.org/confluence/display/MAVEN/MojoExecutionException
```

`Not authorized , ReasonPhrase:Unauthorized.` 这个错误表明认证失败，说明远程仓库【或者私服】没有开放访问权限，需要密钥、用户名密码之类的认证方式。

我检查了一下我的 `settings.xml` 配置文件，发现已经配置好了 `server` 属性，并且确保了 `id` 与 项目 `pom.xml` 中指定仓库的 `id` 一致。但是还是出现异常，感觉上 `Maven` 使用的配置文件就不是我的这份，查看 `MAVEN_HOME` 也没有指定。

询问了一下运维人员，果然是的，服务器执行 `mvn` 相关命令，默认使用公共的配置文件【没有认证信息】，如果需要使用自己的配置文件【有自己特有的配置信息】，使用 `-s` 参数指定即可。如果需要经常使用，可以在 `.bashrc` 脚本中加上 `alias`：`alias mcp='mvn -s "/path/to/your/settings.xml" clean package'`，这样每次登录时都会自动设置别名命令。


# JDK8注解问题


切换到 `JDK8` 并且升级之后，在 `deploy` 构件到私服仓库的时候，出现了另外一个问题，直接 `deploy` 失败，报错信息如下：

```
Failed to execute goal org.apache.maven.plugins:maven-javadoc-plugin:2.7:jar (attach-javadocs) on project [projectname]: MavenReportException: Error while generating Javadoc:
Exit code: 1 - [path-to-file]:[linenumber]: warning: no description for @param
```

`deploy` 失败日志截图

![deploy 失败日志截图](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/old/b7f2e3a3gy1g1tay67elbj20qo0fqtfc.jpg "deploy 失败日志截图")

查看里面的关键信息，可以找出 `maven-javadoc-plugin` 这个插件，说明是这个插件在生成 `Javadoc` 的时候出问题了。而我回想了一下，最近的插件版本、代码结构并没有变化，唯一变化的就是开发环境，`JDK` 由1.7版本切换为了1.8版本，那就往这方面找问题了。

查了一下资料，由于 `JDK8` 的 `Javadoc` 生成机制比之前的版本要严谨许多，在 `Javadoc` 中添加了 `doclint`，而这个工具的主要目的是获得符合 `W3C HTML 4.01` 标准规范的 `HTML` 文档。所以使用 `maven-javadoc-plugin` 插件 `deploy` 的时候，`JDK8` 环境触发了 `Javadoc` 验证，验证自然不能通过，`Maven` 插件直接报错，`deploy` 不成功。

为了验证这个过程，我又把本地环境的 `JDK` 切回到了1.7版本，可以正常 `deploy`，成功发布 `SNAPSHOT` 版本的构件到私服仓库。而由于线上发布系统的 `JDK` 版本强制设置为了1.8，无法更改，所以无法在线上做验证，只能发现在线上发布的 `RELEASE` 版本构件一定是失败的。

既然找到了原因所在，接下来就容易操作了，可以选择关闭 `Javadoc` 验证，或者直接不使用 `maven-javadoc-plugin` 这个插件。而我选择继续使用这个插件，但是可以选择是跳过生成 `Javadoc` 还是关闭 `Javadoc` 验证，根据自己的需要了，具体步骤与效果我会在下面演示。

先来看一下这个插件的 `pom.xml` 文件配置：

```
<!-- javadoc打包插件 -->
<plugin>
    <groupId>org.apache.maven.plugins</groupId>
    <artifactId>maven-javadoc-plugin</artifactId>
    <version>2.9</version>
    <executions>
        <execution>
            <id>attach-javadocs</id>
            <goals>
                <goal>jar</goal>
            </goals>
            <configuration>
                <!-- 直接跳过 Javadoc 生成 -->
                <skip>true</skip>
                <encoding>UTF-8</encoding>
                <charset>UTF-8</charset>
                <!-- 此参数针对jdk8环境使用,如果本机是jdk7环境会报错,所以增加上述skip配置,保证线上和本地都可以部署(install/deploy),当然最好使用profile激活灵活的配置 -->
                <!-- add this to disable checking,禁用Javadoc检查 -->
                <additionalparam>-Xdoclint:none</additionalparam>
                <!-- 使用profile激活灵活的配置 -->
                <additionalparam>${javadoc.opts}</additionalparam>
            </configuration>
        </execution>
    </executions>
</plugin>
```

以上配置是非常完整的，把所有的重要配置项都列出来了，并给出了注释，实际使用中选择自己需要的即可，如果看不懂没有关系，接着往下看，详细解释了参数的使用以及最终的优化配置方案。

在这里需要注意一个问题，如果你的 `pom.xml` 文件中根本没有配置 `maven-javadoc-plugin` 插件，但是这些错误仍旧存在，那是为什么呢？其实是因为 `Maven` 已经默认给每个生命周期都绑定了对应的插件，如果没有在 `pom.xml` 中配置自定义的插件，则使用 `Maven` 默认的【这里的默认有2层意思，一个是插件类型默认，一个是版本号默认】。例如当前项目如果没有配置 `javadoc` 插件，则会默认使用仓库里版本最高的稳定版 `maven-javadoc-plugin` 插件，插件的配置也都是默认的，无法更改。

而使用 `Maven` 默认的插件，很可能会引发莫名的问题，根本原因就在于对于某个插件、某个版本的插件、插件的默认配置，我们都是未知的，出了问题也比较难定位，所以在一些重要的插件上面还是手动显式配置出来比较好，这样问题都能在自己的掌握之中。

## 跳过 Javadoc 的生成

如果直接配置了跳过 `Javadoc` 的生成【使用 `skip` 参数】，`configuration` 下面的内容都不需要配置了，配置了也不会用到。由于插件会直接跳过 `Javadoc` 的生成，所以也就不存在验证的过程了。然而，这种做法对于构件的使用方是不友好的，因为缺失了 `Javadoc`，当查看源码遇到问题时就无法寻求有效的帮助了。

```
<configuration>
    <skip>true</skip>
</configuration>
```

## 开启 Javadoc 生成但是关闭 Javadoc 验证

因此，还是要开启 `Javadoc` 的生成，但是关闭 `JDK8` 对于 `Javadoc` 的严格验证，此时需要在 `configuration` 里面增加参数：

```
<configuration>
    <additionalparam>-Xdoclint:none</additionalparam>
</configuration>
```

一般为了方便他人查看项目的参数，最好把这种重要的参数值设置为全局变量，在 `pom.xml` 文件的 `properties` 节点下面声明即可，例如：

```
-- 设置全局变量
<properties>
    <additionalparam.val>-Xdoclint:none</additionalparam.val>
</properties>

-- 使用全局变量
<configuration>
    <additionalparam>${additionalparam.val}</additionalparam>
</configuration>
```

## 潜在的问题

难道这样配置就完了吗，显然有潜在的问题，作为经历过的人，我告诉你，附加参数 `-Xdoclint:none` 是只有 `JDK8` 及以上版本才会支持的，如果有人在构建项目时使用了 `JDK7` 的环境，最终的结果还是失败，失败的原因是参数不合法，无法支持。

报错信息举例：

```
Failed to execute goal org.apache.maven.plugins:maven-javadoc-plugin:2.7:jar (attach-javadocs) on project [projectname]: MavenReportException: Error while generating Javadoc:
Exit code: 1 - javadoc:错误 - 无效的标记: -Xdoclint:none
```

所以接下来还要想一个更好的办法，不仅能关闭 `Javadoc` 的验证，还要根据当前的实际 `JDK` 环境来自动切换参数的取值，这样就可以兼容所有的环境了。显然，没有什么比 `profile` 更适合这个情况了，配置一个 `profile` 激活信息，根据 `JDK` 的版本激活全局变量，参数值传入给 `additionalparam` 使用，比起上面的固定的全局变量，这种可变的全局变量更灵活。

详细配置如下：

```
-- 全局变量 javadoc.opts 在 JDK8 及以上版本才激活
<profiles>
  <profile>
    <id>doclint-java8-disable</id>
    <activation>
      <jdk>[1.8,)</jdk>
    </activation>
    <properties>
      <javadoc.opts>-Xdoclint:none</javadoc.opts>
    </properties>
  </profile>
</profiles>

-- 使用激活的全局变量,如果没有激活则为空
<configuration>
    <additionalparam>${javadoc.opts}</additionalparam>
</configuration>
```

## 插件版本的踩坑

在解决问题的过程中还遇到了一个典型的问题，由插件版本引起。

一开始在项目的 `pom.xml` 文件中没有配置插件 `maven-javadoc-plugin` 的版本号，即 `version` 参数，导致项目使用的是公司私服仓库最新的版本：`v3.0.0`，而在这个版本中使用 `-Xdoclint:none` 关闭验证是无效的，不知道是插件本身的问题还是参数 `-Xdoclint:none` 对3.0.0版本的插件无效。后来指定版本为2.9，就没有这个问题了。

由于一开始没有指定插件 `maven-javadoc-plugin` 的版本号，出错了也不知道为啥，在 `deploy` 的输出日志中看到使用的 `v3.0.0` 版本的插件，猜测可能和插件版本有关系，于是更换了版本，就没有问题了。因此这种重要的插件还是要手动指定自己认为稳定的版本，这样有问题也能在自己的掌握之中。

## 参考

- [在JDK8中禁用Javadoc验证](http://www.locked.de/how-to-ignore-maven-javadoc-errors-in-java-8/) 
- [stackoverflow中的问答一例](https://stackoverflow.com/questions/27728733/javadoc-error-invalid-flag-xdoclintnone-when-i-use-java-7-but-it-works-i) 


# IDEA 乱码问题


在解决上面的 `JDK8` 注解的问题过程中，遇到了一个乱码问题，系统环境是 `Windows7 X64`。当在 `JDK7` 的环境中配置了以下内容时：

```
<configuration>
    <additionalparam>-Xdoclint:none</additionalparam>
</configuration>
```

本意是想测试这个参数在 `JDK7` 环境中的效果【前面已经验证过在 `JDK8` 中是完美运行的】，发现报错了，但是错误信息是乱码的，导致看不出来错误信息是什么，也就没法解决问题。

在 `JDK7` 中 `deploy` 报错乱码

![Maven报错信息乱码](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/old/b7f2e3a3gy1g1tb5tee2qj20qo0a1td9.jpg "Maven报错信息乱码")

其实，这只是 IDEA 的编码设置问题，更改一下编码就行了。在 **setting --> maven --> rumnner --> VMoptions** ，添加参数：**-Dfile.encoding=GB2312** ，就可以正常输出了。当然，Windows 系统配置编码为 **GBK** 也行。

![设置IDEA的Maven编码](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/old/b7f2e3a3gy1g1tb6bm56gj20qo0fi0vd.jpg "设置IDEA的Maven编码")

为什么要这么配置呢，因为 Maven 是依赖于当前系统的编码的，可以使用 **mvn -version** 命令查看编码的信息，查看 **Default locale** 那一项，可以看到是 **GBK**。

![查看Maven的编码使用](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/old/b7f2e3a3gy1g1tb6jiivhj20gj0ahaab.jpg "查看Maven的编码使用")

配置完成后，报错信息正常显示

![报错信息正常显示](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/old/b7f2e3a3gy1g1tb6u2gzgj20qo0awq7a.jpg "报错信息正常显示")


# 问题总结


1、通过手动导入证书的方式，一开始解决了问题，后来过了一段时间突然又不能使用，这时候我很是疑惑的。问了问同事却都能正常使用，我还以为是我的 Maven 的版本问题，换了 Maven 版本也不行，最后折腾了很久发现是私服域名的 SSL 证书失效了，再重新导入一份就行了。因为私服域名的 **Let's Encrypt** 证书有效期只有三个月，所以每次证书续期或者更换的时候，都要手动重新导入，旧证书会自动失效。这样多麻烦，所以还是直接升级 JDK 比较好，一劳永逸。

2、在与同事的开发环境对比的过程中，仔细对比了 Maven 的版本和 JDK 的版本，发现都是 Maven 3.5 与 JDK1.7，但是别人能用我的就不能用，一度怀疑人生。最终才发现根本原因是没有对比小版本号，同样是 JDK1.7，没有 **>=7u111** 也不行。

3、关于 Maven 的插件版本问题，切记要手动指定自己认为可靠的版本，不要让 Maven 使用仓库最新的稳定版本，哪怕的确是使用最新的版本，也要指明，确保出了问题自己可控，否则就像无头的苍蝇乱打乱撞。
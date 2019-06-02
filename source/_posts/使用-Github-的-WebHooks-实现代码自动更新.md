---
title: 使用 Github 的 WebHooks 实现代码自动更新
id: 2019030601
date: 2019-03-06 23:13:32
updated: 2019-03-07 23:13:32
categories: 建站
tags: [Github,PHP,WebHooks,Git,自动更新,钩子]
keywords: Github,PHP,WebHooks,Git,自动更新,钩子
---


我的静态博客为了百度爬虫单独部署了一个镜像，放在了我的 VPS 上面【在 vultr 购买的主机】，并单独设置了二级域名 blog.playpi.org。但是，每次 GitHub 有新的提交时【基本每周都会有至少三次提交】，为了及时更新，我都会登录到 VPS 上面，到指定的项目下做一下拉取更新的操作，即执行 **git pull**。这样操作了三五次，我就有点不耐烦了，自己身为做技术的人，怎么能忍受这个呢，做法既低效又不优雅。于是，我就在想有没有更好的方法来实现自动拉取更新。一开始想到，直接在 VPS 起一个周期性脚本不就行了，比如每隔1分钟自动执行 **git pull**，但是立马又被我否定了，虽然做法很简单，但是太不优雅了，而且极大浪费 CPU。后来想到，GitHub 自带了 WebHooks 功能，概念类似于回调钩子，可以给 GitHub 的项目设置各种各样的行为，满足一定的场景才会触发【例如当有新的 push 时，就会向设置的 url 发送请求，并且在请求体中携带 push 的相关信息】。我的自动化构建就是这样的原理，每当 source 分支有提交时，都会通知 tavis-ci【这就是一个行为】，然后在 travis-ci 中设置好脚本，自动运行脚本，就完成了自动生成、部署的操作。

根据这个思路，就可以给 GitHub 的项目设置一个 WebHooks，每当 master 分支有提交时【代表着静态博客有更新了】，会根据设置的链接自动发送消息到 VPS 上面，然后 VPS 再执行拉取更新，这样的话就优雅多了。但是问题又来了，满足这种场景还需要在 VPS 设置一个后台服务，用来接收 GitHub 的消息通知并执行拉取更新的操作。我想了一下，既然 VPS 上面已经起了 Nginx 服务，那就要充分利用起来，给 Nginx 设置好反向代理，把指定的请求转给另外一个服务就行了。那这个服务怎么选呢，当然是选择 PHP 后台了，毕竟 PHP 号称世界上最好的语言， PHP 后台搭建起来也容易。本文就记录从基础环境安装配置到成功实现自动拉取更新的整个过程，本文涉及的系统环境是 CentOS 7 x64，软件版本会在操作中具体指明。


<!-- more -->


# 配置服务器的 PHP 支持


VPS 上面的 Nginx 已经安装好了，就不再赘述过程，不清楚的可以参考我的另外一篇文章：[GitHub Pages 禁止百度蜘蛛爬取的问题](https://www.playpi.org/2019010501.html) 。配置 PHP 的后台服务支持主要有三个步骤：一是配置安装 PHP，包括附加模块 PHP-FPM，二是配置启动 PHP-FPM 模块，三是配置重启 Nginx。由于我的机器资源问题【配置太低】，在这个过程踩了很多坑，我也会一一记录下来。

毕竟我是新手，有很多地方不是太懂，所以先参考了官网和一些别人的博客，有时候看多了也会迷惑，有些内容大家描述的不一样，所以要结合自己的实际环境来操作，有些步骤是可以省略的。这些链接我放在这里给大家参考：[参考 PHP 官网](https://secure.php.net/manual/zh/install.unix.nginx.php) 、[CentOS 7.2环境搭建实录(第二章：php安装)](https://segmentfault.com/a/1190000013344675) 、[PHP-FPM 与 Nginx 的通信机制总结](https://learnku.com/articles/23694) 、[使用Github的WebHooks实现生产环境代码自动更新](https://qq52o.me/2482.html) 。

先安装软件仓库，我的已经安装好了，重复安装也没影响。

```
yum -y install epel-release
```

## 踩着坑安装 PHP

1、下载指定版本的 PHP 源码，我这里选择了最新的版本 7.3.3，然后解压。

```
-- 下载
wget http://php.net/get/php-7.3.3.tar.gz/from/this/mirror -O ./php-7.3.3.tar.gz
-- 解压
tar zxvf php-7.3.3.tar.gz
```

2、configure【配置】，指定 PHP 安装目录【默认是 /usr/local/php，使用**\-\-prefix**参数】和 PHP 配置目录【默认和 PHP 安装目录一致，使用**\-\-with-config-file-path**参数】，我这里特意指定各自的目录，更方便管理。

```
-- 配置,并且开启 PHP-FPM 模块[使用 --enable-fpm 参数]
./configure --prefix=/site/php/  --with-config-file-path=/site/php/conf/  --enable-fpm
```

遇到报错：**configure: error: no acceptable C compiler found in $PATH**。
![缺少 c 编译器](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/old/b7f2e3a3gy1g167nenhspj20jt06tglu.jpg "缺少 c 编译器")

竟然缺少 c 编译器，那就安装吧。

```
-- 安装 gcc 编译器
yum install gcc
```

安装 gcc 编译器成功
![安装 gcc 编译器1](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/old/b7f2e3a3gy1g167o1kn4dj21hc0mrgna.jpg "安装 gcc 编译器1")

![安装 gcc 编译器2](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/old/b7f2e3a3gy1g167ol7hilj21hc0mrjsx.jpg "安装 gcc 编译器2")

安装 gcc 编译器完成后，接着执行配置，又报错：**configure: error: libxml2 not found. Please check your libxml2 installation.**。
![缺少对应的依赖环境库](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/old/b7f2e3a3gy1g167p2bqdaj20l20bxq3h.jpg "缺少对应的依赖环境库")

这肯定是缺少对应的依赖环境库，接着安装就行。

```
-- 安装2个，环境库
yum install libxml2
yum install libxml2-devel -y
```

安装依赖环境库成功
![安装环境库完成](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/old/b7f2e3a3gy1g167pq2doqj21hc0mrabc.jpg "安装环境库完成")

接着就重复上述的配置操作，顺利通过配置。
![执行配置完成](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/old/b7f2e3a3gy1g167qgfhy8j21hc0mrta5.jpg "执行配置完成")

3、编译、安装。
```
-- 编译,安装一起进行
make && make install
```

遇到报错：

```
cc: internal compiler error: Killed (program cc1)
Please submit a full bug report,
with preprocessed source if appropriate.
See <http://bugzilla.redhat.com/bugzilla> for instructions.
make: *** [ext/fileinfo/libmagic/apprentice.lo] Error 1
```

![编译安装内存不够报错](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/old/b7f2e3a3gy1g167qyojuij20rn0563yp.jpg "编译安装内存不够报错")

这是由于服务器内存小于 1G 所导致编译占用资源不足【好吧，我的服务器一共就 512M 的内存，当然不足】。解决办法：在配置【configure】参数后面加上一行内容 **\-\-disable-fileinfo**，减少内存的开销。

接着执行编译安装又报错：

```
cc: internal compiler error: Killed (program cc1)
Please submit a full bug report,
with preprocessed source if appropriate.
See <http://bugzilla.redhat.com/bugzilla> for instructions.
make: *** [Zend/zend_execute.lo] Error 1
```
这是因为虚拟内存不够用，我的主机只有 512M。没办法了，降低版本试试，先降为 v7.0.0【或者开启 swap 试试，后面发现不用了，切换低版本后就成功了】，接着重新下载、配置、编译、安装，从头再来一遍。

```
-- 下载的时候更改版本号就行
wget http://php.net/get/php-7.0.0.tar.gz/from/this/mirror -O ./php-7.0.0.tar.gz
```

更换了版本后，一切操作都很顺利，就不再考虑开启 swap 了，最终执行编译、安装完成。
![执行编译安装完成](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/old/b7f2e3a3gy1g167tfxfarj20iv0mr3zs.jpg "执行编译安装完成")

## 真正开始配置

配置、编译、安装完成后，开始编辑各个模块的配置文件，更改默认参数，包括配置 PHP 与 PHP-FPM 模块。确认配置无误，再启动对应的服务或者重新加载对应的配置【也可以使用命令验证参数配置是否正确，下文会有描述】。

### PHP 配置文件

在执行编译安装的目录，复制配置文件 **php.ini-development** 粘贴到 PHP 的配置目录【如果一开始 configure 时没有显示指定 PHP 的配置目录，默认应该和 PHP 的安装目录一致，也就是要复制粘贴在 /usr/local/php 中，而我指定了 PHP 的配置目录 /site/php/conf】。

```
cp php.ini-development /site/php/conf/php.ini
```

更改 PHP 的配置文件，修改部分参数，更改 **cgi.fix_pathinfo** 的值为0，以避免遭受恶意脚本注入的攻击。

```
vi /site/php/conf/php.ini
cgi.fix_pathinfo=0
```

### PHP-FPM 配置文件

在 PHP 的安装目录中，找到 etc 目录【如果在一开始的 configure 时没有显示指定 PHP 的安装目录，默认安装在 /usr/local/php 中，则需要到此目录下寻找 etc 目录，而我指定了 PHP 的安装目录 /site/php/】，复制 PHP-FPM 模块的配置文件 **php-fpm.conf.default**，内容不需要更改。

```
-- PHP 的附加模块的配置默认安装在了 etc 目录下
cd /site/php/etc
cp php-fpm.conf.default php-fpm.conf
```

在上面的 etc 目录中，继续复制 PHP-FPM 模块的默认配置文件。因为在上述的配置文件 **php-fpm.conf** 中，指定了 **include=/site/php/etc/php-fpm.d/\*.conf**，也就是会从此目录 **/site/php/etc/php-fpm.d/** 加载多份有效的配置文件，至少要有一份存在，否则后续启动 PHP-FPM 的时候会报错。

```
-- 先直接使用模板,不改配置参数,后续需要更改用户和组
cp php-fpm.d/www.conf.default php-fpm.d/www.conf
```

配置完成后，开始启动 PHP-FPM 模块，在 PHP 的安装目录中执行。

```
-- PHP 的附加模块的脚本默认安装在了 sbin 目录下
-- 为了方便可以添加环境变量,把 sbin、bin 这2个目录都加进去
cd /site/php
-- 配置文件合法性测试
./sbin/php-fpm -t
-- 启动,现在还不能使用 service php-fpm start 的方式,因为没有把此模块配置到系统里面
./sbin/php-fpm
-- 检验是否启动
ps aux|grep php-fpm
```

配置文件合法性检测
![配置文件合法性检测](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/old/b7f2e3a3gy1g167zej3snj20ja02t0sm.jpg "配置文件合法性检测")

可以看到正常启动了
![PHP-FPM 启动成功](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/old/b7f2e3a3gy1g167zqai4zj20nb03zt8s.jpg "PHP-FPM 启动成功")

那怎么关闭以及重启呢，PHP 5.3.3 以后的 PHP-FPM 模块不再支持 PHP-FPM 以前具有的 **./sbin/php-fpm (start|stop|reload)** 等命令，所以不要再看这种古老的命令了，需要使用信号控制：
- INT，TERM，立刻终止
- QUIT 平滑终止
- USR1 重新打开日志文件
- USR2 平滑重载所有 worker 进程并重新载入配置和二进制模块

注意，这里的信号标识和 Unix 系统中的一样，被 kill 命令所使用，其中 USR1、USR2 是用户自定义信号，PHP-FPM 模块需要自定义实现，仅供参考。

其中，根据 Unix 基础知识，INT【2】表示中断信号，等价于 Ctrl + C，TERM【15】表示终止信号【清除后正常终止，不同于编号9 KILL 的强制终止而不清除】，QUIT【3】表示退出信号，等价于 Ctrl + \，USR1【10】、USR2【12】这2个表示用户自定义信号。

所以可以使用命令 **kill -INT pid** 来停止 PHP-FPM 模块，pid 的值可以使用 **ps aux|grep php-fpm** 获取。当然，也可以使用 **kill -INT pid 配置文件路径** 来停止 PHP-FPM 模块，pid 配置文件路径 可以在 php-fpm.conf 中查看，**pid 参数**，默认是关闭的。
![使用信号控制的方式停止 PHP-FPM](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/old/b7f2e3a3gy1g1681vrhobj20om071mxh.jpg "使用信号控制的方式停止 PHP-FPM")

为了能使用 **service php-fpm start|stop|restart|reload** 的方式来进行启动、停止、重启、重载配置，这种方式显得优雅，需要把此模块配置到系统里面。在 PHP 的编译安装目录，复制文件 **sapi/fpm/init.d.php-fpm** ，粘贴到系统指定的目录即可。

```
cd /site/php-7.0.0
-- 复制文件
cp sapi/fpm/init.d.php-fpm /etc/init.d/php-fpm
-- 添加执行权限
chmod +x /etc/init.d/php-fpm
-- 添加服务
chkconfig --add php-fpm
```

![使用 service 操作 PHP-FPM](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/old/b7f2e3a3gy1g16828okbij20nq06zaaf.jpg "使用 service 操作 PHP-FPM")

### Nginx 的配置文件

接下来就是更改 Nginx 的配置文件，让 Nginx 支持 PHP 请求，并且同时设置好反向代理，把请求转给 PHP-FPM 模块处理【前提是在不影响 html 请求的情况下】，在 server 中增加一个配置 location。

```
-- 打开配置文件
vi /etc/nginx/nginx.conf
-- 更改 server 模块的内容,增加 php 的配置
-- 80端口就不用管了,直接在443端口下配置
location ~* \.php$ {
      fastcgi_index   index.php;
      fastcgi_pass    127.0.0.1:9000;
      include         fastcgi_params;
      fastcgi_param   SCRIPT_FILENAME    $document_root$fastcgi_script_name;
      fastcgi_param   SCRIPT_NAME        $fastcgi_script_name;
    }
-- 重新加载 nginx 配置,不需要重启
nginx -s reload
```

这样配置好，就会把所有的 PHP 请求转给 PHP-FPM 模块处理，同时并不会影响原来的 html 请求。

### 额外优化配置项

此外，还有一些环境变量配置、开机启动配置，这里就不再赘述了，这些配置好了可以方便后续的命令简化，不配置也是可以的。

```
-- 设置开机启动的 chkconfig 方法,以下是添加服务
cp sapi/fpm/init.d.php-fpm /etc/init.d/php-fpm
chmod +x /etc/init.d/php-fpm
chkconfig --add php-fpm
-- 设置开机启动
chkconfig php-fpm on
-- 添加环境变量,之后 php 的相关命令就可以直接使用了
vi /etc/profile
export PATH=$PATH:/site/php/bin:/site/php/sbin
source /etc/profile
```


# PHP 脚本


先在静态站点的根目录下，添加默认的 index.php 文件，用来测试，内容如下，内容的意思是输出 PHP 的所有信息。注意，PHP 文件的格式是以 **&lt;?php** 开头，以 **?&gt;** 结尾。

```
vi index.php
<?php phpinfo(); ?>
```

打开浏览器访问，可以看到成功，这就代表着 PHP 与 Nginx 的配置都没有问题，已经能正常提供服务。
![成功访问 index.php](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/old/b7f2e3a3gy1g1685gzg77j21hk0s6did.jpg "成功访问 index.php")

接下来就来测试一下复杂的脚本，可以用来自动拉取 GitHub 的提交。再创建一个 auto_pull.php 文件，内容如下，会自动到执行目录拉取 GitHub 的更新，这样就能实现镜像的自动更新了，还加入了秘钥验证【先不用管功能性是否可用，而是先测试一下复杂的 PHP 脚本能不能正常执行，脚本内容后续还要优化更改】，内容大致如下。

```
vi auto_pull.php
<?php
// 生产环境 web 目录
$target = '/site/iplaypi.github.io';
// 密钥,验证 GitHub 的请求
$secret = "test666";
// 获取 GitHub 发送的内容
$json = file_get_contents('php://input');
$content = json_decode($json, true);
// GitHub 发送过来的签名
$signature = $_SERVER['HTTP_X_HUB_SIGNATURE'];
if (!$signature) {
   return http_response_code(404);
}
list($algo, $hash) = explode('=', $signature, 2);
// 计算签名
$payloadHash = hash_hmac($algo, $json, $secret);
// 获取分支名字
$branch = $content['ref'];
// 判断签名是否匹配,分支是否匹配
if ($hash === $payloadHash && 'refs/heads/master' === $branch) {
    $cmd = "cd $target && git pull";
    $res = shell_exec($cmd);
    $res_log = 'Success:'.PHP_EOL;
    $res_log .= $content['head_commit']['committer']['name'] . ' 在' . date('Y-m-d H:i:s') . '向' . $content['repository']['name'] . '项目的' . $content['ref'] . '分支push了' . count($content['commits']) . '个commit：' . PHP_EOL;
    $res_log .= $res.PHP_EOL;
    $res_log .= '======================================================================='.PHP_EOL;
    echo $res_log;
} else {
    $res_log  = 'Error:'.PHP_EOL;
    $res_log .= $content['head_commit']['committer']['name'] . ' 在' . date('Y-m-d H:i:s') . '向' . $content['repository']['name'] . '项目的' . $content['ref'] . '分支push了' . count($content['commits']) . '个commit：' . PHP_EOL;
    $res_log .= '密钥不正确或者分支不是master,不能pull'.PHP_EOL;
    $res_log .= '======================================================================='.PHP_EOL;
    echo $res_log;
}
?>
```

接下来先手工测试一下 PHP 文件的访问是否正常，可以使用 curl 模拟请求，或者直接使用 GitHub 的 WebHooks 请求。我这里为了简单，先使用 curl 命令来测试，后续的步骤才使用 GitHub 来真正测试。

```
curl -H 'X-Hub-Signature:test'  https://blog.playpi.org/auto_pull.php
```

可以看到，访问正常，先不管功能上能不能正常实现，至少保证 PHP 可以正常提供服务，后面会和 GitHub 对接。
![使用 curl 模拟访问正常](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/old/b7f2e3a3gy1g168ab7ih9j20r206awep.jpg "使用 curl 模拟访问正常")


# 测试 WebHooks 效果


在 GitHub 中使用 WebHooks，为了表现出它的效果是什么样，我画了一个流程图，可以直观地看到它优雅的工作方式。
![WebHooks 效果流程图](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/old/b7f2e3a3gy1g168bmzii3j20lo0jwwfi.jpg "WebHooks 效果流程图")

在上一步骤中，自动拉取更新的脚本已经写好，并且使用 curl 测试过模拟访问可用，那接下来就测试功能是否可用，当然，踩坑是避免不了的，优化脚本内容也是必要的。特别要注意用户权限和脚本内容这两方面，用户权限方面我直接使用 nginx 用户，踩坑比较少，脚本内容方面要保证你的服务器支持 **shell_exec()** 这个 PHP 函数，可以在 **index.php** 文件中加一段代码 **echo shell_exec('ls -la');**，测试一下。我的机器经过测试时支持的。
![测试 shell_exec 函数](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/old/b7f2e3a3gy1g168e04yz0j21hk0s6gs3.jpg "测试 shell_exec 函数")

## 在 GitHub 设置 WebHooks

在 GitHub 对应项目的设置【Settings】中，找到 **Webhooks** 选项，可以看到已经有一些设置完成的 WebHook，这里面就包括 travis-ci 的自动构建配置。
![Webhooks 列表](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/old/b7f2e3a3gy1g1691o58jij20ty0en755.jpg "Webhooks 列表")

然后点击新建按钮，创建一个新的 WebHook【这个过程需要重新填写密码确认】，填写必要的参数，url 地址、秘钥、触发的事件，然后确认保存即可。注意，秘钥只是为了测试使用，实际应用时请更改，包括 WebHooks 的秘钥设置和 PHP 脚本里面的秘钥字符串。
![新建 WebHook](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/old/b7f2e3a3gy1g1692ybibgj20su0qxgn6.jpg "新建 WebHook")

如果是第一次创建完成，还没有触发请求的历史记录，可以先手动在 master 分支做一次变更提交，然后就会触发一次 WebHooks 事件。我这里已经有触发历史了，拿一个出来看就行了。注意，为了方便测试，只要有一次请求就行了，因为如果后续更改了脚本，不用再手动向 master 分支做一次变更提交，可以直接点击重新发送【redeliver】。
触发请求的信息，就是 http 请求头和请求体
![WebHook 触发请求携带的信息](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/old/b7f2e3a3gy1g1694gk8tdj20pl0pi3zt.jpg "WebHook 触发请求携带的信息")

VPS 的 PHP 后台服务返回的信息，可以看到正常处理了 WebHooks 请求，但是没有做拉取更新的操作，原因可能是秘钥不对或者分支不对。
![PHP 后台服务返回的信息](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/old/b7f2e3a3gy1g1694ke4dbj20or0judgk.jpg "PHP 后台服务返回的信息")

## 测试功能是否可用

以下内容所需要的 PHP 脚本：index.php、auto_pull.php 。

```
<?php
echo shell_exec("id -a");
echo shell_exec('ls -la');
phpinfo();
?>
```

```
<?php
// 生产环境 web 目录
$target = '/site/iplaypi.github.io';
// 密钥,验证 GitHub 的请求
$secret = "test666";
// 获取 GitHub 发送的内容,解析
$json = file_get_contents('php://input');
$content = json_decode($json, true);
// GitHub发送过来的签名,一定要大写,虽然http请求里面是驼峰法命名的
$signature = $_SERVER['HTTP_X_HUB_SIGNATURE'];
if (!$signature) {
   return http_response_code(404);
}
// 使用等号分割,得到算法和签名
list($algo, $hash) = explode('=', $signature, 2);
// 在本机计算签名
$payloadHash = hash_hmac($algo, $json, $secret);
// 获取分支名字
$branch = $content['ref'];
// 日志内容
$logMessage = '[' . $content['head_commit']['committer']['name'] . ']在[' . date('Y-m-d H:i:s') . ']向项目[' . $content['repository']['name'] . ']的分支[' . $content['ref'] . ']push了[' . count($content['commits']) . ']个commit' . PHP_EOL;
$logMessage .= 'ret:[' . $content['ref'] . '],payloadHash:[' . $payloadHash . ']' . PHP_EOL;
// 判断签名是否匹配,分支是否匹配
if ($hash === $payloadHash && 'refs/heads/master' === $branch) {
    // 增加执行脚本日志重定向输出到文件
    $cmd = "cd $target && git pull";
    $res = shell_exec($cmd);
    $res_log = 'Success:' . PHP_EOL;
    $res_log .= $logMessage;
    $res_log .= $res . PHP_EOL;
    $res_log .= '======================================================================='.PHP_EOL;
    echo $res_log;
} else {
    $res_log  = 'Error:' . PHP_EOL;
    $res_log .= $logMessage;
    $res_log .= '密钥不正确或者分支不是master,不能pull' . PHP_EOL;
    $res_log .= '======================================================================='.PHP_EOL;
    echo $res_log;
}
?>
```

上面已经测试了访问正常，但是为了保证 PHP 脚本的功能正常执行，接下来要优化 PHP 脚本内容了。我分析一下，根据脚本的内容，只有当秘钥正确并且当前变更的分支是 master 时才会执行拉取更新操作，看返回结果也是这样的。当前没有执行拉取更新的操作，但是我的这一个触发通知里面是表明了 master 分支【根据 ref 参数】，那就是秘钥的问题了，需要详细看一下秘钥计算的那段 PHP 代码。如果怕麻烦，直接把加密这个流程去掉【会导致恶意请求，浪费 CPU 资源】，GitHub 并没有要求一定要填写秘钥，但是我为了安全，仍旧填写。

我看了一下代码，并没有发现问题，于是加日志把后台处理的一些结果返回，看看哪里出问题了。最终发现竟然是分支名字的问题，PHP 代码通过 **$content** 没有获取到任何内容，包括分支名字、项目名字、提交信息等，而秘钥签名的处理是正常的。
![错误日志返回](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/old/b7f2e3a3gy1g1697xx5vaj20nl0g00tb.jpg "错误日志返回")

思考了一下，然后我就发现，竟然是创建 WebHooks 的时候内容传输类型【Content type】设置错误，不能使用默认的，要设置为 **application/json**，否则后台的 PHP 代码处理不了内容解析，获取的全部是空内容。
![内容传输类型设置错误](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/old/b7f2e3a3gy1g1699fp81lj20uf0oiwg0.jpg "内容传输类型设置错误")

好，一切准备就绪，再来试一次，问题又来了，果然用户权限问题是逃不了的。这个问题我早有防备，本质就是没有设置好 PHP 的用户，导致 PHP 执行脚本的时候，没有权限获取与 Git 有关的信息【执行脚本的用户没有自己的家目录，也没有存储 ssh 认证信息】。
![PHP 执行权限问题](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/old/b7f2e3a3gy1g169b32samj20pj0hpwf4.jpg "PHP 执行权限问题")

接下来就简单了，去设置 PHP 的执行用户，可能还要涉及到 Nginx。先在原先的 **index.php** 脚本中增加内容 **echo shell_exec("id -a");**，用来输出当前用户信息，发现是 nobody，那就和我想的一样了。
![输出 PHP 的执行用户信息](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/old/b7f2e3a3gy1g169d8f9fbj20sa0fsdi8.jpg "输出 PHP 的执行用户信息")

为了规范起来便于管理，还是改为和 Nginx 同一个用户比较好，还记得 PHP-FPM 模块的配置文件吗 **/site/php/etc/php-fpm.d/www\.conf **，去里面找到用户和组的配置项 **user、group**，把 nobody 改为 nginx。
![设置 PHP-FPM 的用户名和组](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/old/b7f2e3a3gy1g169e1crm2j20gl02qwec.jpg "设置 PHP-FPM 的用户名和组")

为什么选择 nginx 用户呢，因为我的 Nginx 服务使用的就是 nginx 用户，这样就不用再创建一个用户了，可以去配置文件 **/etc/nginx/nginx.conf** 里面查看。
![查看 Nginx 的用户](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/old/b7f2e3a3gy1g169fau9zzj20c806amx2.jpg "查看 Nginx 的用户")

其实，用户的设置是随意的，如果把 PHP-FPM 的用户设置为 root 更方便，但是这样有很大风险，所以不要这么做。如果非要使用 nobody 也是可以的，我只是为了方便管理用户，和 Nginx 服务共同使用一个用户。一切配置完成后别忘记重启 PHP-FPM 模块。

接着就是最重要的步骤了，把本地的 GitHub 项目所属用户设置为 nginx，并且保证 nginx 用户的家目录有 ssh 认证相关的秘钥信息，这样在以后的自动拉取更新时才能畅通无阻。我把原先的项目删掉，然后使用 sudo 命令给 nginx 用户生成 ssh 认证信息，并且重新克隆项目，克隆的同时指定所属用户为 nginx。【由于用户 nginx 没有登录 Shell 的权限，所以不能直接使用 nginx 用户登录后再操作的方式解决】

```
-- 目录不存在先创建,赋给 nginx 用户权限
mkdir -p /home/nginx/.ssh/
chown nginx:nginx -R /home/nginx/.ssh/
-- H 参数表示设置家目录环境,u 参数表示用户名
cd /site/
sudo -Hu nginx ssh-keygen -t rsa -C "plapyi@qq.com"
sudo -Hu nginx git clone https://github.com/iplaypi/iplaypi.github.io.git
-- 如果没有 iplaypi.github.io 目录的权限,也要赋予 nginx 用户
mkdir iplaypi.github.io
chown nginx:nginx iplaypi.github.io
```

好，一切准备就绪，我再来试一次。可以看到，完美执行，热泪盈眶。
![解决所有问题后成功实现自动拉取](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/old/b7f2e3a3gy1g169gkpo0cj20s30nfgmm.jpg "解决所有问题后成功实现自动拉取")

为了方便，本来我把这2个 php 文件直接放在项目里面了，放在 source 分支，再更新一下 travis-ci 的配置文件，把它们提交到 master 分支去。但是这样做的风险就是把秘钥暴露出去了，显然不可取，所以折中的办法就是把这2个文件当做模板，把秘钥隐去，放在 source 分支，以后用的时候直接复制就行了。

我想了一下，这个秘钥哪怕暴露出去看起来也没有什么大的危害，除了能伪造请求，产生多余的 pull 操作，浪费机器资源。


---
title: 使用 Stream Load 的方式批量导入数据到 Doris 中
id: 2021062601
date: 2021-06-26 22:27:23
updated: 2021-06-26 22:27:23
categories: 大数据技术知识
tags: [Doris,JSON,http,curl,Stream Load]
keywords: Doris,JSON,http,curl,Stream Load
---


最近在处理 `Doris` 数据库相关的需求，需要用到导入数据的功能。粗略看了一下官方文档，对于我这种临时处理文本数据的情况，我感觉还是使用 `Stream Load` 方式比较好，文本数据是 `JSON` 格式。本文记录导入数据的过程，以及整理的脚本。


<!-- more -->


# 思路分析


在 `Apache Doris` 的官方文档上面浏览了一下，发现它有好几种写入的方式，应对不同的场景。我看了官方的建议，对号入座，选择了 `Stream Load` 方式。因为这种方式简单快捷，并且支持 `JSON` 格式。

注意，`Apache Doris` 从 `v0.12` 版本才开始支持 `JSON` 格式的数据导入，必要情况下请读者升级版本。

我的数据文件已经准备好，可以直接导入。

先使用少量数据测试了一下，遇到了一点问题，导入失败，查看任务日志，提示：`Reason: Parse json data for JsonDoc failed. code = 2, error-info:The document root must not be followed by other values`，告知我文本数据不是 `JSON Array` 的格式。

我又查了一下文档，原来 `Apache Doris` 只支持两种 `JSON` 格式的文本文件，一种是 `JSON Array` 格式，文本需要以 `[` 开始，以 `]` 结束，每一行数据都是一个 `JSONObject`，并且以 `,` 结尾，表示整个文件是一批数据，数组里面的每个元素都是一条数据；另外一种就是普通的行式 `JSON` 文件，没有 `[]` 包围起来，直接回车换行区分每一行数据。

第一种 `JSON` 数据格式，需要借助 `sed` 重新编辑一下文件。把文件开头加上 `[` 符号，把文件末尾加上 `]` 符号，把文件的每一行行尾加上 `,` 符号。


```
--1、$表示第一行、尾行，s表示替换，a表示追加，i表示插入
--每一行行尾加上,
sed -i 's/}$/},/g' "$file"
--第一行行首加上[
sed -i '1s/^/[/' "$file"
--最后一行行尾加上]
sed -i '$s/,$/]/' "$file"
```


但是这里的第二种 `JSON` 格式只支持 `Routine Load` 方式导入，并不支持 `Stream Load` 方式。

既然数据已经是 `JSON Array` 格式了，那还需要在请求中添加参数，显式声明数据的格式结构：`-H "strip_outer_array:true"` 。

一切准备就绪，使用如下的请求就可以把数据导入 `Doris` 数据库。


```
curl --location-trusted -u test:test -T /tmp/doris-data.json -H "format: json" -H "label:doris-data-test" -H "strip_outer_array:true" http://fe-ui-host:8030/api/db_xxx/table_yyy/_stream_load
```


导入速度还挺快，1个节点大概10000条/秒。


# 脚本实现


脚本已经放在 `GitHub` 上面，读者可以提前下载查看：[stream_load_batch.sh](https://github.com/iplaypi/iplaypistudy/tree/master/iplaypistudy-normal/src/bin/20210626) ，注意替换掉自己的 `fe-ui-host:port` 就行。

既然上面已经有完整的思路，并且使用少量数据测试过，接下来就可以简单写一个脚本处理大文件数据。

处理步骤：拆分大文件为小文件、处理小文件格式、把数据导入 `Doris` 表、删除处理完的小文件。

这里面要注意，**拆分大文件为小文件**的目的是防止文件过大，一次导入任务耗时过长，中途失败就前功尽弃了。另外文件太大，`curl` 不支持，只能拆分，拆分为小于 `100MB` 的文件。

脚本内容如下：


```
#!/bin/sh
#拆分文件，导入数据库
# 判断部署脚本传入的参数个数
if [ $# -ne 2 ]; then
  echo "Usage: sh stream_load_batch.sh <data path> <table name>\n"
  exit
fi
data_path=$1
ip_port=fe-ui-host:8030
db_name=db_xx
table_name=$2
echo "data_path: $data_path, ip_port: $ip_port, db_name: $db_name, table_name: $table_name"
#拆分文件
split -l 200000 $data_path -d -a 3 temp_data_
for file in `ls .`
do
  if [ -f "$file" ] && [[ $file == temp_data_* ]];then
    #处理文件格式
    sed -i 's/}$/},/g' "$file"
    sed -i '1s/^/[/' "$file"
    sed -i '$s/,$/]/' "$file"
    #导入doris
    label=doris_data_`date '+%Y%m%d%H%M%S'`
    echo "stream_load label: $label"
    curl --location-trusted -u test:test -T "$file" -H "format: json" -H "label:$label" -H "strip_outer_array:true" http://"$ip_port"/api/"$db_name"/"$table_name"/_stream_load
    rm "$file"
    sleep 1s
  else
    echo "skip $file"
  fi
done

```


# 问题记录


在这里记录一下各种异常的情况，并截图配文字说明，各位读者遇到可以查看。

1、**"Message": "too many filtered rows"**，打开日志查看：`Reason: actual column number is less than schema column number.` 

`JSON` 数据的列数与表 `Schema` 不一致，缺少，需要确保 `JSON` 数据规范。

2、**Reason: JSON data is array-object, `strip_outer_array` must be TRUE**

数据文件是 `JSON Array` 格式，但是 `strip_outer_array` 参数没设置，无法解析。原来是官方文档这里写错了，单词拼错了：[支持的 Json 格式](http://doris.apache.org/master/zh-CN/administrator-guide/load-data/load-json-format.html#%E6%94%AF%E6%8C%81%E7%9A%84-json-%E6%A0%BC%E5%BC%8F) 。导致我折腾了一会重试好几次都不行。

![官方文档写错](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2021/20210707234327.png)

3、导入 `JSON` 文件数据，**"Message": "The size of this batch exceed the max size [104857600]  of json type data  data [ 4450871978 ]"**

`JSON` 文件太大（4.2GB），大于 `http` 传输的默认的 `100MB`，这里不建议盲目扩大传输文件的大小（文件大了传输不稳定，耗时太长），而是建议拆分小文件上传处理。

补充，如果是大文件，`Doris` 本身也有限制，此时根据实际情况可以分别设置 `be`、`fe` 的配置参数解决。

文件大小限制，修改 `BE conf：streaming_load_max_mb = 10240（大小为10GB，默认值）`

任务超时限制，预估导入时间 ≈ 10240 / 10 = 1024s，超过了默认的 `timeout` 时间（600s），需要修改 `FE` 的配置：`stream_load_default_timeout_second = 1200` 。

4、另外一种 `Broker load` 导入方式，不支持 `JSON` 格式，仅支持 `csv` 格式，并且需要启动 `Broker` 进程。

5、**Reason: Parse json data for JsonDoc failed. code = 2, error-info:The document root must not be followed by other values** 

`JSON` 文件，首尾缺失 `[]` 符号，要确保文件内容是 `JSON` 数组格式。

6、**Reason: the length of input is too long than schema. column_name**

写入的字符长度大于 `schema` 定义的，要么当做脏数据过滤掉，要么修改 `schema` 定义。


# 备注


官方文档参考：[导入 Json 格式数据](http://doris.apache.org/master/zh-CN/administrator-guide/load-data/load-json-format.html#%E6%94%AF%E6%8C%81%E7%9A%84%E5%AF%BC%E5%85%A5%E6%96%B9%E5%BC%8F) 。


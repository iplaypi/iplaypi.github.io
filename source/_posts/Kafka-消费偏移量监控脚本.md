---
title: Kafka 消费偏移量监控脚本
id: 2020050701
date: 2020-05-07 00:45:30
updated: 2020-05-07 00:45:30
categories: 大数据基础知识
tags: [Kafka,Shell]
keywords: Kafka,Shell
---


利用 `Shell` 脚本，做一个简单的 `Kafka` 消费偏移量监控功能，当数据积压过多时，发送信息。当然，发送通知利用了 `Server` 酱这个服务，感谢她。


<!-- more -->


# 入门知识


下面列举一下 `Kafka` 的基础知识、常用脚本。

众所周知，`Kafka` 是一种消息队列，性能无敌，读写速度快，吞吐量高，常用于数据的流式处理中。

此外，在日常管理维护中，会用到一些自带的脚本：

- `kafka-topics.sh --list --zookeeper host_xx:2181`：查看 `Kafka` 集群的 `Topic` 列表以及详情
- `kafka-console-producer.sh --topic topic_xx --broker-list host_xx:6667`：生产数据
- `kafka-console-consumer.sh --zookeeper host_xx:2181 --topic topic_xx`：消费数据
- `kafka-topics.sh --zookeeper host_xx:2181 --describe --topic topic_xx`：查看指定的 `Topic` 详情
- `kafka-consumer-offset-checker.sh --zookeeper host_xx:2181 --group group_xx --topic topic_xx`：查看消费情况，生产量、消费量、积压量
- `kafka-run-class.sh kafka.tools.ConsumerOffsetChecker --group group_xx --topic topic_xx --zkconnect host_xx:2181`：查看消费情况，生产量、消费量、积压量【同上】


# 脚本内容


查看消费情况时，注意到上面一点，有时候由于开发环境的原因【没有配置客户端脚本、无法直接连接 `Kafka`】，可能无法直接使用 `Kafka` 的 `Shell` 脚本：`kafka-consumer-offset-checker.sh`，此时迫不得已可以使用 `kafka-run-class.sh kafka.tools.ConsumerOffsetChecker`，直接运行 `Java` 类。

```
./bin/kafka-consumer-offset-checker.sh --zookeeper localhost:2181 --topic your_topic --group your_group
```

所以下面这个也是同样的效果：

```
kafka-run-class.sh kafka.tools.ConsumerOffsetChecker --zkconnect localhost:2181 --topic your_topic --group your_group
```

以下就整理一个 `Shell` 脚本，用来定时检测消费量，当积压数据量达到配置的阈值时，则发送通知。

注意，大家在写 `Shell` 脚本的时候，如果遇到在不同操作系统之间传输文件后不可用的问题，要注意转换格式，参考我的另外一篇博客：[未预期的符号，附近有语法错误](https://playpi.org/2020091601.html) 。

`Shell` 脚本已经被我上传至 `GitHub`：[kafka_monitor_offset.sh](https://github.com/iplaypi/iplaypistudy/tree/master/iplaypistudy-normal/src/bin/2020050701)，读者可以下载使用，脚本内容如下：

```
#!/bin/bash
#计算kafka消费偏移量,并判断数据是否积压,发送通知
#存放消费组描述,group,topic,limit的文件
file="./kafka_monitor_group_topic.txt"
#zk地址,测试环境dev1:2181
zkconnect="dev1:2181"
#原始分隔符
ORIGIN_IFS="$IFS"
#换行分隔符
IFS=$'\n'
#无限循环
while :
do
    #读取文件每一行
    for line in `cat "$file"`
    do
    if [[ "$line" =~ "#" ]];then
        #跳过注释
        #echo "skip comment:$line"
        :
    else
        #分割字符串获取4个参数:消费组描述,消费组名,topic名称,数据积压上限
        OLD_IFS="$IFS"
        IFS="$ORIGIN_IFS"
        array=($line)
        IFS="$OLD_IFS"
        description="${array[0]}"
        group="${array[1]}"
        topic="${array[2]}"
        limit="${array[3]}"
        total=0
        #查询积压信息,累加求和
        for result in `kafka-run-class.sh kafka.tools.ConsumerOffsetChecker --group "$group"  --topic "$topic" --zkconnect "$zkconnect"`;
        do
        if [[ "$result" =~ "consumer_" ]];then
            OLD_IFS="$IFS"
            IFS="$ORIGIN_IFS"
            array=($result)
            IFS="$OLD_IFS"
            factor="${array[5]}"
            #是数字才累加
            expr $1 "+" 10 &> /dev/null
            if [ $? -eq 0 ];then
                total=`expr $total + $factor`
            fi
        fi
        done
        #比较大小,大于积压上限发送通知
        if [ "$total" -gt "$limit" ];then
            echo "!!!![$description,$group,$topic],配置积压数据量上限->[$limit],当前积压数据量->[$total]"
            cat>./kafka_monitor_msg.txt<<EOF
text=Kakfa消费积压啦$total
&desp=
- 消费组描述：$description

- 消费组名：$group

- topic：$topic

- 配置积压数据量上限：$limit

- 当前积压数据量：$total
EOF
            server_key=SCU60861T303e1c479df6cea9e95fc54d210232565d7dbbfxxyyzz
            curl -X POST --data-binary @./kafka_monitor_msg.txt  https://sc.ftqq.com/"$server_key".send
            echo ""
        #else
            # echo "====[$group,$topic] is normal"
        fi
    fi
    done
    #休息10分钟
    sleep 10m
done
#还原分隔符
IFS="$ORIGIN_IFS"
```

配置文件也已经被我上传至 `GitHub`：[kafka_monitor_group_topic.txt](https://github.com/iplaypi/iplaypistudy/tree/master/iplaypistudy-normal/src/bin/2020050701)，读者可以下载使用，内容示例如下：

```
消费组1	group_xx_v1	topic_xx_v1	100000
消费组2	group_xx_v2	topic_xx_v2	500000
```


---
title: 预估 Mysql 数据表的数据大小和索引大小
id: 2019041001
date: 2019-04-10 16:27:18
updated: 2019-04-13 16:27:18
categories: 基础技术知识
tags: [Mysql,数据库,database,space]
keywords: Mysql,数据库,database,space
---





待整理。



<!-- more -->





待整理。

数据库表空间预估：<https://blog.csdn.net/laiyijian/article/details/70873568> ；

select data_length,index_length
from information_schema.tables t
where table_schema='db_yeezhao_stats'
and table_name = 't_banyan_elk_request';



待看：

https://blog.csdn.net/bisal/article/details/74784124 。


---
title: 使用 IDEA 自动生成 serialVersionUID
id: 2020-03-08 11:42:02
date: 2016-06-08 11:42:02
updated: 2020-03-08 11:42:02
categories:
tags:
keywords:
---



2016060801
基础技术知识
IDEA,Java,serialVersionUID,Serializable,InvalidCastException

今天在一个 `Java Web` 项目中，遇到反序列化的问题，在前端生成的参数列表以 `JSON` 格式保存，然后在后端需要提取参数，并反序列化为指定的实体类使用，结果反序列化失败，失败异常是 `InvalidCastException`，根本原因还是 `serialVersionUID` 不一致。本文简述一下这个知识点，也是自己复习使用。


<!-- more -->


# 自动生成


如果使用 `IDEA` 开发，可以设置自动生成。


# 作用简介






# 备注


`IDEA` 官网：[jetbrains](https://www.jetbrains.com/idea) 。


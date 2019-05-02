---
title: 使用 Gson 将 = 转为 u003d 的问题
id: 2019010601
date: 2019-01-06 21:57:22
updated: 2019-01-07 21:57:22
categories: 基础技术知识
tags: [Gson,等号编码转换,u003d]
keywords: Gson,等号编码转换,u003d
---


今天遇到一个问题，实现 Web 后台接收 http 请求的一个方法，发现前端传过来的参数值，有一些特殊符号总是使用了 unicode 编码，例如等号=，后台接收到的就是 \u003d，导致使用这个参数做 JSON 变换的时候就会出错。我看了一下这个参数取值，是前端直接填写的，而填写的人是从其它地方复制过来的，人为没有去改变，前端没有验证转换，导致传入后台的已经是这样了，那么后台只好自己想办法转换。


<!-- more -->


# 问题解决


其实就是字符串还原操作，把 Java 字符串里面的 unicode 编码子串还原为原本的字符，例如把 \u003d 转为 = 这样。

自己实现一个工具类，做编码字符串和普通字符串的转换，可以解决这个问题。

单个编码转换，公共方法示例：
````java
    /**
     * unicode 转字符串
     *
     * @param unicode 全为 Unicode 的字符串
     * @return
     */
    public static String unicode2String(String unicode) {
        StringBuffer string = new StringBuffer();
        String[] hex = unicode.split("\\\\u");
        for (int i = 1; i < hex.length; i++) {
            // 转换出每一个代码点
            int data = Integer.parseInt(hex[i], 16);
            // 追加成string
            string.append((char) data);
        }
        return string.toString();
    }
````

整个字符串转换，公共方法示例：
````java
    /**
     * 含有 unicode 的字符串转一般字符串
     *
     * @param unicodeStr 混有 Unicode 的字符串
     * @return
     */
    public static String unicodeStr2String(String unicodeStr) {
        int length = unicodeStr.length();
        int count = 0;
        // 正则匹配条件,可匹配 \\u 1到4位,一般是4位可直接使用 String regex = "\\\\u[a-f0-9A-F]{4}";
        String regex = "\\\\u[a-f0-9A-F]{1,4}";
        Pattern pattern = Pattern.compile(regex);
        Matcher matcher = pattern.matcher(unicodeStr);
        StringBuffer sb = new StringBuffer();
        while (matcher.find()) {
            // 原本的Unicode字符
            String oldChar = matcher.group();
            // 转换为普通字符
            String newChar = unicode2String(oldChar);
            int index = matcher.start();
            // 添加前面不是unicode的字符
            sb.append(unicodeStr.substring(count, index));
            // 添加转换后的字符
            sb.append(newChar);
            // 统计下标移动的位置
            count = index + oldChar.length();
        }
        // 添加末尾不是Unicode的字符
        sb.append(unicodeStr.substring(count, length));
        return sb.toString();
    }
````

调用示例：

````java
String str = "ABCDEFG\\u003d";
System.out.println("====unicode2String工具转换:" + unicodeStr2String(str));
````

输出结果：

````bash
====unicode2String工具转换:ABCDEFG=
````

截图示例：

![自己转换](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/old/b7f2e3a3gy1fyyep0kwtgj20yv0kk0ug.jpg "自己转换")


# 问题后续


后续我又在想，这个字符串到底是怎么来的，为什么填写的人会复制出来这样一个字符串，一般 unicode 编码不会出现在日常生活中的。我接着发现这个字符串是从另外一个系统导出的，导出的时候是一个类似于 Java 实体类的 JSON 格式字符串，从里面复制出来这个值，就是 \u003d 格式的。

那我觉得肯定是这个系统有问题，做 JSON 序列化的时候没有控制好序列化的方式，导致对于特殊字符就会自动转为 unicode 编码，给他人带来麻烦，当然，我无法得知系统内部做了什么，但是猜测可能是使用 Gson 工具做序列化的时候没有正确使用 Gson 的对象，只是简单的生成 JSON 字符串而已，例如看我下面的代码示例（等号=会被转为\u003d）。

使用普通的

````java
Gson gson1 = new Gson();
````

会导致后续转换 JSON 字符串的时候出现 unicode 编码子串的情况，而正确生成 Gson 对象

````java
Gson gson2 = new GsonBuilder().disableHtmlEscaping().create();
````

则不会出现这种情况。

![正确使用Gson](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/old/b7f2e3a3gy1fyyeompqqcj20zr0k3jt4.jpg "正确使用Gson")


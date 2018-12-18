---
title: JavaScript 中字符串截取方法总结
id: 2018121901
date: 2018-12-19 00:31:19
updated: 2018-12-19 00:31:19
categories: 基础技术知识
tags: [JavaScript,字符串截取]
keywords: JavaScript,字符串截取,JavaScript字符串截取
---


最近在处理数据的时候，用到了 JavaScript 编程语言，通过绕弯路来解决 ETL 处理的逻辑，其中就用到了字符串的截取方法，查 JavaScript 的文档看到了3个方法，被绕的有点晕，本文就总结一下 JavaScript 中字符串截取的方法。


<!-- more -->


# 开篇


首先声明，JavaScript 中对方法名字的大小写是敏感的，该是小写就是小写，该是大写就是大写。


# substring() 方法


## 定义和用法


>substring() 方法用于截取字符串中介于两个指定下标之间的字符


## 语法


>stringObject.substring(start, stop)

上述参数解释：

|参数名|解释说明|
|:------:|:------:|
|start|必须，一个整数（是负数则被自动置为0），要截取的子串的第一个字符在 stringObject 中的位置|
|end|可选（如果省略该参数，则被默认为字符串长度），一个整数（是负数则被自动置为0），比要截取的子串的最后一个字符在 stringObject 中的位置多1|


## 返回值


一个全新的字符串，其实就是 stringObject 的一个子字符串，其内容是从 start 到 stop-1 的所有字符，其长度为 stop 减 start。


## 注意事项


1、substring()  方法返回的子字符串包括 start 处的字符，但是不包括 stop 处的字符，这一点可能很多人会迷惑，其实很多编程语言都是这个逻辑；

2、如果参数 start 与 stop 相等，那么该方法返回的就是一个空串（即长度为0的字符串，不是null，也不是 undefined）；

3、如果 start 比 stop 大，那么该方法在截取子串之前会先交换这两个参数，这就会导致参数的顺序不影响截取的结果了；

4、参数理论上不能出现负数（在本方法中无特殊意义，在其它方法中就有特殊意义了），如果有，那么在截取子串之前会被置为0。


## 举例说明


**例子1（从下标3截取到字符串最后）：**
```javascript
<script type="text/javascript">
var str="Hello-world!"
document.write(str.substring(3))
</script>
```
输出（长度为10的子串）：
```javascript
lo-world!
```

**例子2（从下标3截取到下标8）：**
```javascript
<script type="text/javascript">
var str="Hello-world!"
document.write(str.substring(3, 8))
</script>
```
输出（长度为5的子串）：
```javascript
lo-wo
```

**例子3（从下标3截取到下标8，但是参数位置反了）：**
```javascript
<script type="text/javascript">
var str="Hello-world!"
document.write(str.substring(8, 3))
</script>
```
输出（长度为5的子串）：
```javascript
lo-wo
```

**例子4（参数为负数，从下标0截取到下标3）：**
```javascript
<script type="text/javascript">
var str="Hello-world!"
document.write(str.substring(-1, 3))
</script>
```
输出（长度为3的子串）：
```javascript
Hel
```


# substr() 方法


## 定义和用法


>substr() 方法可在字符串中截取从 start 下标开始的指定长度的子串


## 语法


>stringObject.substr(start, length)

上述参数解释：

|参数名|解释说明|
|:------:|:------:|
|start|必须，必须是数值（0、正数、负数都可以），表示要截取的子串的起始下标。如果是负数，那么该参数声明的是从字符串的尾部开始计算的位置。也就是说，-1指字符串中最后一个字符，-2指倒数第二个字符，以此类推。（参数为负数也可以理解成字符串长度加负数之和即为起始下标）|
|length|可选（如果省略该参数，那么默认为从 start 开始一直到 stringObject 的结尾对应的长度），必须是数值（0、正数、负数都可以）。|


## 返回值


一个全新的字符串，包含从 stringObject 的 start（包括 start 所指的字符）下标开始的 length 个字符。如果没有指定 length，那么返回的字符串包含从 start 到 stringObject 的结尾的字符。如果 length 指定为负数或者0，那么返回空串。如果 length 指定为远远大于 stringObject 长度的正数，那么返回的字符串包含从 start 到 stringObject 的结尾的字符。


## 注意事项


1、start 参数为负数是有特殊含义的；

2、如果 length 指定为负数或者0，那么返回空串（即长度为0的字符串，不是null，也不是 undefined）；

3、ECMAscript 没有对该方法进行标准化，因此不建议使用它。


## 举例说明


**例子1（从下标3截取到字符串最后）：**

```javascript
<script type="text/javascript">
var str="Hello-world!"
document.write(str.substr(3))
</script>
```
输出（长度为9的子串）：
```javascript
lo-world!
```

**例子2（从下标3截取长度为5的子串）：**

```javascript
<script type="text/javascript">
var str="Hello-world!"
document.write(str.substr(3, 5))
</script>
```
输出（长度为5的子串）：
```javascript
lo-wo
```

**例子3（从下标3截取长度为-5的子串，返回空串）：**

```javascript
<script type="text/javascript">
var str="Hello-world!"
document.write(str.substr(3, -5))
</script>
```
输出（返回空串）：
```javascript

```

**例子4（start 参数为负数，即从字符串倒数第5个位置截取长度为3的子串）：**

```javascript
<script type="text/javascript">
var str="Hello-world!"
document.write(str.substr(-5, 3))
</script>
```
输出（长度为3的子串）：
```javascript
orl
```


# slice() 方法


## 定义和用法


>slice() 方法用于截取字符串中介于两个指定下标之间的字符，与 substring() 方法的功能类似


## 语法


>stringObject.slice(start, end)


上述参数解释：


|参数名|解释说明|
|:------:|:------:|
|start|必须，一个整数（0、正数、负数，负数有特殊含义），要截取的子串的第一个字符在 stringObject 中的位置。如果是负数，那么该参数声明的是从字符串的尾部开始计算的位置。也就是说，-1指字符串中最后一个字符，-2指倒数第二个字符，以此类推。（参数为负数也可以理解成字符串长度加负数之和即为起始下标）|
|end|可选（如果省略该参数，则被默认为字符串长度），一个整数（负数含义与 start 相同），比要截取的子串的最后一个字符在 stringObject 中的位置多1|


## 返回值


一个全新的字符串，其实就是 stringObject 的一个子字符串，其内容是从 start 到 stop-1 的所有字符，其长度为 stop 减 start。


## 注意事项


1、slice()  方法返回的子字符串包括 start 处的字符，但是不包括 stop 处的字符，这一点可能很多人会迷惑，其实很多编程语言都是这个逻辑；

2、如果参数 start 与 stop 相等，那么该方法返回的就是一个空串（即长度为0的字符串，不是null，也不是 undefined）；

3、参数可以出现负数（比 substring() 方法灵活多了）。


## 举例说明


**例子1（从下标3截取到字符串最后）：**
```javascript
<script type="text/javascript">
var str="Hello-world!"
document.write(str.slice(3))
</script>
```
输出（长度为9的子串）：
```javascript
lo-world!
```

**例子2（从下标3截取到下标8）：**

```javascript
<script type="text/javascript">
var str="Hello-world!"
document.write(str.slice(3, 8))
</script>
```
输出（长度为5的子串）：
```javascript
lo-wo
```

**例子3（从下标3截取到下标8，但是参数使用负数，从下标-9截取到下标-4）：**

```javascript
<script type="text/javascript">
var str="Hello-world!"
document.write(str.slice(-9, -4))
</script>
```
输出（长度为5的子串，（-4）-（-9）=5）：
```javascript
lo-wo
```

**例子4（从下标3截取到下标2）：**
```javascript
<script type="text/javascript">
var str="Hello-world!"
document.write(str.slice(3, 2))
</script>
```
输出返回空串）：
```javascript

```


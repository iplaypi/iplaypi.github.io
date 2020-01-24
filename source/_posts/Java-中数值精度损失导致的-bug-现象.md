---
title: Java 中数值精度损失导致的 bug 现象
id: 2016092001
date: 2016-09-20 23:39:54
updated: 2020-01-19 23:39:54
categories: 基础技术知识
tags: [Java,bug]
keywords: Java,bug
---


在 `Java` 中隐藏着一个看似是 `bug` 的冷门现象：在一些数值计算中得不到你想象的结果，会多很多位小数点后面的数字。其实，这是浮点型数字的精度损失问题，本文简单做一个现象记录，以供读者参考。


<!-- more -->


在此说明，以下内容中涉及的代码已经被我上传至 `Github`：[LossPrecision](https://github.com/iplaypi/iplaypistudy/tree/master/iplaypistudy-normal/src/main/java/org/playpi/study/javabug) ，读者可以提前下载查看。


# 现象演示记录


假如读者按照下面的代码运行，猜猜看是什么结果。

```
public void lossPrecisionTest() {
	// 结果不等于0.06
	log.info("====sum:[{}]", 0.05 + 0.01);
	// 结果不等于0.58
	log.info("====sum:[{}]", 1 - 0.42);
	// 结果不等于401.5
	log.info("====sum:[{}]", 4.015 * 100);
	// 结果不等于1.233
	log.info("====sum:[{}]", 123.3 / 100);
}
```

请读者看到结果不要惊讶，是的，你没有看错，运行结果真的不是你想象的那样，总会多一点或者少一点。

```
2020-01-24_00:38:55 [main] INFO javabug.LossPrecision:15: ====sum:[0.060000000000000005]
2020-01-24_00:38:55 [main] INFO javabug.LossPrecision:17: ====sum:[0.5800000000000001]
2020-01-24_00:38:55 [main] INFO javabug.LossPrecision:19: ====sum:[401.49999999999994]
2020-01-24_00:38:55 [main] INFO javabug.LossPrecision:21: ====sum:[1.2329999999999999]
```

![精度损失代码示例](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2016/20200124004608.png "精度损失代码示例")

在 `Java` 中的简单浮点数类型 `float` 和 `double`，有时候不能够进行运算，其实不光是在 `Java` 中，在其它很多编程语言中也有这样的问题【本质在于硬件寄存器存储二进制数字会有精度损失】。尽管在大多数的情况下，计算的结果是准确的，但是有时候会出现意想不到的精度损失问题，读者也需要注意。

那么如何解决这个问题呢？【下面示例都以4.015这个数字演示】

## 简单四舍五入

我的第一个反应是做四舍五入【通过四舍五入把多余的数字尾巴清除掉，保留正确的数值】，`Math` 类中的 `round` 方法不能设置保留几位小数，只能像这样保留两位小数：

```
// 1-Math 四舍五入
double val = 4.015;
log.info("====sum:[{}]", Math.round(val * 100) / 100.0);
```

非常不幸，上面的代码并不能正常工作，得到的结果是错误的，给这个方法传入4.015它将返回4.01而不是4.02，如我们在上面看到的：`4.015 * 100 = 401.49999999999994`。

得到结果：

```
2020-01-24_01:04:13 [main] INFO javabug.LossPrecision:25: ====round:[4.01]
```

![简单四舍五入](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2016/20200124010553.png "简单四舍五入")

它只能保留2位小数，而且得到的结果还是错误的。

因此，如果我们需要做到精确的四舍五入，不能利用简单类型做任何运算，要想想其它方法。

## 数值格式化

那么这种问题还有没有其它办法呢？当然有，可以使用 `DecimalFormat` 格式化，代码如下：

```
// 2-DecimalFormat格式化,四舍五入,保留2位小数
DecimalFormat decimalFormat = new DecimalFormat("0.00");
decimalFormat.setRoundingMode(RoundingMode.HALF_UP);
log.info("====format:[{}]", decimalFormat.format(val));
```

运行后读者又发现，并没有得到想象的结果，仍旧是错误的，因为计算过程还是涉及到数值的精度损失问题。

```
2020-01-24_02:12:56 [main] INFO javabug.LossPrecision:33: ====format:[4.01]
```

![数值格式化结果](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2016/20200124021515.png "数值格式化结果")

此时想必一些读者已经陷入了懵圈。

## 大数值计算

那么这种问题有没有其它办法可以彻底解决问题呢？当然有，可以使用 `BigDecimal` 计算。

其实，`float` 和 `double` 只能用来做**科学计算**或者是**工程计算**【允许损失一定的数值精度】，而在**商业计算**中我们要用 `BigDecimal`【不允许损失数值精度】，精度是可以保证的。

但是要注意，`BigDecimal` 有2种构造方法，一个是：`BigDecimal(double   val)`，另外一个是：`BigDecimal(String   val)`，请确保使用 `String` 来构造，否则在计算时还是会出现精度丢失问题，这算是 `BigDecimal` 的一个坑，很多人应该也遇到过。

代码示例：

```
// 3-BigDecimal,四舍五入,保留2位小数
BigDecimal bigDecimal1 = new BigDecimal(double.toString(val));
BigDecimal bigDecimal2 = new BigDecimal(double.toString(1D));
log.info("====multiply:[{}]", bigDecimal1.multiply(bigDecimal2).setScale(2, BigDecimal.ROUND_HALF_UP));
// 如果直接使用double构造,得到的结果仍旧是错误的
BigDecimal bigDecimal3 = new BigDecimal(val);
BigDecimal bigDecimal4 = new BigDecimal(1D);
log.info("====multiply:[{}]", bigDecimal3.multiply(bigDecimal4).setScale(2, BigDecimal.ROUND_HALF_UP));
```

运行结果：

```
2020-01-24_02:12:56 [main] INFO javabug.LossPrecision:37: ====multiply:[4.02]
2020-01-24_02:12:56 [main] INFO javabug.LossPrecision:41: ====multiply:[4.01]
```

![大数值计算结果](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2016/20200124021359.png "大数值计算结果")

可以看到，使用 `String` 构造 `BigDecimal` 对象可以准确计算结果，而使用 `double` 构造 `BigDecimal` 对象还是会损失精度。

## 工具类

现在已经可以解决这个问题了，原则上是使用 `BigDecimal` 并且一定要用 `String` 来够造对象。

但是想像一下，如果我们要做一个加法运算，需要先将两个浮点数转为 `String` 类型，然后再构造成 `BigDecimal` 对象，在其中一个对象上调用 `add` 方法，传入另一个 `BigDecimal` 对象作为参数。然后把运算的结果，也是一个 `BigDecimal`对象，再转换为浮点数。

我们能够忍受这么烦琐的过程吗？肯定不能，所以我在此提供一个工具类 `BigDecimalUtil` 来简化操作，它提供以下静态方法【参考下面的方法声明】，包括加减乘除和四舍五入，调用时可以传参从而灵活设置结果的精度和取舍的模式【四舍五入、去尾、进位等等】。

代码已经被我上传至 `Github`：[BigDecimalUtil](https://github.com/iplaypi/iplaypistudy/tree/master/iplaypistudy-common-core/src/main/java/org/playpi/study/util) ，在这里就只贴出方法声明【类注释中可以看到】，读者可以自行下载使用。

```
/**
 * 大数值计算工具类
 *
 * @see #add(double, double, int, int)
 * @see #subtract(double, double, int, int)
 * @see #multiply(double, double, int, int)
 * @see #div(double, double)
 * @see #div(double, double)
 * @see #round(double, int, int)
 */
```

试运行结果如下：

![大数值计算工具类试运行结果](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2016/20200124162810.png "大数值计算工具类试运行结果")


# 备注


## 小问题

以下记录一个常见的判断差值为0的小问题。

如果在项目中碰到了如下的业务逻辑计算：

```
double val1 = 61.5;
double val2 = 60.4;
double dif = 1.1;
// 判断差值结果为0的问题
if (Math.abs(val1 - val2 - dif) == 0) {
	log.info("====差值结果为0");
	//do things
} else {
	log.info("====差值结果不为0");
}
```

结果发现这一组数据：`61.5、60.4、1.1`无法达到正确的预期结果，即结果不为0，有些人可能想破了脑袋也无法发现问题所在【千万不要试图拿计算器计算的结果对比，因为这是精度损失的问题】。

如果是有经验的开发人员一眼就可以发现问题所在，也知道应该采用如下的方式修改代码：

```
// 加上允许精度损失的判断逻辑
double exp = 10E-10;
if (Math.abs(val1 - val2 - dif) > -1 * exp && Math.abs(val1 - val2 - dif) < exp) {
	log.info("====差值结果为0");
	//do things
} else {
	log.info("====差值结果不为0");
}
```

这样的话，运行结果就会与期望一致了【同样的数值，只是更改了判断逻辑：允许精度损失】。

![差值为0的问题演示](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2016/20200124022757.png "差值为0的问题演示")

## 引申问题

除了精度损失的问题，还有一种 `byte` 类型自动转换的坑【当然，编译器有可能自动识别了问题代码，无法通过编译】。

有数值或者变量参与的加法运算，结果会转为 `int` 类型，再赋值给 `byte` 类型的变量无法通过编译，问题代码如下：

```
// 类型自动转换问题
int num1 = 5;
//1-类型无法强转,编译无法通过
//        byte num2 = num1;
byte num3 = 5;
byte num4 = 127;
//2-溢出,编译无法通过
//        byte num5 = 128;
byte num6 = 12;
//3-类型无法强转,编译无法通过(有数值参与加法运算,结果会转为int类型)
//        num6 = num6 + 1;
num6 += 1;
num6++;
// 类型自动转换问题
int i = 7;
byte b = 5;
// 1-类型无法强转,编译无法通过(有数值参与加法运算,结果会转为int类型)
//        b = b + b;
b += b;
// 2-类型无法强转,编译无法通过(有数值参与加法运算,结果会转为int类型)
//        b = b + 7;
// 3-类型无法强转,编译无法通过(有数值参与加法运算,结果会转为int类型)
//        b = b + i;
b += i;
```


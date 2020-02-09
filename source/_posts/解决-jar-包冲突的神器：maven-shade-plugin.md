---
title: 解决 jar 包冲突的神器：maven-shade-plugin
id: 2019120101
date: 2019-12-01 00:54:21
updated: 2019-12-01 00:54:21
categories: 踩坑记录
tags: [Java,Maven,shade]
keywords: Java,Maven,shade
---


最近因为协助升级相关业务 `sdk`，遇到过多次 ` jar` 包冲突的问题，此外自己在升级算法接口 `sdk` 时，也遇到过 `jar` 冲突问题。而且，这种冲突是灾难性的，不要指望通过排除、升级版本、降级版本解决，根本无法解决。

那么，最高效的方法是使用 `shade` 插件，只要加上冲突相关的配置，变更类名，即可迅速化解冲突的问题。


<!-- more -->


在此提前说明，下文中涉及的代码已经被我上传至 `GtiHub`：[iplaypistudy-shade](https://github.com/iplaypi/iplaypistudy-shade) ，独立创建了一个 `Maven` 小项目，专供演示使用，读者可以提前下载使用。


# 前提场景


在 `Maven` 项目中，当功能越来越丰富，需要的第三方依赖也就越来越多，此时很容易发生 `jar` 包冲突。而通常是因为，`Mavne` 项目中依赖了同一个 `jar` 包的多个版本，即坐标版本号不同。

一般的思路是只保留一个版本，删除掉不需要的版本，但是在复杂情况下，版本之间不兼容，不可能就这么删掉某一个【因为多个 `jar` 分别被引用了不同的方法】，所以这种思路行不通。

例如我最近遇到了一个下图这样的例子【本文开头指定的 `GitHub` 源代码可以直接下载】：

![依赖冲突的项目结构](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20200208195230.png "依赖冲突的项目结构")

其中，`module-a`、`module-b`、`module-c` 是我项目中的三个模块，`module-a` 同时依赖了子模块 `module-b` 和 `module-c`，这个很容易理解。

但是，在 `module-b`、`module-c` 中分别依赖了不同版本的 `guava`，并且在代码中有实际调用不兼容的方法，高版本的方法在低版本中不存在，低版本的方法在高版本中不存在【这属于 `guava` 没有做到向前兼容】。

代码具体内容在后面的演示中会详细描述，这里先探讨一下这种情况该怎么办。

如果排除掉 `guava v19.0` 的话【使用 `exclude` 特性】，`module-b` 会报错，如果排除掉 `guava v26.0-jre` 的话，`module-c` 会报错，但是我又希望在项目中可以同时使用 `guava v19.0` 和 `guava v26.0-jre`，为了功能考虑也必须同时使用，不能排除任何一个。

好像陷入了僵局，反正我一开始是没有什么好办法的。直到有一位同事，在我旁边偶尔提了一句，你可以使用 `maven-shade-plugin` 插件，可以完美解决你这个需求场景，方便快捷，毫无痛苦。

我自己先去了解了一下，后来又听他解释了一遍，我才恍然大悟，感觉技术观念再一次被刷新了，居然还有这种操作。

下面就简单描述一下具体怎么用 `maven-shade-plugin` 插件解决这个问题。


# 解决方案演示


## 案例说明

由于是演示 `maven-shade-plugin` 插件的使用，所以仅仅只有几行核心代码、几个核心依赖，但是完全可以表达出解决冲突的思路，源代码请读者从本文开头指定的 `GitHub` 链接下载。

如上图所示，`module-a`、`module-b`、`module-c` 是我项目中的三个模块，`module-a` 同时依赖了子模块 `module-b` 和 `module-c`。在子模块 `module-b` 中，依赖了 `guava v19.0`，在 子模块 `module-c` 中，依赖了 `guava v26.0-jre`。

好，接下来重点来了，在 `guava` 的两个版本中有下面两个不兼容的方法，特意挑选出来，用来测试：

```
// 这个方法在v19.0中有,在v26.0-jre中没有
@CheckReturnValue
  @Deprecated
  public static ToStringHelper toStringHelper(Object self) {
	return new ToStringHelper(self.getClass().getSimpleName());
}

// 这个方法在v26.0-jre中有,在v19.0中没有
public static String lenientFormat(@Nullable String template, @Nullable Object... args) {
...
}
```

当然，如果在 `module-b`、`module-c` 的子 `jar` 源码中有调用到，也是可以的，但是不直观，而且子 `jar` 的方法也不一定会执行，不好控制，所以我选择手动显示写代码调用的方式。

## 代码清单

演示代码主要内容如下。

在 `module-b` 中有一个类 `ModuleBRun`，调用了 `toStringHelper()` 方法：

```
@Slf4j
public class ModuleBRun {
	public static void main(String[] args) {
		log.info("====Hello World!");
		run();
	}
	public static void run() {
		// 这个方法在v19.0中有,在v26.0-jre中没有
		log.info("====开始执行module-b的代码");
		Objects.ToStringHelper toStringHelper = Objects.toStringHelper(new Object());
		toStringHelper.add("in", "in");
		toStringHelper.add("out", "out");
		log.info("====[{}]", toStringHelper.toString());
		log.info("====module-b的代码执行完成");
	}
}
```

![ModuleBRun](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20200208015421.png "ModuleBRun")

在 `module-c` 中有一个类 `ModuleCRun`，调用了 `lenientFormat()` 方法：

```
@Slf4j
public class ModuleCRun {
	public static void main(String[] args) {
		log.info("====Hello World!");
		run();
	}
	public static void run() {
		log.info("====开始执行module-c的代码");
		// 这个方法在v26.0-jre中有,在v19.0中没有
		log.info("====[{}]", Strings.lenientFormat("", "in", "out"));
		log.info("====module-c的代码执行完成");
	}
}
```

![ModuleCRun](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20200208015600.png "ModuleCRun")

在 `module-a` 中有一个类 `ModuleARun`，有一个 `run()` 方法，分别调用了上面的 `ModuleBRun.run()`、`ModuleCRun.run()`：

```
/**
     * 依赖b/c时,无法成功运行
     * <p>
     * 依赖b/c-shade时,可以成功运行
     */
public static void run() {
	log.info("====开始执行module-a的代码");
	ModuleBRun.run();
	ModuleCRun.run();
	log.info("====module-a的代码执行完成");
}
```

![ModuleARun](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20200208015629.png "ModuleARun")

## 运行效果

此时，尝试本地调试运行 `ModuleARun.run()`，或者使用 `Maven` 打 `jar` 包后运行：`java -jar iplaypistudy-shade-module-a-1.0-SNAPSHOT-jar-with-dependencies.jar`，需要提前使用 `maven-shade-plugin` 配置 `mainClass` 后打包。

可以发现如下错误：

```
2020-02-08_01:27:25 [main] INFO study.ModuleARun:13: ====Hello World!
2020-02-08_01:27:25 [main] INFO study.ModuleARun:24: ====开始执行module-a的代码
2020-02-08_01:27:25 [main] INFO study.ModuleBRun:19: ====开始执行module-b的代码
2020-02-08_01:27:25 [main] INFO study.ModuleBRun:23: ====[Object{in=in, out=out}]
2020-02-08_01:27:25 [main] INFO study.ModuleBRun:24: ====module-b的代码执行完成
2020-02-08_01:27:25 [main] INFO study.ModuleCRun:18: ====开始执行module-c的代码
Exception in thread "main" java.lang.NoSuchMethodError: com.google.common.base.Strings.lenientFormat(Ljava/lang/String;[Ljava/lang/Object;)Ljava/lang/String;
	at org.playpi.study.ModuleCRun.run(ModuleCRun.java:20)
	at org.playpi.study.ModuleARun.run(ModuleARun.java:26)
	at org.playpi.study.ModuleARun.main(ModuleARun.java:14)
```

![调试运行结果](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20200208014735.png "调试运行结果")

看到 `NoSuchMethodError` 就知道出现了严重的问题，如果试图使用搜索功能搜索 `Strings` 这个类，可以发现有2个一模一样的类，但是他们对应的 `guava jar` 的版本号不一致。这时候有经验的工程师就可以立马判断，编译运行 `JVM` 加载的 `jar` 对于 `ModuleCRun.run()` 方法来说是有问题的，只加载了特定版本的 `guava jar`，确保了 `ModuleBRun.run()` 方法可以顺利执行【和手动排除 `module-c` 中的 `guava v26.0-jre` 一个效果】。

如果是编译打包后使用 `java` 命令再运行，可以发现同样的错误，但是此时可以解压 `jar` 包，反编译源码，查看具体的类，可以看到编译打包后有些类是不存在的【多版本的 `jar` 只会保留一个，就会导致另一个 `jar` 中的类全部丢失，如果此时恰好有不兼容的类，那就出问题了】。

![搜索 Strings 类](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20200208013756.png "搜索 Strings 类")

那有人会想到，能不能手动排除 `module-a` 中的 `guava v19.0` 呢，我来试试，在 `module-a` 的 `pom.xml` 中对 `module-b` 添加 `exclude` 属性：

```
<dependency>
    <groupId>org.playpi.study</groupId>
    <artifactId>iplaypistudy-shade-module-b</artifactId>
    <version>${parent.version}</version>
    <!-- 这里排除会导致调用ModuleBRun.run()时出现NoSuchMethodError -->
    <exclusions>
        <exclusion>
            <groupId>com.google.guava</groupId>
            <artifactId>guava</artifactId>
        </exclusion>
    </exclusions>
</dependency>
```

调试运行结果：

```
2020-02-08_01:40:33 [main] INFO study.ModuleARun:13: ====Hello World!
2020-02-08_01:40:33 [main] INFO study.ModuleARun:24: ====开始执行module-a的代码
2020-02-08_01:40:33 [main] INFO study.ModuleBRun:19: ====开始执行module-b的代码
Exception in thread "main" java.lang.NoSuchMethodError: com.google.common.base.Objects.toStringHelper(Ljava/lang/Object;)Lcom/google/common/base/Objects$ToStringHelper;
	at org.playpi.study.ModuleBRun.run(ModuleBRun.java:20)
	at org.playpi.study.ModuleARun.run(ModuleARun.java:25)
	at org.playpi.study.ModuleARun.main(ModuleARun.java:14)
```

![调试运行结果](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20200208014710.png “调试运行结果”)

可见还是有同样的问题，运行到 `ModuleBRun()` 方法已经出错了，根源就在于多版本的 `guava` 之间无法兼容。

这里需要注意的是，在 `module-a` 中并不能随意调用 `module-c` 中 `guava v26.0-jre` 的方法，如果方法不存在的话编译不会通过【`maven` 先加载了低版本的 `guava v19.0`】。而 `module-c` 是一个独立的子模块，所以 `module-c` 中的方法不受编译的限制，只有在把 `module-a` 打包后，真正运行时才会抛出异常。

具体可以参考 `ModuleARun` 中的 `runGuava()` 方法：

```
/**
     * 依赖b/c时或者依赖b/c-shade时:
     * 在这里无法像module-c那样直接调用26.0-jre里面的方法,编译无法通过
     * 但是module-c里面的代码是单独处于模块里面,编译时无法检测,所以ModuleCRun.run()可以通过编译(编译阶段不会检测run里面的代码)
     * <p>
     * 所以:
     * 制作shade只是可以保证ModuleCRun.run()正常执行,并不能保证Strings.lenientFormat可用(连编译都无法通过)
     */
public static void runGuava() {
	log.info("====开始执行module-a的guava v19.0代码");
	Objects.ToStringHelper toStringHelper = Objects.toStringHelper(new Object());
	toStringHelper.add("in", "in");
	toStringHelper.add("out", "out");
	log.info("====[{}]", toStringHelper.toString());
	log.info("====module-a的guava v19.0代码执行完成");
	log.info("");
	log.info("====开始执行module-a的guava v26.0-jre代码");
	//        log.info("====[{}]", Strings.lenientFormat("", "in", "out"));
	log.info("====module-a的guava v26.0-jre代码执行完成");
}
```

## 插件登场

看似疑无路，其实还有柳暗花明，使用 `maven-shade-plugin` 插件可以完美解决上述的场景。

在 `module-c` 的 `pom.xml` 配置文件中，给插件 `maven-shade-plugin` 添加 `relocation` 配置，把 `com.google.common` 包路径变为 `iplaypi.com.google.common`，要确保独一无二，总体内容如下：

```
<!-- 非常好用的shade插件 -->
<plugin>
    <groupId>org.apache.maven.plugins</groupId>
    <artifactId>maven-shade-plugin</artifactId>
    <version>${maven-shade-plugin.version}</version>
    <executions>
        <execution>
            <!-- Maven的生命周期 -->
            <phase>package</phase>
            <goals>
                <!-- 插件目标 -->
                <goal>shade</goal>
            </goals>
            <configuration>
                <!-- 配置多版本jar包中类路径的重命名 -->
                <relocations>
                    <relocation>
                        <pattern>com.google.common</pattern>
                        <shadedPattern>iplaypi.com.google.common</shadedPattern>
                    </relocation>
                </relocations>
            </configuration>
        </execution>
    </executions>
</plugin>
```

![给 C 模块添加 relocation](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20200208185321.png "给 C 模块添加 relocation")

此外，在 `module-a` 中也需要配置常规的打包参数，`mainClass` 指定主类，`shadedClassifierName` 指定 `jar` 包后缀【不会用到 `relocation` 的功能】，内容如下：

```
<plugin>
    <groupId>org.apache.maven.plugins</groupId>
    <artifactId>maven-shade-plugin</artifactId>
    <version>${maven-shade-plugin.version}</version>
    <executions>
        <execution>
            <!-- Maven的生命周期 -->
            <phase>package</phase>
            <goals>
                <!-- 插件目标 -->
                <goal>shade</goal>
            </goals>
            <configuration>
                <transformers>
                    <!-- 使用资源转换器ManifestResourceTransformer,可执行的jar包 -->
                    <transformer
                                        implementation="org.apache.maven.plugins.shade.resource.ManifestResourceTransformer">
                        
                     <!-- 指定主类入口 -->                       <mainClass>org.playpi.study.ModuleARun</mainClass>
                    </transformer>
                </transformers>
                <!-- 指定jar包后缀 -->
                <shadedClassifierName>jar-with-dependencies</shadedClassifierName>
            </configuration>
        </execution>
    </executions>
</plugin>
```

![给 A 模块添加打包参数](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20200208185900.png "给 A 模块添加打包参数")

接着就可以编译打包了：`mvn clean package`，打包完成后，在 `target` 目录下找到最终的 `jar` 包，使用 `java` 命令执行：

```
java -jar iplaypistudy-shade-module-a-1.0-SNAPSHOT-jar-with-dependencies.jar
```

运行结果：

```
2020-02-08_19:08:04 [main] INFO study.ModuleARun:12: ====Hello World!
2020-02-08_19:08:04 [main] INFO study.ModuleARun:23: ====开始执行module-a的代码
2020-02-08_19:08:04 [main] INFO study.ModuleBRun:19: ====开始执行module-b的代码
2020-02-08_19:08:04 [main] INFO study.ModuleBRun:23: ====[Object{in=in, out=out
]
2020-02-08_19:08:04 [main] INFO study.ModuleBRun:24: ====module-b的代码执行完成
2020-02-08_19:08:04 [main] INFO study.ModuleCRun:18: ====开始执行module-c的代码
2020-02-08_19:08:04 [main] INFO study.ModuleCRun:20: ====[ [in, out]]
2020-02-08_19:08:04 [main] INFO study.ModuleCRun:21: ====module-c的代码执行完成
2020-02-08_19:08:04 [main] INFO study.ModuleARun:26: ====module-a的代码执行完成
```

![运行成功](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20200208190909.png "运行成功")

可以看到运行结果，所有的方法都调用成功，说明不存在多版本的 `jar` 包冲突问题了。

注意，此时不能使用**调试运行的方法**，读者会发现使用 `IDEA` 等工具直接调试运行，仍旧会出错，这是因为 `IDEA` 调试运行只是经过了 `compile` 阶段，而 `maven-shade-plugin` 插件中的 `shade` 根本没有执行。

我们配置的 `phase` 是 `package`【绑定到 `Maven` 的 `package` 生命周期】，因此，必须经过打包后，直接指定 `main` 主类运行 `jar` 包，才会看到效果。

为了知其然也知其所以然，我们肯定要看看 `jar` 包到底发生了什么变化，找到 `jar` 包，使用 `Java Decompiler` 工具反编译字节码文件，查看 `.java` 文件有什么变化，我们首先能想到的就是类路径变化了。

找到 `Strings` 类文件，可以看到它的类路径变化了，已经变为了 `iplaypi.com.google.common.base`，同时它所 `import` 的类路径也添加了 `iplaypi` 前缀。

![反编译查看源码](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20200208192045.png "反编译查看源码")

也就是说，打包完成之后，在 `jar` 包里面可以看到原本 `com.google.common` 下面的类全部被保留，`guava v19.0` 的类路径没有变化，而 `guava v26.0-jre` 的所有类路径被添加了前缀 `iplaypi`，而这正是 `shade` 的功劳。如此一来，高、低版本的所有类都分离开了，调用方可以任意使用，不会再有冲突或者缺失情况。

那我们再看看调用方的 `import` 是怎样的，分别找到 `ModuleBRun`、`ModuleCRun` 类。

![反编译后的 ModuleBRun](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20200208192409.png "反编译后的 ModuleBRun")

![反编译后的 ModuleCRun](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20200208192525.png "反编译后的 ModuleCRun")

从 `ModuleCRun` 中可以看到，调用方的代码类的 `import` 类路径也被同步替换。当然，由于 `ModuleBRun` 并没有参与 `shade relocation` 流程，所以 `import` 还是原来的样子。

**总结来说**，其实 `maven-shade-plugin` 插件并没有什么难以理解的地方，它只是帮助我们在构建 `jar` 包时，把特定的类路径转换为了我们指定的新路径，同时把所有调用方的 `import` 语句也改变了，这样就能确保这些类在加载到 `JVM` 中是独一无二的，也就不会冲突了。

它的效果概念图如下：

![效果概念图](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20200208195142.png "效果概念图")

当然，只看到现象还不够，下面我们来探讨一下它的实现方法，读者请看下一小节：**实现分析**。

## 实现分析

想要分析 `maven-shade-plugin` 插件是如何实现这个功能的，源代码少不了，下面简单分析一下。可以直接打断点调试一下源代码，跟着源代码跑一遍打包的流程即可。

首先，需要下载源代码，在 `GitHub` 上面下载：[maven-shade-plugin](https://github.com/apache/maven-shade-plugin/tree/maven-shade-plugin-3.2.1) ，注意下载后切换到指定版本的，例如我使用的版本是 `v3.2.1`，则 `git clone` 后需要 `git checkout` 到指定的 `tag`【例如：`maven-shade-plugin-3.2.1`】。

源码下载成功后，它其实也是一个 `Maven` 项目【如果导入时 `IDEA` 识别不了，可以先 `Open` 看一下，需要一些初始化动作】，可以直接以 `Module` 的形式导入 `IDEA` 中，可以直接被我们自己的项目依赖。

在 `IDEA` 中依次选择 `File`、`New`、`Module from existing Sources`【也可以在 `Project Structure` 中直接添加】，最终选择已经下载的项目源码，导入过程中还需要选择一些配置，例如项目为 `Maven` 类型，项目名称，使用默认值即可。

![添加模块](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20200209205501.png "添加模块")

由于有部分 `jar` 包需要从远程仓库拉取，如果网络不好的话【或者没配置国内的仓库、镜像】，速度有点慢，需要耐心等待。

添加成功后，需要确保 `maven-shade-plugin` 模块正常，通过 `File`、`Project Structure`、`Module` 查看。

![检查模块](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20200209205616.png "检查模块")

此时，我们 `module-a` 的 `pom.xml` 文件中配置的 `maven-shade-plugin` 插件，实际使用的就不是本地仓库的了，而是我们导入的 `Module`，这样就可以调试代码了。

找到 `maven-shade-plugin` 插件的入口，`Maven` 规定一般是 `@Mojo` 注解类的 `execute()` 方法，我在这里找到类：`org.apache.maven.plugins.shade.mojo.ShadeMojo`，`execute()` 方法在代码381行，在这个方法入口处385行：`setupHintedShader();`，打上断点，如下图：

具体的生成 `jar` 包以及 `shade relocation` 功能实现逻辑在 `org.apache.maven.plugins.shade.DefaultShader` 中，在160行的 `shadeJars()` 方法中打上断点。

接着准备调试的步骤，可以增加一个 `Run/Debug Configuration`，把 `mvn clean package` 配置成为一个 `Application`，最后点击 `debug` 按钮就可以调试了。也可以直接选中项目右键，依次选择 `Debug Maven`、`debug: package`，直接进行调试，我使用的就是这种方式，如下图：

![开始调试](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20200209205712.png "开始调试")

首先进入到第一个断点：`execute()` 方法，说明调试程序执行正常，直接进入到下一个断点：`shadeJars()` 方法【注意，我这里截图执行的是 `module-c` 打包的流程，列出的 `jar` 包近和 `module-c` 有关】：

![execute 方法](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20200209205731.png "execute 方法")

![shadeJars 方法](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20200209205746.png "shadeJars 方法")

可以从 `shadeRequest` 对象中看到 `jar` 包列表，以及 `relocators` 列表，`shade relocation` 的代码逻辑在 `org.apache.maven.plugins.shade.relocation.SimpleRelocator` 里面，里面有替换类路径、文件路径的操作实现。

接着进入到 `shadeSingleJar()` 方法，可以看到对每一个文件进行处理，替换、合并等操作。

![shadeSingleJar 方法](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20200209205801.png "shadeSingleJar 方法")

最后也可以测试一下，如果不对 `module-c` 做 `shade relocation`，最终项目打包收集的所有 `jar` 包中，是没有 `guava v26.0-jre` 的，只有 `guava v19.0`，这也可以解释为什么运行时会缺失。

## 另一种情况

假设 `module-c` 不是我们自己维护的模块，我们无权限变更，更不可能直接去更改它的 `pom.xml` 文件，此时应该怎么办。可以把 `module-c` 类比成一个独立的 `jar` 包，拥有自己的坐标，由开源组织发布【例如 `hive-client`、`hbase-client`】，被 `module-a` 依赖引用，此时我们不可能去改它的配置文件或者代码。

也有办法，那就是为这类 `jar` 包单独创建一个独立的 `module`，在这个 `module` 中完成 `shade` 操作，然后才把这个 `module` 给我们的项目引用。

在本例中，就以 `module-c` 为例，加入我们没有权限更改 `module-c` 中的代码、配置文件，只能新创建一个 `module-c-shade`，它里面什么代码都没有，只是简单地依赖 `module-c`，然后在配置文件 `pom.xml` 中做一个 `shade relocation`，把可能冲突的类解决掉。

项目结构如下图：

![复杂情况的传递依赖](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20200208200838.png "复杂情况的传递依赖")

和上面的效果一致，编译打包后，依旧可以成功运行。

可以多思考一下，根据上面的情况，还可以在什么场景下需要单独创建一个 `module`，里面没有任何代码，只是为了做影子依赖呢？

最先想到的肯定是类似上面那种，传递依赖导致的冲突，例如项目中依赖了 `es-hadoop`，而由此带来的 `guava`、`http` 等 `jar` 包冲突，我们不可能想着去改 `es-hadoop` 的 `pom.xml` 文件，因为我们不应当变更源码【太麻烦而且不利于管理】，当然也不一定能拿到源码。那么，只能单独创建一个 `module`，使用 `maven-shade-plugin` 插件做影子复制。

另外还有一种情况，如果传递依赖过多，例如 `es-hadoop` 中的 `guava`，`hbase` 中的 `commons-lang`，也没有必要为每一个 `jar` 包都单独创建一个 `module`，显得繁琐而且没必要。此时可以只创建一个 `module`，用来解决所有的依赖冲突，但是如果这些 `jar` 包之间的传递依赖本来就冲突，那还是得为每一个 `jar` 包都创建一个 `module`【此时这种 `Maven` 项目冲突过多，是不健康的，还是升级适配为好】。


# 备注


1、新建 `module` 如果卡住，可以设置参数 `archetypeCatalog=internal` 解决。

2、还要注意一点，低版本的 `maven-shade-plugin` 插件并不支持 `relocation` 参数来制作影子，编译时会报错。例如 `v2.4.3` 就不行，需要 `v3.0` 以上，例如：`v3.1.0`、`v3.2.1`。

3、引入新依赖后，要确保传递依赖不能污染了当前项目的依赖，而制作 `shade` 的目的在于这个新依赖不会有异常。

当前项目中或者当前项目的依赖中，会有一些调用，如果被传递依赖污染，会导致异常。如果是当前项目的代码显示调用，编译不会通过，但是如果是依赖 `jar` 中调用，编译阶段是检测不出来的，只会在运行调用时抛出异常。

使用上面的例子来说，如果在 `module-a` 中与 `module-b` 中的依赖有相同的，则在 `module-a` 中代码引用使用时【不是 `module-a` 中我们写的代码，而是 `module-a` 中 `jar` 的源代码】，确保使用的是 `module-a` 中的版本对应的类或者方法【即把 `module-b` 中的依赖给排除掉】，否则编译会通过，但是打包后还是会缺失。

因为 `jar` 包中的源代码在编译阶段不会被检测调用的是哪个依赖里面的类或者方法【编译时只会检测我们写的代码】，必须是打包运行后才明确【其实运行前就会把所有 `jar` 包的类加载到 `JVM` 中，由于冲突会丢弃一些】，但是运行前的加载 `JVM` 过程对于多版本的依赖无法确定具体是哪个依赖生效，编译完成后到运行的时候【执行到 `jar` 中相应的代码】，就会出问题。注意这里虽然在 `module-b` 中对部分依赖做了 `shade`，但是只是对 `module-b` 生效，对 `module-a` 是无效的，所以可能会导致 `module-a` 中的 `jar` 中源代码引用时找不到类或者方法，编译打包正常，运行时会出现 `NoClassDefFoundError` 异常。


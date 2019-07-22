---
title: Hexo博客静态资源压缩优化
id: 2018112101
date: 2018-11-21 00:53:13
updated: 2018-11-21 00:53:13
categories: 建站
tags: [建站,Hexo,代码压缩]
keywords: Hexo,静态博客,压缩优化,gulp,hexo-neat
---

使用 `hexo-cli` 生成的静态网页 html 文件，使用文本编辑器打开，可以看到内容中有大量的回车换行等空白符。尽管是空白符，但是也占据着空间大小，而且那么多，导致 html 文件偏大，网页加载时不仅浪费流量，而且还影响速度。同时，最重要的是对于手机端来说，静态页面 html 文件太大了的确不友好。所以要做优化，用术语说是压缩，其实目的就是在生成 html 文件时，尽量去除内容中多余的空白符，减小 html 文件的大小。此外，顺便也把 `css` 文件、`js` 文件一起压缩了。

<!-- more -->

# 当前现象

为了简单起见，只是列举 html 文件来看现象，目前查看生成的8个 html 静态页面（为了具有对比性，不包含当前页面），大小为314 K。
![8个 html 文件](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/old/b7f2e3a3gy1fxg5iuthmbj20sr0guta4.jpg "8个 html 文件")

打开其中一个 html 文件查看内容，可以看到很多回车换行符。
![连续多个回车换行符](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/old/b7f2e3a3gy1fxg5kn3bz2j20u00iidgy.jpg "连续多个回车换行符")

接下来就是要想办法消除这些空白符。

# 压缩方式选择

通过查看 `hexo` 官网（附上插件库：[hexo 插件库](https://hexo.io/plugins/)），搜索资料了解别人的例子，发现有两种方式：
- 一种是先全局（-g 参数）安装 `gulp` 模块，根据压缩需求再安装需要的模块，例如 `gulp-htmlclean`、`gulp-htmlmin`、`gulp-imagemin`、`gulp-minify-css`、`gulp-uglify`，每个模块都有自己的功能，另外需要单独配置一个 `js` 脚本（放在站点根目录下），指明使用的模块，文件所在目录或者通配符文件名，然后每次使用 `hexo generate` 之后再使用 `gulp` 就可以压缩文件了。这种方式灵活度高，可以自定义，而且 `gulp` 的功能与 `hexo` 解耦，如果有其它静态文件，也可以使用 `gulp` 进行压缩。但是缺点也显而易见，门槛太高了，根据我的折腾经验，如果出了问题肯定要捣鼓半天，对于我这种零基础的人来说不够友好，我不选择；
- 另一种是类似于 `hexo` 的一个插件，像其它插件或者主题一样，直接安装一个模块，在配置文件中配置你想要的压缩内容，在 `hexo generate` 的时候就可以实现压缩，无需关心具体流程，也不用配置什么脚本，非常容易，我选择这个，目前我看到有两个类似的插件：[hexo-neat](https://github.com/rozbo/hexo-neat)、[hexo-filter-cleanup](https://github.com/mamboer/hexo-filter-cleanup)，用法都差不多，我选择前者，其实这些插件也是依赖于其它插件，把多种插件的功能整合在一起而已。

# 安装配置

`hexo-neat` 插件其实是使用 `HTMLMinifier`、`clean-css`、`UglifyJS` 插件实现。

安装（由于网络不稳定因素，可能不是一次就成功，可以多试几次）
```bash
npm install hexo-neat --save
```

站点配置
编辑站点的配置文件 `_config.yml`，开启对应的属性

```bash
# 文件压缩,设置一些需要跳过的文件
# hexo-neat
neat_enable: true
# 压缩html
neat_html:
  enable: true
  exclude:
# 压缩css
neat_css:
  enable: true
  exclude:
    - '**/*.min.css'
# 压缩js
neat_js:
  enable: true
  mangle: true
  output:
  compress:
  exclude:
    - '**/*.min.js'
    - '**/jquery.fancybox.pack.js'
    - '**/index.js'
```

# 查看效果

在执行 `hexo generate` 的命令行中就可以看到压缩率输出。

![压缩率输出](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20190722232547.png "压缩率输出")

8个 html 文件被压缩后，大小只有206 K，和之前的314 K比少了108 K，虽然只是简单的数字，也可以看到压缩效果不错。
![8个文件压缩后](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/old/b7f2e3a3gy1fxg6y7u1mej20ro0guq49.jpg "8个文件压缩后")

继续打开先前打开的那个 html 文件，可以看到整个 html 文档被合并成为了一行文本内容，不影响浏览器对 html 文件的解析展示，回车换行的空白符内容肯定没有了。但是这样对于 html 文件的可读性变差了，最好还是使用一些回车换行符的，还好这些 html 文件我不会去看，能接受目前的效果。
![html 文件内容合并为一行](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/old/b7f2e3a3gy1fxg743fu8jj20u00igq3g.jpg "html 文件内容合并为一行")

# 踩坑记录

1、由于牵涉到压缩文件，所以 `hexo` 生成静态文件的速度会比以前慢一点，但是可以接受。

2、不要跳过 .md 文件，也不要跳过 .swig 文件，因为是在 `hexo generate` 阶段进行压缩的，所以这些文件必须交给 `hexo-neat` 插件处理，才能保证生成的 html 文件纯净。

3、参考博客：

- [个人博客](https://www.huangzz.xyz/hexo-optimized-file-compression.html) 
- [CSDN博客](https://blog.csdn.net/lewky_liu/article/details/82432003) 
- [个人博客](https://www.ecpeng.com/2018/04/02/%E5%85%B3%E4%BA%8Ehexo%E5%8D%9A%E5%AE%A2%E9%9D%99%E6%80%81%E8%B5%84%E6%BA%90%E5%8E%8B%E7%BC%A9%E4%BC%98%E5%8C%96/) 
- [掘金博客](https://juejin.im/post/5a93c9385188257a84625aad) 


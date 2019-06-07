---
title: FFmpeg 使用总结
id: 2019032701
date: 2019-03-27 21:28:09
updated: 2019-03-27 21:28:09
categories: 知识改变生活
tags: [FFmpeg,视频剪辑,音频剪辑,视频转码]
keywords: FFmpeg,视频剪辑,音频剪辑,视频转码
---


FFmpeg 是一款开源的软件，可以进行多种格式的视频、音频编码转换、片段剪辑。它包含了libavcodec -- 这是一个用于多个项目中音频和视频的解码器库，以及 libavformat -- 一个音频与视频格式转换库。**FFmpeg** 这个单词中的 **FF** 指的是 **Fast Forward**。FFmpeg 官网：[https://ffmpeg.org](https://ffmpeg.org) ，下载时会跳转到这里：[https://ffmpeg.zeranoe.com/builds](https://ffmpeg.zeranoe.com/builds) ，请选择合适的版本下载使用。本文记录 FFmpeg 的使用方法，基于 Windows X64 平台。


<!-- more -->


# 下载安装


## 下载

在 [https://ffmpeg.zeranoe.com/builds](https://ffmpeg.zeranoe.com/builds) 下载页面，选择适合自己操作系统的版本，我这里选择 Windows X64 的 static zip 包，解压后直接使用，无需安装。
![FFmpeg下载页面](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/old/b7f2e3a3ly1g1ivhlcgh4j21hc0q9dkh.jpg "FFmpeg下载页面")

## 解压配置环境变量

下载到指定的目录【最好放在方便管理的目录，不显得混乱】，直接解压，得到一个文件夹，里面有 bin、doc、presets 这3个子文件夹，其中 bin 里面就包含了主程序：ffmpeg、ffplay、ffprobe，这里不涉及安装的概念，程序可以直接使用。

解压主目录
![解压主目录](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/old/b7f2e3a3ly1g1ivi9q552j20o00hgt9m.jpg "解压主目录")

子文件夹 bin
![子文件夹 bin](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/old/b7f2e3a3ly1g1ividmkdbj20o00hg753.jpg "子文件夹 bin")

为了方便使用这3个主程序，需要把 bin 所在目录配置到环境变量 PATH 中【我这里是 D:\Program Files\ffmpeg\bin】，这里就不再赘述，如果不配置，每次使用命令时都要给出完整的目录，我觉得很麻烦。


# 使用示例


ffmpeg 的命令行参数的位置会影响执行的结果，例如时间参数，这与我所知道的其它工具不一样，所以参数位置不能乱放。此外，还需要注意涉及到转码的操作会比较耗时，几十分钟的视频不是几分钟能处理完的，和视频的清晰度也有关系，这个要有一定的心理准备。

1、把 mkv 格式的视频文件转为 mp4 格式的文件，视频使用 **libx264** 编码。

```
-- 如果没有配置环境变量 PATH,命令需要指定 D:\Program Files\ffmpeg\bin\ffmpeg
ffmpeg -i imput.mkv -c:v libx264 output.mp4
```

里面的字幕信息如果是和视频一起的，会自动携带输出。

2、查看视频文件的流信息，包括视频、音频、字幕。

```
-- 其中类似 Stream #0:0 格式的内容就是流信息,指定参数时可以直接使用数字编号表示流
ffmpeg -i input.mkv
```

![查看视频文件的流信息](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/old/b7f2e3a3ly1g1ivijvhopj20l50cpjso.jpg "查看视频文件的流信息")

3、mkv 文件剪辑，截取片段，指定音轨。

```
-- -ss 表示开始时间,-to 表示结束时间,
ffmpeg -ss 01:22:08 -to 01:32:16 -accurate_seek -i in.mkv -map 0:v -map 0:a:1 -codec copy -avoid_negative_ts 1 out.mkv
```

其中，**-accurate_seek** 表示画面帧数校准，**-avoid_negative_ts 1** 表示修复结尾可能的空白帧，**-map 0:v** 表示截取所有视频，**-map 0:a:1** 表示截取第2道音轨。

此外，如果把时间参数放在 -i 前面，结果总会多截取1-2秒【如上面示例】。但是如果放在后面，截取的视频片段时间准确了，然而开头的音频正常，视频有20-30秒的漆黑一片，不知道为啥。

注意，如果视频带有内嵌字幕【mkv 携带的一般是 ASS 字幕】，也需要一起剪辑的话，需要指定参数：**-map 0:s**，格式和指定视频、音频的格式一致。如果是其它格式的字幕，只要确保 ffmpeg 支持即可使用字幕相关的参数，那么怎么查看呢，很简单，使用 **ffmpeg -codecs |grep title** 命令即可搜索。

4、rmvb 文件转为 mp4 文件，涉及到编码转换。

```
-- 视频使用 h264 编码,音频使用 aac 编码
ffmpeg -i input.rmvb -c:v h264 -c:a aac out.mp4
```

这里需要注意，涉及到编码转换的比较消耗 CPU，上面这个命令把我的 CPU 消耗到 100%，动态视频详见微博：[FFmpeg视频转码CPU飙升到100%](https://weibo.com/3086148515/HmVcnm7Kl) 。其中，留意流输出信息：

```
Stream mapping:
  Stream #0:1 -> #0:0 (rv40 (native) -> h264 (libx264))
  Stream #0:0 -> #0:1 (cook (native) -> aac (native))
```

此外，FFmpeg 不支持 rmvb 格式的文件，只能转码为 mp4 的格式再使用，这里的不支持不是指不能处理，而是不能直接输出 rmvb 格式的文件，处理输入是可以的。

5、多个 mp4 文件拼接，先转为同样的编码格式的 ts 流，再拼接 ts 流接着转换为 mp4 格式的输出。

```
ffmpeg -i 1.mp4 -vcodec copy -acodec copy -vbsf h264_mp4toannexb 1.ts
ffmpeg -i 2.mp4 -vcodec copy -acodec copy -vbsf h264_mp4toannexb 2.ts
ffmpeg -i "concat:1.ts|2.ts" -acodec copy -vcodec copy -absf aac_adtstoasc output.mp4
```

简单高效，而且视频质量没有损失。


# 其它


1、如果只是为了转换 mkv 文件的格式为 mp4，也可以使用一款软件：[MkvToMp4](https://www.videohelp.com/software/MkvToMp4) 。


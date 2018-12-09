---
title: Win10 默认程序设置无效
id: 2018120901
date: 2018-12-09 17:21:14
updated: 2018-12-09 17:21:14
categories: 知识改变生活
tags: [Win10,默认程序设置]
keywords: Win10默认程序设置,Win10,默认程序设置
---


装了 Windows 10系统（教育版本），用了将近3个月了，最近发现一个诡异的现象，我的默认程序设置每次都只是设置后生效一段时间，例如视频播放器、音乐播放器，我分别设置成了迅雷看看、网易云音乐，用了半天之后，发现又变成了 Window 10系统自带的视频播放器。这个现象也不是重启之后才出现的，而是平时用着用着就会出现，很莫名其妙。后来查阅资料发现这是一个普遍的现象，这个问题的根本原因是 Windows 10自带的 bug，通常导致这个 bug 出现的原因是开启了系统的自动更新。


<!-- more -->


# 现象


在 Windows 10系统（没有打对应补丁的）中，如果开启了系统自动更新，就会触发相应的 bug：默认程序会被系统更改回系统自带的程序，例如视频播放器、音乐播放器等等。这个问题的原因用官方标识来指定就是由于 **KB3135173** 所致，同时这个 bug 已经有对应的补丁了。


按照系统设置，把某些默认程序改为自己需要的，我这里把视频播放器改为迅雷影音，设置特定格式的文件（.mkv，.mp4 等等）使用迅雷影音打开。

在桌面右下角打开**所有设置**选项
![所有设置](https://ws1.sinaimg.cn/large/b7f2e3a3gy1fy0n2j57csj20bq0ahmz4.jpg "所有设置")

在 Windows 设置中，选择**应用**选项
![选择应用](https://ws1.sinaimg.cn/large/b7f2e3a3gy1fy0nlh83ifj20xc0pwdgf.jpg "选择应用")

选择默认应用，设置视频播放器为**迅雷影音**
![设置视频播放器为迅雷影音](https://ws1.sinaimg.cn/large/b7f2e3a3gy1fy0nnjkzdcj20xc0pw445.jpg "设置视频播放器为迅雷影音")

上述的设置步骤实际上还不够，因为视频类型有很多种，还需要进一步指定每种类型的默认播放器，在默认应用下方有一个**按文件类型指定默认应用**选项
![按文件类型指定默认应用](https://ws1.sinaimg.cn/large/b7f2e3a3gy1fy0nqc3hdtj20xc0pw43w.jpg "按文件类型指定默认应用")

我这里特别关注 **.mkv**、**.mp4** 这2种格式的文件，默认应用设置为**迅雷影音**
![单独设置2种文件类型](https://ws1.sinaimg.cn/large/b7f2e3a3gy1fy0nusxmrxj20md0pw0tu.jpg "单独设置2种文件类型")

上述内容设置完成，就可以使用了，但是用不了多久，系统时不时就弹出提示框，通知默认程序重置，然后又被设置为系统内置的应用了
![弹出提示框](https://ws1.sinaimg.cn/large/b7f2e3a3gy1fy0mr10t67j20bh0h977t.jpg "弹出提示框")


# 解决方案


## 不推荐方案


更改注册表、使用命令行卸载系统默认程序，这些方案是可行的，但是对于普通用户来说太麻烦了一点，根本不懂得如何操作，而且解决方法太粗暴了，当然喜欢折腾的人是可以选择的。

以下给出几个命令行示例（需要在管理员模式下执行，打开 Windows PowerShell 的时候选择有管理员的那个）：

卸载“电影和电视”应用（星号表示通配符，下同）
```bash
get-appxpackage *zunevideo* | remove-appxpackage
```

卸载“Groove 音乐”应用
```bash
get-appxpackage *zunemusic* | remove-appxpackage
```

卸载“照片”应用
```bash
get-appxpackage *photos* | remove-appxpackage
```

如果还想恢复已经卸载的系统自带应用，可以使用以下命令（重装所有系统内置的应用）
```bash
Get-AppxPacKage -allusers | foreach {Add-AppxPacKage -register "$($_.InstallLocation)appxmanifest.xml" -DisableDevelopmentMode}
```


## 推荐直接打补丁（更新系统）


这个方法很简单，容易操作，直接在系统更新里面更新即可，确保要能更新到 **KB3135173**这个补丁才行（或者更高版本的补丁）。

我这里是已经更新完成的，等待重启，补丁标识是 **KB4469342**。
![系统更新](https://ws1.sinaimg.cn/large/b7f2e3a3gy1fy0n75u4o3j20xc0pw442.jpg "系统更新")


---
title: Git 常用命令总结
id: 2019-08-07 23:39:06
date: 2019-08-07 23:39:06
updated: 2019-08-07 23:39:06
categories:
tags:
keywords:
---
在软件工程师的工具列表中，`Git` 肯定是少不了的，作为分布式版本控制系统，`Git` 在目前非常流行，可以说，掌握 `Git` 的使用是工程师的基本功。而且，`Git` 也会为我们带来诸多的便利，根本离不开它。本文会记录一些常用的 `Git` 命令，不仅可以自查，也可以帮助读者。

另外，说明一下，关于远程仓库的选择，目前有多种多样，例如：`GitHub`、`GitLab`、`Gitee`【码云】、`coding` 等等，读者自行选择。其中，最流行的莫过于 `GitHub`，在全球非常受欢迎，被微软收购后也没有大家想象的那么可怕，反而更加开源了，现在都可以免费使用3个私有仓库了，可见微软还是愿意拥抱开源世界的。

<!-- more -->
2019080701
基础技术知识
Git,pull,push,commit


# 安装


为了使用 `Git`，本地肯定要先安装好，在次不再赘述，请读者根据自己的操作系统类型选择合适的版本。


# 初始化


对于新建的本地文件【以及文件夹】来说，需要初始化并关联到远程仓库【例如在 `GitHub` 新建了一个空白项目】，然后才能方便管理这个项目，可以按照如下流程操作：

```
# 进入项目目录
cd your_project_dir
# 初始化
git init
# 添加所有文件
git add .
# 提交到本地仓库
git commit -m "first commit"
# 关联到远程仓库
git remote add origin https://github.com/your_user_name/your_project_name.git
# 推送更新到远程仓库
git push -u origin master
```

如果本地的文件夹已经是一个标准 `Git` 项目，并且没有关联到任何远程分支，则直接关联即可，可以按照如下流程操作：

```
# 关联到远程仓库
git remote add origin https://github.com/your_user_name/your_project_name.git
# 推送更新到远程仓库
git push -u origin master
```


# 提交更新


待整理


# 合并分支


待整理，此种情况有可能会遇到代码冲突问题。


# 更换关联远程分支


如果本地代码，已经关联了远程分支，但是想更换远程分支，例如想从 `GitHub` 切换到 `GitLab`，或者想在不同的项目直接切换。则需要先解除对远程分支的关联，再关联到新的远程分支，可以按照如下流程操作：

```
# 解除对远程仓库的关联
git remote remove origin
# 关联到新的远程仓库
git remote add origin https://github.com/your_user_name/your_project_name.git
# 接下来写代码、提交即可
```


# 强制更新覆盖本地修改


有些时候我们只想要 `Git` 远程仓库的代码，而对于本地的项目中修改不做任何理会【即本地的修改不提交，放弃不要了】，这时候就需要用到 `Git pull` 的强制覆盖，可以按照如下流程操作：

```
git fetch --all
# 或者直接使用git reset --hard HEAD也行
git reset --hard origin/master 
git pull
```


# 保存用户名密码


`Git` 可以将用户名，密码和仓库链接保存在硬盘中，而不用在每次 `git push` 的时候都输入密码。保存密码到硬盘只要一条命令就可以：

```
git config credential.helper store
```

当 `git push` 的时候输入一次用户名和密码后，就会被记录下来，以后不用再次输入。但是，这样保存的密码是明文的，保存在用户家目录的 `~/.git-credentials` 文件中，读者可以查看内容，使用：

```
cat ~/.git-credentials
```

由于这种方式密码是明文存储在文件中的，所以不安全，还是推荐大家使用 `SSH` 的方式。

此外，如果想手动设置用户名、邮箱，可以按照如下流程操作：

```
# 如果项目的环境众多,就不要带--global参数,否则全局的参数设置会影响到其它Git项目
git config --global user.name [username]
git config --global user.email [email]
```


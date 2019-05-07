#!/bin/bash
# 遍历文件
index=./source/guide/index.md
for file in ./source/_post/*
do
  if [ -f $file ]
    then
      # 获取单个文件
      echo '====read file:' $file
      var1=$(grep -nE '^id: [0-9]{10}' $file | grep -E '^3:id: [0-9]{10}' | awk -F': ' '{print $2;}')
      echo '====read id:' $var1
      var2=$(grep -n '^title: ' $file | grep '^2:title: ' | awk -F': ' '{print $2;}')
      echo '====read title:' $var2
      # 判断非空必须使用双引号,否则逻辑错误
      if [ -n "$var1" ] && [ -n "$var2" ]
        then
          has=$(grep $var1 $index)
          # 为空,表示 id 不在 index 文件中
          if [ -z "$has" ]
            then
              # 追加到 index 文件中
              echo 'append to index'
            else
              echo '====index has:' $var1
          fi
        else
          echo '!!!!invalid var:' $var1 $var2
       fi
    else
      echo '!!!!invalid file:' $file
  fi
done
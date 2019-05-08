#!/bin/bash
# index 文件
index=./source/guide/index.md
index_bak=./source/guide/index_bak.md
# 文本格式
content_pattern='- id，[title](https://www.playpi.org/id.html)'
# 遍历文件夹内的所有文件
for file in ./source/_post/*.md
do
  if [ -f $file ]
    then
      # 获取单个文件的 id【在第3行】 和 title【在第2行】
      echo '====read file:' $file
      var1=$(grep -nE '^id: [0-9]{10}' $file | grep -E '^3:id: [0-9]{10}' | awk -F': ' '{print $2;}')
      echo '====read id:' $var1
      var2=$(grep -n '^title: ' $file | grep '^2:title: ' | awk -F': ' '{print $2;}')
      echo '====read title:' $var2
      # 判断非空必须使用双引号,否则逻辑错误
      if [ -n "$var1" ] && [ -n "$var2" ]
        then
          has=$(grep $var1 $index)
          # 为空,表示 id 不在 index 文件中,has 变量切记使用双引号
          if [ -z "$has" ]
            then
              # 字符串搜索替换,待搜索字符串是变量,不是字符串本身,//表示替换所有
              content=${content_pattern/title/$var2}
              content=${content//id/$var1}
              # 追加到 index 文件中
              echo '====append to index --->' $content
              # 重命名 index 文件
              mv $index $index_bak
              while read line
              do
                match_id=$(echo $line | grep -E '^- [0-9]{10}，\[' | awk -F'，' '{print $1;}' | awk -F' ' '{print $2;}')
                if [ -z "$match_id" ]
                  then
                    echo '====match_id is null,write this line:' $line
                  else
                    echo '====compare,match_id:' $match_id
                    # 比较大小
                    
                    
                fi
              done < $index_bak
              # 再次重命名 index 文件
              mv $index_bak $index
            else
              # index 文件已经存在,不处理
              echo '====index has:' $var1
          fi
        else
          echo '!!!!invalid var:' $var1 $var2
       fi
    else
      echo '!!!!invalid file:' $file
  fi
done
#!/bin/bash
# index 文件
index=./source/guide/index.md
index_bak=./source/guide/index_bak.md
# 文本格式
content_pattern='- id，[title](https://www.playpi.org/id.html)'
# 遍历文件夹内的所有文件
for file in ./source/_posts/*.md
do
  if [ -f $file ]; then
    # 获取单个文件的 id【在第3行】 和 title【在第2行】
    echo '================================================================'
    # echo '====read file:' $file
    var1=$(grep -nE '^id: [0-9]{10}' $file | grep -E '^3:id: [0-9]{10}' | awk -F': ' '{print $2;}')
    # echo '====read id:' $var1
    var2=$(grep -n '^title: ' $file | grep '^2:title: ' | awk -F': ' '{print $2;}')
    # echo '====read title:' $var2
    # 判断非空必须使用双引号,否则逻辑错误
    if [ -n "$var1" ] && [ -n "$var2" ]; then
      has=$(grep $var1 $index)
      # 为空,表示 id 不在 index 文件中,has 变量切记使用双引号
      if [ -z "$has" ]; then
        # 字符串搜索替换,待搜索字符串是变量,不是字符串本身,//表示替换所有
        content=${content_pattern/title/$var2}
        content=${content//id/$var1}
        # 追加到 index 文件中
        echo '====prepare append to index:' $content
        # 重命名 index 文件
        mv $index $index_bak
        # 标记是否写入/是否同一年份
        has_write=''
        is_same_year=''
        while read line
        do
          match_id=$(echo $line | grep -E '^- [0-9]{10}，\[' | awk -F'，' '{print $1;}' | awk -F' ' '{print $2;}')
          # 搜索到匹配内容并且还没写入
          if [ -n "$match_id" ] && [ -z "$has_write" ]; then
            # echo '====compare,match_id:' $match_id
            # 判断是否相同年份
            if [ ${var1:0:4} == ${match_id:0:4} ]; then
              is_same_year='1'
              # 比较大小
              if [ $var1 -gt $match_id ]; then
                echo '====gt match_id append to index:' $content
                echo $content >> $index
                echo $line >> $index
                has_write='1'
              else
                echo $line >> $index
              fi
            else
              echo $line >> $index
            fi
          elif [ -n "$is_same_year" ] && [ -z "$has_write" ]; then
            # 当前行没有搜索到匹配内容,并且同一年份,并且还没写入,说明已经是当前年份的最后一行了,直接写入即可
            echo '====last append to index:' $content
            echo $content >> $index
            echo $line >> $index
            has_write='1'
          else
            # 没有搜索到匹配内容,或者不同年份,或者已经写入,直接写入即可
            echo $line >> $index
          fi
        done < $index_bak
        # 删除 index_bak 文件,此时只有最新的 index 文件
        rm $index_bak
      else
      # 在 index 文件中已经存在,无需处理
      echo '====index has:' $var1
      fi
    else
    echo '!!!!invalid var:' $var1 $var2
    fi
  else
  echo '!!!!invalid file:' $file
  fi
done
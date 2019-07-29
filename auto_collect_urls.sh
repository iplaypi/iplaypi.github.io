#!/bin/bash
# urls 文件 
urls=./baidu_urls.txt
# url 格式 
content_pattern='https://www.playpi.org/id.html'
# 遍历文件夹内的所有文件 
for file in ./source/_posts/*.md
do
  if [ -f $file ]; then
    # 获取单个文件的 id【在第 3 行】
    echo '================================================================'
    # echo '====read file:' $file
    var1=$(grep -nE '^id: [0-9]{10}' $file | grep -E '^3:id: [0-9]{10}' | awk -F': ' '{print $2;}')
    # echo '====read id:' $var1
    # 判断非空必须使用双引号，否则逻辑错误 
    if [ -n "$var1" ]; then
      has=$(grep $var1 $urls)
      # 为空，表示 id 不在 urls 文件中，has 变量切记使用双引号 
      if [ -z "$has" ]; then
        # 字符串搜索替换，待搜索字符串是变量，不是字符串本身，// 表示替换所有 
        content=${content_pattern//id/$var1}
        # 追加到 urls 文件中 
        echo '====prepare append to urls:' $content
        echo $content >> $urls
      else
      # 在 urls 文件中已经存在，无需处理 
      echo '====urls has:' $var1
      fi
    else
    echo '!!!!invalid var:' $var1
    fi
  else
  echo '!!!!invalid file:' $file
  fi
done
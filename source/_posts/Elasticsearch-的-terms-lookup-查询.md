---
title: Elasticsearch 的 terms lookup 查询
id: 2019060601
date: 2019-06-06 01:38:12
updated: 2019-06-06 01:38:12
categories: 大数据技术知识
tags: [Elasticsearch,lookup,filter]
keywords: Elasticsearch,lookup,filter
---


对分析工作熟练的人，想必都用过 `Excel` 中的 `VLOOKUP` 函数，参考我的另一篇博客：[VLOOKUP 函数跨工作表跨文件使用方式](https://www.playpi.org/2017051401.html) ，但是目前已经被官方取消【2019年末宣布】，转而使用 `XLOOKUP`。此外，可能很少有人知道，在 `Elasticsearch` 中也存在这样一个类似的查询接口：`terms lookup`，可以跨索引查询数据，看起来很是方便，本文简单介绍一下。开发环境基于 `Elasticsearch v5.6.8`。


<!-- more -->


# 接口介绍


在 `Elasticsearch` 中，是存在父子文档这种设置的，即在父索引中嵌套一个子索引，例如在主帖中嵌套用户的信息。这样查询主帖时，不仅可以同时指定用户的筛选条件，而且返回数据时可以连同用户信息一起返回，在使用层面很方便。

但是，这种存储方式显然冗余了大量的用户信息，如果数据量级很大，浪费了大量的存储空间，不可取。随着业务的数据增长，这种设计方式肯定要被淘汰掉，转而选择把父子文档拆分，此时如果还想使用类似父子文档的查询特性，可以选择跨索引查询，即 `terms lookup`。

例如查询某个用户关注列表中所有用户发表的主帖，如果是拆开查询，需要两步：先查出关注列表，再查询发表的主帖，而使用 `terms lookup` 查询只需要一步即可。但是这种方式有诸多的限制，下面会举例说明，我想这也是为了性能考虑。

其实，`terms lookup` 是一个查询过滤器【`filter`，从 `v0.90` 开始引进】，只不过不需要用户指定 `filter`、`filtered` 等关键字，所以用户使用起来也无感知。

参考官方文档：[query-dsl-terms-query](https://www.elastic.co/guide/en/elasticsearch/reference/5.6/query-dsl-terms-query.html) 。

读者在继续往下阅读之前可以先去了解一下与**缓存**相关的知识点，例如：如何开启、如何关闭、删除缓存、自定义命名、什么场景应该使用、哪些查询不会被缓存。


# 演示示例


我在这里使用两个典型的场景进行演示，一个可以支持，另一个不能支持。假如有2个索引：用户 `my-index-user`、主帖 `my-index-post`，它们之间是通过用户的 `id` 来进行关联的【在用户索引中字段为 `item_id`，在主帖索引中字段为 `user_item_id`】，即用户可以任意发表主帖。

## 场景一

查询某个用户的关注列表中所有用户发表的主帖。【可以支持】

查询思路分两个步骤，一是利用 `item_id` 查询用户索引，返回关注列表 `friends` 中的所有 `item_id`；二是利用一步骤中返回的 `itemt_id` 列表，去匹配主帖的 `user_item_id` 字段，从而查询所有的主帖。

转换为 `terms lookup` 查询为：

```
POST my-index-post/_search
{
  "query": {
    "bool": {
      "must": [
        {
          "terms": {
            "user_item_id": {
              "index": "my-index-user",
              "type": "user",
              "id": "0f42d65be1f5287e1c9c26e3728814aa",
              "path": "friends"
            }
          }
        }
      ]
    }
  }
}
```

![场景一查询结果](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20200216174317.png "场景一查询结果")

可以看到查询出来2743条主帖，这样的查询方式是不是很方便呢。

下面可以拆分步骤简单验证一下，先查询用户索引，把关注列表查出来：

```
POST my-index-user/user/_search
{
  "query": {
    "bool": {
      "must": [
        {
          "terms": {
            "id": [
              "0f42d65be1f5287e1c9c26e3728814aa"
            ]
          }
        }
      ]
    }
  },
  "_source": [
    "item_id",
    "friends",
    "birth_year"
  ]
}
```

![场景一验证用户索引](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20200216175058.png "场景一验证用户索引")

可以看到有3个用户，接着使用 `item_id` 列表去查询主帖：

```
POST my-index-post/_search
{
  "query": {
    "bool": {
      "must": [
        {
          "terms": {
            "user_item_id": [
              "98681482902",
              "63639783663",
              "59956667929"
            ]
          }
        }
      ]
    }
  }
}
```

![场景一验证主帖索引](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20200216175113.png "场景一验证主帖索引")

可以看到，也是2743条数据，完全一致。

## 场景二

查询出生日期是1994年的所有用户发表的主帖。【不可以支持】

查询思路分两个步骤，一是利用 `birth_year` 查询用户索引，返回满足条件的所有 `item_id`；二是利用一步骤中返回的 `itemt_id` 列表，去匹配主帖的 `user_item_id` 字段，从而查询所有的主帖。

转换为 `terms lookup` 查询为：

```
POST my-index-post/_search
{
  "query": {
    "bool": {
      "must": [
        {
          "terms": {
            "user_item_id": {
              "index": "my-index-user",
              "type": "user",
              "birth_year": 1994,
              "path": "item_id"
            }
          }
        }
      ]
    }
  }
}
```

![场景二查询结果](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20200216175820.png "场景二查询结果")

可以看到，报错了：`[terms] query does not support [birth_year] within lookup element`，想象很美好，现实很残酷，其实 `Elasticsearch` 并不支持对用户索引使用非 `id` 字段条件，也就是指定内层的索引条件，只能是和 `id` 有关的，这也是一种限制。

## 引申说明

`terms` 个数限制，对于场景一来说，如果关注列表中的 `item_id` 过多，也会导致查询主帖的 `terms` 匹配失败，因为 `terms` 查询是有个数限制的。可以通过配置更改，设置 `terms` 最大个数：`index.max_terms_count`，默认最大个数为65535，可以根据集群情况降低，例如设置为10000，为了集群稳定，一般不需要设置那么大。

内层返回字段需要存储，对于场景一来说，如果关注列表 `friends` 字段没有存储【`stored_fields` 属性】，只是做了索引，也是无法支持的，会报错：`[terms] query does not support [friends] within lookup element`。

![不支持未存储的字段](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20200216180618.png "不支持未存储的字段")

对于场景二来说，表现的就是 `terms lookup` 无法支持复杂的查询条件，只能是和 `id` 字段有关的，这样就降低了 `Elasticsearch` 的计算量。


# 流程总结


回顾我们发送到 `Elasticsearch` 的查询条件，可以看到，它只是一个简单的过滤查询，包含一个 `terms` 过滤器，匹配指定的 `user_item_id`。只是该查询条件中的 `terms` 过滤器使用了一种不同的技巧，即不是明确指定某些 `term` 的值【没有明确指定 `user_item_id` 取值列表】，而是从其它的索引中动态加载【从用户索引中加载】。

可以看到，我们的过滤器是基于 `user_item_id` 字段，但是并没有进一步指定取值列表，而是引用了新的属性：`index`、`type`、`id`、`path`。`index` 属性指明了加载 `terms` 的索引名称【在上面的例子中是 `my-index-user`】，`type` 属性指明了索引类型【在上面的例子中是 `user`】，`id` 属性指明了我们在指定索引上使用的查询匹配条件，最后 `path` 指明了 `Elasticsearch` 应该从哪个字段中加载 `terms`【在上面的例子中是 `friends`】。

总结一下，`Elasticsearch` 所做的工作就是从 `my-index-user` 索引的 `user` 类型中，`id` 为 `0f42d65be1f5287e1c9c26e3728814aa` 的文档里加载 `friends` 字段中的所有取值。这些取得的值将用于 `terms filter` 来过滤从 `my-index-post` 索引中查询到的文档，过滤条件是文档的 `user_item_id` 字段的值在过滤器中存在。


# 备注


1、需要注意的是，由于使用到了缓存机制，比较消耗 `Elasticsearch` 的内存，不建议大量任意使用，使用前一定要思考：「这个过滤器会被多次重复使用吗？」，避免不必要的资源浪费。

2、`path` 参数指定的字段必须是存储在 `Elasticsearch` 中的，可以返回，如果只是做了索引是不支持的【使用 `_source.excludes` 关键字排除，只支持查询而已，无法返回】。

a
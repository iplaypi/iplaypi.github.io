---
title: 一个诡异的 ES-Hadoop 问题
id: 2019061301
date: 2019-06-13 21:41:49
updated: 2019-06-19 21:41:49
categories: 大数据技术知识
tags: [Elasticsearch,Hadoop,es-hadoop]
keywords: Elasticsearch,Hadoop,es-hadoop
---


最近在处理 Elasticsearch 数据的时候，使用的是 ES-Hadoop 组件，方便快捷，但是今天遇到一个小问题，让我着实折腾了一番。折腾的原因在于我本以为一切顺利，确实没想到会有一些奇怪的事情发生，这也让我积累了经验，其中错误的核心内容为：`Incompatible types found in multi-mapping: Field [your_field] has conflicting types`，本文详细记录分析问题的过程，文中内容涉及的开发环境为 `Elasticsearch v5.6.8`、`Windows7 X64`。


<!-- more -->


# 问题出现


代码的逻辑很简单，使用 Spark 连接 Elasticsearch 集群【使用 ES-Hadoop 组件】，读取数据，然后简单处理一下就写入 HDFS 中，没有任何复杂的逻辑。但是在程序运行的过程中，出现了异常：

```
org.elasticsearch.hadoop.EsHadoopIllegalArgumentException: Incompatible types found in multi-mapping: Field [query.bool.must.match.content] has conflicting types of [OBJECT] and [KEYWORD].
```

![异常信息日志](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20190619230522.png "异常信息日志")

根据图中的异常信息，可以猜测是字段问题：类型冲突，下面来逐步分析。


# 问题分析


看起来是存在不兼容的 `type`，根本原因是字段类型冲突，一个字段同时存在两种类型：OBJECT、KEYWORD，但是这个字段名称也太诡异了：`query.bool.must.match.content`，不用说，肯定是有人在查询时误把查询语句作为数据 `put` 到了 Elasticsearch 数据库中，导致产生了这种奇怪的字段名称，去数据库查询一下就知道。

## 查询数据量

由于从异常信息中无法得知其它有效信息，只能使用 `exists` 查询语句，看看有几条这种数据，查询语句如下：

```
{
  "query": {
    "bool": {
      "must": [
        {
          "exists": {
            "field": "query.bool.must.match.content"
          }
        }
      ]
    }
  }
}
```

![查询数据结果](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20190619230502.png "查询数据结果")

通过查询，可以看到有一条数据，这一看就是一条标准的查询语句，被作为数据存入了 Elasticsearch 数据库，应该是有人误操作。

可以看到，整个索引别名【底下可能会有多个真实索引名称】里面只有这一条数据，那为什么会冲突呢？其实，不能只看数据量，因为可能数据被删除了，但是 `mapping` 中仍旧保留着字段信息【Elasticsearch 的 `mapping` 无法针对字段粒度进行删除、更新】，所以要进一步查看索引别名下面的每个真实索引名称对应的 `mapping` 中是不是都有这个字段。因此，直接查看 `mapping` 更为准确。

## 查看索引配置

这里需要特别注意一个问题，现在很多索引的 `mapping` 都是使用**匹配模版**构造的，即定义了一些规则【例如字段名称以什么开头、以什么结尾就会存储成对应的类型】，然后字段都以这些规则自动生成，例如如果写入一条数据，里面的内容字段以 `_content` 结尾，则会自动分词，方便检索。这种方式的好处是可以综合考虑多种情况，提前全部设置为模版，不仅管理起来方便，也为以后的字段扩展留下余地。

一般的模版信息格式如下，了解一下即可：

```
{
    "mappings": {
        "your_index_name": {
            "_source": {
                "excludes": [
                    "content",
                    "author"
                ]
            },
            "dynamic_templates": [
                {
                    "template_1": {
                        "mapping": {
                            "index": "not_analyzed",
                            "type": "string"
                        },
                        "match": "*",
                        "match_mapping_type": "string"
                    }
                },
                {
                    "content1": {
                        "mapping": {
                            "analyzer": "wordsEN",
                            "type": "text"
                        },
                        "match": "*_content"
                    }
                },
                {
                    "price": {
                        "mapping": {
                            "type": "float"
                        },
                        "match": "*_price"
                    }
                }
            ]
        }
    }
}
```

![查看模版信息](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20190619230438.png "查看模版信息")

模版里面的内容其实是一个 JSON 数组，可以设置多个匹配规则，方便字段的规范管理。

接着使用 `head` 插件查看 `mapping`，把几个真实的索引下面的 `mapping` 都检查了一遍【一共四个】，只在两个索引下面找到了期望的 `mapping` 信息，如下：

第一处：

```
{
    "properties": {
        "query": {
            "properties": {
                "bool": {
                    "properties": {
                        "must": {
                            "properties": {
                                "match": {
                                    "properties": {
                                        "content": {
                                            "properties": {
                                                "query": {
                                                    "type": "keyword"
                                                },
                                                "type": {
                                                    "type": "keyword"
                                                }
                                            }
                                        }
                                    }
                                },
                                "range": {
                                    "properties": {
                                        "publish_date": {
                                            "properties": {
                                                "from": {
                                                    "type": "long"
                                                },
                                                "include_lower": {
                                                    "type": "boolean"
                                                },
                                                "include_upper": {
                                                    "type": "boolean"
                                                },
                                                "to": {
                                                    "type": "long"
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
```

![第一处mapping](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20190619230357.png "第一处mapping")

第二处：

```
{
    "properties": {
        "query": {
            "properties": {
                "bool": {
                    "properties": {
                        "must": {
                            "properties": {
                                "match": {
                                    "properties": {
                                        "content": {
                                            "type": "keyword"
                                        }
                                    }
                                },
                                "term": {
                                    "properties": {
                                        "site_id": {
                                            "type": "keyword"
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
```

![第二处mapping](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20190619230345.png "第二处mapping")

虽然只找到了两处，但是足够造成前面的异常，通过对比可以发现其中的细微不同之处，核心的地方在于 `content` 的类型不一致，对比如下：

```
-- OBJECT
{
    "content": {
        "properties": {
            "query": {
                "type": "keyword"
            },
            "type": {
                "type": "keyword"
            }
        }
    }
}

-- KEYWORD
{
    "content": {
        "type": "keyword"
    }
}
```

好了，破案了，问题根本原因被找到，那么怎么解决呢？


# 问题解决


直接查看源码，先看看 ES-Hadoop 是怎么处理的，根据异常信息里面的方法调用，主要就是看 `MappingSet.addToFieldTable()`，我的环境依赖的 ES-Hadoop 坐标为：

```
<dependency>
    <groupId>org.elasticsearch</groupId>
    <artifactId>elasticsearch-hadoop</artifactId>
    <version>5.6.8</version>
</dependency>
```

我查询到的源代码如下：

```
@SuppressWarnings("unchecked")
    private static void addToFieldTable(Field field, String parent, Map<String, Object[]> fieldTable) {
	String fullName = parent + field.name();
	Object[] entry = fieldTable.get(fullName);
	if (entry == null) {
		// Haven't seen field yet.
		if (FieldType.isCompound(field.type())) {
			// visit its children
			Map<String, Object[]> subTable =  new LinkedHashMap<String, Object[]>();
			entry = new Object[]{field, subTable};
			String prefix = fullName + ".";
			for (Field subField : field.properties()) {
				addToFieldTable(subField, prefix, subTable);
			}
		} else {
			// note that we saw it
			entry = new Object[]{field};
		}
		fieldTable.put(fullName, entry);
	} else {
		// We've seen this field before.
		Field previousField = (Field)entry[0];
		// ensure that it doesn't conflict
		if (!previousField.type().equals(field.type())) {
			throw new EsHadoopIllegalArgumentException("Incompatible types found in multi-mapping: " +
			                        "Field ["+fullName+"] has conflicting types of ["+previousField.type()+"] and ["+
			                        field.type()+"].");
		}
		// If it does not conflict, visit it's children if it has them
		if (FieldType.isCompound(field.type())) {
			Map<String, Object[]> subTable = (Map<String, Object[]>)entry[1];
			String prefix = fullName + ".";
			for (Field subField : field.properties()) {
				addToFieldTable(subField, prefix, subTable);
			}
		}
	}
}
```

![源代码片段](https://raw.githubusercontent.com/iplaypi/img-playpi/master/img/2019/20190619230307.png "源代码片段")

看到这里就没有什么办法了，因为 Elasticsearch 数据不规范【本来是正常的，后来人为因素破坏了 `mapping` 数据结构】，导致 ES-Hadoop 无法处理，从而抛出异常。

但是，仔细思考一下，ES-Hadoop 的这种处理逻辑显然有点问题，因为客户端在读取数据的时候，可以指定同一个索引下的多个类型，当然，也可以同时指定多个索引。然而，有时候为了方便，会把很多索引的别名设置成同一个，这样在查询或者取数的时候就不用指定索引名称的列表了。

如果是这样，多个索引下面的 `mapping` 不能保证一致，由于是手动设置的索引别名，索引数据可能多种多样【另一层面的知识点，Elasticsearch 官方是不允许同一个索引下的多个类型拥有不同的字段属性的，而且，6.x 取消了索引类型的概念】，但是客户端在读取数据的时候是可以过滤字段的，使用 `es.read.field.include`、`es.read.field.exclude` 参数分别设置必要的字段、过滤的字段。这样的话，开发者就可以把可能有问题的字段去除掉，避免影响程序的正常运行。然而可以看到，ES-Hadoop 没有给任何机会，遇到类型冲突的字段直接抛出异常，程序无法正常运行。

我觉得应该在日志中给出警告，提醒开发者可能出现的问题，但是程序仍旧可以正常运行，在运行的过程中，如果真的遇到字段冲突的问题【例如同时读取了不同索引中的相同字段，但是字段类型不一致，无法处理】，程序自会抛出运行时异常，而如果从头至尾没有任何字段问题，程序就可以正常运行了，开发者甚至毫无感知发生了什么。

于是，接着我找到一个 GitHub 的讨论帖子：
[https://github.com/elastic/elasticsearch-hadoop/issues/1074](https://github.com/elastic/elasticsearch-hadoop/issues/1074 )、
[https://github.com/elastic/elasticsearch-hadoop/issues/1192](https://github.com/elastic/elasticsearch-hadoop/issues/1192 )，
发现早就有人遇到同样的问题了，并且提出了建议，作者也把它作为开发特性，计划在以后的版本发布。目前来看，应该在 v6.4.2、v6.5.0 修复了这个问题，但是我使用的还是 v5.6.8，而且在帖子中也可以看到一些人同样是 v5.6.0、v5.6.1、v5.6.5 版本有问题。此时，我要么升级版本，要么更改源码，要么重建数据源，这些方式对于我来说都有未知的风险，我陷入了沉思。

突然，一阵灵光闪现，我觉得可以适当降低小版本号，可能以前 ES-Hadoop 是没有这个限制的，以防走弯路，同时我又参考了别的项目代码，发现 v5.5.0 可以使用。于是，我更改了构件的版本号，其它地方不用变动【要确保低版本的构件可以支持高板的 Elasticsearch】，测试了一下，果然可以，遇到字段冲突不会抛出异常，程序可以正常运行。此时，我再想查查源代码是怎么处理的，发现已经找不到 v5.6.8 那个 `MappingSet` 类了。

依赖构件坐标如下：

```
<dependency>
    <groupId>org.elasticsearch</groupId>
    <artifactId>elasticsearch-hadoop</artifactId>
    <version>5.5.0</version>
</dependency>
```

这种情况虽然看起来有潜在的危险，我也知道，但是我在自定义配置中，使用 `es.read.field.include` 参数只读取少量的字段，就可以保证有冲突的字段不影响我的业务处理逻辑，也认为对整个应用程序没有什么危害。


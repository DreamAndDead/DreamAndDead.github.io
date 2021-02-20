---
title: Recover mysql table structure from frm file
date: "2018-09-27T10:20:00Z"
categories:
- Mysql
tags: 
- devops
- mysql
- trouble-shooting
featured_image: images/featured.jpg
aliases:
- /2018/09/27/recover-mysql-table-structure-from-frm-file.html
---

mysql 正常运行的时候，[查看 table 的结构][show-create-table-doc]并不是困难的事。
但是有时 mysql 发生故障，这种方法便不再可行。

当遇到故障，通常使用新的 mysql 实例来恢复当前的数据。
建表是非常重要的步骤，我们必须有其它的方法来寻找 table 的结构。

<!--more-->

# table 结构定义在哪里

通常关注的用户数据，底层都实际存储在 mysql 数据目录。
其它的元数据也不例外，比如 table 表结构的定义。

mysql 数据目录文件结构是非常清晰的，
- 目录对应数据库
- frm 文件存储了 table 结构的定义
- ibdata 文件存储了 mysql 的元数据及其它

table 定义的结构，就存在于 frm 文件中，当然管理元数据的 ibdata 也会有记录。

当存在 frm 文件的时候，恢复表结构相对容易；
但是如果执行了 drop table，便删除了 frm 文件，本文所提供的方法就爱莫能助了。
这种情况下，可以尝试从 ibdata 恢复表结构，这暂时不在下面的讨论范围内。

# 解析 table 结构

下面介绍 3 种方式，从 frm 文件中，解析得到 `create table` 命令。

## mysqlfrm

mysqlfrm 是 [mysql utilities 工具集][mysql-utilities-download] 中的其中之一，
用于分析 frm 文件生成 create table 命令。
目前已经不再更新，部分功能并入了新版本的 mysql shell（version 8 及以后）。

mysql utilities 需要 python2 环境，安装非常简单。

```
$ tar -xvzf mysql-utilities-1.6.5.tar.gz
$ cd mysql-utilities-1.6.5
$ python setup.py build
$ python setup.py install
```

mysqlfrm 支持两类模式来解读 frm：

### 直接分析

这种模式比较直接，逐个字节分析 frm 文件，尽可能的提取信息。

这种模式下，需要使用 `--diagnostic` 参数。

```
$ mysqlfrm --diagnostic /data/sakila/actor.frm
```

### 借助 mysql 实例分析

这种模式，借助新的 mysql 实例，从中完成 frm 的分析工作。
可以用两种方式来指定，如何开启新的 mysql 实例。

一，从当前的 mysql 服务中 spawn，使用 `--server` 指定 mysql 服务

```
$ mysqlfrm --server=root:pass@localhost:3306 --port=3310 /data/sakila/actor.frm
```

二，启动新的 mysql 实例，使用 `--basedir` 指定 mysql 程序路径

```
$ mysqlfrm --basedir=/usr/local/bin/mysql --port=3310 /data/sakila/actor.frm
```

`--port` 给新的实例指定端口，是为了避免与当前的 3306 端口出现冲突。



## dbsake

这是偶然发现的一个工具，文档中它这样介绍自己：

> dbsake - a (s)wiss-(a)rmy-(k)nif(e) for MySQL

作者一定是一个对 mysql 很有心得的人，
工具从下载，安装到使用，简单，利落。

```
$ curl -s get.dbsake.net > dbsake
$ chmod u+x dbsake
$ ./dbsake frmdump [frm-file-path]
```

## online service

有一些在线的服务，也关注这样的问题。
使用过的[twindb online][twindb-online]，体验非常好，相关的工具集也很棒。

从 `Recover Structure -> from .frm file` 入口，上传 frm，就可以得到 `create table` 命令。



# 写在最后

在使用上，可以多个工具都测试一下，对比哪个工具恢复的命令更为完善可取，选择最佳的。

参考：
- [mysqlfrm official doc][mysqlfrm-doc]
- [dbsake project doc][dbsake-frmdump-doc]


[show-create-table-doc]: https://dev.mysql.com/doc/refman/8.0/en/show-create-table.html

[mysql-utilities-download]: https://downloads.mysql.com/archives/utilities/
[mysqlfrm-doc]: https://docs.oracle.com/cd/E17952_01/mysql-utilities-1.6-en/mysqlfrm.html

[dbsake-frmdump-doc]: https://dbsake.readthedocs.io/en/latest/commands/frmdump.html

[twindb-online]: https://recovery.twindb.com/


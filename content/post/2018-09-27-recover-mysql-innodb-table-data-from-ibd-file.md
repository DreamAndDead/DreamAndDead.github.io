---
date: "2018-09-27T00:00:00Z"
tags: devops mysql trouble-shooting
title: Mysql table suddenly doesn't exists
---

最近内部的 mysql 数据库发生了一件奇怪的事，其中有一个表 users625 突然出现问题，
所有对它的操作都报错误 `数据表不存在`。

```
mysql> select count(*) from users625;
ERROR 1146 (42S02): Table 'km8.users625' doesn't exist
```

`show tables` 它还显示在列表里，在 mysql 数据目录中也可以找到对应的表文件，也没有
进行过删除操作，突然出现这样的错误非常奇怪。

<!--more-->

内部运行环境：

| 名称 | 值 |
|:---:|:---:|
| OS  |Debian Squeeze x64|
|mysql 版本| 5.1|
|mysql 引擎| innodb|


# 发生了什么

突然出现这种情况，第一反应必定是想办法将表中的用户数据找回，但是目前发生问题的情况与原因都不明晰，
不能轻举妄动。

查看 mysql 日志，在操作出错的时候，日志这样显示：

```
mysqld: 180926 11:10:53  InnoDB: cannot calculate statistics for table km8/users625
mysqld: InnoDB: because the .ibd file is missing.  For help, please refer to
mysqld: InnoDB: http://dev.mysql.com/doc/refman/5.1/en/innodb-troubleshooting.html
mysqld: 180926 11:10:53 [ERROR] MySQL is trying to open a table handle but the .ibd file for
mysqld: table km8/users625 does not exist.
mysqld: Have you deleted the .ibd file from the database directory under
mysqld: the MySQL datadir, or have you used DISCARD TABLESPACE?
mysqld: See http://dev.mysql.com/doc/refman/5.1/en/innodb-troubleshooting.html
mysqld: how you can resolve the problem.
```

其中提到3个可追溯的点：
- ibd file
- DISCARD TABLESPACE
- http://dev.mysql.com/doc/refman/5.1/en/innodb-troubleshooting.html


了解这3点提到的内容，应该对判断情况有很好的帮助。

## ibd file

日志中提问，是否丢失了 ibd 文件？先到 mysql 数据目录下查找，

```
.
├── ibdata1
├── .......
├── .......
└── km8
    ├── ............
    ├── ............
    ├── users625.frm
    ├── users625.ibd
    ├── ............
    └── ............
```

users625 的 ibd 文件是存在的，与之一起的还有文件 users625.frm 。

根据官方文档[对 frm 文件的描述][frm-file-format]，frm 文件是用来保存 table 表结构（即 table 的定义）的，无论使用什么存储引擎。

与之相对的，ibd 文件是用来存储表数据（即行数据）的，通常情况下，所有数据都会存储在系统的 ibd 文件，
但是当开启选项 [innodb_file_per_table][innodb_file_per_table-option] 的时候，每个表的数据会使用单独的 ibd 文件来存储。


当前的 mysql 就开启了这个选项，

```
[mysqld]
innodb_file_per_table=1
```

目前 frm 与 ibd 文件都存在，从中恢复数据便存在一些希望。

## DISCARD TABLESPACE

日志中提到的 `DISCARD TABLESPACE` 其实是在猜测导致 ibd 文件丢失的原因，因为它会删除相应 table 的 ibd 文件（所谓 tablespace）。

```
> ALTER TABLE km8.users625 DISCARD TABLESPACE;
```

底层的 users625.ibd 文件就会被删除，丢失所有表数据。

根据目前情况来看， ibd 文件还存在，所以它不是导致错误的原因。

## trouble shooting doc

[日志中提到的参考链接][innodb-troubleshooting]，其中列举了多种情况，和当前问题相关的是一个[子链接][innodb-troubleshooting-datadict]，
按照它提供的方法，尝试进行数据恢复。

# 数据恢复

官方文档提到的[恢复数据][innodb-troubleshooting-datadict]的方法，思路很清晰：
1. 启用相同版本的 mysql 实例（启用选项 innodb_file_per_table）
2. 建立同样结构的数据表
3. 替换 ibd 文件（保持文件权限一致）
4. 导入 ibd 文件中的数据
5. 使用 mysqldump，导出数据
6. 将导出的数据导入原数据库

我按照这种方式尝试恢复数据，并不是那么顺利：

## 如何获得 table 表结构？

在第2步，需要建立同样结构的数据表，目前只有 frm 和 ibd 文件，怎么样得到 `create table` 命令？

根据底层数据存储的理解，table 表结构存储在 frm 文件中，而目前已经有[相应的方法][recover-table-from-frm]从中提取出 `create table` 命令，
这样就可以用于在新的 mysql 实例中建立 table 。

## tablespace id 不对应？

在第4步，尝试导入数据的时候，

```
> ALTER TABLE km8.users625 IMPORT TABLESPACE;
ERROR 1030 (HY000): Got error -1 from storage engine
```

总是出现失败，同时在 mysql 新实例的日志中发现这样的错误：

```
mysqld: InnoDB: Error: tablespace id in file './km8/users625.ibd' is 18446744073709551615, but in the InnoDB
mysqld: InnoDB: data dictinary it is 1.
```

原来在内部，ibd 文件本身有一个 id，必须和 mysql innodb 内部的 table 元数据相对应，才可以进行导入。

根据错误信息搜索到[一篇文章][innodb-tablespace-id-error]，其中提到两种办法：
1. 重复建表，因为 mysql 内部的 tablespace id 是累计递增的，预先建立 （18446744073709551615 - 1）张表，再建立
   users625 表，就可以对应 id，并进行导入。
2. 修改 ibd 文件，因为 tablespace id 存储于 ibd 文件，找到它并将其修改为 1，使之与内部的 id 对应，就可以进行导入。

考虑第 1 种方法，要预先建立上亿张空表？！这根本不可能。

于是尝试第 2 种方法，研究 ibd 的文件格式，修改对应 id。

用二进制编辑器打开 users625.ibd 文件，

![users625-ibd-hexdump](http://on7blnbb0.bkt.clouddn.com/18-9-27/5492997.jpg)

```
18:26:08 UTC - mysqld got signal 6. This could be because you hit a bug. It is also possible that this
binary or one of the libraries it was linked against is corrupt, improperly built or misconfigured.
This error can also be cuased by malfunctioning hardware.
```

不敢相信自己的眼睛，居然有错误 log 在二进制文件里？！ibd 的文件格式可没有这么说明过。

随便找一个邻居表正常的 ibd 文件作对比，

![normal-ibd-hexdump](http://on7blnbb0.bkt.clouddn.com/18-9-27/50479657.jpg)

看来是出现了 bug ，崩溃的环境直接将数据文件给毁了，这也解释了为什么 tablespace id 会那么大，因为 log
覆盖了原本的 id 字段，使 mysql 解读出了一个好笑的数字。

## 暂时放弃

这种情况下，还没有办法将数据恢复回来，只能暂时将表删除，新建空表，保证上层应用程序可以运行。
将 ibd 文件备份下来，看后续还没有其它的办法将其恢复。

# 检测所有 table 状态

当前只发现一个出现问题的 table ，可能同时也有其它的 table 出现问题。对此需要做一个全面的检测，
检测有没有其它的表受到牵连。

```
$ mysqlcheck --all-databases
```

# 写在最后

数据库的备份是非常重要的！直接导入备份数据，是解决问题最保险最便捷的办法。
如果没有备份，遇到 bug 丢失数据，只能怪时运不济。

同时数据库也最好选择稳定的版本，降低出现 bug 的概率。

[innodb_file_per_table-option]: https://dev.mysql.com/doc/refman/5.5/en/innodb-parameters.html#sysvar_innodb_file_per_table
[frm-file-format]: https://dev.mysql.com/doc/internals/en/frm-file-format.html
[innodb-troubleshooting]: http://dev.mysql.com/doc/refman/5.1/en/innodb-troubleshooting.html
[innodb-troubleshooting-datadict]:https://dev.mysql.com/doc/refman/8.0/en/innodb-troubleshooting-datadict.html
[recover-table-from-frm]: https://www.cnblogs.com/dreamanddead/p/recover-mysql-table-structure-from-frm-file.html
[innodb-tablespace-id-error]: http://www.chriscalender.com/recovering-an-innodb-table-from-only-an-ibd-file/

[twindb-github]: https://github.com/twindb/undrop-for-innodb

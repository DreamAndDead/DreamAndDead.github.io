---
title: "基础算法之 C++ 基础"
author: ["DreamAndDead"]
date: 2021-04-14T18:15:00+08:00
lastmod: 2021-04-16T17:32:49+08:00
tags: ["algorithm", "oj", "programing"]
categories: ["Algorithm"]
draft: true
featured_image: "images/featured.jpg"
series: ["基础算法"]
---

oj 中，不会用到太多

涉及到算法中的语言知识点

更方便


## io {#io}


### input {#input}

<https://blog.csdn.net/oneline%5F/article/details/80746759>

-   getchar == scanf %c
-   scanf 输入 %s %c
-   scanf 针对换行的问题
-   cin 的返回值，scanf 的返回值
    比如输入 0 终止
    while (cin >> N)
    vs
    while (scanf())
-   输入遇到 EOF 的时候，cin 和 scanf 的效果


### output {#output}

-   cout & printf
    -   printf 更容易控制格式
        ‰5d？输出 5 个长度
        %05d 不足补0？
    -   printf 相应的格式化字符列表
        %lld 输出 long long
-   cout 在于泛型
-   cout 如何输出二进制数

<https://www.techiedelight.com/binary-representation-number/>


## c stdlib {#c-stdlib}


### mem {#mem}

`<cstring>`

memcpy/memset

int A[10]，

mem 单位是 byte，注意使用 sizeof(A)


## stl {#stl}


### container {#container}

数据结构的核心


### iterator {#iterator}

pure [] and iterator


### string {#string}

string char[] char\*

.size()  strlen

-   stringstream
    -   用于存储输出
    -   how to clear stringstream

<https://stackoverflow.com/questions/20731/how-do-you-clear-a-stringstream-variable>

`string` 和 `cstring` 是不一样的

-   how to copy a string instance?

    <https://stackoverflow.com/questions/12678819/how-to-copy-a-string-of-stdstring-type-in-c>

-   string and char\*

    <https://cloud.tencent.com/developer/article/1525205>


### pair {#pair}

how to use

<https://blog.csdn.net/sinat%5F35121480/article/details/54728594>


### vector {#vector}

<https://www.cnblogs.com/xylc/p/3653036.html>


### std::array {#std-array}

固定长度，不可变化

array<int, 10>

not

array<int, n>


### queue {#queue}

必须使用 q.front(); q.pop();

q.pop() 不返回值

push() 向后添加，back() 索引
pop() 向前删除，front() 索引

如何清空队列

<https://www.cnblogs.com/zhonghuasong/p/7524624.html>

priority queue

no front(), just top()

如何区分大顶，小顶堆？

<https://www.cnblogs.com/huashanqingzhu/p/11040390.html>


### set {#set}

find 方法，返回 iter

没找到，返回 end()

自定义类型，需要提供 < 方法

分为类内重载 和 类外重载

<https://zhuanlan.zhihu.com/p/320519745>

-   类外，public 属性，重载
-   类外，friend，访问 private 属性
-   类内，

如果是类内重载，无法用于 set 的比较


### algo {#algo}

std::copy

copy 数组

chapter 11

sort

std::sort

<https://en.cppreference.com/w/cpp/algorithm/swap>

custom comp method

std::swap

std::count

std::reverse

reverse

fill\_n vs memset

std::equal

<https://stackoverflow.com/questions/5405203/is-there-a-standard-way-to-compare-two-ranges-in-c>

compare two ranges

only 3 arguments, enough


### math {#math}

combine function

<https://stackoverflow.com/a/42285958/9167165>

TODO 恰好整除

<numeric>

std::accumulate

chapter 17


## class {#class}

-   定义类
    -   构造函数
    -   默认值
    -   快速初始化

-   重载运算符

<https://www.runoob.com/cplusplus/cpp-overloading.html>

-   比较方法

-   静态成员

<http://c.biancheng.net/cpp/biancheng/view/209.html>

<https://blog.csdn.net/vict%5Fwang/article/details/80994894>


## high level {#high-level}


### lambda {#lambda}


### 模板 template {#模板-template}

next perm 数组通用化

<https://blog.csdn.net/qq%5F35637562/article/details/55194097>


### cpp traits {#cpp-traits}


## c++ profile {#c-plus-plus-profile}

<https://blog.csdn.net/absurd/article/details/1477532>

<http://airekans.github.io/cpp/2014/07/04/gperftools-profile>

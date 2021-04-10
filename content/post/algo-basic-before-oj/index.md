---
title: "写在 OJ 之前"
author: ["DreamAndDead"]
date: 2021-04-07T18:21:00+08:00
lastmod: 2021-04-10T14:33:13+08:00
tags: ["algorithm", "oj", "programing"]
categories: ["Algorithm"]
draft: true
comment: false
featured_image: "images/featured.jpg"
series: ["基础算法"]
---

OJ 是锻炼算法的好去处。
很多经典的题目，考察算法的方方面面，磨练思维能力。
有意义，有趣。

每个题目都需要的
适用于每个算法的


## 语言 {#语言}

解决问题需要算法，算法需要组织成程序，程序需要用语言编写。

个人推荐使用 C++ 语言。
C++ 接近底层，
方便估计数据结构的空间消耗，以及算法运行的时间效率。
虽然 Python Java 都是优秀的语言，
但是都存在独立的 vm 层，
而且很多高阶数据结构和方法的实现对使用者是不透明的，
不利于估计空间消耗与时间效率。


## 复杂度 {#复杂度}


### 大 O {#大-o}

算法的时间和空间效率常常用复杂度来衡量。
对于一般的算法分析，常常只简化使用大 O 表示法。

常见的复杂度有 `O(logN) O(N) O(NlogN) O(N^2) O(N!) O(2^N)` ，
N 是数据集规模。

不同复杂度的增长速度是不同的。

{{< figure src="images/complexity.png" caption="Figure 1: 不同复杂度的增长速度" >}}

虽然不同复杂度的增速不同，
考虑问题时也要有绝对性。
时间复杂度为 `O(N!)` 的算法虽然比 `O(N)` 慢，
但如果 N 很小，在时间约束下也是可以完成的，
同样是可接受的算法。


### 绝对估计 {#绝对估计}


#### 常见数值 {#常见数值}

<!--list-separator-->

-  阶乘

    阶乘规模增加的是非常快的，可以看到其位数基本随着 n 的增加基本呈线性，由系数 1 慢慢增加

    {{< figure src="images/factor.png" >}}

<!--list-separator-->

-  组合数

    组合数 C(n, k) 中，k = n/2 时，组合数是最大的。

    基本趋势也是线性上升，系数约为 0.25 左右。

    趋势和 pow(2) 是相近的，因为 sum(C(n, k)) = pow(n, 2)

    {{< figure src="images/comb.png" >}}

<!--list-separator-->

-  2 的幂

    2 的幂对应的位数基本也呈线性增长，不过速度比阶乘要慢。

    关键记忆

    -   `2^10 = 10^3`
    -   `2^32 = 10^10`
    -   `2^64 = 10^19`

    {{< figure src="images/power_2.png" >}}

<!--list-separator-->

-  浮点数的精确位

    float

    double


#### 时间估计 {#时间估计}

<!--list-separator-->

-  3000ms 对应什么概念

    对于单线程程序， `运行时间 = 运行指令数 * 每个指令的周期数 * cpu 周期时间` 。

    cpu 内部的时钟一个 tick 为一个周期，周期时间为主频的倒数， 比如 `Intel(R) Core(TM) i7-6700 CPU @ 3.40GHz` ，
    周期时间为 `1/3.4G`

    不同指令，需要不同周期数才能完成，比如乘法指令就比加法指令消耗更多周期

    运行指令数是由程序生成的指令以及数据规模决定的

    根据上面的分析，粗略简化为

    -   `1G` 个指令运行 `1s = 1000ms`

    <!--listend-->

    ```cpp
    #include <ctime>
    #include <iostream>

    using namespace std;

    int main()
    {

        clock_t start,end;
        start = clock();

        for(int i = 0; i < 1e9; i++)
          {
    	i++;
          }

        end = clock();

        cout <<"running time: " << (float)(end-start)*1000.0/CLOCKS_PER_SEC << "ms" << endl;
    }
    ```

    ```text
    running time: 1765.85ms
    ```

    <https://blog.csdn.net/qq%5F30763385/article/details/104580790>

    <https://zhuanlan.zhihu.com/p/90829922>

<!--list-separator-->

-  io 时间

    memset 大数组

    for loop 重置

    scanf 和 cin 的速度


#### 空间估计 {#空间估计}

<!--list-separator-->

-  131072k 是什么概念

    内存管理的最小单位为 字节(1 byte = 8 bits)，4G 内存对应 `4*1024*1024*1024` bytes。

    cpp 中类型直接对应空间的大小，也用字节表示，用 `sizeof` 计算。

    | bytes | of | char      | = | 1    |
    |-------|----|-----------|---|------|
    | bytes | of | bool      | = | 1    |
    | bytes | of | short     | = | 2    |
    | bytes | of | int       | = | 4    |
    | bytes | of | long      | = | 8    |
    | bytes | of | longlong  | = | 8    |
    | bytes | of | float     | = | 4    |
    | bytes | of | double    | = | 8    |
    | bytes | of | void      | = | 1    |
    | bytes | of | void\*    | = | 8    |
    | bytes | of | int[1000] | = | 4000 |

    `空间 = 类型大小 * 数组长度`

    -   `int[1000]` 占用空间 4k
    -   `int[1000 000]` 占用空间 4000 k
    -   `int[1000 000 000]` 占用空间 4000 000k


## 解题过程 {#解题过程}

某种意义上，算法就是分析模型，针对问题代入模型
从问题中抽象得到，再应用于问题，采用相似性


### 问题 {#问题}


### 算法 {#算法}


### 复杂度估计 {#复杂度估计}


#### 时间 {#时间}


#### 空间 {#空间}


### 溢出 {#溢出}


#### 整数溢出 {#整数溢出}


#### 递归栈溢出 {#递归栈溢出}


### 边界 {#边界}


#### 最简单情况 {#最简单情况}


#### 最大边界情况 {#最大边界情况}


## 调试方法 {#调试方法}


### PE {#pe}

空行的问题

输出的间隔之间存在空行

最后不存在空格，PR error

there is a blank line after each test case

there is a blank line between each test case

是不同的


### WA {#wa}


#### printf {#printf}


#### gdb {#gdb}

cgdb .out -ex "b main" -ex "r"

$home/.cgdb/cgdbrc

```nil
set winsplit=even
set wso=vertical
```

<!--list-separator-->

-  gdb 的检查指令

    如何查看数字的不同格式


#### 寻找数据集 {#寻找数据集}

uva udebug

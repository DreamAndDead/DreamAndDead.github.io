---
title: "基础算法之枚举排列组合"
author: ["DreamAndDead"]
date: 2021-03-25T15:10:00+08:00
lastmod: 2021-04-07T18:31:41+08:00
tags: ["algorithm", "programing"]
categories: ["Algorithm"]
draft: false
featured_image: "images/featured.jpg"
series: ["基础算法"]
---

> 过早优化是万恶之源。

遇到问题，第一想到的方法往往是使用暴力手段破解。
枚举出所有可能的解，一一进行检测，
这一点正是计算机所擅长的。

这种做法有很多优点。比如可以快速检验思路；初步理解问题复杂度，为进一步优化提供可能；
避免陷入过度优化的陷阱。

在多数问题中，排列组合是常见的枚举对象。
本文主要探讨枚举排列组合的常见做法。


## 集合 {#集合}

凡排列和组合都针对一组元素，这组元素构成一个集合（set）。

排列是所有集合元素构成的一个有序序列；
组合是集合的子集。

与些同时，存在一种集合的推广，称为多重集合（multiset）[^fn:1]。
在一个集合（set）中，相同的元素只能出现一次；
在多重集合（multiset）中，同一个元素可以出现多次。

两种集合性质不同，所涉及的枚举方法也存在差异。


## 排列 {#排列}

> 排列是所有集合元素构成的一个有序序列。

枚举方法有两种，迭代法和递归法。


### 迭代法 {#迭代法}


#### 集合 {#集合}

枚举排列的迭代法和字典序关系密切。

字典序，义如其名，指应用于字典中的单词排序规则，

-   两个单词（序列）从左到右，依次比较字符（元素），直到比出大小
-   空字符（元素）最小

字典序决定了单词的顺序，比如

-   `am < be`
-   `am < among`

考虑集合 `{1, 2, 3, 4}` 的 16 个排列，按字典序排序，

```text
1 2 3 4
1 2 4 3
1 3 2 4
1 3 4 2
1 4 2 3
1 4 3 2
2 1 3 4
2 1 4 3
2 3 1 4
2 3 4 1
2 4 1 3
2 4 3 1
3 1 2 4
3 1 4 2
3 2 1 4
3 2 4 1
3 4 1 2
3 4 2 1
4 1 2 3
4 1 3 2
4 2 1 3
4 2 3 1
4 3 1 2
4 3 2 1
```

可以观察到相邻序列存在潜在的关系，迭代法利用的正是这一点。

第一个字典序是已知的，即排序序列 `1 2 3 4` ，
根据相邻序列的关系，不断枚举下一个序列，从而遍历所有排列。

那么，如何从当前序列得到下一个序列？

根据字典序的定义，头部元素的影响大于尾部元素，因为在头部已经比较出大小的情况下，
后续的元素没有比较的必要。
所以在计算下一个相邻序列时，尽量从尾部开始变动，不变动头部的元素。

以序列 `1 2 4 3` 为例，

-   最后一位，只有一个数 `3` ，没有变动的空间
-   最后两位， `4 3` ，此时 `4 > 3` ，没有可变动的空间。如果交换位置成 `3 4` ，字典序会变得更小
-   最后三位， `2 4 3` ，此时 `2 < 4` ，说明有调整的空间。
    用 `3` 取代 `2` 的位置是最合理的，因为 `4 3` 中， `3` 是比 `2` 大的最小的数。
    `3` 的位置确定之后，字典序 `3 * *` 已经比之前更大，
    剩下的 `4 2` 需要排序为 `2 4` ，确保得到最小的序列，这样才会和原先的序列相邻。

最终得到下个序列 `1 3 2 4` 。

上述过程中， `2` 称为定位元素， `3` 称为替换元素。

思考不难发现，仍存在两点改进之处。

一，如何快速寻找用于替换的元素？

当定位结束时，剩余的尾部元素是呈逆序排列的。
因为只有尾部元素从后至前递增，定位过程才会继续下去。

比如 `1 4 3 2` 定位到元素 `1` ， `1 3 4 2` 只能定位到元素 `3` 。

所以在寻找替换元素时，只需倒序遍历，直到比定位元素更大的即可，比全部遍历更快速。

二，替换之后，剩余尾部元素必须全部进行排序？

这一步其实是不需要的。

在交换之前，尾部元素已经是逆序，将替换元素和定位元素交换后，逆序的性质并没有改变。
此时只需要将剩余尾部元素反转[^fn:2]，就可以得到正序。

这一点不容小觑，reverse 的复杂度为 O(N)，而 sort 的复杂度为 O(Nlog(N))。

以下 `next_perm` 函数是这个过程的代码实现。

{{< highlight cpp "linenos=table, linenostart=1" >}}
#include <cstdio>
#include <iostream>
#include <algorithm>

bool next_perm(int perm[], int n) {
  for (int i = n-1; i > 0; i--) {
    int j = i - 1;

    if (perm[i] > perm[j]) {
      int k;
      for (k = n-1; k >= i; k--) {
	if (perm[k] > perm[j])
	  break;
      }

      std::swap(perm[j], perm[k]);

      std::reverse(perm + i, perm + n);

      return true;
    }
  }

  return false;
}

int main(void) {
  int perm[4] = {1, 2, 3, 4};

  do {
    for (int i = 0; i < 4; i++)
      printf("%d ", perm[i]);

    printf("\n");
  } while (next_perm(perm, 4));

  return 0;
}
{{< /highlight >}}

```text
1 2 3 4
1 2 4 3
1 3 2 4
1 3 4 2
1 4 2 3
1 4 3 2
2 1 3 4
2 1 4 3
2 3 1 4
2 3 4 1
2 4 1 3
2 4 3 1
3 1 2 4
3 1 4 2
3 2 1 4
3 2 4 1
3 4 1 2
3 4 2 1
4 1 2 3
4 1 3 2
4 2 1 3
4 2 3 1
4 3 1 2
4 3 2 1
```


#### 可重集合 {#可重集合}

有一个好消息， `next_perm` 同时可以处理多重集合的情况。

比如多重集合 `{1, 2, 2, 3, 3, 3, 4}` 的排列 `2 4 3 3 3 2 1` ，
应用 `next_perm` 得到 `3 1 2 2 3 3 4` 。

```text
locate
2 4 3 3 3 2 1
j i     k

swap
3 4 3 3 2 2 1
j i     k

reverse
3 1 2 2 3 3 4
j i     k
```

可以拓展到多重集合的关键在于两处，读者可自行体会。

-   line 9，使用 `>` 比较，而不是 `>=`
-   line 12，使用 `>` 比较，而不是 `>=`

另一个好消息是，标准库已经实现了这个方法，
就是包含在头文件 `<algorithm>` 中的 `std::next_permutation` ，
同时对可重集合生效。

推荐练习：

-   [UVA146 ID Codes](https://www.luogu.com.cn/problem/UVA146)，动手实现 `next_perm` 过程


### 递归法 {#递归法}

相比于迭代法，递归方式更加直观。


#### 集合 {#集合}

递归过程中，按照从左到右的位置，每次从未使用的元素中挑选一个，直到排列完成。

且每次递归时，按照从小到大的顺序来挑选未使用的元素，如此得到所有排列的字典序。

```cpp
#include <cstdio>
#include <algorithm>

void enum_perm(int eles[], int perm[], int n, int ith) {
  if (ith == n) {
    for (int i = 0; i < n; i++)
      printf("%d ", perm[i]);

    printf("\n");
    return;
  }

  for (int i = 0; i < n; i++) {
    int e = eles[i];
    int c = std::count(perm, perm+ith, e);

    if (c == 0) {
      perm[ith] = e;
      enum_perm(eles, perm, n, ith+1);
    }
  }
}

int main(void) {
  int eles[4] = {1, 2, 4, 7};
  int perm[4];

  enum_perm(eles, perm, 4, 0);

  return 0;
}
```

```text
1 2 4 7
1 2 7 4
1 4 2 7
1 4 7 2
1 7 2 4
1 7 4 2
2 1 4 7
2 1 7 4
2 4 1 7
2 4 7 1
2 7 1 4
2 7 4 1
4 1 2 7
4 1 7 2
4 2 1 7
4 2 7 1
4 7 1 2
4 7 2 1
7 1 2 4
7 1 4 2
7 2 1 4
7 2 4 1
7 4 1 2
7 4 2 1
```

推荐练习：

-   [UVA524 Prime Ring Problem](https://www.luogu.com.cn/problem/UVA524)，递归配合回溯来处理


#### 可重集合 {#可重集合}

以上代码虽然非常直观，遗憾的是，对于可重集合是不生效的。

考虑可重集合 `{1, 1, 1}` ，使用上述算法会生成 8 个重复的 `1 1 1` 的排列，
其实只需要输出一个即可。

其实只需要对之前的递归过程做一点修改，就可以适应可重集合。

在每次挑选元素时，按照元素的种类遍历，而不是每个元素都全部遍历。

比如 `{1, 1, 2, 2, 3, 4}` ，只遍历 `1 2 3 4` 即可。

在确定元素是否可以使用时，要计算元素是否已经使用完。

综合来看，可认为是上述算法的拓展。

```cpp
#include <cstdio>
#include <algorithm>

void enum_perm(int eles[], int perm[], int n, int ith) {
  if (ith == n) {
    for (int i = 0; i < n; i++)
      printf("%d ", perm[i]);

    printf("\n");
    return;
  }

  for (int i = 0; i < n; i++) {
    if (i != 0 && eles[i] == eles[i-1])
      continue;

    int e = eles[i];
    int c = std::count(eles, eles+n, e) - std::count(perm, perm+ith, e);

    if (c > 0) {
      perm[ith] = e;
      enum_perm(eles, perm, n, ith+1);
    }
  }
}

int main(void) {
  int eles[4] = {1, 2, 2, 7};
  int perm[4];

  enum_perm(eles, perm, 4, 0);

  return 0;
}
```

```text
1 2 2 7
1 2 7 2
1 7 2 2
2 1 2 7
2 1 7 2
2 2 1 7
2 2 7 1
2 7 1 2
2 7 2 1
7 1 2 2
7 2 1 2
7 2 2 1
```

推荐练习：

-   [UVA10098 Generating Fast](https://www.luogu.com.cn/problem/UVA10098)，尝试使用递归法生成


## 组合 {#组合}

> 组合就是从全部元素挑选出部分组成的子集。

枚举组合就是枚举子集。同样地，有迭代和递归两种方式。

**以下算法只对普通集合生效，不适用于 可重集合。**


### 迭代法 {#迭代法}

集合和二进制有一种天生的关系。

规定一个元素对应一个 bit， 1 表示元素存在， 0 表示元素不存在，
则一个二进制数可以唯一确定一个子集。
`0b11...11` 对应全集， `0b00...00` 对应空集。

比如集合 `{1, 2, 3, 4, 7, 9}` 的子集和其二进制表示，

```text
  { 1, 2, 3, 4, 7, 9 }
0b  1  1  1  1  1  1

  { 1,    3, 4, 7, 9 }
0b  1  0  1  1  1  1

  { 1, 2,       7, 9 }
0b  1  1  0  0  1  1

  {                  }
0b  0  0  0  0  0  0
```

这种表示法将子集和整数一一对应，
这就是迭代法的原理。
n 个元素的集合，共有 `2^n` 个子集，
从 0 到 `2^n` 迭代整数，每个整数对应一个子集。

```cpp
#include <cstdio>
#include <algorithm>
#include <cmath>

int main(void) {
  int n = 4;
  int eles[n] = {1, 2, 4, 9};

  for (int i = 0; i < std::pow(n, 2); i++) {
    for (int k = 0; k < n; k++) {
      if ((1 << k) & i)
	printf("%d", eles[k]);
      else
	printf(" ");

      printf(" ");
    }
    printf("\n");
  }
}
```

```text
1
  2
1 2
    4
1   4
  2 4
1 2 4
      9
1     9
  2   9
1 2   9
    4 9
1   4 9
  2 4 9
1 2 4 9
```

推荐练习：

-   [luogu P1036 选数](https://www.luogu.com.cn/problem/P1036)


#### 枚举子集的子集 {#枚举子集的子集}

用二进制表示集合，同时也将位运算和集合运算关联起来，

-   二进制与 对应 集合的交
-   二进制或 对应 集合的并
-   二进制异或 对应 集合的对称差，如果集合是包含关系，对应集合的差

结合运算关系，可以将子集枚举表示的更精细。

从全集枚举子集，只需遍历 0 到 `2^n` 即可。
对于已经枚举得到的子集，如何枚举这个子集的子集？

比如集合 `{1, 2, 4, 9, 11, 13}` ， `0b010011` 对应子集 `{2, 11, 13}` ，
如何枚举子集 `{2, 11, 13}` 的子集呢？（依然使用 6 bits 表示）

一种方法是，依旧从 0 到 `2^n` 遍历，判断是否为 `0b010011` 的子集，虽然可行但不是最优的方法。

另一种方法是，每次从 `0b010011` 向下减 1，使用 与 运算屏蔽无关位，这样只需遍历 8 次。

以下代码呈现了这个技巧，

```cpp
#include <iostream>
#include <bitset>

int main(void) {
  const int n = 6;
  int eles[n] = {1, 2, 4, 9, 11, 13};
  int sub_set = 0b010011;

  int left = sub_set;
  int right = 0;

  while (left) {
    std::cout << std::bitset<n>(left) << std::endl;
    std::cout << std::bitset<n>(right) << std::endl;
    std::cout << std::endl;

    left = (left - 1) & sub_set;
    right = left ^ sub_set;
  }
}
```

```text
010011
000000

010010
000001

010001
000010

010000
000011

000011
010000

000010
010001

000001
010010
```

推荐练习：

-   [UVA1354 Mobile Computing](https://www.luogu.com.cn/problem/UVA1354)，可以应用上面的技巧


#### 枚举 k 个元素的子集 {#枚举-k-个元素的子集}

考虑问题，如何枚举只有 k 个元素的集合？

比如集合 `{1, 2, 4, 9, 11, 13}` ，只枚举包含 4 个元素的子集。

将位对应元素的思路可以拓展开来，这次用数组来表示。

用数组 `[0 0 1 1 1 1]` 表示起始子集，使用 `next_permutation` 方法，
枚举所有排列的情况，对应所有 4 个元素的子集。

> 可重集合 {0, 0, 0, ..., 1, 1, 1} 的排列和只含 n 个元素的子集一一对应。

```cpp
#include <cstdio>
#include <algorithm>

int main(void) {
  const int n = 6;
  int eles[n] = {1, 2, 4, 9, 11, 13};

  int mask[n] = {0, 0, 1, 1, 1, 1};

  do {
    for (int i = 0; i < n; i++)
      if (mask[i])
	printf("%d ", eles[i]);

    printf("\n");
  } while (std::next_permutation(mask, mask+n));
}
```

```text
4 9 11 13
2 9 11 13
2 4 11 13
2 4 9 13
2 4 9 11
1 9 11 13
1 4 11 13
1 4 9 13
1 4 9 11
1 2 11 13
1 2 9 13
1 2 9 11
1 2 4 13
1 2 4 11
1 2 4 9
```

推荐练习：

-   [luogu P1157 组合的输出](https://www.luogu.com.cn/problem/P1157)


### 递归法 {#递归法}

最直观的方式，每次递归，考虑第 i 个元素在不在子集，
直到最终确定集合。

其实和按位表示是一种思想，不过使用递归来实现。

```cpp
#include <cstdio>

void enum_subset(int eles[], int subset[], int n, int ith) {
  if (ith == n) {
    for (int i = 0; i < n; i++)
      if (subset[i])
	printf("%d ", eles[i]);

    printf("\n");
    return;
  }

  subset[ith] = 0;
  enum_subset(eles, subset, n, ith+1);
  subset[ith] = 1;
  enum_subset(eles, subset, n, ith+1);
}

int main(void) {
  int eles[4] = {1, 2, 4, 9};
  int subset[4];

  enum_subset(eles, subset, 4, 0);
}
```

```text
9
4
4 9
2
2 9
2 4
2 4 9
1
1 9
1 4
1 4 9
1 2
1 2 9
1 2 4
1 2 4 9
```

另一种方法是使用定序的技巧，子集后面的元素必须比前面大，
这样在递归枚举集合时，可避免出现重复。

```cpp
#include <cstdio>

void enum_subset(int eles[], int subset[], int n, int ith) {
  for (int i = 0; i < ith; i++)
    printf("%d ", subset[i]);
  printf("\n");

  for (int i = 0; i < n; i++) {
    if (ith == 0 || eles[i] > subset[ith-1]) {
      subset[ith] = eles[i];
      enum_subset(eles, subset, n, ith+1);
    }
  }
}

int main(void) {
  int eles[4] = {1, 2, 4, 9};
  int subset[4];

  enum_subset(eles, subset, 4, 0);
}
```

```text
1
1 2
1 2 4
1 2 4 9
1 2 9
1 4
1 4 9
1 9
2
2 4
2 4 9
2 9
4
4 9
9
```


## 结论 {#结论}

枚举排列和组合各有两种方式，不同的方法适用于不同的问题，按需挑选。

|    | 迭代       | 递归       |
|----|----------|----------|
| 排列 | 存在标准库实现 | 符合直觉，易实现 |
|    | 无法减小复杂度 | 可回溯，减小复杂度 |
|    | 同时适用可重集合 | 可重集合需要拓展处理 |
| 组合 | 只需枚举整数 | 不如迭代法简洁 |
|    | 需要注意位运算 |            |
|    | 整数表示的位数量有限 | 不限集合元素数量 |


## License {#license}

{{< license >}}

[^fn:1]: : 多重集合的定义 <https://baike.baidu.com/item/%E5%A4%9A%E9%87%8D%E9%9B%86>
[^fn:2]: : <https://blog.csdn.net/u011465808/article/details/37886527>

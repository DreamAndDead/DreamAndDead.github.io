---
title: "基础算法之枚举 排列 组合"
author: ["DreamAndDead"]
date: 2021-03-25T15:10:00+08:00
lastmod: 2021-03-31T13:40:18+08:00
tags: ["algorithm", "programing"]
categories: ["Algorithm"]
draft: true
comment: false
featured_image: "images/featured.jpg"
---

> 过早优化是万恶之源。

遇到问题，第一尝试的方法往往是通过暴力手段破解。
枚举出所有可能的解，一一进行检测，
而这一点也是计算机所擅长的。

这种思路有很多优点。比如可以快速检验思路；建立问题复杂度的初步理解；
为进一步优化提供可能；避免陷入过度优化的陷阱。

在多数问题中，排列组合是常见的枚举对象。
本文主要探讨枚举排列组合的常见方法。


## 集合 {#集合}

排列与组合都涉及到一组元素，这组元素构成一个集合（set）。

排列是集合所有元素构成的一个有序序列；
组合是集合的子集。

存在一种集合的推广，称为多重集合（multiset）[^fn:1]。
在一个集合（set）中，相同的元素只能出现一次；
在多重集合（multiset）中，同一个元素可以出现多次。

由于两种集合性质不同，涉及的枚举方法也存在差异。


## 排列 {#排列}

> 排列是集合所有元素构成的一个有序序列。

枚举方法可分为两类，迭代法和递归法。


### 迭代枚举排列 {#迭代枚举排列}

迭代法和字典序关系密切。

字典序，义如其名，指字典中单词的排序规则，

-   两个单词（序列）从左到右，依次比较字符（元素），直到比出大小
-   空字符（元素）最小

字典序规则确定了单词的顺序，

-   `am < be`
-   `am < among`

考虑集合 `{1, 2, 3, 4}` ，存在 16 个排列序列，将所有序列按字典序排序，
可以感觉到相邻的序列有明显的关系。

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

迭代法利用的就是这一点。
第一个字典序是已知的，即排序序列 `1 2 3 4` ，
根据相邻关系，不断枚举字典序相邻的下一个序列，
从而遍历所有排列。

下面详细描述，相邻序列的关系究竟是什么。

根据字典序的定义，头部元素影响大于尾部元素，因为在头部已经比较出大小的情况下，
后续的元素没有比较的必要。
所以在寻找相邻的下一个序列时，从尾部开始变动，尽量不变动头部的元素。

以序列 `1 2 4 3` 到 `1 3 2 4` 为例，

-   最后一位，只有一个数 `3` ，没有变动的空间
-   最后两位， `4 3` ，此时 `4 > 3` ，没有可变动的空间。如果交换位置成 `3 4` ，字典序会变得更小
-   最后三位， `2 4 3` ，此时 `2 < 4` ，说明有调整的空间。
    `2` 是一定要被调整的，用 `3` 取代这个位置是最合理的，因为 `4 3` 中， `3` 是比 `2` 大的最小的数。
    在 `3` 的位置确定之后，字典序 `3 * *` 已经比之前更大，
    剩下的 `4 2` 需要排序为 `2 4` ，确保得到的序列是最小的，这样才会和原先的序列保持相邻。
    最终得到序列 `1 3 2 4` 。

仔细思考上述过程，会发现有两点可改进之处。

一，如何快速寻找用于替换的元素？

当定位结束时，可以发现剩余尾部元素是呈逆序排列的。
因为只有尾部元素从后至前依次增长，定位过程才会继续下去。

比如 `1 4 3 2` 定位到元素 `1` ， `1 3 4 2` 定位到元素 `3` 。

所以在寻找元素替换时，只需倒序遍历，直到比定位元素更大即可。

二，替换之后，剩余尾部元素必须进行排序？

仔细考虑，这一步是不需要的。

尾部已经是逆序，交换定位元素后，逆序的性质并没有改变。
此时只需要将剩余尾部元素反转[^fn:2]，就可以排序结果。

这一点不容小觑，reverse 的复杂度为 O(N)，而 sort 的复杂度为 O(Nlog(N))。

`next_perm` 函数就是这个过程的代码描述。

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

有一个好消息， `next_perm` 同时可以处理多重集合的情况。

比如多重集合 `{1, 2, 2, 3, 3, 3, 4}` 的
序列 `2 4 3 3 3 2 1` ，应用 `next_perm` 过程，
得到 `3 1 2 2 3 3 4` 。

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

可以拓展到多重集合的关键在于两处，

-   line 9，比较使用 `>` ，而不是 `>=`
-   line 12，比较使用 `>` ，而不是 `>=`

读者可自行体会。

另一个好消息是，标准库已经实现了这个方法，
直接调用 `std::next_permutation` 即可，同时对可重集合生效。

推荐练习：

-   [UVA146 ID Codes](https://www.luogu.com.cn/problem/UVA146)，动手实现 `next_perm` 过程


### 递归枚举排列 {#递归枚举排列}

相比于迭代法，递归方式更加直观。

使用递归过程，按照从左到右的位置，每次从未使用的元素中挑选一个，直到用完所有。

在挑选时，使用从小到大的顺序来遍历未使用的元素，这样可得到所有排列的字典序。

```cpp
#include <cstdio>
#include <iostream>
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

推荐练习：

-   [UVA524 Prime Ring Problem](https://www.luogu.com.cn/problem/UVA524)

上面的代码虽然非常直观，但是遗憾的是，对于可重集合是不生效的。

考虑可重集合 `{1, 1, 1}` ，使用上面的算法会生成 8 个 `1 1 1` 的排列，
其实它们是相同的一个排列。

在每次确定元素的时，只遍历元素的种类，而不是全部遍历

比如 `{1, 1, 2, 2, 3, 4}` ，只遍历 `1 2 3 4` 即可

同时在确定是否可以摆放时，要计算元素是否已经使用完，而不是是否出现过，
因为元素可能是多个

可认为是前面一种算法的拓展情况

```cpp
#include <cstdio>
#include <iostream>
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

推荐练习：

-   [UVA10098 Generating Fast](https://www.luogu.com.cn/problem/UVA10098)


## 组合 {#组合}

> 组合就是从全部元素挑选出部分元素组成的子集。

枚举组合就是枚举子集，同样有迭代和递归两种方式。

**以下算法只对普通集合生效，不适用于可重集合。**


### 迭代枚举组合 {#迭代枚举组合}

集合和二进制有一种天生的关系。

一个元素对应一个 bit 位， 1 表示元素存在， 0 表示元素不存在，
则一个二进制数可以唯一确定一个子集。
全集对应 `0b11...11` ，空集对应 `0b00...00` 。

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

这样就将子集和整数一一对应起来。n 个元素的集合，共有 `2^n` 个子集。

这就是迭代法的原理，从 0 到 `2^n` 迭代整数，每个整数对应一个子集。

```cpp
#include <iostream>
#include <algorithm>
#include <cmath>

int main(void) {
  int n = 4;
  int eles[n] = {1, 2, 4, 9};

  for (int i = 0; i < std::pow(n, 2); i++) {
    for (int k = 0; k < n; k++) {
      if ((1 << k) & i)
	std::cout << eles[k];
      else
	std::cout << ' ';

      std::cout << ' ';
    }
    std::cout << std::endl;
  }
}
```

TODO 不是字典序？
TODO 推荐练习？

用二进制表示集合，同时也将位运算和集合运算关联起来。

-   二进制与 对应 集合的交
-   二进制或 对应 集合的并
-   二进制异或 对应 集合的对称差。如果集合是包含关系，对应集合的差

结合运算关系，可以将子集分割表示的更精细。

从全集分割子集，可以遍历 0 到 `2^n` 即可。
对于已经分割出的子集，如何枚举这个子集的子集？

比如集合 `{1, 2, 4, 9, 11, 13}` ， `0b010011` 对应子集 `{2, 11, 13}` ，
如何枚举这个子集的子集（依然使用 6 bits 表示）？

一种方法是，依旧从 0 到 `2^n` 遍历，判断是否为 `0b010011` 的子集，可行但不是最优的方法

另一种方法是，从 `0b010011` 向下减，使用 与 运算屏蔽无关位，这样只需遍历 8 次。

以下代码呈现了这个技巧，

{{< highlight cpp "linenos=table, linenostart=1" >}}
#include <iostream>
#include <bitset>
#include <iomanip>

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
{{< /highlight >}}

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

-   这个题目可以应用上面的表示法

位对应元素的思路可以拓展开来，考虑问题，
如何枚举只有 k 个元素的集合？

比如集合 `{1, 2, 4, 9, 11, 13}` 中枚举只有 4 个元素的集合。

依旧使用位对应，不过这次用数组来表示。

用数组 `[0 0 1 1 1 1]` 表示起始子集，使用 `next_permutation` 方法，
枚举所有排列，即对应所有 4 个元素的子集。

```cpp
#include <iostream>
#include <algorithm>

int main(void) {
  const int n = 6;
  int eles[n] = {1, 2, 4, 9, 11, 13};

  int mask[n] = {0, 0, 1, 1, 1, 1};

  do {
    for (int i = 0; i < n; i++) {
      if (mask[i])
	std::cout << eles[i] << ' ';
    }
    std::cout << std::endl;
  } while (std::next_permutation(mask, mask+n));
}
```


### 递归枚举组合 {#递归枚举组合}

直观的方式，每次递归，针对第 ith 个元素，可选择用还是不用，
最终到长度结束，再确定集合。

和二进制表示是一种思想，不过是使用递归来过滤

```cpp
#include <iostream>

void enum_subset(int eles[], int subset[], int n, int ith) {
  if (ith == n) {
    for (int i = 0; i < n; i++) {
      if (subset[i]) {
	std::cout << eles[i] << ' ';
      }
    }
    std::cout << std::endl;

    return;
  }

  subset[ith] = 0;
  enum_subset(eles, subset, n, ith+1);
  subset[ith] = 1;
  enum_subset(eles, subset, n, ith+1);
}

int main(void) {
  int eles[6] = {1, 2, 4, 9, 11, 13};
  int subset[6];

  enum_subset(eles, subset, 6, 0);
}
```

一种是定序，后面的元素必须比前面大，才可以加进去

不需要遍历到长度结束

```cpp
#include <iostream>

void enum_subset(int eles[], int subset[], int n, int ith) {
  for (int i = 0; i < ith; i++) {
    std::cout << subset[i] << ' ';
  }
  std::cout << std::endl;

  if (ith == n)
    return;

  for (int i = 0; i < n; i++) {
    if (ith == 0 || eles[i] > subset[ith-1]) {
      subset[ith] = eles[i];
      enum_subset(eles, subset, n, ith+1);
    }
  }
}

int main(void) {
  int eles[6] = {1, 2, 4, 9, 11, 13};
  int subset[6];

  enum_subset(eles, subset, 6, 0);
}
```


## 如何选择 {#如何选择}

迭代，并检验，是最朴素的方法

迭代必定超时，剪枝，

检验过程是递进的


## License {#license}

{{< license >}}

[^fn:1]: : 多重集合的定义 <https://baike.baidu.com/item/%E5%A4%9A%E9%87%8D%E9%9B%86>
[^fn:2]: : <https://blog.csdn.net/u011465808/article/details/37886527>

---
title: KD Tree
date: "2019-08-22T15:09:00Z"
categories:
- Data Structure
tags:
- algorithm
- data-structure
- machine-learning
featured_image: images/featured.jpg
aliases:
- /2019/08/22/kd-tree.html
---

之前了解学习了机器学习中的 KNN 算法，它的本质是从“已有经验”中找出最相似的案例，来“预测”新的未出现过的情况。

在 sklearn 的 KNN 算法描述中，其中提到使用 KD Tree 结构可以加速 nearest neighbors 的查找，从而提高 KNN 算法的效率。

这里就来讨论一下 KD Tree 数据结构。

<!--more-->

# intro

KD Tree 的名字中，KD means k dimension，是用于描述 k 维空间的树形结构。
在 k = 1 的情况下，整体退化为二叉搜索树。

同样的，KD Tree 也是二叉树形结构，不同在于，树的每一层对应一个分割维度，由当前层级的节点分割。
随着树的层次越来越深，分割维度在全部维度之间循环。

和二叉搜索树类似，在 KD Tree 中，所有分割维度小于分割节点的节点，分布在左子树；否则分布在右子树。

{{< figure src="images/kd-tree-intro.png" caption="2 dimension kd tree" >}}

总体来看，KD Tree 无非就是将二叉搜索树从一维空间扩展到多维空间。

# methods

下面介绍 KD Tree 的一些元语方法，深层地理解它是如何使 KNN 得到搜索上的效率提升的。

## insert

根据 KD Tree 的结构定义，插入节点是一个明显的过程，就像二叉搜索树一样。
- 如果不存在根节点，将插入节点作为根节点
- 在分割维度下，对比插入节点和根节点的值，如果小于，则递归插入左子树；否则递归插入右子树

在这个过程下，新插入的节点都会被插入到叶子处。

{{< figure src="images/kd-tree-insert.png" caption="2 dimension kd tree insert" >}}

我们可以用 insert 方法来构建 KD Tree，只需要将所有数据顺序插入即可。

{{< gist-it path="DreamAndDead/kd-tree-example/blob/f05161dd86486fe673e6615a4477e630cf8b80c4/kdtree.py" start=116 end=139 >}}

## contain

查找 KD Tree 是否包含特定节点，查询方法和插入节点是相同的。
- 如果根节点不存在，则不包含
- 如果查询节点和根节点相同，则包含
- 在分割维度下，对比查询节点和根节点的值，如果小于，则递归在左子树查找；否则递归在右子树查找

{{< gist-it path="DreamAndDead/kd-tree-example/blob/f05161dd86486fe673e6615a4477e630cf8b80c4/kdtree.py" start=140 end=159 >}}

## find_min

find_min 的含义是，在 KD Tree 树中查找某一个维度值最小的节点。

{{< figure src="images/kd-tree-example.png" caption="2 dimension kd tree" >}}

比如之前的例子，在 x 维度最小的节点是 `(1, 10)`，在 y 维度最小的节点是 `(55, 1)`。

最简单的实现方法，我们将树整体遍历，用全局变量保存分割维度值最小的节点。

这个方法虽然可行，但可以更加高效。
我们详细来分析，哪些情况下，可以进行剪枝，缩小整体搜索的规模。

假如现在要搜索 x 维度下的最小值，

{{< figure src="images/find_min_x.png" caption="find min node in x dimension" >}}

同样地，我们用全局变量保存目前遇到的最小节点值。

最开始，从第一层开始搜索，`(51, 75)`，对应的分割维度是 x ，刚好是要搜索的维度。
根据 KD Tree 的结构定义，节点的右子树肯定都是 x 值比 `(51, 75)` 大的节点，所以在这种情况下，根本不用搜索右子树（剪枝）。
同时，如果存在左子树，其中的节点一定比当前根节点要小。

到了第二层，进入左子树，`(25, 40)`，分割维度为 y 。
在这个时候，没有依据判断，x 维度下的最小节点一定在左子树/右子树，所以无法剪枝，需要在两个子树下查找。

在第三层，
- `(10, 30)`，同样的，分割维度回到 x 维度，只在左子树查找最小值。
- `(35, 90)`，对应 x 维度，左子树为空，当前节点可以作为最小值的备选。

到下一层，`(1, 10)`，对应 y 维度，但是左/右子树都为空，可以将当前节点作为备选。

综合这个过程，就可以找到任意分割维度下的最小值。

{{< gist-it path="DreamAndDead/kd-tree-example/blob/f05161dd86486fe673e6615a4477e630cf8b80c4/kdtree.py" start=160 end=187 >}}

## delete

这个方法从树中删除对应的节点。如果树中包含节点，则删除；否则不影响。

删除节点的情况就更复杂一些，如果删除的是叶子节点，则直接删除。如果要删除的节点存在子树，则需要处理子树下的节点。

假如要删除 A 节点，对应的分割维度为 cd。

{{< figure src="images/delete-with-two-subtrees.png" caption="delete node A in dimension cd" >}}

回想假如图中的树是二叉搜索树，在删除 A 之后，需要用 B = find_min(A.right) 来替换 A 的位置，再在右子树递归的删除 B 节点。
这样即可以删除节点，又保证了树的平衡。

相似地，在 KD Tree 中，需要用 B = find_min(A.right, cd) 来替换 A 节点，再在右子树递归删除 B 节点。
在 KD Tree 的结构中，在相应的分割维度下，右子树的节点**大于等于**根节点，根节点**大于**左子树的节点，所以上述的删除策略依旧可以保持树的平衡。

{{< figure src="images/delete-without-right-subtree.png" caption="delete node A without right subtree" >}}

假如没有右子树，我们模仿上面的策略，使用 B = find_max(A.left, cd) 来替换节点 A，这样不可行，因为可能会破坏树的平衡。

假设 A[cd] = x, find_max(A.left, cd) = a，但是根据定义，在左子树有可能存在一个节点 C，C[cd] = a，因为 a < x，在插入节点的时候也被分配到了 A 的左子树这边。
这样的话，在用 B 替换 A 之后，因为 C 的存在，树就不平衡了。

在这种情况下，我们对方法做一些修正，使用 B = find_min(A.left, cd) 代替 A 的位置，再将左/右子树交换位置，这样就完美保持了树结构的平衡。

{{< gist-it path="DreamAndDead/kd-tree-example/blob/f05161dd86486fe673e6615a4477e630cf8b80c4/kdtree.py" start=188 end=216 >}}

## find_nearest

在 KD Tree 的所有节点中，寻找距离查询节点最近的节点（这里使用 euclidean 距离）。

和 find_min 一样，最直观的方法是遍历树的所有节点，用全局变量记录最小距离和距离最小的节点。
这是直观且可行的，同样地，我们要思考分析如何提高搜索效率。

假定搜索节点为 Q，需要在 KD Tree 中找到离 Q 最近的点 C。

第一个方面，引入 bounding box 的概念。

{{< figure src="images/kd-tree-bounding.png" caption="kd tree bounding box" >}}

每个节点都有一个对应的 bounding box（下面简称 BB），它的含义是表明当前节点以及其子节点所可能分布的一个范围。

来看图上的例子，对于根节点，`(51, 75)`，BB 是整个 xy 平面，$x \in (-\infty, \infty), y \in (-\infty, \infty)$。

对于第二层节点 `(25, 40)`，因为它处于根节点的左侧，由 x 维度分割而来，对应的 BB 为所有 $x < 51$ 的平面范围，$x \in (-\infty, 51), y \in (-\infty, \infty)$。

{{< figure src="images/bounding-box-optimization.png" caption="bounding box optimization" >}}

使用 BB 的核心在于，假如当前已知的最小距离小于查询节点到 BB 的距离，那么就可以进行剪枝。
也就是说，当前遇到的最近节点是 C，如果遇到新节点，相应的 bounding box 不可能比 C 更近，就没有必要继续在新节点下进行搜索。

第二个方面，如果不能利用 BB 进行裁剪，则第一步先搜索 Q 可能在的子树，再搜索另外的子树。
即如果在分割维度下，Q 比当前节点小，则先搜索左子树；否则先搜索右子树。

这样在概率上，更快的缩小全局已知的最小距离，在其它节点的查询更可能根据 BB 进行剪枝。

{{< gist-it path="DreamAndDead/kd-tree-example/blob/f05161dd86486fe673e6615a4477e630cf8b80c4/kdtree.py" start=222 end=260 >}}

## find_k_nearest

在 KD Tree 的所有节点中，找到距查询节点最近的 k 个节点（这里使用 euclidean 距离）。

这里用到的查询方法，和 find_nearest 是一样的，不同在于，我们使用一个优先队列存储前 k 个最近距离的节点。
队列的优先级是节点与查询节点 Q 的距离，距离越小，优先级越高。队列有固定的大小，新插入队列的节点会“挤出”优先级更低的节点。

这里容易遗忘的一个要点是，只有当队列满的时候再进行 BB 的检测，不然会出现搜索节点数量不足的情况。

{{< gist-it path="DreamAndDead/kd-tree-example/blob/f05161dd86486fe673e6615a4477e630cf8b80c4/kdtree.py" start=261 end=297 >}}


# ref

- thanks [CMSC 420 lesson][cmsc lesson], most pictures are from its [lesson note][cmsc note]
- thanks [CS106 assignment in stanford][assignment], from it we get how to do k nearest neighbors searching

[cmsc lesson]: https://www.cs.umd.edu/~mount/420/
[cmsc note]: https://dreamanddead-github-io.oss-cn-hongkong.aliyuncs.com/kd-tree/KD-Trees-CMSC-420.pdf
[assignment]: https://dreamanddead-github-io.oss-cn-hongkong.aliyuncs.com/kd-tree/assignment-3-kdtree.pdf

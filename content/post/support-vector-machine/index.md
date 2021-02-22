---
title: 简明 SVM
date: "2019-10-14T14:03:00Z"
categories:
- Algorithm
tags: 
- algorithm
- machine-learning
featured_image: images/intuition.png
enableMathJax: true
aliases:
- /2019/10/14/support-vector-machine.html
draft: true
---

最近研究了 SVM 算法[^1] [^2]，发现它本身的推导过程真是充满了美感！
在这里梳理其中的逻辑关系，记录下自己的理解。

<!--more-->

# 间隔 Margin

## 启发 Intuition

考虑一个简单的二分类问题，实例的特征(feature)空间有两个维度，实例分类目标值(target)为正例和反例。

假如所有实例**完全线性可分**（存在超平面将正反实例完全分开），

{{< figure src="images/intuition.png" caption="x 代表正例，o 代表反例" >}}

上图实线直线（在高维度也称超平面 hyper plane，后面统一简称平面）就是一种可能的分类方法。

在当前分类下，直观上看，正例 A 距离分类平面比正例 B 要”远“很多。
相比之下，我们更容易相信正例 A 在当前分类方法下“更可能”是正确的，因为正例 B 距离平面”太近“了，分类方法稍微有一些参数的调整，比如变成了虚线表示的分类，正例 B 很可能就被划分为反例。

根据这个示例，直觉上猜想，实例距离分类平面”越远“，它”更可能“被分类正确。


## 量化间隔

在直觉的基础上，需要进一步量化所谓“远近”这个概念。
以下使用 **间隔(margin)** 表示实例与平面之间的距离。

在继续之前，先完整定义上面示例的分类问题。

实例 feature 有两个维度，用向量 $x$ 表示，$x \in \mathbb{R}^2 $，
分类 target 分为正例和反例，用整数 $y$ 表示， $ y \in \{ +1, -1 \} $，
并且假设所有实例完全线性可分。

因此分类平面可以用下式来表示，

$$ w ^T x + b = 0 $$

$w, b$ 是分类平面的参数，$w \in \mathbb{R}^2, b \in \mathbb{R}$。

{{< figure src="images/classify.png" caption="" >}}

可以计算，对于所有正例，$ w ^T x + b > 0 $，对于反例，$ w ^T x + b < 0 $，正反例有明显的符号区别。

根据符号的不同，就可以构建一个简单的分类假设，

$$
h(x) = g(w ^T x + b) \\\\\\
g(z) = \begin{cases}
+1, \text{ when $z > 0$ } \\\\\\
-1, \text{ when $z < 0$ }
\end{cases}
$$

{{< figure src="images/gz.png" caption="" >}}

在具体公式的基础上，应用最先关于“远近”的直觉，如果一个正例， $w ^T x ^{(i)} + b \gg 0$，则可以认为间隔很大，当前分类正确的可能性更高。

这个间隔称其为 *函数间隔(functional margin)*，因为它只关心函数计算得到的结果，符号表示为 $\hat \gamma$。

$$
\hat \gamma ^{(i)}= w ^T x ^{(i)} + b
$$

仔细思考会发现，使用函数间隔存在一个问题，对于 $w = [1, 1] ^T, b = 1$ 和 $w = [100, 100]^T, b = 100$，两者表示的是相同的分类平面 $w ^T x + b = 0$，但是后者计算得到的函数间隔是前者的 100 倍，这就有些不合理。

从另一个角度来看待间隔，直接在几何平面上考虑实例点到分类平面的距离。这样就克服了上述问题，无论 $w, b$ 怎样放缩变化，只要分类平面不变，间隔就是不变的。

这个间隔称为 *几何间隔(geometric margin)*，符号定义为 $\gamma$。容易发现，在 $\|\|w\|\| = 1$ 的情况下，函数间隔和几何间隔相同。

$$
\gamma ^{(i)} = \frac{w ^T x ^{(i)} + b}{||w||}
$$

推导过程主要应用了，向量 $PA$ 长度为单位向量 $\dfrac{w}{\|\|w\|\|}$ 的 $\gamma$ 倍。

{{< figure src="images/geometry-distance.png" caption="" >}}

$$
w ^T (A - \gamma \frac{w}{||w||} ) + b = 0 \\
w ^T A - \gamma \frac{w^T w}{||w||} + b = 0 \\
\gamma ||w|| = w ^T A + b \\
\gamma = \frac{w^T A + b}{||w||}
$$

# 最优分类

对全部实例应用最开始得到的直觉，最优的分类平面，应该使所有实例到平面的间隔尽可能的远。
具体的说，就是使所有实例中到平面的最小间隔最大化。

给定实例集合，

$$
S = \{ (x ^{(i)}, y ^{(i)}); i=1,...,m \}
$$

定义 $S$ 到分类平面的间隔为所有实例到平面的最小几何间隔，

$$
||w|| = 1 \\
\gamma^{(i)} = y^{(i)} * (w ^T x^{(i)} + b)\\
\gamma = \min \gamma^{(i)}\ \ \ i=1,...,m
$$

*间隔永远是正值，对于正例，$y^{(i)} = +1, w ^T x^{(i)} + b > 0$，对于反例，$y^{(i)} = -1, w ^T x^{(i)} + b < 0$*

最优的分类，就是使 $\gamma$ 最大的分类。

$$
\begin{align}
& max_{\gamma,w,b}\ \gamma\\
s.t.\ & y^{(i)} * (w ^T x^{(i)} + b) \geq \gamma,\ i=1,...,m\\
& ||w|| = 1
\end{align}
$$

根据凸优化理论[^8]，$\|\|w\|\| = 1$ 在这里不是一个仿射函数，优化问题不符合 QCQP 的求解条件。

变通地，使用函数间隔改写方程，

$$
\begin{align}
& max_{\hat \gamma,w,b}\ \frac{\hat \gamma}{||w||}\\
s.t.\ & y^{(i)} * (w ^T x^{(i)} + b) \geq \hat \gamma,\ i=1,...,m
\end{align}
$$

前面讨论过使用函数间隔遇到的问题，在保持分类平面不变的情况下，函数间隔可以随着 $ w, b $ 的放缩而放缩。
同样地，在最优解情况，总可以放缩 $w, b$，使得 $\hat \gamma = 1$。

于是问题就转化为

$$
\begin{align}
& max_{w,b}\ \frac{1}{||w||} \\
s.t.\ & y^{(i)} * (w ^T x^{(i)} + b) \geq 1,\ i=1,...,m
\end{align}
$$

将 $\|\|w\|\|$ 取倒数平方，$max \rightarrow min$，问题就转化成了 QCQP 的形式，可以应用已知的凸优化方法进行求解。

$$
\begin{align}
& min_{w,b}\ \frac 1 2 ||w||^2 \\
s.t.\ & y^{(i)} * (w ^T x^{(i)} + b) \geq 1,\ i=1,...,m
\end{align}
$$

求解得到 $w, b$，其参数构成的超平面就是之前假设的最优分类。

## 计算最优化

这个问题是一个经典的凸优化问题，

$$
\begin{align}
& min_{w,b}\ \frac 1 2 ||w||^2 \\
s.t.\ & y^{(i)} * (w ^T x^{(i)} + b) \geq 1,\ i=1,...,m
\end{align}
$$

将条件转化为 $\leq$ 的形式，

$$
g_i(w, b) = - y^{(i)} * (w ^T x^{(i)} + b) + 1 \leq 0
$$

使用拉格朗日乘子法[^3] [^4] [^5]，转化为拉格朗日函数(lagrangian)，

$$
\mathcal{L} (w, b, \alpha) = \frac 1 2 ||w||^2 + \sum_{i=1}^{m} \alpha_i \left[- y^{(i)} * (w ^T x^{(i)} + b) + 1 \right]
$$

根据不等式约束的 KKT 条件[^6]，在极值处 $w, b$，存在 $\alpha$ 满足

$$
\triangledown _w \mathcal{L} (w, b, \alpha) = 0 \\
\triangledown _b \mathcal{L} (w, b, \alpha) = 0 \\
g_i(w , b ) \le 0 \\
\alpha_i  \geq 0 \\
\alpha_i  g_i(w , b ) = 0 \\
$$


从另外的角度[^7] [^8]来观察拉格朗日函数，

$\min\limits_{w, b} \max\limits_{\alpha} \mathcal{L} (w, b, \alpha)$ 和约束条件下的 $\min\limits_{w, b} \dfrac 1 2 \|\|w\|\|^2$ 问题是等价的。

假如存在 $g_i > 0$ 脱离了约束，则可以使对应的 $\alpha_i = \infty$，相应的 $\max\limits_{\alpha} \mathcal{L} (w, b, \alpha) = \infty$；
如果所有 $g_i \le 0$ 满足约束，则只有 $\alpha_i = 0\ (\text{unless } g_i = 0)$ 才能确保 $\max\limits_{\alpha} \mathcal{L} (w, b, \alpha)$ 取最大值，此时 $\max\limits_{\alpha} \mathcal{L} (w, b, \alpha) = \dfrac 1 2 ||w||^2$。

所以对于 $\min\limits_{w, b} \max\limits_{\alpha} \mathcal{L} (w, b, \alpha)$，必定在满足 $g_i \le 0$ 的约束时才能取到最小值（表面上没有约束，其实过滤了不满足约束的值）。


假设原(primal)问题最优解为 $p^* = \min\limits_{w, b} \max\limits_{\alpha} \mathcal{L} (w, b, \alpha)$，
考虑其对偶(dual)问题，$d^* = \max\limits_{\alpha} \min\limits_{w, b} \mathcal{L} (w, b, \alpha)$，

根据弱对偶性(weak duality)，始终满足

$$
d^* \le p^*
$$

因为，假如原问题最优解取值为 $w_p, b_p, \alpha_p$，对偶问题最优解取值为 $w_d, b_d, \alpha_d$，则

$$
d^* = \mathcal{L} (w_d, b_d, \alpha_d) \le \mathcal{L} (w_p, b_p, \alpha_d) \le \mathcal{L} (w_p, b_p, \alpha_p) = p^*
$$

在这里，问题满足 Slater 条件（*充分条件，暂时不讨论*），故问题满足强对偶性(strong duality)，$d^* = p^*$。

所以可以通过求解对偶问题，得到原问题的解，以下先求解 $\min\limits_{w, b} \mathcal{L} (w, b, \alpha)$，将 $\alpha$ 看作常量。

$$
\triangledown _w \mathcal{L} (w, b, \alpha) = 0 \\
w + \sum_{i=1}^{m} \alpha_i (-y ^{(i)} x ^{(i)}) = 0 \\
w = \sum_{i=1}^{m} \alpha_i y ^{(i)} x ^{(i)} \\
\triangledown _b \mathcal{L} (w, b, \alpha) = 0 \\
\sum_{i=1}^{m} \alpha_i y ^{(i)} = 0
$$

根据上面求得的公式，代入 $\mathcal{L} (w, b, \alpha)$，消去 $w, b$，

$$
\begin{align}
\mathcal{L} (w, b, \alpha) & = \frac{1}{2} w^T w + \sum_{i=1}^{m} (-w^T \alpha_i y^{(i)} x^{(i)} - \alpha_i y^{(i)} b + \alpha_i) \\
&  = \frac{1}{2} w^T w + \sum_{i=1}^{m} -w^T \alpha_i y^{(i)} x^{(i)} + \sum_{i=1}^{m} - \alpha_i y^{(i)} b + \sum_{i=1}^{m} \alpha_i \\
& = \frac{1}{2} w^T w - w^T w + 0 + \sum_{i=1}^{m} \alpha_i \\
& = - \frac{1}{2} w^T w + \sum_{i=1}^{m} \alpha_i \\
& = \sum_{i=1}^{m} \alpha_i - \frac{1}{2} \sum_{i=1}^{m} \sum_{j=1}^{m} y^{(i)} y^{(j)} \alpha_i \alpha_j \langle x^{(i)}, x^{(j)} \rangle \\
\end{align}
$$

现在问题转化为对称问题的最大值问题（之后使用 SMO 算法[^1]来求解）。

$$
\begin{align}
\max \limits_{\alpha} \ & \sum_{i=1}^{m} \alpha_i - \frac{1}{2} \sum_{i=1}^{m} \sum_{j=1}^{m} y^{(i)} y^{(j)} \alpha_i \alpha_j \langle x^{(i)}, x^{(j)} \rangle \\
\text{s.t.} \ & \alpha_i \geq 0 \\
& \sum_{i=1}^{m} \alpha_i y^{(i)} = 0
\end{align}
$$



## 支持向量

假如已经通过最优化方法求得 $w, b, \alpha$，得到分类平面 $ {w} ^T x + b = 0$，
对于新的未知分类的实例，可以通过计算 ${w} ^T x + b$，根据符号的正负来进行分类其是正例还是反例。

$$
{w} ^T x + b = \sum_{i=1}^{m} \alpha_i y^{(i)} {x^{(i)}} ^T x + b \\
= \sum_{i=1}^{m} \alpha_i y^{(i)} \langle x^{(i)}, x \rangle + b
$$

根据之前讨论的 KKT 条件，

$$
g_i(w, b) \le 0 \\
\alpha_i  \geq 0 \\
\alpha_i  g_i(w , b ) = 0 \\
$$

当 $g_i(w, b) < 0$，即 $y^{(i)} (w^T x^{(i)} + b) > 1$ 时，$\alpha_i= 0$；
当 $g_i(w, b) = 0$，即 $y^{(i)} (w^T x^{(i)} + b) = 1$ 时，$\alpha_i > 0$。

对于 $\alpha_i = 0$ 的部分，都可以在分类计算中省略，只有 $\alpha_i > 0$ 才参与计算，大大减少了计算量。

{{< figure src="images/support.png" caption="" >}}

从图形来看，当 $y^{(i)} (w ^T x^{(i)} + b) = 1，\alpha_i > 0$，对应的实例 $(x^{(i)}, y^{(i)})$ 是距离分类平面最近的点，称作支持向量（这也是支持向量机名字的由来），也只有相应的支持向量参与判别新分类的运算。

# 核方法 kernel trick

之前的所有讨论，假设限定于所有实例完全线性可分。存在一些情况，在实例空间下，所有实例不能完全线性可分。
这时可以通过空间的映射 $\phi(x)$，将原空间映射到新空间，在新空间里，实例也许就完全线性可分了。
在新空间计算得到分类平面后，将其逆向转换回来，在原空间就得到了非线性的分类平面。

{{< figure src="images/phi.png" caption="" >}}

假如将所有实例映射到新空间，进行分类平面的求解。
观察最优化的求解过程，将 $x^{(i)} \rightarrow \phi(x^{(i)})$，并不影响求解过程（因为求解的变量为 $w, b, \alpha$, 而 $x^{(i)}$ 看作常量），只需要将所有的 $x^{(i)} $ 进行替换。

相应的在新实例的分类计算中，$ \langle x^{(i)}, x \rangle \rightarrow \langle \phi(x^{(i)}), \phi(x) \rangle$。

对于新实例的分类结果，只涉及到 $\langle x^{(i)}, x \rangle$ 的计算，而不涉及 $x^{(i)}$ 单个值的计算。

定义核函数来提取这种共性

$$
K(x, z) = \phi(x)^T\phi(z)
$$

原先所有 $\langle x^{(i)}, x^{(j)} \rangle$ 的地方就用 $K(x^{(i)}, x^{(j)} )$ 来代替。

$K(x, z)$ 可以是一个显性表示，比如通过具体的 $\phi(x)^T\phi(z)$ 来得到，也可以是一个隐性表示，比如高斯核，

$$
K(x, z) = e^{- ||x-z||^2 / 2 d^2}
$$

并非可以显性的得到 $\phi(x), \phi(z)$ 的表示，但是 $K(x, z)$ 一定是可以分解的，因此它是一个有效的核函数。

如何判定一个隐性的核函数是否有效？

根据 Mercer 定理，K 是有效的核函数，当且仅当 Kernal matrix 是对称半正定的

Kernal martix 是一个矩阵 $K$，$K_{ij} = K(x^{(i)}, x^{(j)})$

虽然使用核方法，SVM 可以进行非线性判别，但是并没有明确的准则来决定如何选择一个恰当的空间映射 $\phi(x)$，以及在相应映射下使用什么参数，并不确定哪一种映射可以反映问题的本质。

所以在实际中，通常使用 [GridSearch][grid search] 来遍历搜索，选择效果最好的核函数和参数。

[grid search]: https://scikit-learn.org/stable/modules/generated/sklearn.model_selection.GridSearchCV.html


# soft margin SVM

之前讨论的方法，假定所有的实例是完全线性可分的，但是也存在不完全线性可分的情况。
比如，

{{< figure src="images/nonlinear.png" caption="" >}}

在这种情况下，可以使用核方法，得到非线性分类．
但是总体上看，实例还是线性分类的，如果只因为少量的分类错误就使用非线性的方法，代价太大了。

{{< figure src="images/soft.png" caption="" >}}

之前假定实例完全线性可分，使用的是*硬间隔(hard margin)*的判别方法。
现在引入一种*软间隔(soft margin)*的判别方法，使分类可以容忍部分错误。

引入松弛变量 $\xi$，由软间隔定义的优化问题如下，

$$
\begin{align}
& \min_{w,b,\xi}\ \frac 1 2 ||w||^2 + C \sum_{i=1}^{m} \xi^{(i)}\\
\text{s.t.} \ & y^{(i)} * (w ^T x^{(i)} + b) \geq 1 - \xi^{(i)},\ i=1,...,m\\
& \xi^{(i)} \geq 0 \\
\end{align}
$$

相比于之前的硬间隔问题，允许间隔 $< 1$ ，但是计入相应的惩罚，由 $C$ 控制了惩罚的权重，$C$ 越大，对分类错误的容忍度越低。

## 求解最优化

软间隔最优化求解的过程大体和硬间隔相似。

$$
g_i(w, b, \xi) = - y^{(i)} * (w ^T x^{(i)} + b) + 1 - \xi^{(i)} \leq 0
$$

写出拉格朗日函数，

$$
\mathcal{L} (w, b, \xi, \alpha, \beta) = \frac 1 2 ||w||^2 + C \sum_{i=1}^{m} \xi^{(i)} + 
\sum_{i=1}^{m} \alpha_i (1 - \xi^{(i)} - y^{(i)} * (w ^T x^{(i)} + b) + \sum_{i=1}^{m} - \beta_i \xi^{(i)} \\
$$

满足 KKT 条件，

$$
g_i(w, b, \xi) \le 0 \\
\alpha_i \geq 0 \\
\alpha_i g_i(w, b, \xi) = 0 \\
-\xi^{(i)} \le 0 \\
\beta_i \geq 0 \\
\beta_i \xi^{(i)} = 0 \\
$$

求解对偶问题，

$$\triangledown _w \mathcal{L} (w, b, \xi, \alpha, \beta) = 0 \\
w = \sum_{i=1}^{m} \alpha_i y^{(i)} x^{(i)} \\
\triangledown _b \mathcal{L} (w, b, \xi, \alpha, \beta) = 0 \\
\sum_{i=1}^{m} \alpha_i y^{(i)} = 0 \\
\triangledown _{\xi^{(i)}} \mathcal{L} (w, b, \xi, \alpha, \beta) = 0 \\
C - \alpha_i - \beta_i = 0 \\
\alpha_i + \beta_i = C \\
$$


将求导得到的上式代入 $\mathcal{L} (w, b, \xi, \alpha, \beta)$，消去 $w, b, \xi$，

$$
\begin{align}
\max \limits_{\alpha} \ & \sum_{i=1}^{m} \alpha_i - \frac{1}{2} \sum_{i=1}^{m} \sum_{j=1}^{m} y^{(i)} y^{(j)} \alpha_i \alpha_j \langle x^{(i)}, x^{(j)} \rangle \\
\text{s.t.} \ & 0 \leq \alpha_i \leq C \ (\text{because } \alpha_i \ge 0, \beta_i \ge 0, \alpha_i + \beta_i = C) \\
& \sum_{i=1}^{m} \alpha_i y^{(i)} = 0
\end{align}
$$

令人惊奇的是，最终结果没有大的改变，只是对 $\alpha^{(i)}$ 多了约束 $\le C$。

根据 KKT 条件，
- 当 $\alpha_i = 0,\ \beta_i = C$ 时，$\xi^{(i)} = 0,\  g_i(w, b, \xi) < 0,\  y^{(i)} * (w ^T x^{(i)} + b) > 1$，实例在最大间隔外；
- 当 $\alpha_i = C,\  \beta_i = 0$ 时，$\xi^{(i)} > 0,\  g_i(w, b, \xi) = 0,\  y^{(i)} * (w ^T x^{(i)} + b) = 1 - \xi^{(i)} < 1$，实例落在最大间隔内，当 $\xi^{(i)} > 1$ 时被错误分类；
- 当 $0 < \alpha_i < C,\  0 < \beta_i < C$ 时，$\xi^{(i)} = 0,\  g_i(w, b, \xi) = 0,\  y^{(i)} * (w ^T x^{(i)} + b) = 1$，实例是支持向量。

至于 $\xi$ 的值，有多种不同的损失函数来计量，这里不讨论。


# SMO 算法

SMO 算法用来求解上面最优化得到的 $\max \limits_{\alpha}\ ...$ 问题。

SMO 启发于坐标上升方法。

一个简单的示例，对于一个二维凸函数，每次固定一个维度，选取另一个维度作为变量，进行最大化求解。

由等高线来看，在固定一个维度的前提下，找到函数的最大值，即与等高线相切的点，

{{< figure src="images/contour.png" caption="" >}}

由三维立体来看，逐个维度取最大值，最终会慢慢接近极值点。

{{< figure src="images/contour-3d.png" caption="" >}}

下面类比的来看，用 SMO 求解软间隔的最优化问题，

$$
\begin{align}
& \max \limits_{\alpha} \sum_{i=1}^{m} \alpha_i - \frac{1}{2} \sum_{i=1}^{m} \sum_{j=1}^{m} y^{(i)} y^{(j)} \alpha_i \alpha_j \langle x^{(i)}, x^{(j)} \rangle \\
\text{s.t.} \ & 0 \leq \alpha_i \leq C \\
& \sum_{i=1}^{m} \alpha_i y^{(i)} = 0
\end{align}
$$

使用同样的思路，不过在这里维度有所增加，变成了 m 维。
逐个 $\alpha_i $ 作为变量，进行坐标上升求极值。

但是因为有等式关系存在，

$$
\alpha_1 y^{(1)} = -\sum_{i=2}^{m} \alpha_i y^{(i)} 
$$

$\alpha_i $ 受到等式的约束，所以不能通过逐个调整 $\alpha_i $ 来调优。

可以变通的同时选择两个 $\alpha_i, \alpha_j $ 作为变量，用 $\alpha_j $ 表示 $\alpha_i $，代入原方程消去 $\alpha_j$，这样问题就符合约束条件，可以在 $\alpha_i$ 维度上进行坐标上升优化。

化简后的问题是关于 $\alpha_i$ 的一元二次问题，在相应的范围内求极值，是一个简单的问题。

比如对于 $\alpha_1, \alpha_2$，

$$
0 \le \alpha_1 \le 0 \\
0 \le \alpha_2 \le 0 \\
\alpha_2 y^{(2)} = - \sum_{i=3}^{m} \alpha_i y^{(i)} - \alpha_1 y^{(1)} \\
$$

{{< figure src="images/aiaj.png" caption="" >}}

对于不同的情况，$\alpha_i$ 取值范围会受到不同的影响。

对于硬间隔问题，没有 $\alpha_i \le C$ 的条件，但是思路是一样的。


[^1]: [CS229 Lecture note 3](http://dreamanddead-github-io.oss-cn-hongkong.aliyuncs.com/SVM/CS229%20Lecture%20note%203.pdf)

[^2]: [Gentle Introduction to Support Vector Machines in Biomedicine](http://dreamanddead-github-io.oss-cn-hongkong.aliyuncs.com/SVM/A%20Gentle%20Introduction%20to%20Support%20Vector%20Machines%20in%20Biomedicine.pdf)


[^3]: [Lagrange Multipliers (Com S 477 577 Notes)](http://dreamanddead-github-io.oss-cn-hongkong.aliyuncs.com/SVM/Lagrange%20Multipliers%20%28Com%20S%20477%20577%20Notes%29.pdf)


[^4]: [Lagrange Multipliers without Permanent Scarring](http://dreamanddead-github-io.oss-cn-hongkong.aliyuncs.com/SVM/Lagrange%20Multipliers%20without%20Permanent%20Scarring.pdf)


[^5]: [Lagrange Multipliers for Inequality Constraints](http://dreamanddead-github-io.oss-cn-hongkong.aliyuncs.com/SVM/Lagrange%20Multipliers%20for%20Inequality%20Constraints.pdf)


[^6]: [Lagrange Multipliers and the Karush-Kuhn-Tucker conditions](http://dreamanddead-github-io.oss-cn-hongkong.aliyuncs.com/SVM/Lagrange%20Multipliers%20and%20the%20Karush-Kuhn-Tucker%20conditions.pdf)


[^7]: [CS229 Lecture Review note 3](http://dreamanddead-github-io.oss-cn-hongkong.aliyuncs.com/SVM/CS229%20Lecture%20Review%20note%203.pdf)

[^8]: [CS229 Lecture Review note 4](http://dreamanddead-github-io.oss-cn-hongkong.aliyuncs.com/SVM/CS229%20Lecture%20Review%20note%204.pdf)

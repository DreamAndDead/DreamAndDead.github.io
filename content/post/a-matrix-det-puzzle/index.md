---
title: a matrix det puzzle
date: "2019-04-22T08:39:00Z"
categories:
- Math
tags: 
- math
- linear-algebra
featured_image: images/featured.jpg
enableMathJax: true
draft: true
aliases:
- /2019/04/22/a-matrix-det-puzzle.html
---

求解行列式

$$
\newcommand\iddots{\mathinner{
  \kern1mu\raise1pt{.}
  \kern2mu\raise4pt{.}
  \kern2mu\raise7pt{\Rule{0pt}{7pt}{0pt}.}
  \kern1mu
}}
$$

$$
D_{2n} = \begin{vmatrix}
a & & & & & b \\
  & \ddots & & & \iddots & \\
  & & a & b & & \\
  & & b & a & & \\
  & \iddots & & & \ddots & \\
b & & & & & a
\end{vmatrix}_{2n}
$$

<!--more-->

# 解法1

将第 $n+1, n+2, \dotsm, 2n$ 行分别加到第 $ n, n-1, \dotsm, 1$ 行，再提取公因式 $(a+b)$，得

$$
D_{2n} = (a+b)^n
\begin{vmatrix}
1 & & & & & 1 \\
  & \ddots & & & \iddots & \\
  & & 1 & 1 & & \\
  & & b & a & & \\
  & \iddots & & & \ddots & \\
b & & & & & a
\end{vmatrix}_{2n} =
(a+b)^n
\begin{vmatrix}
1 & & & & & 1 \\
  & \ddots & & & \iddots & \\
  & & 1 & 1 & & \\
  & & 0 & a-b & & \\
  & \iddots & & & \ddots & \\
0 & & & & & a-b
\end{vmatrix}_{2n} =
(a+b)^n \cdot (a-b)^n = (a^2 - b^2)^n
$$


# 解法2

用递推法，按第一行展开，得

$$
D_{2n} = (-1)^{1+1} \cdot a \cdot
\begin{vmatrix}
a & & & & & b & 0 \\
  & \ddots & & & \iddots & & \\
  & & a & b & & & \\
  & & b & a & & & \\
  & \iddots & & & \ddots & & \\
b & & & & & a & \\
0 & & & & & & a
\end{vmatrix}_{2n-1}
+
(-1)^{1+2n} \cdot b \cdot
\begin{vmatrix}
0 & a & & & & & b \\
  & & \ddots & & & \iddots & \\
  & & & a & b & & \\
  & & & b & a & & \\
  & & \iddots & & & \ddots & \\
  & b & & & & & a \\
b & & & & & & 0
\end{vmatrix}_{2n-1}
$$

再按最后一行展开

$$
D_{2n} = (-1)^{1+1} \cdot a \cdot (-1)^{2n-1+2n-1} \cdot a \cdot
\begin{vmatrix}
a & & & & & b  \\
  & \ddots & & & \iddots & \\
  & & a & b & & \\
  & & b & a & & \\
  & \iddots & & & \ddots & \\
b & & & & & a \\
\end{vmatrix}_{2n-2}
+
(-1)^{1+2n} \cdot b \cdot (-1)^{2n-1+1} \cdot b \cdot
\begin{vmatrix}
a & & & & & b  \\
  & \ddots & & & \iddots & \\
  & & a & b & & \\
  & & b & a & & \\
  & \iddots & & & \ddots & \\
b & & & & & a \\
\end{vmatrix}_{2n-2}
$$

化简为递推式

$$
D_{2n} = a^2 D_{2n-2} - b^2 D_{2n-2} = (a^2 - b^2)D_{2n-2} = (a^2 - b^2)^2 D_{2n-4} = \dotsm = (a^2 - b^2)^{n-1}D_2 = (a^2 - b^2)^n 
$$

---
date: "2019-05-15T00:00:00Z"
tags: math
title: Trigonometric Function Illustrations
---

三角函数是非常重要的一类周期函数，所有周期函数都可以分解为对应的三角函数的组合。

在中学数学中，学习最多是 正弦$sin$，余弦$cos$，正切$tan$ 函数，
之后了解还有 正割$sec$，余割$csc$，余切$cot$ 函数。

其中最让我困惑不解在于它们的命名，什么是正？什么是余？

<!--more-->

# 基础图示

{% include image.html url="triangle-math/figure-in-textbook.png" desc="单位圆中的三角函数值" %}

在图示中，三角函数对应的值可以照如下的表格来计算。

|翻译|缩写|英文|公式|
|:-:|:-:|:-:|:-:|
|正弦|sin|sine|$\dfrac{CD}{OD}$|
|余弦|cos|cosine|$\dfrac{OC}{OD}$|
|正切|tan|tangent|$\dfrac{AB}{OA}$|
|余切|cot|cotangent|$\dfrac{OA}{AB}$|
|正割|sec|secant|$\dfrac{OD}{OC}$|
|余割|csc|cosecant|$\dfrac{OD}{CD}$|

又因为图中是一个单位圆，$OD\ =\ OA\ =\ 1$，所以有三条边的长度对应三个三角函数值。

观察对应的公式，我们会发现，正弦和余割互为倒数，余弦和正割互为倒数。
为什么不是正弦和正割对应，余弦和余割对应呢？

而且图中只能表示出三个函数值，不能表现出六个函数值吗？


# 改进图示

经过一个偶然的机会，看到了关于三角函数更加合理的解释。

{% include image.html url="triangle-math/triangle-functions.png" desc="单位圆中的三角函数值" %}

|翻译|缩写|英文|公式|
|:-:|:-:|:-:|:-:|
|正弦|sin|sine|$\dfrac{CD}{OD}=CD$|
|余弦|cos|cosine|$\dfrac{OC}{OD}=\dfrac{FG}{OF}=FG$|
|正切|tan|tangent|$\dfrac{AB}{OA}=AB$|
|余切|cot|cotangent|$\dfrac{OA}{AB}=\dfrac{AE}{OA}=AE$|
|正割|sec|secant|$\dfrac{OD}{OC}=\dfrac{OB}{OA}=OB$|
|余割|csc|cosecant|$\dfrac{OD}{CD}=\dfrac{OE}{OA}=OE$|

所以，三角函数重要的是比例关系，这张图就清晰的表达了一点。

co means complementary 表示余角。所以也就有了弦，切，割的正，余值，以及图中优雅的对应关系。

# The End
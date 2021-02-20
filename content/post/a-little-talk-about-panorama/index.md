---
title: A little talk about panorama
date: "2020-09-27T14:02:58Z"
categories:
- Panorama
tags:
- algorithm
- image
- 3D
featured_image: images/panorama-preface.jpg
aliases:
- /2020/09/27/a-little-talk-about-panorama.html
---

全景图本身并不神秘。

普通的图片，记录的只是在一个位置，一个视角下观察到的场景；
而全景图可以记录一个位置，所有视角可观察到的场景。

全景图虽起名全景，但本质还是图片，可以和普通图片对比着来理解。

<!--more-->

# 图片文件

图片也是文件，是文件就需要存储。

普通图片一般存储为 jpg/png 等格式，全景图也不例外，同样使用相同格式来存储，
不过存储的内容有些许不同。

全景图既然记录了所有视角的场景，必然在内容方面和普通图片有所区别，本质区别在于[投影变换][format]。

{{< figure src="images/world-map.png" title="inflate world to panorama map" >}}

上图所有人都不陌生。将地球球体映射到圆柱，再将圆柱展开，成为 2：1 的一张图片，就是常见的世界地图。

其本质就是一种主流的存储全景图的方法 [equirectangular][equirectangular]。

还有另一种存储全景图的方法 [cubic][cubic]，以观察点为中心，用六张图片记录 前，后，左，右，上，下 立方体包围盒的六个面。

{{< figure src="images/cubic-map.png" title="panorama in cubic way" >}}

可以将包围盒理解为是球体的内接立方体，两者在场景存储方面是等价的。

比如 [Panorama to Cubemap][transform]，就可以将 equirectangular 转换为 cubic 格式。

# 图片浏览器

存储图片文件之后，需要图片浏览器来查看图片。

普通图片的浏览器，只是简单读取矩阵像素点，呈现在平面屏幕。

而全景图保留了全部视角，就需要另外的一种浏览方式，允许各个视角进行切换。

[相应的浏览器][viewer]有很多，本质都是将全景图中投影的数据，通过算法计算，还原到任意视角上。

下面示例使用 js 实现的全景图浏览器 [pannellum][pannellum]。

{{< iframe "https://cdn.pannellum.org/2.5/pannellum.htm#panorama=https://pannellum.org/images/alma.jpg" "100%" "400px" >}}

其中查看的 equirectangular 全景图是

{{< figure src="images/panorama-rect.jpg" >}}

转换为 cubic 方式，则如下图

{{< figure src="images/panorama-cubic.png" >}}

# 图片生成

普通图片只需要一个镜头，在一个视角下感光即可，记录所有颜色的矩阵，即保留为图片。

对于全景图，假如使用 cubic 记录的方式（因为等价），则需要通过镜头来记录 6 张图，即包围盒的六个面。

假如使用单镜头拍摄，在现实中做到这一点并不容易。

1. 6 张图片需要使用 fov = 90 的广角来拍摄，大部分设备是不支持的。
2. 即使得到 6 张相应的图片，并不能保证边角是严丝合缝的，可能存在误差引起的断裂痕迹。

普通的用户如果想通过这种方式得到完美的全景图，远远没有拍摄一张图片加美颜那么简单。

如果把拍摄放到虚拟世界中呢？

想像在 3D 游戏中，实时看到的场景是通过线性代数计算出来的，想要得到一个角度的场景图片轻而易举，
并且数学计算十分严密，边界是完全吻合的。相机被抽象为点，没有实体相机的大小误差。

简单的实践，可以在 FPS 游戏中，完全的第一视角，在分辨率 1：1 的情况下，记录下 fov = 90 的 前，后，左，右，上，下
6 张图片，完全可以充当全景图浏览器的输入！

# 更多

- 普通手机如何拍摄全景图？

目前存在拍摄全景图的相机应用，考虑手机只有一个摄像头，且 fov 调整空间有限，分辨率各不相同，
拍摄全景图就需要相机应用引导用户拍摄多个视角下的场景，覆盖全景所有的面，最后通过合成算法合成全景图。

相应地也存在一些优秀的合成工具，如 microsoft 的 [ICE][ice]，和 开源的 [PTGui][ptgui]。

- 有哪些拍摄全景图的设备？

市场存在很多不同的拍摄全景图的设备，拍摄全景的原理并没有发生变化，只不过其使用多个固定的镜头，
使输入易预测，加上部分冗余和一些算法处理，可以一步生成相应的全景图。

详细可参考 [this link][more]。

[more]: https://www.leiphone.com/news/201512/bMLT4bE88swBjG19.html

[format]: https://wiki.panotools.org/Panorama_formats

[equirectangular]: https://wiki.panotools.org/Equirectangular_Projection

[cubic]: https://wiki.panotools.org/Cubic_Projection

[pannellum]: https://pannellum.org/documentation/overview/

[transform]: https://jaxry.github.io/panorama-to-cubemap/


[ice]: https://www.microsoft.com/en-us/research/product/computational-photography-applications/image-composite-editor/

[ptgui]: https://www.ptgui.com/

[viewer]: https://wiki.panotools.org/Panorama_Viewers


---
title: A simple way to draw a circle always facing you
date: "2019-04-17T13:24:00Z"
lastmod: "2021-02-22T14:12:00Z"
categories:
- Algorithm
tags: 
- algorithm
- 3D
featured_image: images/featured.jpg
enableMathJax: true
aliases:
- /2019/04/17/a-simple-way-to-draw-a-circle-always-facing-you.html
---

In the latest work about deferred shading light, I need to figure out a way to demonstrate the light range of point light,
so that user can easily tune the parameters about the light.

<!--more-->

The idea is simple.
Imaging a point light lighting range is a ball bubble, you will see a round transparent circle wherever you look at it.
The point is the circle edge indicates the maximum lighting range of the light.

# Drawing

Everyone knows 3d coordinate pipeline.

{{< figure src="images/3d-coordinate-pipeline.png" caption="" >}}

You put into a 3d coordinate point, and get a 2d coordinate point back(visible or not).

Assuming we have got a vertexes list, that forms a circle whose center is in origin and normal vector is parallel with z axis in local coordinate system.

{{< figure src="images/circle-facing-z-axis.png" desc="a circle whose surface is perpendicular to z caption" >}}

What we do next is to rotate the circle so that the normal vector points at the camera in the **local transform** phase.

{{< figure src="images/circle-facing-camera.png" caption="" >}}

The normal vector $\vec{n}$ is easy to get:

$$
\vec{n} = normalize(Pos_{camera} - Pos_{light})
$$

$Pos$ is the position in world coordinate system.

## Rotation

Let's discuss about the rotation. Before we start, you will realize the figure below is a great helper for the understanding.

{{< figure src="images/rotate-vector-to-z.png" caption="" >}}

Given a vector $\vec{p}$, how do we rotate it until it coincides in $z$ axis?

Check out this approach: first we rotate $\vec{p}$ to $\vec{r}$, then rotate $\vec{r}$ to $\vec{s}$. We do an easy transformation in one step.

Conversely, how to rotate $\vec{s}$ to $\vec{p}$ is just a reverse procedure. 

1. rotate around $y$ axis by angle $\beta$;
2. rotate around $x$ axis by angle $-\alpha$.

The rotation matrix is easy to be constructed.

_rotate around $y$ axis by angle $\beta$_

$$
\begin{bmatrix}
  \cos\beta & 0 & -\sin\beta & 0 \\\\\\
  0         & 1 &          0 & 0 \\\\\\
  \sin\beta & 0 &  \cos\beta & 0 \\\\\\
  0         & 0 &          0 & 1 \\\\\\
\end{bmatrix}
$$

_rotate around $x$ axis by angle $-\alpha$_

$$
\begin{bmatrix}
  1 & 0              & 0             & 0 \\\\\\
  0 &  \cos(-\alpha) & \sin(-\alpha) & 0 \\\\\\
  0 & -\sin(-\alpha) & \cos(-\alpha) & 0 \\\\\\
  0 & 0              & 0             & 1 \\\\\\
\end{bmatrix} =
\begin{bmatrix}
  1 & 0          & 0           & 0 \\\\\\
  0 & \cos\alpha & -\sin\alpha & 0 \\\\\\
  0 & \sin\alpha &  \cos\alpha & 0 \\\\\\
  0 & 0          & 0           & 1 \\\\\\
\end{bmatrix}
$$

The trigonometric functions values are easy to get too.

$$
sin\alpha=\frac{b}{\sqrt{b^2+c^2}}
$$

$$
cos\alpha=\frac{c}{\sqrt{b^2+c^2}}
$$

$$
sin\beta =\frac{a}{\sqrt{a^2+b^2+c^2}}
$$

$$
cos\beta=\frac{\sqrt{b^2+c^2}}{\sqrt{a^2+b^2+c^2}}
$$

It's a clear and simple way, isn't it?
And it can be use to solve more similar problems.

e.g.

1. how to rotate a vector to $x$ or $y$ axis?
2. how to rotate two vectors together? (rotating the first vector to z axis and rotating back to the second vector)
3. etc

Trust you could find more. :)


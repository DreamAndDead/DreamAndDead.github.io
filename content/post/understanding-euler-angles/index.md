---
title: Understanding Euler Angles
date: "2019-04-24T09:10:00Z"
lastmod: "2021-04-05T16:16:00Z"
categories:
- Math
tags: 
- algorithm
- 3D
- math
- linear-algebra
featured_image: images/featured.jpg
enableMathJax: true
aliases:
- /2019/04/24/understanding-euler-angles.html
---

Rotation is a big part of transformation in 3d programming. Every programmer
have to understand the underlying math things.

I have known about Euler angles for a while, and today we talk about some more details about it.

<!--more-->

# Direction vs Orientation

Most people can't tell the difference of direction and orientation.
They two are different concepts.

In brief, vectors have got direction and orientation is for objects.

{{< figure src="images/aircraft-rotation.png" caption="intrinsic rotation of aircraft from wikipedia" >}}

$\vec{X}$ is a vector and is determined by $\psi$ and $\theta$.

$\phi$ means nothing to the vector(a spinning vector?), but is necessary to the plane object.

That's the key difference between direction and orientation and
Euler angles describe the orientation.

# Euler angles

The Euler angles are three angles introduced by Leonhard Euler to describe the orientation of rigid
body with respect to a fixed coordinate system.

## Order

There exist 12 possible sequences of rotation axes, divided into 2 groups:
- Proper Euler angles($z-x-z, x-y-x, y-z-y, z-y-z, x-z-x, y-x-y$)
- Tait-Bryan angles($x-y-z, y-z-x, z-x-y, x-z-y, z-y-x, y-x-z$)

Proper Euler angles only use 2 axes in rotations($x,y$ or $y,z$ or $x,z$),
but Tait-Bryan angles use all 3 axes($x,y,z$) in different order.

## Convention

The three elemental rotations may be extrinsic or intrinsic.

**extrinsic** means the original coordinate system remains motionless as the rotations go.

**intrinsic** means the rotation is always based on the rotating coordinate system which is solidary
with the moving object.

The figures below will provide better understanding.

{{< figure src="images/extrinsic-rotation.png" caption="extrinsic rotation axes in order $x-y-z$" >}}

{{< figure src="images/intrinsic-rotation.png" caption="intrinsic rotation axes in order $z-y'-x''$ (also well known as yaw,pitch,roll)" >}}


## Conversion between extrinsic and intrinsic rotations

_Any extrinsic rotation is equivalent to an intrinsic rotation by the same angles but with inverted order of elemental rotations, and vice versa._

Take the figure above as an example.
We have got extrinsic rotation in order $x-y-z$ with angles $\phi,\theta,\psi$
and intrinsic rotation in inverted order $z-y'-x''$ with angles $\psi,\theta,\phi$.

The final rotation results are same as long as the angles($\phi,\theta$ and $\psi$)
are equivalent.

Let's get a proof.

First we denote

- $E_x$ as the transformation matrix rotating around $x$ axis with angle $\phi$
- $E_y$ as the transformation matrix rotating around $y$ axis with angle $\theta$
- $E_z$ as the transformation matrix rotating around $z$ axis with angle $\psi$
- $I_z$ as the transformation matrix rotating around $z$ axis with angle $\psi$
- $I_{y'}$ as the transformation matrix rotating around $y'$ axis with angle $\theta$
- $I_{x''}$ as the transformation matrix rotating around $x''$ axis with angle $\phi$

**All the matrices are relative to original $x-y-z$ coordinate system.**

We need to prove

$$
E_x E_y E_z = I_z I_{y'} I_{x''}
$$

Obviously, 

$$E_z = I_z$$

because they share the same definition.

Next, considering $I_{y'}$, rotating around $y'$ in the new $x'-y'-z'$ coordinate system after $I_z$'s rotation.

If $x'-y'-z'$ coincides with $x-y-z$ then $E_y = I_{y'}$.

So we first rotate the $x'-y'-z'$ back and use $E_y$ to do the rotation and resume the $x'-y'-z'$ coordinate system.

In equation that's

$$
I_{y'} = I_z^{-1} E_y I_z
$$

In the same idea we get 

$$
I_{x''} = (I_z I_{y'})^{-1} E_x (I_z I_{y'})
$$

So

$$
\begin{align}
I_z I_{y'} I_{x''} &= I_z I_{y'} (I_z I_{y'})^{-1} E_x (I_z I_{y'}) \\\\\\
&= E_x (I_z I_{y'}) \\\\\\
&= E_x (I_z I_z^{-1} E_y I_z) \\\\\\
&= E_x E_y I_z \\\\\\
&= E_x E_y E_z 
\end{align}
$$

# Acknowledgement

In [wikipedia][euler angles], I know more about [euler angles][euler angles] including extrinsic/intrinsic and Proper/Tait-Bryan.

I first see the conversion between extrinsic and intrinsic in [this blog][intrinsic and extrinsic] and that shocked me. There's [another proof in wikipedia][chained rotation] and a enlightening answer about [relativity][relative idea].

# License

{{< license >}}

[euler angles]: https://www.wikiwand.com/en/Euler_angles

[intrinsic and extrinsic]: http://www.cnitblog.com/luckydmz/archive/2010/09/07/68674.html

[chained rotation]: https://www.wikiwand.com/en/Davenport_chained_rotations#/Conversion_between_intrinsic_and_extrinsic_rotations

[relative idea]: https://math.stackexchange.com/a/1155951

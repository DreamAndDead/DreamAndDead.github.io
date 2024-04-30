---
type: card
created: 2024-04-05T20:41
tags:
- ue
- animation
- bp
---

在动画蓝图中，有这样两个节点
- get current state name
	- ![[function2.png]]
- current state time
	- ![[function1.png]]
	

两个节点只能用在transition graph中

在每个sm中，任何一个时刻，只存在一个active的状态

get current state name 的意思是，获取这个状态机中当前active状态的name

current state time 的意思是，获取一个状态机中，当前active状态已经active的时间

![[function6.png]]

这两个节点的特点在于，不是只能获取当前transition graph所在的状态机相关的active数据，而是可以获取当前 anim graph 中所有状态机的相关active数据

![[Pasted image 20240405204839.png]]
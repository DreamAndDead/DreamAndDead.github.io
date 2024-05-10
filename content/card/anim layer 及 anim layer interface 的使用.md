---
type: card
created: 2024-03-27T17:14
tags:
- ue
- animation
---

anim layer 有两种使用方式

一，作为 abp 的一个“子函数”

直接在 abp 的 animation layers tab 中新建并实现，在主 anim graph 中通过 linked anim layer 调用

通过组合多个“子函数”，实现整体pose输出的实现

![[Pasted image 20240327171941.png]]

其中 layer 内部可以使用其它 abp 中定义的layer，也可以使用 event graph 收集的各种变量

二，用于模块化组织动画

首先定义 anim layer interface 资产，内部可以定义多个 anim layer 的signature
- 定义输入类型
- 定义组
	- [ ] 定义组的作用是什么

abp a 接入了interface，可以选择实现“子函数” or 不实现（默认为空 or output = input pose输出）

abp a 在主 anim graph 中，通过 linked anim layer node 来引用这些“子函数”
- [x] detail 中的 instance class 如何选择？ ✅ 2024-03-27
	- 可能是由 charater bp 中的调用来自动实现切换的 [[#^09d7fc]]
	- none 对应 abp a 自己的 layer实现

同时可以定义 abp b，接入同样的interface，进行“子函数”的自己的实现

character a 的mesh组件，使用的是 abp a，可以在运行时，动态切换内部的layers，全部使用 abp b layers的逻辑

在 character bp 中，使用 link anim class layers (by class) and unlink anim class layers (by class) ^09d7fc

![[Pasted image 20240327173100.png]]

这里对一些细节点依旧存在疑问
- [x] apb b 作为单独的实现，内部进行 event graph 进行数据收集，不是和 abp a 的相关步骤有重复？ ✅ 2024-03-27
	- 不同动画操作，需要的数据不一样
	- 不同功能收集不同的数据，避免在 abp a 中进行大量的数据收集操作 monolithic
	- 或者可以选择在定义 layer的时候，同时定义数据输入接口，这样layer就直接从abp a中传入数据，而不用自己再实现收集数据的工作
- [x] abp b 是否需要和 abp a 有相同的骨骼？ ✅ 2024-03-28
	- 理论上是需要一样的
- [x] 从哪个维度进行模块化的组织？ ✅ 2024-04-01
	- 动作可以从多个方面进行分解，理解为层次结构，或者分为手脚等部位
	- 每个 blend节点，就是分隔了两个需要融合的维度
- [ ] 使用interface时内部有同名的“子函数”，是否可以进行 Link?
- [ ] 和 linked anim graph 的区别
	- 使用其它 abp 作为一个子函数




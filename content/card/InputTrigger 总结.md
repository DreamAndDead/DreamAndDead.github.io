---
created: 2024-05-21T18:27
draft: true
tags: 
- card
- ue
- input
---


input value 在经过 [[InputModifier 总结|modifier pipeline]]  之后，输出 final input value

一个 IA 上可配置多个 trigger，每个 trigger 都读取 final input value，进行自己 state 的计算，统计 state 之后，再计算出一个 final state

trigger state 可能是
- none
	- condition 未满足，fail
- ongoing
	- 部分满足，正在处理中
- triggered
	- 所有条件满足，suc

input trigger 有 3 种类型
- explicit
- implicit
- blocker

在计算 final state 时，trigger 的类型很重要
- 空，如果 final input value 不为 0，输出 trigger state
- 全部为 im 类型，当 all trigger 都到 trigger  时，才输出 trigger 
- 全部为 ex 类型，当 any trigger 到 trigger ，就输出 trigger 
- 都有，当 all im 和 any ex 同时满足，才输入 trigger 
- 存在 blocker，如果 any blocker 被满足，则输出 none 

- [ ] 这里只讨论了 trigger state，没有讨论 none state 和 ongoing state 如何在多个 input trigger 中处理
	- 猜测，全部为 none 则 none
	- 介于中间状态，为 ongoing

得到 final state 之后，再和之前的状态对比，看状态的转变，从而触发不同的 trigger event，从而调用不同的 delegate

![[Pasted image 20240521184419.png]]

[[ue input.drawio]]



ue 已实现一些 trigger

| trigger  | type     | supported type |
| -------- | -------- | -------------- |
| pressed  | explicit | instant        |
| released | explicit | instant        |
| down     | explicit | instant        |
| hold     |          | ongoing        |


# down

- actuation threshold

只要大于 threshold 就触发

没有设置 trigger 时的默认行为

# pressed

- actuation threshold
	- input value 大于这个阈值，才进行触发

```cpp
return IsActuated(ModifiedValue) && !IsActuated(LastValue) ? ETriggerState::Triggered : ETriggerState::None;
```

在新值突破 threshold 的时机触发

# released

- actuation threshold

在 hold 时，ongoing
松开，在新值小于 threshold 的时机，触发

```cpp
// Ongoing on hold
if (IsActuated(ModifiedValue))
{
	return ETriggerState::Ongoing;
}

// Triggered on release
if (IsActuated(LastValue))
{
	return ETriggerState::Triggered;
}

return ETriggerState::None;
```


# hold

- actuation threshold
- [ ] affected by time dilation
	- 是否被全局的时间膨胀所影响
	- true 不使用传入的参数 deltatime，而乘以一个 dilation 系数
		- 如果游戏放慢，则输入的时间跟着放慢
		- 和游戏内时间保持一致
	- false
		- 和现实时间同步
- hold time threshold
	- 按下在这个时间内，都是 ongoing
	- 超过才 trigger
- is one shot
	- true，超过时间，只触发一次
	- false，超过时间，重复触发

# hold and release

- hold time threshold

在按下至少 threshold 秒之后，再松开，在这个时机触发

# pulse

- trigger on start
	- 时刻 0 是否触发
- interval
	- 触发间隔
- trigger limit
	- 触发次数

超过 threshold 之后，进行周期性的触发
超过次数之后，不再触发

# tap

- tap release time threshold

按下，并在 release time threshold 内松开，这个时机会触发

相当于点击


# combo

- combo actions
	- combo step action
	- combo step completion states
		- 需要的 event
	- time to press key
		- 时间阈值
- cancel actions
	- cancel action
	- cancellation state

多个 action 按顺序产生相应的 event，整体作为一个 action，得到最终的状态

其中如果有 cancel action 产生相应的 event，则combo 被中断，被迫从头开始

# chord

- chord action

附加的action，如果当前 action 要触发，此 action 必须触发

即同时按键，才会触发

# chord blocker

在 `void IEnhancedInputSubsystemInterface::RebuildControlMappings()` 中自动添加

无法手动配置
---
type: card
created: 2024-04-02T22:19
tags:
- ue
- animation
---

简称 AN，用于在动画的特定时间点触发事件

# skeleton notify

类似于curve，新建的notify仅仅是一个名称，保存在skeleton中

可以添加在track中，触发事件，在 abp 的event graph中接收

仅仅是一个事件，没有参数
适合传递一个关键的时间点，通常不用于特定功能

## 用于状态机事件通知

在 ue4 中使用，在ue5中不推荐

在状态机内部，存在状态和过渡，而这两者在某些时刻，都可以定义事件触发

> [!tip]
> conduit 没有事件通知


对于状态而言 为 animation state ^c89574
- entered state event
	- state刚刚active 
- left state event
	- state刚刚inactive 
- fully blended state event
	- active 后，权重刚刚成为 1 

![[Pasted image 20240405230414.png]]

对于过渡而言，是 notifications
- start transition event
	- 刚刚触发过渡 
- end transition event
	- 结束blend，过渡结束 
- interrupt transition event
	- 过渡被中断时
	- [ ] transition interrupt 有更详细的 setttings 在 events section 中


![[Pasted image 20240405230513.png]]

默认为 None，填写一个字符串，就相当于定义了一个 skeleton notify，在 abp 中通过 notify event 来接收

（效果等同于 skeleton notify，不过没有保存在 skeleton 中，在 track 的notify 列表搜索不到这里添加的）

# anim notify

本质是一个类，UAnimNotify，添加在track中，同样在特定时间点触发

类的可发挥空间很大，多用于特定功能
如内建的
sound， 脚步声
particle，脚步灰尘

可以自定义子类，为自己所用
- GetNotifyName
	- 返回在track中呈现的名称 ，可以和参数相结合 
- Received_Notify
	- [x] return bool 的作用 ✅ 2024-04-19
		- 在源码中没有发现返回值的作用
		- 直接被忽略
		- 保持自己的编程习惯
			- 如果是正常的调用，返回 true
			- 如果出现意外，如 cast fail 返回 false

# anim notify state

- [ ] ans被中断会发生什么
	- 如果已经 begin，则 end 会在中断时触发
	- 如果没有 begin，则什么都不会发生，不会调用 begin tick end，相当于忽略

存在于一个时间段，本质是类 UAnimNotifyState

同样可以拓展子类
- GetNotifyName
- Received_NotifyBegin
	- 返回 bool 的含义同 notify
- Received_NotifyTick
- Received_NotifyEnd

# notify in montage

在anim seq的track上编辑an，an和seq的特定帧相关联

而在montage的track上编辑an，an和montage的特定帧关联
montage是一个容器，可以容纳不同的seq片段，在某个帧不一定是什么内容

官方自己实现了两个类，用于在 montage中独特使用

UAnimNotify_PlayMontageNotify
UAnimNotify_PlayMontageNotifyWindow

配合play montage节点，可以在其它bp中检测相应事件

![[montagenotify1.png]]
 ![[montagenotify2.png]]


# 触发权重

如果在当前an时间点，相应的pose参与了final pose的混合过程，则相应的an就会触发

在混合的过程中，pose点有相应的权重

min trigger threshold 描述了权重触发的临界点
默认是 0.00001 已经很小了，基本都能触发到

---
created: 2024-05-23T15:13
draft: true
tags: 
- card
- ue
- input
- debug
---

# showdebug enhancedinput

显示
- IMC
- action 对应 key 的输入情况
- action 对应的 trigger state
- state 维持时间

不显示 trigger

并不完美

显示 modifier 的手柄图，是静态的，理论上应该是动态的

手柄图有 bug，同一 action 不同 key 绑定的 modifier 显示在一起

![[Pasted image 20240523151207.png]]

![[Pasted image 20240523151148.png]]

# showdebug deviceproperty

- [ ] 显示 input device subsystem 中的 FActiveDeviceProperty 信息

# showdebug devices

- [ ] 显示 FHardwareDeviceIdentifier 的信息

# showdebug inputsettings

- [ ] 和 input user settings 相关
	- 需要在 project settings 中设置

# showdebug worldsysteminput

- [ ] 和 UEnhancedInputWorldSubsystem 相关
	- 用输入去控制没有 player controller 的 actor
	- 需要在 project settings 中开启

# input.+action ActionAssetName

强调触发相应 action

如果不关闭，一直发送 trigger event

```
input.+action IA_Attack
```

# input.-action ActionAssetName

与上对应，关闭

# input.+key KeyName

使一个物理键始终有输入值

```
input.+key w
```


# input.-key KeyName

与上对应，关闭
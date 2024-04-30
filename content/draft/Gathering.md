
- [ ] player camera manager class
	- 在 player controller 中，可以选择 player camera manager class 为自定义的类，实现自己的 camera manager
	- override blueprint update camera method , return
		- loc
		- rot
		- fov
		- true or false
			- decide whether the manager manage the camera for now
			- if false, use default behavior
- 
- [ ] 网格体插槽 是什么？
	- 和普通socket的区别

- [ ] leg ik node
- [ ] virtual bone 与 ik bone 协同运作的原理
- [ ] 为什么 ue skeleton 中会存在 Ik foot ik hand 的骨骼

- [ ] 脚部 ik 的实现

- [ ] hand ik retarget node
	- 使持枪动作保持正确
- [ ] pose asset
	- with curve
	- current or whole animation
	- create animation with pose
- [ ] LOD 概念 ⏬

- [ ] understand transition
- [ ] skeletal control nodes

- [ ] break hit result


- [ ] rotation from x vector
- [ ] is playing slot animation
- [ ] play slot animation as dynamic montage
- [ ] dynamic montage params
- [ ] get distance between two sockets
- [ ] trace api family, ref logseq
- [ ] add tick prerequisite actor
- [ ] timeline node
  - 新建 timeline 会自动生成变量在 components中
  - 定义连接事件
  - 可以在其它地方调用 


- [ ] draw debug shape apis
- [ ] has any root motion
- [ ] 高级相机系统 
- [ ] get physics linear velocity 
- [ ] set all motors angular drive params
- [ ] set enable gravity
- [ ] set actor location and rotation
- [ ] save pose snapshot
- [ ] ragdoll start update end
- [ ] set master pose component 🆔 e5etde
	- > Great to know you’ve found the solution. Just a advice, you don’t need animation blueprint for the clothes, use “set master pose” in the construct script inside your character bop. Connect the main body mesh to new master pose, and cloth mesh to the target. With this setup, the main body drives the other meshes.
- [ ] vertex color in static mesh
- [ ] physics asset
- [ ] anim post process instance
- [ ] anim modifier
  - enable  root motion 只是 seq 的属性吗   
- [ ] stop slot animation

- [ ] 状态机的层次概念
	- 当前层只关注当前层的转换

- [ ] turn in place  和 rotate in place 的区别在哪里
	- rotate 可以连续进行 
- [ ] fast path compatible

- [ ] blend profile in transition blend setting
- [ ] transition standard blend curve

- [ ] machine weight
- machine weight 只可以用在 transition 中？
- 含义是什么
- 在什么地方可用？
- 在整个 pose 中贡献的比例？

- [ ] windget reflector 使用方法
	- 如何定位到使用变量的相关代码块 
---
type: card
created: 2024-04-04T22:45
tags:
- ue
- animation
- bp
---

正常的 seq 片段在 abp 中使用 play 节点进行播放，整个片段帧从头到尾

![[Pasted image 20240404224631.png]]

右键菜单中，选择 convert to single frame animation，变成 evaluate 节点，只播放指定时间的一帧，相当于一个pose

![[Pasted image 20240404224643.png]]

同理，evaluate 节点的右键菜单中，可以再度转换回来
convert to sequence player

- [ ] play sequence node settings
	- [ ] play rate scale bias clamp
- [ ] evaluate sequence node settings
	- [ ] Teleport to Explicit Time
	- [ ] Reinitialization Behaviour
	- https://www.aaronkemner.com/animnode-reference/sequenceevaluator/
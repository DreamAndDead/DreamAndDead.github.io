---
type: draft
created: 2024-04-20T19:55
---

# 距离判断

将距离分为 3 6 9 等
3m 内为近距离
中
远

不同的程度，进行不同的行为选择

将距离离散化，表示为状态

## 计时机制

  所有计时器为单向不循环计时器
  在设定时长之后，开始向 0 倒计时
  到 0 即停止

可以设定计时器启动

检查是否开始 

```lua
--[[
  return true 如果 n 号计时器倒计时结束
]]
self:IsFinishTimer(n)

--[[
  将 0 号计时器置为 10s 并启动倒计时
]]
self:SetTimer(0, 10)

--[[
  3020 动作自上次开始，已经过了多少 s
]]
self:GetAttackPassedTime(3020)
```

## 计数机制

  用于招式计数忍耐度
  
```lua
--[[
  将计数器 22 设置为 1
]]
self:SetNumber(22, 1)
```

## 空间检测

```lua
--[[
  取得自身胶囊碰撞体的半径，单位 m
  在与玩家进行距离判断时，将其减去
]]
self:GetMapHitRadius(TARGET_SELF)

--[[
  获取自己到pc的距离
]]
self:GetDist(TARGET_ENE_0)

--[[
  自己的目标是谁

  主要仇恨对象，一般是玩家，也可能是其它npc
  如果是self，则说明对玩家没有仇恨
]]
self:GetStringIndexedNumber("targetWhich") == TARGET_SELF


--[[
  目标是否在以自己为中心的范围内
  
  前后左右 4 个方向，各摆出 degree / 2 的角度构成扇形，进行检测
]]
self:IsInsideTarget(target, direction, degree)
-- 加上距离
self:IsInsideTargetEx(target, self, diretion, degree, distance)


--[[
  检测相应角度以 self 发出的 dist 长度的直线上，有没有障碍物

  正前是 0 度，顺时针增大；180是背后

  没有障碍物 返回 true
]]
SpaceCheck(self, meaningless, degree, distance)


-- 发射射线，进行障碍检测
self:IsExistMeshOnLine(TARGET_ENE_0, AI_DIR_TYPE_ToB, dist)

--[[
  添加一个后台 service observer，时刻进行位置检测

  如果出现情况，则进行中断

  self:IsInterupt(INTERUPT_Inside_ObserveArea)
  self:IsInsideObserve(0) == true 
  self:DeleteObserve(0)
]]
self:AddObserveArea(obs_name, self, target, direction, degree, distance)
```

# 机制

每个 goal 中都有 4 个方法
- activate
  - 没有返回值
  - 在被 add 时马上执行一次
  - 先尝试选择交锋 act，添加对应的 subgoal
  - 如果没有，则尝试主动 act，添加对应的 subgoal
- update
- terminate
  - 没有返回值
- interrupt
  - topgoal 可以被 interrupt
  - subgoal 不可以被 interrupt

```
                     root               
                       |
                     top goal
                       |
                    sub goal
                      /   \
                  sub      sub
```

启动条件
终止条件

每个 goal 都有自己的 lifetime，过期会 terminate

topgoal 作为 root 的 subgoal

top goal 是第一级的 goal，一般第一级只存在一个 goal，时长无限

topgoal 一般是一个业务 goal，和某个场景某个人物相关，虽然有时也能复用

subgoal 是用于构建 topgoal 的 goal，一般功能明确，具有复用性


执行过程

root 清空正在执行的 top goal，添加要使用的 top goal，lifetime  -1
马上进行 activate

top activate 中，
先执行 交锋 act，如果没有，则执行主动 act
每个 act 都会添加一些 subgoal，这些 subgoal 都有 lifetime，到时会自动 term，删除自己与所有sub sub goal


ai 被弹开后，动作思路被打断，topgoal 进行 clear 并重新 activate

lifetime 只有在 update 时才会计时
每次只 update root 到 leaf 链上的所有节点

top goal 是每个角色的逻辑
一般每个角色有两个，一个 logic non battle top goal，一个 battle top goal
目前先研究 battle top goal

每个 top goal 在运行时，会开始进行 plan，主动 交锋 中断
决定当下使用哪个 act
每个 act 的完成，需要 sub goal 组合进行配合

- [x] htn ai 算法 🔼 ⏳ 2024-04-28 ✅ 2024-04-29
- [ ] htn 算法是如何与 sekiro ai 结合的 ⏳ 2024-04-29
- [ ] 研究 flunt htn 的实现 🔼
- [ ] 研究 ue htn plugin 的实现 🔼
- [x] ue htn 插件 ⏳ 2024-04-28 ✅ 2024-04-28

- MoveToSomewhere
  - ApproachSettingDirection
  - ApproachTarget
- CommonAttack
  - EndureAttack (SetEnableEndureCancel)
  - AttackImmediateAction (SetEnableImmediateAction)
  - AttackNonCancel
  - AttackTunableSpin
  - Attack
  - ComboAttack_SuccessAngle180
  - ComboAttackTunableSpin
  - ComboAttack
  - ComboFinal
  - ComboRepeat_SuccessAngle180
  - ComboRepeat
  - ComboTunable_SuccessAngle180
  - GuardBreakAttack
  - NonspinningAttack
- BackToHome
  - BackToHome_With_Parry
- Wait
  - ClearTarget
- Turn
- Guard
- SidewayMove
- SpinStep
- KeepDist
- LeaveTarget

```lua
--[[
  当前正在执行的 subgoal 类型?
  当前帧是否有jumptable的执行条件？
]]
self:IsActiveGoal(GOAL_COMMON_SidewayMove)

parent_goal:ClearSubGoal()

goal:Replanning()
```

瞬发动作，即刻生效的动作，不需要依赖tae中的条件

同时存在屏蔽瞬发动作的event block，disable ai immediate action

- [ ] 非战斗状态下 - 索敌机制
	- 自由状态的敌人，在站立 待机 巡逻
	- 当玩家接近，处于发现状态，头上开始积累警戒值 三角形积累
	- 满了之后，进入黄色警戒状态，开始去警戒到的点 （声音 看到的） 去小心探测是否存在目标  黄色三角形加黄色边框
	- 当发现玩家，进入战斗状态   三角形全红，后消失
	- 参考孤影众的分析


每帧循环，只执行一个 subgoal，从 root 到leat的path会更新 lifetime

当 subgoal update 不返回 continue 时，subgoal 运行结束，parent goal 删除 sub goal

当 topgoal update 不为 continue，结束
如果 lifetime -1, 会 replan，重新从头开始进行计划

变招计划与主动计划并行执行
不断搜索可能导致变招的信号，必要时将主动计划中断


主动计划，交锋计划
内部分成不同的 act
一个 act 代表一种行动选择
每个 act 有不同的权重
act 添加 subgoal，表示实际 act 要怎么做

每个 subgoal 有不同的启动条件，和tae event block中的设定相关

wait cancel timing  subgoal
在上个 attack 被 parry or guard 中断之后，当前的 subgoal 就中止
被迫 term，因为当前在播放的动画id已经和动作设定的 id 不符合

因为被弹开 被招架的动作 行为并不是代码中计划的 subgoal

topgoal 决定再次进行 replan，从头开始选择 act
如果此时下个 act 不符合启动条件，当前动画的 event block cancel 条件，就无法 update
此时需要一个 psudo subgoal  wait cancel timing  进行占位，避免 topgoal 因为 update 结束而replan

未被忍杀后恢复，开始replan


如果 findpath 不通，说明距离为无限，无法开启下一个 attack goal，即使是 9999 
这时选择用远程攻击方式，如扔石子

后一个 subgoal 总是想尽全力 cancel 前一个正在执行的 subgoal
当前面没有正在执行的 subgoal 而又无法被 cancel 时，用 wait cancel time 来替代


## 交锋计划 kengeki

是否存在交锋 sp

 交锋只有小幅弹开才有可能续招
被弹太远，无法进行交锋

对敌人的多数招式，如果被弹开，玩家马上反斩，敌人会优先防御，而不是发动交锋计划

霸体敌人，ai不用考虑防御，无论近 或 远，更不用考虑交锋
因为无法被弹开

这种敌人需要在主动计划上更为细致
距离细分
方位细分

## 主动计划 activate

- 先执行交锋
	- 如果未成功，则继续
- 根据条件，赋予不同act以权重
	- hp rate
	- 躯干 rate
	- dist
	- random int
	- space check
  - 每个act有自己的冷却时间
	  	-  未冷却结束，使用冷却权重 1
	  		-  不使用 0，为了防止无技能可用
	  	-  冷却结束，不修改权重，重置计时器
- 根据权重，随机选择 act 执行， add subgoal

## 中断变招计划 interupt

返回 false 说明没有中断发生
true 说明进行了中断

中断发生在 topgoal的级别上

中断类型
- 身上有某种sp引发的中断 
  - 观察相应的sp需要提前注册
- parry timing 防御行为中断
  - 检测到玩家的攻击信号
  - 通用ai防御
    - 连续防御 2 3 次进行弹开
    - 对突刺直接弹开
    - 再执行交锋计划
- 被射击导致的中断
  - 通用行为
    - <= 30m 触发防御
    - 否则 0.3s 后再进行防御
    - 用招架防御
- 药检中断
  - <= 3m 用投技
  - 3-6m 挥枪
  - 6m 外使用主动计划
- 失去追踪目标引发的中断，距离太远
- 事件引发的中断

变招计划不会考虑动作冷却而修改权重
但出招后，会影响主动计划 交锋计划的冷却时间

replan noaction 都会回到主动计划



- [ ] 敌人之间的通信
- [ ] 特定地点的事件触发


AI_TARGET_TYPE__NONE = 0
AI_TARGET_TYPE__NORMAL_ENEMY = 3
AI_TARGET_TYPE__SOUND = 4
AI_TARGET_TYPE__MEMORY_ENEMY = 5
AI_TARGET_TYPE__INDICATION_POS = 6
AI_TARGET_TYPE__CORPSE_POS = 7

ai 对目标类型的记忆

            self:ClearEnemyTarget()
            self:ClearSoundTarget()
            self:ClearIndicationPosTarget()
            self:ClearLastMemoryTargetPos()


# ai 的状态

caution state
find state
battle state

normal

non combat vigilance
非战斗警戒

combat alert
战斗警戒

discovery or combat

sp 是随着程序内部的状态在改变的
由相应的动画驱使

被pc发现，惊动自己

# 属性

视距
视觉上下角度
视觉左右角度
索尸视距衰减
尸体遗忘时间
回位计划寿命
视距索敌遗忘时间
被obj卡住攻击obj的动作
听距
响应友军求助信号的动作
发出求助信号的动作
归位过程中的防御动作
听觉截断距离
嗅距
强制归位距离
归位距离
战斗中归位距离
发现敌人后仍不进入战斗的时间
归位时注视敌人的时间
归位时注视敌人的距离
视距遗忘时间
听距遗忘时间
开战距离
队友作战效率
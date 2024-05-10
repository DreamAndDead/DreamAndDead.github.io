---
created: 2024-05-07T20:05
draft: true
---


* sekiro analysis

** game param

game config file, affect game mechanics

- ai sound param
	- walking
	- running
	- landing
		- radius
		- lifetime, frame
		- type

- bullet
	- 手里剑
		- attack param id
		- 发射子弹，自己的特效 id
		- fly visual effect id
		- hit visual effect id
		- guarded visual effect id
		- 命中派生子弹id
		- lifetime
		- 数量
		- 发射角度
		- 能否穿透
		- distance
			- 范围内重力，加速度
			- 范围外重力，加速度
		- 发射时间间隔
		- 初始速率，最大速率，最小速率
		- 加速时长
		- 与目标在范围内，开始追踪；在范围外，停止追踪
		- 子弹伤害半径，最大伤害半径
- calc correct graph
	- 与角色成长相关，值的变化
	- 不同等级的最大hp，躯干值，回复速度
- camera param
	- 不同相机的参数设置
- camera set param，在不同情景下，使用什么相机
 	- 锁定视角下 camera id
	- 正常视角下 camera id
- clear count correction param
	- 高周目下，对敌人的参数加成
		- hp倍率
		- mp倍率
		- 躯干上限倍率
		- 物理伤害倍率
		- 灵，炎，雷，锐利伤害倍率
		- 躯干伤倍率
		- 毒抗，炎抗，雷抗提升倍率
		- 躯干恢复速度倍率
- equip goods param
	- 素材
	- 物品系统
	- 特效id
	- 出售价格
	- 最大携带数量
	- 使用调用动作id
	- 是否是消耗品
- npc param
	- 行为组id
	- 基础转向速度
	- 身高
	- 常驻动作组
	- 常驻特效
	- 防御减伤比例
	- 红点数
	- 阵营
	- 招架时躯干减伤比例
	- 碾压等级
		- 高等级的自然做动作，可以把低等级的弹开
- npc think param
  - ai logic config related
	- common ai id
	- 战斗ai id
	- 警戒类型，小兵，大兵，boss
	- 视距
	- 听距
	- 队友作战效率
		- 越高，队友越少摸鱼
- shop list param
	- 商品类
	- 价格
	- 数量
- skill param
- sp effect param
	- icon
	- 持续时间
	- 是否会结束
	- 特效结束时触发的特效
	- 特效分类id，同类只能存在一个
	- 按百分比减少hp，数值减少
	- 影响面板
	- 敌人索敌视距衰减比率
	- 敌人警戒积累速率
- vfx param
	- 部署点
- throw param，和终结技相关
	- atk id
	- def id
	- atk anim id
	- def anim id


* TAE time act editor

** jumptable [0]

| ID  | DS Anim Studio                                     | English                                               | zh                | Japanese                |
| --- | -------------------------------------------------- | ----------------------------------------------------- | ----------------- | ----------------------- |
| 0   | Do Nothing                                         | Undefined Character Control Flag                      |                   | 定義されてないキャラ制御フラグ         |
| 1   | InvokeAnimCancelStart_R1_R2_LightKick_HeavyKick    | Right Hand Attack Key Input                           | 允许攻击输入？           | 右手攻撃キー入力                |
| 3   | InvokeShieldBlock                                  | Guarding                                              | 格挡区间, guard box   | ガード中                    |
| 4   | End If Right Hand Attack Queued                    | Right Hand Attack Anim Cancel                         | 允许右手攻击取消当前动画      | 右手攻撃アニメキャンセル            |
| 5   | InvokeParriedState                                 | Parry Possible                                        | 完美弹反区间            | パリィ可能                   |
| 6   | InvokeAnimCancelEndWithKeyboardKey                 | Shield Push Possible                                  |                   | 盾プッシュ可能                 |
| 7   | Disable Turning                                    | Disable Turning                                       | 禁止转向              | 旋回不可                    |
| 8   | Flag As Doding                                     | Invincible                                            | 无敌                | 無敵                      |
| 9   | InvokeAnimCancelStart_L1_L2                        | Left Hand Attack Key Input                            |                   | 左手攻撃キー入力                |
| 10  | InvokeAnimCancelStart_MagicR_Magic                 | Magic Key Input                                       |                   | 魔法キー入力                  |
| 11  | End If LS Move Queued                              | Anim Cancel By Movement Key Input                     |                   | 移動キー入力でアニメキャンセル         |
| 12  | InvokeDeath                                        |                                                       |                   |                         |
| 14  |                                                    | Right Hand Attack Release Input                       | fake input?       | 右手攻撃リリース入力              |
| 15  |                                                    | Left Hand Attack Release Input                        |                   | 左手攻撃リリース入力              |
| 16  | End If LH Attack Queued                            | Left Hand Attack Anim Cancel                          |                   | 左手攻撃アニメキャンセル            |
| 17  |                                                    | Anim Cancel After Dealing Damage                      |                   | ダメージを与えた後にアニメキャンセル      |
| 18  |                                                    | Anim Cancel After Successful Parry                    |                   | パリィ成功後にアニメキャンセル         |
| 19  | DisableMapHit                                      | Disable Map/Object Collision                          |                   | マップ・オブジェあたり無効           |
| 20  |                                                    | Ghost Info Send Start Flag At The Time Of Death       |                   | 死亡時のゴースト情報転送開始フラグ       |
| 21  | InvokeAnimCancelStart_Guard                        | Left Hand Guard Key Input                             |                   | 左手ガードキー入力               |
| 22  | End If Guard Queued                                | Left Hand Guard Anim Cancel                           |                   | 左手ガードアニメキャンセル           |
| 24  |                                                    | Super Armor                                           |                   | スーパーアーマー                |
| 25  | InvokeAnimCancelStart_SpMove_Backstep_Rolling_Jump | Step Movement Key Input                               |                   | ステップ移動キー入力              |
| 26  | End If Dodge Queued                                | Step Movement Anim Cancel                             |                   | ステップ移動アニメキャンセル          |
| 27  | SetNoGravity                                       | Ignore Gravity                                        |                   | 重力無視                    |
| 28  | InvokeIsLadder                                     | Disable Foot IK                                       | 是否在空中，脚未在地面       | 足IK無効                   |
| 29  | InvokeAction_AndTAEDebuggingClass                  | Magic Anim Cancel                                     |                   | 魔法アニメキャンセル              |
| 30  | InvokeAnimCancelStart_UseItem                      | Item Key Input                                        |                   | アイテムキー入力                |
| 31  | InvokeAnimCancelEnd_UseItem                        | Item Anim Cancel                                      |                   | アイテムアニメキャンセル            |
| 32  | End If Weapon Switch Queued                        | Generic Anim Cancel                                   |                   | 汎用アニメキャンセル              |
| 34  | InvokeAnimCancelEnd_General                        |                                                       |                   |                         |
| 35  |                                                    | First Step Right Hand Attack Key Input                |                   | 一段目右手攻撃キー入力             |
| 36  |                                                    | First Step Right Hand Attack Anim Cancel              |                   | 一段目右手攻撃アニメキャンセル         |
| 37  |                                                    | Left/Right Movement Possible                          |                   | 左右移動可能                  |
| 38  |                                                    | Flying Character Fall                                 |                   | 飛行キャラ落下                 |
| 39  |                                                    | Disable Enemy Character Collision                     |                   | 対キャラあたり無効               |
| 40  |                                                    | Temporary Death State                                 |                   | 仮死状態                    |
| 41  | InvokeHasSpace_HKs305                              | Gap                                                   |                   | 隙                       |
| 42  | InvokeIsSweetSpot                                  | Sweet Spot                                            |                   | スイートスポット                |
| 43  |                                                    | (DEPRECATED) Enable Foot IK                           |                   | (削除されました)足IK有効          |
| 44  |                                                    | Disable Event Object Collision                        |                   | 対イベントオブジェあたり無効          |
| 45  |                                                    | Disable Super Armor                                   |                   | スーパーアーマー無効              |
| 46  | ExtraJumptable_IFAlive?                            | Completely Disable. Cannot Return From Anim.          |                   | 完全無効。アニメからの復帰不可         |
| 47  | ExtraJumptable_InvokeDeath2                        |                                                       |                   |                         |
| 48  | ExtraJumptable_InvokeCultPromptCheck1              |                                                       |                   |                         |
| 49  |                                                    | Disable Lock-On                                       | 无法锁定              | ロックオン不可                 |
| 50  |                                                    | Disable Character Capsule Collision                   |                   | キャラカプセルあたりだけ無効          |
| 51  |                                                    | Disable Fall Motion                                   |                   | 落下モーション無効               |
| 52  |                                                    | Disable Vertical Movement Sync                        |                   | 起伏にあわせる無効               |
| 53  |                                                    | Disable Floating Gauge Display                        |                   | フローティングゲージ表示無効          |
| 54  | InvokeTalk_DisableInput                            | Disable Menu Display                                  |                   | メニュー表示無効                |
| 55  |                                                    | Disable Lock-On Operation                             |                   | ロック操作不可                 |
| 56  |                                                    | Disable Wall Attack Clang                             |                   | 壁攻撃弾き無効                 |
| 57  |                                                    | Disable NPC Wall Attack Clang                         |                   | NPC用壁攻撃弾き無効             |
| 59  | InvokeWeakSpot                                     | Attack Weak Spot                                      |                   | 攻撃ウィークスポット              |
| 60  |                                                    | Throw Angle Cancel                                    |                   | 投げ角度取り消し                |
| 61  |                                                    | Disable Y-Axis Of Movement Target                     |                   | 移動目標のＹ軸を無効にする           |
| 62  | SetYAxisAutoRot_AndUnk                             | Display Fixed Y-Axis Direction                        |                   | 表示方向をＹ軸固定               |
| 64  |                                                    | Camouflage OK Flag                                    |                   | カムフラージュOKフラグ            |
| 65  |                                                    | Extend Special Effects Lifespan                       |                   | 特殊効果寿命延長                |
| 66  |                                                    | Special Transition                                    |                   | 特殊遷移                    |
| 67  | InvokeThrowStart2                                  | Invincible Excluding Throw Attacks                    |                   | 投げ攻撃以外無敵                |
| 68  | InvokeHitSwing_ThrowStart1                         | Invincible Excluding Throw Damage                     |                   | 投げ抜けダメージ以外無敵            |
| 69  | InvokeThrowType5                                   | Throw Death Transition Decision                       |                   | 投げ死亡遷移判定                |
| 70  | InvokeThrowType4                                   | Throw Escape Transition Decision                      |                   | 投げ抜け遷移判定                |
| 71  |                                                    | SA Break Unrecoverable Flag                           |                   | SAブレイク回復不可フラグ           |
| 72  | InvokeKnockbackValue                               | Knockback Take-Over Time                              |                   | KB肩代わり時間                |
| 74  |                                                    | Ladder Collision Start                                |                   | はしごアタリ開始                |
| 75  | ItemPickUp_RememberInput                           | Item Acquisition Anim Cancel Possible Start           |                   | アイテム取得アニメキャンセル可能開始      |
| 80  |                                                    | Item Acquisition Anim Cancel Queue Start              |                   | アイテム取得アニメキャンセル受付開始      |
| 81  |                                                    | Item Acquisition: Close Button Disable Start          |                   | アイテム取得：閉じるボタン無効化開始      |
| 82  |                                                    | Perfectly Match Ragdoll Pose                          |                   | ラグドル姿勢完全あわせ             |
| 83  |                                                    | Mimicry Force Cancel Flag                             |                   | 擬態強制解除フラグ               |
| 84  |                                                    | Special Transition 2                                  |                   | 特殊遷移２                   |
| 85  |                                                    | Light Lantern Weapon                                  |                   | ランタン武器点灯                |
| 87  | InvokeAttackAction_Complex                         | Common Key Input                                      | 用户输入有效            | 共通キー入力                  |
| 88  |                                                    | Disable Precision Shooting                            |                   | 精密射撃無効                  |
| 89  | Disable All Movement                               | Completely Disable Movement                           |                   | 全移動不可                   |
| 90  | Limit Move Speed To Walk                           | No Dash/Run                                           |                   | ダッシュ・走り不可               |
| 91  | Limit Move Speed to Dash                           | No Dash                                               |                   | ダッシュ不可                  |
| 92  |                                                    | Sky Death Warp Possible                               |                   | 空中死亡ワープ可能               |
| 94  |                                                    | Perfect Invincibility                                 |                   | 完全無敵                    |
| 95  | InvokePlayerDeathLight                             | Disable Shadow Displaying                             |                   | 影表示無効                   |
| 96  |                                                    | Set Immortality                                       |                   | 不死設定                    |
| 97  | InvokeMagicCastingUselessChecks                    | Disable Magic / Item Use Anim Cancel Flag             |                   | 魔法/アイテム使用アニメキャンセルフラグ無効  |
| 98  |                                                    | Align Look Direction To Head Direction (DummyPoly 50) |                   | 視線方向を頭の方向（ダミポリ：50）に合わせる |
| 99  | InvokeIsCultRitualProgressing                      | During Corpse Carrying                                |                   | 死体運び中                   |
| 100 |                                                    | During Ceremony                                       |                   | 儀式中                     |
| 101 |                                                    | Corpse Carrying Keyframe                              |                   | 死体運びキーフレーム化             |
| 102 |                                                    | Super Armor Forced Break                              |                   | スーパーアーマー強制ブレイク          |
| 103 | InvokeAnimCancelEnd_L2                             | Early Weapon Animation Cancel                         |                   | 早い剣戟アニメキャンセル            |
| 104 | InvokeAnimCancelEnd_L2_WeaponCancelType            | Late Animation Cancel                                 |                   | 遅いアニメキャンセル              |
| 105 | InvokeAnimCancelStart_L2                           | Early Weapon Key Input Flag                           |                   | 早い剣戟キー入力フラグ             |
| 106 | GetWeaponCancelType                                | Late Weapon Key Input Flag                            |                   | 遅い剣戟キー入力フラグ             |
| 107 | InvokeAnimCancelEnd_UseItem_ByGoodsParam           | Early Item Anim Cancel                                |                   | 早いアイテムアニメキャンセル          |
| 108 | InvokeAnimCancelStart_UseItem_ByGoodsParam         | Early Item Key Input                                  |                   | 早いアイテムキー入力              |
| 109 | InvokeCanDoubleCast                                | Magic Double Casting Possible                         |                   | 魔法２重詠唱可能                |
| 110 | InvokeDisableDirectionChange                       | Disable Joystick Rotation Input                       |                   | スティック旋回入力無効             |
| 111 | InvokeAnimCancelStart_EmergencyStep                | Urgent Dodge Key Input                                |                   | 緊急回避キー入力                |
| 112 | InvokeAnimCancelEnd_EmergencyStep                  | Urgent Dodge Cancel                                   |                   | 緊急回避キャンセル               |
| 113 | InvokeHeightCorrection                             | Disable Foot IK Up/Down Visually                      |                   | 足IKの見た目の上下を無効           |
| 114 | InvokeChangeLockOnMarkerPos                        | Enhanced Camera Tracking                              |                   | カメラ追従強化                 |
| 115 | InvokeAnimCancelEnd_R1_LightKick                   | Right Hand - Weak Attack Anim Cancel                  | 可被R1所cancel? 普通攻击 | 右手_弱攻撃アニメキャンセル          |
| 116 | InvokeAnimCancelEnd_R2_HeavyKick                   | Right Hand - Strong Attack Anim Cancel                |                   | 右手_強攻撃アニメキャンセル          |
| 117 | InvokeAnimCancelEnd_L1                             | Left Hand - Weak Attack Anim Cancel                   | 可被L1所cancel？格挡    | 左手_弱攻撃アニメをキャンセル         |
| 118 | InvokeAnimCancelEnd_L2                             | Left Hand - Strong Attack Anim Cancel                 |                   | 左手_強攻撃アニメキャンセル          |
| 119 | TryToInvokeForceParryMode                          |                                                       |                   |                         |
| 120 | InvokeAnimCancelStart_L1_L2_ByWeaponParam          |                                                       |                   |                         |
| 121 | InvokeAnimCancelEndExtra_L1_L2_ByWeaponParam       |                                                       |                   |                         |
| 124 | InvokeLockOnAutoSearch                             |                                                       |                   |                         |

** invoke bullet behavior [2]

invoke a bullet, may be a effect or sort of projectile

drain stamina, fire projectile, etc

look up index in gameparam - bullet

- dummy poly id

** invoke common behavior [5]

like attack but simpler

like falling on sb's head causing staggering

** blend [16]

** set weapon style [32]

- none
- right weapon one-hand
- left weapon two-hand
- right weapon two-hand
- one-hand (left weapon transformed)
- one-hand (right weapon transformed)

** switch weapon [33]

- weapon slot id

** UnequipCrossbowBolt [34]

- handtype
	- left hand
	- right hand

** equip crossbow bolt [35]

same with 34

** set bool request ai state 63

npc 在开始进攻时，防御时，给予ai识别的一个信号

** cast high lighted magic [64]

- dummy poly id

** consume current goods [65]

- hand type
	- right
	- left

** add sp effect multiplayer [66]

** add sp effect [67]

add sp effect

duration may or not rely on how long the block is
instant or not

sp effect is a wide category, including
- poisoning
- buffs
- ai triggers

param is a int, look index in game param - SpEffectParam

** spawn one shot ffx ember [95]

** spawn one shot ffx [96]

spawn a vfx while block is active

ffx, look up index in game param - SpEffectVfxParam

- dummy poly id
- slot id
- is ignore dummy poly angle
- is follow dummy poly

** spawn repeating ffx [99]

** spawn ffx [100-110]

** spawn ffx by floor [112]

** spawn ffx goods and magic [114]

** spawn ffx goods and magic ex [115]


** spawn ffx throw [116]

- repeat type
	- play once
	- play twice
- is repeat

** spawn ffx throw direction [117]

** spawn ffx blade 118

- dummy poly source
	- body
	- left weapon
	- right weapon
- blade base id
- blade tip id

** spawn ffx body for event duration 119

** play ffx 120

** invoke ffx 121

** spawn ffx by sp effect 122, 123


** play sound center body [128]

- sound type
  - environment
  - character
  - menu
  - cutscene
  - sfx
  - bgm
  - voice
  - floor material determined
  - armor material determined
  - ghost
- sound id, look up index in game param - ????

** play sound by state info 129

** play sound by dummy poly player voice 130



** play sound by dummy poly 131

** play sound weapon 132

** invoke decal param id dummy poly 138

** invoke decal param id by foot 139

** invoke rumble cam by range 144, 147

- falloff start
- falloff end

** invoke rumble cam global 146

** set lock cam param 150

** camera module 150-156


** invoke debug fade out 192

** set opacity keyframe [193]

smoothly fade from one value to another over the duration of box

start opacity
end opacity

back to default opacity after end

** enable blur feedback 195

** debug string print bump blend decal 196

** invoke fade out 197

** set turn speed [224]

set character rotation speed while the block is active

back to default

** set sp regen rate percent [225]

modify stamina regeneration rate percent

** set knockback percent 226

** invoke event ez state flag 227

** ragdoll revive time 228

** create ai sound 229

** set mp regen rate percent 230

** set ez state request id 231

** allow vertical torso aim [232]

modify vertical facing angle of character's upper body via camera angle

- upper turning limit, max angle can aim up
- lower turning limit, max angle can aim up
- upward angle threshold, angle required for character to start aiming up
- downward angle threshold, angle required for character to start aiming down

** change chr draw mask 233

** add offset to next anim id 234

** root motion reduction [236]

allow to reduce how far root motion actual move

- start
- end
- type

** create ai sound 238

** activate jump table early 300

- default
- equip load
- weapon weight rate
- compressed damage rate
- always as early as possible
- dexterity casting speed
- debug tae value
** add sp effect dragon form 302
** extra sa durability multiplier 305
** action request 320
** weapon art fp consumption 330
** add sp effect weapon arts 331
** invoke weapon art weapon style check 332
** add sp effect multiplayer 401
** invoke full body wet 510
** locked on module 520-522
** enable behavior 600
** set additive anim 601
** debug anim speed 603
** test param 604
** blend to idle or movement anim 605
** invoke jiggle modifier 606
** facial expression additive animation playback 607
** invoke chr turn speed 704
** facing angle correction 705
** invoke chr turn speed for lock 706
** invoke manual attack aiming 707
** hide equipped weapon 710
** hide model mask 711
** invoke weapon shealth flags 712
** show model mask 713
** damage level function 714
** override weapon model location 715

- weapon model type
	- right weapon
	- left weapon
- dummy poly id

** only for non c0000 enemies 730


** change bone pos 770

** fix bone 771

** change bone pos ex 772

** add height 780

** turn lower body 781

** invoke ai replannig ctrl reset 782

** spawn chr finder bullet 785

** disable default weapon trial 790

** invoke part damage additive blend invalid 791

** invoke foot sfx param entity 792

** invoke cult weapon value 793

** invoke cult flag 794

** invoke ds3 poise 795

** invoke menu 796

** add sp effect cult ritual completion 797

** invoke cult completion sfx value 798

** invoke cult execution 799

** debug movement multiplier 800

** action for throw cutscene se 934

** action for throw cutscene se dummy poly following 935

** action for throw cutscene decal specific dummy poly 936

** old sound debug 970

** play sound wander ghost 10130

** invoke debug decal 10137, 10138


** motion blur on weapon swing?

** set opacity of character?

dying

summoned into other wolrd

teleportion

** set attack anim tracking speed of character?

** play camera shake?

** play additional animation layer, like cloth simulation?

** adjusting model render mask, show or hide specific parts of character?

** forcing death?




* param editor

躯干是增量计算的，到满量则可以被忍杀

hp是减量计算的

韧性，受击之后，不会被打断动作；用于大型boss;消耗空之后出硬直，会被打断动作
之后韧性再回满，韧性恢复时间

突刺，无视防御的伤害？

** atk param

记录整个动作的状态，和时机无关的

| name                       | desc                                                   | npc or player |
|----------------------------+--------------------------------------------------------+---------------|
| sp effect                  | 命中敌人，给敌人添加什么特效                               |               |
| atk phys                   | 物理伤害, hp 伤害                                        | n             |
| atk mag                    | 灵属性伤害                                               | n             |
| atk fire                   | 炎属性伤害                                               | n             |
| atk thun                   | 雷属性伤害                                               | n             |
| atk stam                   | 躯干伤害                                                | n             |
| atk super armor            | 韧性伤害，削韧性                                         |               |
| damage level               | 冲击力,可以打断很多动作                                   |               |
| atk attribute              | 攻击属性，斩击，打击，投技                                |               |
| atk dark                   | 锐利伤害                                                |               |
| new stamina damage         | 这招被弹开之后，自己加多少躯干；被弹开后的躯干伤             |               |
| atk phys correction        | 物理修正系数；因为玩家有成长机制，以value * 40 / 100 来计算 | p             |
| atk mag correction         |                                                        | p             |
| atk fire correction        |                                                        | p             |
| atk thun correction        |                                                        | p             |
| atk stam correction        |                                                        | p             |
| atk super armor correction |                                                        |               |

突刺类，识破机制

识破框先出，大于攻击框

调用再次 invoke attack behavior



** bullet

远程组

| name | desc         | n p |
|------+--------------+-----|
|      | 对应伤害组的id |     |
|      |              |     |

** camera param

相机设置预设

| name           | desc             |
|----------------+------------------|
| ChrOrgOffset X | 相对于主角的偏移量 |
| ChrOrgOffset Y |                  |
| ChrOrgOffset Z |                  |
|                |                  |

** npc param

每个敌人的参数设定

| name                     | desc                              |
|--------------------------+-----------------------------------|
| hp                       | 基准血量                           |
| mp                       |                                   |
| sp effect id             | 常驻特效id                         |
| phys guard cut rate      | 防御力？                           |
| mag guard cut rate       |                                   |
| fire guard cut rate      |                                   |
| thun guard cut rate      |                                   |
| debug behavior r1        | 用开发者菜单进行操纵时，对应的招式 id |
| debug behavior l1        |                                   |
| part damage rate 1       | 身体不同部位的伤害倍率               |
| part damage rate 2...    |                                   |
| stamina                  | 躯干                               |
| stamina recover base val | 躯干回复速度                        |
| poison resist            |                                   |
| toxic resist             | same with poison                  |
| blood resist             | 炎抗                               |
| curse resist             | ？                                 |
| super armor durability   | 初始韧性                           |
| health bar num           | 红点数                             |
| npc type                 | 阵营                               |
| team type                |                                   |
| model mask 1-32          |                                   |
| phys slash  rate         | 斩击 hp 受伤倍率                     |
| phys blow  rate          | 打击                               |
| phys thrust rate         | 突刺                               |
| magic rate               |                                   |
| fire rate                |                                   |
| thunder rate             |                                   |
| dark rate                |                                   |
|                          |                                   |

** clear count correct param

clear count 周目

数据隨周目的变化

全部都是乘数因子，在基准上的叠加

全部都是应用于敌人身上的，在 npc param 之上的修正

| name           | desc |
|----------------+------|
| hp             |      |
| mp             |      |
| stamina        |      |
| phys dmg       |      |
| slash dmg      |      |
| blow dmg       |      |
| thrust dmg     |      |
| neutral        |      |
| magic dmg      |      |
| fire dmg       |      |
| thunder dmg    |      |
| dark dmg       |      |
| phys resist    |      |
| magic resist   |      |
| fire resist    |      |
| thunder resist |      |
| dark resist    |      |
| stamina dmg    |      |
| mp recover     |      |
| poison resist  | 毒抗  |
| toxie resist   |      |
| bleed resist   |      |
| curse resist   |      |
| frost resist   |      |
| hp recover     |      |
| sub mp recover |      |
| sub hp recover |      |
|                |      |



** npc think param

和 ai 设定相关的设置

| name                  | desc                                   |
|-----------------------+----------------------------------------|
| logic id              | 引用哪个 ai 文件                         |
| team attack efficency | 团队攻击效率；用于群集 ai；越低，摸鱼人越多 |
|                       |                                        |

** sp effect param

特效组，不同的特效设定

特效可以长驻
瞬间触发
短暂生效

- 铠甲减伤
- 心中战场，进行统一倍率调整
- 回复躯干
- ai 弹开特效，区分招架

编号5xxx 为霸体

| name                    | desc                         |
|-------------------------+------------------------------|
| slash damage cut rate   | 斩击受伤倍率；0.5 相当于减伤一半 |
| blow damage cut rate    |                              |
| thrust damage cut rate  |                              |
| magic damage cut rate   |                              |
| fire damage cut rate    |                              |
| thunder damage cut rate |                              |
| phys atk rate           | 物理攻击力修正                 |
| magic atk rate...       |                              |
| sp effect vfx id        | 同时会触发的视觉特效 id         |
|                         |                              |

*** common list

|     id | desc                                   |
|--------+----------------------------------------|
| 200211 | ai 主动弹开到左手边，动作未失衡，可继续反击连招 |
| 200210 | ai 主动弹开到右手边                      |
|        |                                        |

** sp effect vfx param

vfx 相关设定

| name | desc |
|------+------|
|      |      |


* event

|  id | desc       |
|-----+------------|
| 960 | 锁定回复躯干 |
|     |            |

* game dev menu

按比例掉血 与 按量掉血是不同的

- performance
	- gfx
		- fps
			- 30 60
			- no lock
		- time scale
			- 时间比例
  - game
		- obj ins
			- env obj list around char
				- move position to this pos
		- chr ins
			- world chr man
				- create debug chr
					- select chr
					- select think id
				- map
  				- select chr
  					- move to position
  					- switch control
						- behavior
							- animation
						- ai
							- goal
					- no update 锁定到某一帧，完全不动
				- player lock chr 选择当前锁定的角色
			- chr dbg
				- player exterminate 一击必杀
		- game data 会产生永久影响
		- 弹丸管理
			- 方位描画



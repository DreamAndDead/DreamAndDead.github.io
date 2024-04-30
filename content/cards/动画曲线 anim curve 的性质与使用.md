---
type: card
created: 2024-04-01T17:54
tags:
- ue
- animation
---

动画曲线的本质是 float 曲线
名称定义在 skeleton 中，曲线数值定义在 anim seq 中，和动画一样的长度
在动画的每一帧，都有对应的数值
默认值是 0

curve 有三种类型，作用不同

| 类型           | 适用范围                |
| :----------- | :------------------ |
| attribute    | 用于anim bp属性变化
| material     | 驱动material instance |
| morph target | 驱动面部表情              |

在 abp 中有以下曲线相关的操作节点

| node                   | image            | desc                                                  | anim graph | event graph |
| ---------------------- | ---------------- | ----------------------------------------------------- | ---------- | ----------- |
| get all curve names    | ![[animbp3.png]] | all curve names defined in skeleton                   | y          | y           |
| get active curve names | ![[animbp2.png]] | active curve names at the time, with type parameter   | y          | y           |
| get curve value        | ![[animbp4.png]] | get float value at the time with curve name parameter | y          | y           |


# link curve to bones 

在 anim curves panel 中选择曲线打开 detail，其中可以关联多个骨骼

使得某个曲线在某个骨骼 active 的情况下才 active

情况1，由于 LOD 的原因，某些骨骼被 reduce，此时关联骨骼的曲线就会 inactive

情况2，当导入新的模型，和之前旧的skeleton进行了merge，使得当前的skeleton成为两个模型的超集，同时曲线名称也合并在skeleton中

旧的模型是没有使用某些骨骼的，同时旧的模型也没有使用新模型所引用的曲线
此时将新的曲线和新引入的骨骼关联起来，就不会对旧模型对曲线的使用产生影响


# curve 值在anim graph中的传递 

每一帧anim graph都会计算出一个pose，同样的，每一帧anim graph 也会计算出一个curve weight

anim graph中对pose操作的节点对curve weight也有影响

最终pose是由底层基础pose不断混合，成为最终pose
pose是anim seq的某一时刻的值，在这个时刻有一个关联的curve weight值，也随着pose的不断混合而混合


| 类型       | 节点                     | 曲线混合方式                                 |
| -------- | ---------------------- | -------------------------------------- |
| blend    | 其它                     | 同pose混合方式，线性混合 or enum 选择              |
|          | layered blend per bone | 比较特殊，参考[[layered blend per bone node]] |
| additive | make dynamic additive  | 同pose，进行曲线值减法                          |
|          | apply space additive   | 同pose，进行曲线值加法，带alpha加权                 |
| modify   | modify curve node      | 直接对曲线值进行修改，参考 [[#modify curve node]]   |

## modify curve node

右键点击，add curve pin，选择要修改的curve

每个curve填写一个value参数，总体提供一个alpha

有5种修改方式


| mode                    | 公式 curve =                                                             |
| ----------------------- | ---------------------------------------------------------------------- |
| add                     | $curve + value$ ，alpha没有作用                                             |
| scale                   | $curve * value$，alpha 没有作用                                             |
| blend                   | $(1-alpha)*curve + alpha*value$，普通的线性混合                                |
| weighted moving average | TODO 只和 alpha 相关，以 alpha为初值，不断上升到 1为止并保持                               |
| remap curve             | remap $(value, 1)$ -> $(0, 1)$, e.g. value=0.6, curve remap 0.8 to 0.5 |

# metadata curve

只读的，无法编辑的，保持为1的直线
和普通curve使用一样的名称域，即不能存在同名的 curve 和 meta curve

curve的默认值是 0
- 新建曲线，默认为0的直线
- 如果当前播放的seq不存在相应曲线，对曲线取值是 0

0 相当于没有，有些情况下不是一个合理的默认值
meta curve以1为默认值，是一个不错的替代

少量需要曲线的anim进行曲线刻画
其它需要曲线存在的，默认值的用 meta
剩下不需要曲线的动画则不用管，默认值是 0

meta curve和curve是可以随时相互convert的

# set weight manually for debug

在 anim curves panel 中，如果选择 auto，则曲线当前值(weight)由动画驱动

可以取消勾选，手动修改为一个恒定值，方便调试

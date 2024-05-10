---
type: card
created: 2024-04-05T19:43
tags:
- ue
- animation
- bp
---

- [ ] time node in trans graph
![[Pasted image 20240407142745.png]]




在动画蓝图中，有这样几个node
- get relevant anim length
- get relevant anim time 
- get relevant anim time fraction
- get relevant anim time remaining
- get relevant anim time remaining fraction

这些node只能在transition graph中使用

因为transition出现在 from state 和 to state 之间，这些node主要是搜索来自from state的 most relevant anim相关的时间数据

在一个state中，有多个 anim sequence一同决定了当前state的pose输出
每个anim seq由一个sequence player播放

most relevant anim 指的是为最终pose输出贡献权重最大的sequence player


| node                    | desc                   |
| ----------------------- | ---------------------- |
| length                  | seq的动画长度，以秒为单位的float   |
| time                    | seq已经播放的时间，以s为单位的float |
| time fraction           | seq已经播放的时间，在总体时间中的百分比  |
| time remaining          | seq还剩多少时间播放结束          |
| time remaining fraction | 同上，以百分比的形式             |

可以用 get relevant anim time remaining == 0 来当作过渡条件，当 from state动画一结束，就过渡到 to state，效果同 auto rule

在论坛有看到，在这种情形下，推荐使用 auto rule，因为有 fast path

而且有一个细节在于，transition blend是有时间的，如果使用auto rule，会在即将结束前-blend time的时刻，开启过渡
如果使用 remaining == 0 的方法，则from state已经播放结束，却还要用最后一帧在 blend time 的时间过渡到 to state，不合理


![[Pasted image 20240405202045.png]]
在某些情况下，from state中有多个player，但是 relevancy 相同，如上的 additive 的情况
这时可以打开 player 的 relevancy 设置，check ignore for relevancy test 选项，退出关于 relevancy的检测，这样就不会影响相关node的使用
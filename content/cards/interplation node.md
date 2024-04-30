---
type: card
created: 2024-04-03T12:09
tags:
- ue
- bp
---

interplation 节点多用在 anim bp 中

名称模式为 Interp To，根据操作的数据类型有不同的前缀


| Prefix   | 数据类型      |
| -------- | --------- |
| T        | Transform |
| V        | Vector    |
| F        | Float     |
| R        | Rotation  |
| Vector2D | Vector2D  |

参数都为 4 个
- current
- target
- delta time
- interp speed
返回插值后的新值

核心算法是，在current和target之间，寻找迭代的一小步
这一小步由 delta 和speed的积 clamp 到 0-1 以及差值向量来决定
每次只进行一小步

```cpp
const float DeltaInterpSpeed = InterpSpeed * DeltaTime;
const FRotator Delta = (Target - Current).GetNormalized();

const FRotator DeltaMove = Delta * FMath::Clamp<float>(DeltaInterpSpeed, 0.f, 1.f); 
```

部分节点提供 constant 后缀的新节点，用不同的插值算法

constant 算法没有考虑 clamp
---
created: 2024-05-17T15:37
draft: true
tags: 
- card
- ue
---

用户继承自 uobject 的类，如果没有实现getworld方法，在bp中使用会缺少很多函数

```cpp
virtual UWorld* GetWorld() const override;
```
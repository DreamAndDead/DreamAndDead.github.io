---
created: 2024-05-27T16:53
draft: true
tags: 
- card
- ue
- bp
---

在 bp 新建变量，选择 object type 时，有 4 种 ref 类型可选择

![[Pasted image 20240527165616.png]]

[[ue ref.drawio]]

和 cpp 底层有对应关系

| bp                    | cpp                     |
| --------------------- | ----------------------- |
| Object Reference      | `TObjectPtr<T>`         |
| Class Reference       | `TSubclassOf<T>`        |
| Soft Object Reference | `TSoftObjectPtr<T>`     |
| Soft Class Reference  | `TSoftClassPtr<TClass>` |

本质都是模板类，对外表现的像一个指针

对指向的对象 or uclass 有类型校验


---
created: 2024-05-17T15:43
draft: true
tags: 
- card
- ue
---

被 uproperty 标记的指针，如果指向的对象已经被清除，则会自动修改为nullptr

如果是默认指针，当指定对象被释放，依然指向原来的地址

当指针再次被使用，会发生错误的内存引用



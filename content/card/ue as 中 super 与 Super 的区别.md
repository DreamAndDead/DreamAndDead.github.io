---
created: 2024-04-23T18:59
tags: 
- card
- ue
- as
---

在 angelscript 的原版实现中，在子类的构造函数通过 super 调用父类的构造函数

通过`父类名::`方式调用父类方法

这两种方式是有区别的，

|         | 可调用父类哪些函数 | 在子类的哪些函数中可用 |
| ------- | --------- | ----------- |
| super   | 构造函数      | 构造函数        |
| `父类名::` | 非构造函数     | 所有          |
| Super   | 同上        | 同上          |

在 ue 的版本中，添加了新的符号 Super，代表父类的类名

```angelscript
  class MyDerived : MyBase
  {
    MyDerived()
    {
      super(10);

      MyBase::DoSomething();
    }

    void DoSomething()
    {
      MyBase::DoSomething();
      // 等价
      Super::DoSomething();
    }
  }
```



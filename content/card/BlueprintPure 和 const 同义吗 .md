---
created: 2024-05-03T15:07
draft: true
tags: 
- card
- cpp
- bp
---

[[rule of keyword const#const 成员函数|const 成员函数]] 在 cpp 中意思是，此函数不会对任何成员变量做修改

类似的，BlueprintPure specifier 标识此函数在 bp 调用中，是纯函数，没有副作用，不会修改成员变量，在 graph 中表现为 没有 input output pin

# const 是 BlueprintPure

当 const 函数 expose 到 bp 中时，默认已经是 BlueprintPure，无需重复添加
重复添加有 warning 出现

```cpp
UFUNCTION(BlueprintCallabe)
int32 Foo() const;
```

# const 不是 BlureprintPure

const 成员函数并非一定是 pure 的，因为 [[rule of keyword const#mutable keyword|mutable]] 的存在

当 expose 到 bp 的时候，可以使用

```cpp
UFUNCTION(BlueprintCallable, BlueprintPure=false)
int32 Foo() const;
```

恢复 input output pin

# BlueprintPure 不是 const

const 函数只对类的成员函数有意义，而在 blueprint library 中，函数都是 static，无法 const

但是这些函数是可以 BlueprintPure 的

# BlueprintPure 能保证“const”吗？

假如 expose 如下函数到 bp，在 bp 中呈现 pure，但是内部的实现能保证是 pure 吗？

```cpp
UFUNCTION(BlueprintPure)
int32 Foo();
```

猜测大概率不会，在 bp 中并不存在 const 概念，标识 BlureprintPure 只有图形呈现化的差异，并非在功能上有所限制

const 本身在编译阶段起作用，bp 的编译是 ue 自己开发的，并非属于 cpp 编译器，没有 const 检查的功能
---
created: 2024-05-17T16:34
draft: true
tags: 
- card
- ue
- asset
---

游戏是一个运行的程序，内部由无数个 uobject 对象组成。
在运行时，这些 uobject 存活在内存中的。
在用 editor 制作游戏时，这些 uobject 存活在磁盘上。

类似于虚拟内存的原理，在内存不足时，将部分内存页调度到磁盘上，扩大内存容量。uobject 也是同理。

在一个游戏场景，只需要部分 uobject 在内存中使用，而不是全部。

asset 在磁盘上的引用关系，会依照原样，映射到内存中。


# uasset 是文件

存放在磁盘上的文件，通过文件管理器可看到

文件内容是 uobject 对象的序列化，从内存形式，转变为文件形式

在需要时，可重新加载，从文件形式，转变为内存形式的 uobject 对象

# 索引路径

![[Pasted image 20240517163917.png]]

在代码中加载 uasset 文件使用的路径，和文件系统路径有关系，但不完全相同

格式为 `/Script/Engine.StaticMesh'/Game/Geometry/Meshes/1M_Cube.1M_Cube'`

- `/Script/Engine.StaticMesh`
	- 标识 uasset 数据所代表的 uobject 的类型
	- 表示 engine 模块中的 `UStaticMesh` 类
	- 标识给人看的，在实际加载过程中无作用
- `/Game`
	- `/Game` 标识放置在游戏项目 Content 目标下
	- `/Engine` 标识放置在引擎项目 Content 中的资产
	- `/Script` cpp class
	- ![[Pasted image 20240517164249.png]]
- `/Geometry/Meshes`
	- 以大类目录为根目录，到实际资产的文件目录路径
	- 和文件系统保持一致
- `1M_Cube`
	- uasset 存放的文件名
- `.`
- `1M_Cube`
	- 存储在 uasset 中的 uobject 对象名
	- 一个 uasset 可以存储多个 uobject

# upackage 


可以粗略认为，一个 uasset，是一个 upackage 的序列化生成的

```cpp
class COREUOBJECT_API UPackage : public UObject
```

一个 upackage 中，存放多个 uobject 对象

# outer 指针

```cpp
template< class T >
T* NewObject(UObject* Outer, const UClass* Class, FName Name = NAME_None, EObjectFlags Flags = RF_NoFlags, UObject* Template = nullptr, bool bCopyTransientsFromClassDefaults = false, FObjectInstancingGraph* InInstanceGraph = nullptr, UPackage* ExternalPackage = nullptr)
```

uobject 对象之间通过 outer 指针，一路向上，最终指向最外层的 upackage

> [!NOTE] 不同模式下 Outer 是不同的
> 编辑器中蓝图UObject的“Outer”是UPackage，而在Runtime是Actor的“Outer”一般是所在的Level




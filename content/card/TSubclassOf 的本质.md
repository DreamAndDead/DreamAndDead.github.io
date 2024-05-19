---
created: 2024-05-19T08:15
draft: true
tags: 
- card
- ue
- reflection
---

TSubclassOf 本质是一个模板类，表示一个类型约束的 UClass 指针

```cpp
template <typename T>
class TSubclassOf
{
private:
	TObjectPtr<UClass> Class = nullptr;
}
```

类型 T 由 ue 内部使用，达到一些约束效果

在编辑器中，使用 TSubclassOf 可以约束类的选择，只会弹出相应类型 T 的子类，方便给策划使用

对比

```cpp
/** type of damage */
UPROPERTY(EditDefaultsOnly, Category=Damage)
UClass* DamageType;
```

```cpp
/** type of damage */
UPROPERTY(EditDefaultsOnly, Category=Damage)
TSubclassOf<UDamageType> DamageType;
```

没有使用 TSubclassOf 进行约束的话，在编辑器中所有的类都会被弹出选择，这不是想要的结果



不只在 editor 中提供约束，在 cpp 层面同样提供约束
当两者都是 TSubclassOf，会通过一些模板黑魔法，在编译期提供类型检查

| A = B       | UClass        | TSubclassOf        |
| ----------- | ------------- | ------------------ |
| UClass      | no check      | ?                  |
| TSubclassOf | runtime check | compile time check |

```cpp
TSubclassOf<UDamageType> ClassA;

UClass* ClassB = UDamageType::StaticClass();
// Performs a runtime check
ClassA = ClassB;

TSubclassOf<UDamageType_Lava> ClassC;
// Performs a compile time check
ClassA = ClassC;
```
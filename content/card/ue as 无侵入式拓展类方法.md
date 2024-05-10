---
created: 2024-05-09T18:17
draft: true
tags: 
- card
- ue
- as
---

as 作为 cpp 与 bp 的中间层，利用引擎内部的反射信息，可以直接使用原本 cpp 暴露给 bp 的方法，无法调用 cpp 没有暴露给 bp 的方法

同时，由于技术原因，as 也无法调用 cpp 中 interface 实现的方法

比如 has matching gameplay tag，可以在 bp 中直接使用
 ![[Pasted image 20240509225649.png]]

在 cpp 层面，是一个直接在 interface 中定义的方法

```cpp
bool IGameplayTagAssetInterface::HasMatchingGameplayTag(FGameplayTag TagToCheck) const
{
	FGameplayTagContainer OwnedTags;
	GetOwnedGameplayTags(OwnedTags);

	return OwnedTags.HasTag(TagToCheck);
}
```

这也算是 bp 优于 as 的一点

如果想使一个类暴露更多方法到 bp，在不修改引擎源代码的前提下，只能实现新的子类，在其中定义一个中转方法，并修改 display name 和被覆盖的方法同名

as 提供更高级的功能，通过 [mixin library](https://angelscript.hazelight.se/cpp-bindings/mixin-libraries/)机制，在不修改引擎源代码的基础上，暴露更多方法到 as 层面（非 bp 层面）

```angelscript
UCLASS(Meta = (ScriptMixin = "AActor"))
class UMyActorMixinLibrary : public UObject
{
	GENERATED_BODY()
public:
	// used in script: Actor.TeleportToOrigin();
	UFUNCTION(ScriptCallable)
	static void TeleportToOrigin(AActor* Actor)
	{
		Actor->SetActorLocation(FVector(0, 0, 0));
	}
}
```

- ScriptMixin = 要拓展类的名称
- ufunction 使用 ScriptCallable
- 必须为 static 方法
- 第一个参数为要拓展的类
- 通常方法实现比较短，只需要一个 header 文件足够
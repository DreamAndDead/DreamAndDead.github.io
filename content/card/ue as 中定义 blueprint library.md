---
created: 2024-05-09T17:02
draft: true
tags: 
- card
- ue
- as
---

在 as 中，可以继承 UBlueprintFunctionLibrary 但是无法拓展

```angelscript
class UAttackBlueprintLibrary: UBlueprintFunctionLibrary {
    UFUNCTION(BlueprintCallable, Category = "Gameplay|Attack")
    /*static*/ void HandleAttack(const AActor From, const AActor To) {
    }
}
```

因为 as 中没有类的 static 函数功能，也没有 static 关键字

hazelight 提供了一个等价的功能 [global function](https://angelscript.hazelight.se/scripting/functions-and-events/#global-functions)

在 as 中定义的全局函数，不绑定任何类，效果等同于 UBlueprintFunctionLibrary 的功能

```angelscript
// Example global function that moves an actor somewhat
UFUNCTION()
void ExampleGlobalFunctionMoveActor(AActor Actor, FVector MoveAmount)
{
    Actor.ActorLocation += MoveAmount;
}
```


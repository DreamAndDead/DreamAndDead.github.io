---
created: 2024-05-09T13:22
draft: true
tags: 
- card
- ue
- gas
- ga
---

# by tag

```cpp
UFUNCTION(BlueprintCallable, Category = "Abilities")
bool TryActivateAbilitiesByTag(const FGameplayTagContainer& GameplayTagContainer, bool bAllowRemoteActivation = true);
```

# by class

```cpp
UFUNCTION(BlueprintCallable, Category = "Abilities")
bool TryActivateAbilityByClass(TSubclassOf<UGameplayAbility> InAbilityToActivate, bool bAllowRemoteActivation = true);
```

# by spec handle

```cpp
UFUNCTION(BlueprintCallable, Category = "Abilities")
bool TryActivateAbility(FGameplayAbilitySpecHandle AbilityToActivate, bool bAllowRemoteActivation = true);
```
# by trigger

在 ga 的 detail 面板中，可以设置 activate ga 的 trigger 数组

![[Pasted image 20240509133242.png]]

trigger tag 为触发当前 ga 所监听的 tag

trigger source 有 3 种类型
## gameplay event

通过 bp 方法 send gameplay event 到 actor

```cpp
UFUNCTION(BlueprintCallable, Category = Ability, Meta = (Tooltip = "This function can be used to trigger an ability on the actor in question with useful payload data."))
static void SendGameplayEventToActor(AActor* Actor, FGameplayTag EventTag, FGameplayEventData Payload);
```

如果 actor asc 有设置相应的 trigger tag，则 ga 被触发

ga 中需要 override `ActivateAbilityFromEvent` 来接收 event data

![[Pasted image 20240509133644.png]]

普通的 `ActivateAbility` 不行

![[Pasted image 20240509133726.png]]

> [!WARNING] 这两者之间有一个重要的区别
> event 可以使用 latent 函数，普通函数无法使用

所以在 `ActivateAbilityFromEvent` 中无法使用 ability task 功能，比如 `PlayMontageAndWait`

- [ ] wait gameplay event task 和 gameplay event 的关系
## owned tag added

一旦当前 ga owner 有相应 tag 被添加，则 try activate ga once

## owned tag present

当前 ga owner 有相应 tag 被添加，则 try activate ga
当 tag 被移除，则 try cancel ga
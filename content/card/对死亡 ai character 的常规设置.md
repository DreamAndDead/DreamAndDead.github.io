---
created: 2024-05-17T15:32
draft: true
tags: 
- card
- ue
- ai
---
 
```cpp
// 停止 ai 计算
AAIController* AIC = Cast<AAIController>(GetController());
if (AIC)
{
	AIC->GetBrainComponent()->StopLogic("Killed");
}
// 关闭自身运动
GetCharacterMovement()->DisableMovement();
// 关闭物理碰撞
GetCapsuleComponent()->SetCollisionEnabled(ECollisionEnabled::NoCollision);
// 设置 ragdoll collision profile
GetMesh()->SetCollisionProfileName("Ragdoll");
// 开启 ragdoll 模拟
GetMesh()->SetAllBodiesSimulatePhysics(true);
```

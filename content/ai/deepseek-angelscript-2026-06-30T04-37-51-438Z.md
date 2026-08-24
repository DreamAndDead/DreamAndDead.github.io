# DeepSeek Export
Conversation: AngelScript
URL: https://chat.deepseek.com/a/chat/s/05c9c523-b1be-4b24-a4c7-c38c45104198
Exported: 2026-06-30T04:37:51.438Z

## User

掩码方案如何管理生命周期，比如一起注册，一起移除

## Assistant

你这个问题问得很关键，触及了掩码机制和配置组设计的根本区别。简单来说，**访问掩码本身的设计目标，就是只负责“权限控制”，而不负责“生命周期管理”**。所以，它并没有提供类似 `BeginConfigGroup` / `RemoveConfigGroup` 这样“一起注册，一起移除”的配对方法。

你需要了解的是，随着 AngelScript 版本演进，这两个机制已经各司其职了。

### ⚖️ 各自的职责

可以从官方文档和社区讨论中清晰地看到两者的分工[-3](https://www.angelcode.com/angelscript/sdk/docs/manual/doc_adv_dynamic_config.html)[-4](https://www.gamedev.net/forums/topic/614471-angelscript-2220-is-released/4881640/)[-5](https://gamedev.net/forums/topic/614471-angelscript-2220-is-released/)：

| 机制 | 核心职责 | 提供的功能 |
| --- | --- | --- |
| **配置组 \(Config Group\)** | **生命周期管理** | `BeginConfigGroup` / `EndConfigGroup` / `RemoveConfigGroup`[-3](https://www.angelcode.com/angelscript/sdk/docs/manual/doc_adv_dynamic_config.html) |
| **访问掩码 \(Access Mask\)** | **权限控制** | `SetDefaultAccessMask` / `SetAccessMask`[-1](http://www.contagion-game.com/api/manual/doc_adv_access_mask.html)[-2](https://angelcode.com/angelscript/sdk/docs/manual/classas_i_script_module.html#ab16a29831b08294423390a8170605523) |

-
**访问掩码 \(Access Mask\)**：它通过位掩码，为**每个注册的实体**（函数、类型、方法等）打上一个“标签”，然后在编译模块时检查该模块的“标签”是否匹配[-4](https://www.gamedev.net/forums/topic/614471-angelscript-2220-is-released/4881640/)[-5](https://gamedev.net/forums/topic/614471-angelscript-2220-is-released/)。它的粒度可以精细到单个函数或类型[-1](http://www.contagion-game.com/api/manual/doc_adv_access_mask.html)。而且，从源码中可以看到，每个全局属性（`asCGlobalProperty`）和对象属性（`asCObjectProperty`）都有自己的 `accessMask` 成员，默认值都是 `0xFFFFFFFF`。
-
**配置组 \(Config Group\)**：它依然负责将一组接口**打包成一个逻辑单元**，以实现批量的添加和移除。你可以通过 `BeginConfigGroup` 将一些相关的注册代码包起来，在卸载插件或关卡时，调用 `RemoveConfigGroup` 来整体删除[-3](https://www.angelcode.com/angelscript/sdk/docs/manual/doc_adv_dynamic_config.html)[-8](https://gamedev.net/forums/topic/628377-global-properties-and-modules/?comment=4961992&do=findComment)。

### 🔗 想要“一起移除”，依然需要配置组

如果你希望在运行时动态地添加或移除一批接口，**唯一的方法仍然是使用配置组**。

一个典型的场景是管理游戏关卡：加载新关卡时，注册该关卡专属的实体为全局属性；卸载关卡时，则需要移除这些属性，并丢弃对应的脚本模块。根据社区的成功实践，正确流程如下[-8](https://gamedev.net/forums/topic/628377-global-properties-and-modules/?comment=4961992&do=findComment)[-9](https://gamedev.net/forums/topic/628377-global-properties-and-modules/)：

cpp

```cpp
// 加载场景时，创建配置组并注册属性
engine->BeginConfigGroup("Level_Assets");
for (auto& entity : sceneEntities) {
engine->RegisterGlobalProperty(/* ... */);
}
engine->EndConfigGroup();

// 编译场景脚本
asIScriptModule* mod = engine->GetModule("SceneScript");
// ... 添加脚本并编译 ...

// --- 卸载场景时 ---
// 1. 丢弃脚本模块，切断模块内对属性的引用
engine->DiscardModule("SceneScript");

// 2. 执行垃圾回收，清理可能还存活的脚本对象
engine->GarbageCollect(asGC_FULL_CYCLE);

// 3. 安全移除配置组
int r = engine->RemoveConfigGroup("Level_Assets");
if (r < 0) {
// 处理错误，可能仍有引用未被释放
}
```

> 这其中的关键点在于，`RemoveConfigGroup` 仅当配置组中没有任何接口正在被使用时才能成功。因此，必须**先丢弃相关的模块**，再**执行垃圾回收**，确保所有引用都被清理，最后才能移除配置组[-3](https://www.angelcode.com/angelscript/sdk/docs/manual/doc_adv_dynamic_config.html)[-6](https://gamedev.net:443/forums/topic/364094-issue-with-config-groups/)[-8](https://gamedev.net/forums/topic/628377-global-properties-and-modules/?comment=4961992&do=findComment)。

### 💎 总结

在实际项目中，**访问掩码**和**配置组**通常会配合使用，前者控制“谁能用”，后者管理“何时加载/卸载”。

-
**要动态加载/卸载一批接口**：使用**配置组**。
-
**要精细控制不同模块对接口的可见性**：在配置组内注册接口时，通过**访问掩码**进行标记。

所以，访问掩码方案本身并**不能**直接实现“一起注册，一起移除”的生命周期管理。你需要的是将两者结合起来：用配置组打包接口以实现批量移除，同时在配置组内通过掩码实现模块间的权限隔离。这正是官方在 2.22.0 版本引入掩码机制时所说的“更通用”[-4](https://www.gamedev.net/forums/topic/614471-angelscript-2220-is-released/4881640/)[-5](https://gamedev.net/forums/topic/614471-angelscript-2220-is-released/)的含义——它把原来配置组身兼的“生命周期”和“权限控制”两职分开了。

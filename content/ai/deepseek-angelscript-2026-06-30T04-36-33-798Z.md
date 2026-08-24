# DeepSeek Export
Conversation: AngelScript
URL: https://chat.deepseek.com/a/chat/s/05c9c523-b1be-4b24-a4c7-c38c45104198
Exported: 2026-06-30T04:36:33.798Z

## User

详细讲解一下掩码方案

## Assistant

访问掩码机制，是 AngelScript 从 2.22.0 版本开始引入，用来**替代早期配置组进行权限控制**的更现代方案[-5](https://gamedev.net/forums/topic/614471-angelscript-2220-is-released/)[-6](https://www.gamedev.net/forums/topic/614471-angelscript-2220-is-released/%22http%3A//angryprogrammingprimate.blogspot.com/%22http%3A//angryprogrammingprimate.blogspot.com/%22https%3A//angelscript.svn.sourceforge.net/svnroot/angelscript/trunk/sdk/docs/doxygen/source/%22https%3A//angelscript.svn.sourceforge.net/svnroot/angelscript/trunk/sdk/docs/doxygen/source/)。

它的核心思想非常简单：为每个C\+\+接口（函数、类型、方法等）打上一个**位掩码标签**，同时为每个脚本模块也设置一个**位掩码**。当模块编译时，会检查两者的“标签”是否有交集，有交集才能访问。

### 🏷️ 工作流程：打标签与验证

1.
**注册接口时“打标签”**：调用 `SetDefaultAccessMask` 设置“当前上下文”的掩码，之后注册的所有接口都会带上这个标签[-1](http://www.contagion-game.com/api/manual/doc_adv_access_mask.html)[-7](https://gamedev.net/forums/topic/614471-angelscript-2220-is-released/?comment=4881543&do=findComment)。
cpp

```cpp
// 假设 bit 1 (值=1) 代表“游戏实体”专用接口
engine->SetDefaultAccessMask(1);
engine->RegisterGlobalFunction("void entityOnlyFunc()", ...); // 被打上标签 1

// 假设 bit 2 (值=2) 代表“GUI系统”专用接口
engine->SetDefaultAccessMask(2);
engine->RegisterGlobalFunction("void guiOnlyFunc()", ...); // 被打上标签 2

// 要注册公共接口，掩码设置为0
engine->SetDefaultAccessMask(0);
engine->RegisterGlobalFunction("void commonFunc()", ...); // 标签为0，对所有模块可见
```
2.
**编译模块时“核验标签”**：编译前，通过 `asIScriptModule::SetAccessMask` 设置该模块的掩码。引擎在编译时会做按位与（`&`）运算，只要结果不为 0，该模块就能访问对应接口[-1](http://www.contagion-game.com/api/manual/doc_adv_access_mask.html)[-7](https://gamedev.net/forums/topic/614471-angelscript-2220-is-released/?comment=4881543&do=findComment)[-8](https://www.gamedev.net/forums/topic/614471-angelscript-2220-is-released/4881640/)。
cpp

```cpp
asIScriptModule* mod = engine->GetModule("MyEntityScript", asGM_ALWAYS_CREATE);
mod->SetAccessMask(1); // 只允许访问标签包含 bit 1 的接口
// ... 添加脚本代码并编译 ...
```

### 🆚 配置组 vs 访问掩码

AngelScript 官方的说明指出了两者的核心区别：配置组是模块级别的粗粒度控制，而访问掩码是实体级别的细粒度控制[-5](https://gamedev.net/forums/topic/614471-angelscript-2220-is-released/)[-7](https://gamedev.net/forums/topic/614471-angelscript-2220-is-released/?comment=4881543&do=findComment)。

| 特性 | 配置组 \(Config Group\) | 访问掩码 \(Access Mask\) |
| --- | --- | --- |
| **控制粒度** | **模块级别**，整个模块要么能访问组内所有接口，要么都不能 | **接口实体级别**，每个函数、类型、属性都可以单独控制 |
| **灵活性** | 较低，一个接口只能属于一个配置组 | **非常高**，一个接口可以拥有多个位掩码（通过按位或组合） |
| **管理方式** | 通过配置组名来管理 | 通过位掩码值来管理 |
| **时代** | 早期方案，功能相对简单 | **现代推荐方案**，自 2.22.0 起引入，更强大 |

### 🔍 补充细节：访问掩码与对象类型

值得一提的是，访问掩码的权限控制粒度非常精细。从源码来看，它不仅影响全局函数，连**对象类型的方法和属性**也都可以单独设置访问掩码。这意味着，你甚至可以控制一个模块能否访问某个类的某个特定方法，而不是整个类。

此外，你还可以通过 `asIObjectType::GetAccessMask` 方法，在运行时查询一个已注册的脚本类型被赋予了哪个访问掩码[-2](https://angelcode.com/angelscript/sdk/docs/manual/classas_i_object_type.html#a201bd5cc143082f844f701a5fef65bed)。

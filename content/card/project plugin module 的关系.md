---
created: 2024-05-18T10:00
draft: true
tags: 
- card
- ue
---

module 是 ue 组织代码功能的最小模块
每个 module 都有相应的 build.cs  定义其与其它  module 的依赖关系

plugin 是一个可选的 module 组，内部存在一 or 多个 module
当开启插件，所有 module 都将被启用
通过 uplugin 文件，定义内部 module 的 type 与 loadingphase

```json
	"Modules": [
		{
			"Name": "EnhancedInput",
			"Type": "Runtime",
			"LoadingPhase": "PreDefault"
		},
		{
			"Name": "InputBlueprintNodes",
			"Type": "UncookedOnly",
			"LoadingPhase": "PreDefault"
		},
		{
			"Name": "InputEditor",
			"Type": "Editor",
			"LoadingPhase": "Default"
		}
	]
```

project 是一个项目，通常是用户的游戏项目，可以包含 plugin 与 module
通过 uproject 文件，定义 module 的 type 与 loadingphase，定义 plugin 的开启与关闭


```json
	"Modules": [
		{
			"Name": "TestProject",
			"Type": "Runtime",
			"LoadingPhase": "Default",
			"AdditionalDependencies": [
				"GameplayAbilities",
				"Engine",
				"AIModule"
			]
		}
	],
	"Plugins": [
		{
			"Name": "ModelingToolsEditorMode",
			"Enabled": true,
			"TargetAllowList": [
				"Editor"
			]
		},
		{
			"Name": "GameplayAbilities",
			"Enabled": true
		}
	]
```


project 包含 target.cs，通过 ubt 编译成最终程序

```cs
public class TestProjectTarget : TargetRules
{
	public TestProjectTarget(TargetInfo Target) : base(Target)
	{
		Type = TargetType.Game;
		DefaultBuildSettings = BuildSettingsVersion.V4;
		IncludeOrderVersion = EngineIncludeOrderVersion.Unreal5_3;
		ExtraModuleNames.Add("TestProject");
	}
}
```
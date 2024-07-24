---
created: 2024-05-28T14:03
draft: true
tags: 
- card
- ue
- config
---

在引擎启动的时候加载，初始化 CDO 的值
# category

ue 将所有配置项归为如下几类

general
- Engine
- Game
- Input
- DeviceProfiles
- GameUserSettings
- Scalability
- RuntimeOptions
- InstallBundle
- Hardware
- GameplayTags

editor only
- Editor
- EditorPerProjectUserSettings
- EditorSettings
- EditorKeyBindings
- EditorLayout

desktop only
- Compat
- Lightmass

不同的类别，对应不同的 ini 文件

# platform

ue 支持多平台打包，不同平台下，可单独配置不同的 ini

- Windows
- Unix
- Linux
- LinuxArm64
- Mac
- Android
- TVOS
- IOS

# ini 文件层级

ini 文件可以在多个目录位置，这些文件由前到后，形成 overlay 覆盖关系

1. base 层
2. `Engine/Config/Base.ini`
3. `Engine/Config/Base<CATEGORY>.ini`
4. `Engine/Config/<PLATFORM>/Base<PLATFORM><CATEGORY>.ini`
5. `Engine/Platforms/<PLATFORM>/Config/Base<PLATFORM><CATEGORY>.ini`
6. default 层
7. `<PROJECT_DIRECTORY>/Config/Default<CATEGORY>.ini`
8. `Engine/Config/<PLATFORM>/<PLATFORM><CATEGORY>.ini`
9. `Engine/Platforms/<PLATFORM>/Config/<PLATFORM><CATEGORY>.ini`
10. `<PROJECT_DIRECTORY>/Config/<PLATFORM>/<PLATFORM><CATEGORY>.ini`
11. `<PROJECT_DIRECTORY>/Platforms/<PLATFORM>/Config/<PLATFORM><CATEGORY>.ini`
12. user 层
13. `<LOCAL_APP_DATA>/Unreal Engine/Engine/Config/User<CATEGORY>.ini`
14. `<MY_DOCUMENTS>/Unreal Engine/Engine/Config/User<CATEGORY>.ini`
15. `<PROJECT_DIRECTORY>/Config/User<CATEGORY>.ini`

# 配合代码使用

## 从 ini 加载到 uproperty

```cpp
// 1. config=<Category> in UClass
UCLASS(config=Game)
class AMyConfigActor: public AActor
{
	GENERATED_BODY()

// 2. Config in UProperty
	UPROPERTY(Config)
	int32 MyConfigVariable;
}
```

在 DefaultGame.ini 中配置默认值

```ini
[/Script/MyGameModule.MyConfigActor]
MyConfigVariable=3
```

在引擎启动时，相应的 CDO 中就被初始为相应值

## 保存 uproperty 到 ini

依然使用上面的类 AMyConfigActor

```cpp
// 修改 CDO 中的默认值
AMyConfigActor * Settings = GetMutableDefault<AMyConfigActor>();
Settings->MyConfigVariable = 42;
// 保存到 ini 文件
// 不能使用 GGameIni，因为其是 temp 文件
// 参考 UObject::SaveConfig code
FString PathToConfigFile;
Settings->SaveConfig(CPF_Config, *PathToConfigFile);
```

## 加载自定义 section variable

假如在 Game Category 的配置中，有如下内容

```ini
[MyCategoryName]
MyVariable=2
```

在cpp中，可以在配置文件中将其搜索关加载

```cpp
int MyConfigVariable;
GConfig->GetInt(TEXT("MyCategoryName"), TEXT("MyVariable"), MyConfigVariable, GGameIni);
```

### GConfig

GConfig 本质是全局变量，内部有多不同类别的配置文件中读取各种变量类型的 Get 方法

```cpp
FConfigCacheIni* GConfig;
```

### GGameIni

最后一个参数，本质是 FString

猜测 ue 在启动时，已经将所有目录下的配置文件，根据 overlay 规则合并成一个文件，路径保存在全局变量中

每个类别都对应一个全局变量 `G<Category>Ini`

```cpp
extern CORE_API FString GCompatIni;
extern CORE_API FString GLightmassIni;
extern CORE_API FString GScalabilityIni;
extern CORE_API FString GHardwareIni;
extern CORE_API FString GInputIni;
extern CORE_API FString GGameIni;
extern CORE_API FString GGameUserSettingsIni;
extern CORE_API FString GRuntimeOptionsIni;
extern CORE_API FString GInstallBundleIni;
extern CORE_API FString GDeviceProfilesIni;
extern CORE_API FString GGameplayTagsIni;
```



# 参考

[config files in ue](https://dev.epicgames.com/documentation/en-us/unreal-engine/configuration-files-in-unreal-engine?application_version=5.3)

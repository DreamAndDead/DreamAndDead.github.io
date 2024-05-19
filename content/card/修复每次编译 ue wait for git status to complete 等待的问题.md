---
created: 2024-05-16T22:07
draft: true
tags: 
- card
- build
- ue
- ubt
---

默认情况下，如果目录下有 git 目录，在每次 ubt 编译时多出一步

`wait for git status to complete`

而这一步通常很久，于是又出现

`terminate git process`

导致编译至少等待 1 分钟才开始

参考[社区里的回答](https://forums.unrealengine.com/t/waiting-for-git-status-command-to-complete-making-for-long-compile-times/412358/8)，对 ubt 的[配置文件](https://dev.epicgames.com/documentation/en-us/unreal-engine/build-configuration-for-unreal-engine)进行修改，可以去除这个步骤


```xml
<?xml version="1.0" encoding="utf-8" ?>
<Configuration xmlns="https://www.unrealengine.com/BuildConfiguration">
	<SourceFileWorkingSet> 
		<Provider>None</Provider> 
		<RepositoryPath></RepositoryPath> 
		<GitPath></GitPath> 
	</SourceFileWorkingSet>
</Configuration>
```

> [!NOTE] 修改哪个配置文件
> 经测试，修改 project 中的 xml 是无用的
> 建议直接修改引擎内部的 xml


---
type: card
created: 2024-04-22T16:40
tags: 
- ue
- lua
- vscode
---

在按照 [unlua 官方文档配置调试](https://github.com/Tencent/UnLua/blob/master/Docs/CN/Debugging.md) 的过程设置后，在 vscode 中使用有一些问题
- 每次启动自动开始调试，即使没有断点
- 设定的断点不起作用，无法停止在断点上

需要在 launch.json 修改以下两点
- stopOnEntry 修改为 false
- luaFileExtension 修改为 .lua

```json
{
	"type": "lua",
	"request": "launch",
	"tag": "normal",
	"name": "LuaPanda",
	"description": "通用模式,通常调试项目请选择此模式 | launchVer:3.2.0",
	"cwd": "${workspaceFolder}",
	"luaFileExtension": ".lua",
	"connectionPort": 8818,
	"stopOnEntry": false,
	"useCHook": true,
	"autoPathMode": true
},
```



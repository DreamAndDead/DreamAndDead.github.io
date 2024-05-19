---
type: card
created: 2024-03-24T13:02
tags:
- ue
- build
- compile
---

# 设置编译环境

官网在 5.3 release note 写到

> **IDE Version the Build farm compiles against**
> - Visual Studio: Visual Studio 2022 17.4 14.34.31933 toolchain and Windows 10 SDK (10.0.18362.0)

## toolchiain 版本

2022 是大版本号，机器上可能存在多个，如 2019 和 2022
每个项目可以单独设置大版本号，在 project settings - platform - windows - compiler version 进行选择

17.4 是小版本号，一直由 vs installer 进行更新，现在已经到了 17.9.4
小版本号用 vs installer 管理，如果不想升级可以回退

## sdk 版本

在 vs installer 中，cpp 编译环境的可选项，有多种版本可选择

![[Pasted image 20240324130833.png]]
# 编译

1. 在源码目录，打开 powershell
2. 运行 Setup.bat 安装编译的二进制依赖
	2. 源码 16g，依赖 20g
3. 运行 GenerateProjectFiles.bat
	2. dotnet 编译 ubt
	1. 生成 sln 工程文件
	2. 至此已经 100g
4. 打开 UE5.sln，选择合适的 preset
	1. UE5
	2. development
	3. editor
	4. win64
5. 编译
	1. 6202 actions
	2. 2小时编译完成
	3. 最终占用 220g 空间
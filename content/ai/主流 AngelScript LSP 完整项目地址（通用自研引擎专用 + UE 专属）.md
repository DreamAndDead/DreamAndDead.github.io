---
title: 主流 AngelScript LSP 完整项目地址（通用自研引擎专用 + UE 专属）
---

# 主流 AngelScript LSP 完整项目地址（通用自研引擎专用 + UE 专属）

## 一、通用全能版：**angel-lsp（sashi0034）【自研 C++ 引擎首选】**

目前**唯一通用、不绑定任何引擎**的标准 AngelScript LSP，完全适配 Windows 自研引擎、Neovim / VSCode，支持完整 LSP 语义、跳转、补全、类型检查、内置 DAP 调试，也是社区更新最活跃的版本。

### GitHub 源码地址

[https://github.com/sashi0034/angel-lsp](https://link.wtturl.cn/?target=https%3A%2F%2Fgithub.com%2Fsashi0034%2Fangel-lsp&scene=im&aid=497858&lang=zh)

### 核心信息

1. 开发语言：TypeScript，开箱即用，可脱离 VSCode 独立作为标准 LSP 进程，完美对接 Neovim `nvim-lspconfig`；
2. 核心能力：语法诊断、函数 / 类跳转、引用查找、自动补全、命名空间、`@`句柄识别、`#include`跨文件解析、代码格式化、自带配套 DAP 调试；
3. 适配版本：完整支持 AngelScript 2.38+ 最新版；
4. Neovim 接入方式：直接配置 lspconfig 调用该 LSP 可执行文件。

## 二、轻量简易版：AngelscriptLanguageServer（Deukhoofd）

极简 C++ 实现的轻量 LSP，主打基础语法校验、简单高亮，功能精简，适合极简使用场景。

### GitHub 地址

[https://github.com/Deukhoofd/AngelscriptLanguageServer](https://link.wtturl.cn/?target=https%3A%2F%2Fgithub.com%2FDeukhoofd%2FAngelscriptLanguageServer&scene=im&aid=497858&lang=zh)

## 三、Unreal 引擎专属版：UnrealEngine-Angelscript LSP（Hazelight 官方，双人成行同款）

仅适配 UE 引擎内置 AngelScript，**无法用于通用自研 C++ 引擎**，LSP 需要和 UE 编辑器进程通信获取绑定符号。

### 主仓库

[https://github.com/Hazelight/UnrealEngine-Angelscript](https://link.wtturl.cn/?target=https%3A%2F%2Fgithub.com%2FHazelight%2FUnrealEngine-Angelscript&scene=im&aid=497858&lang=zh)

### VSCode 配套 LSP 客户端仓库

[https://github.com/Hazelight/vscode-unreal-angelscript](https://link.wtturl.cn/?target=https%3A%2F%2Fgithub.com%2FHazelight%2Fvscode-unreal-angelscript&scene=im&aid=497858&lang=zh)

## 四、官方原生状态说明

AngelScript 原作者**并未推出官方标准 LSP**，以上全部为社区开源实现，**`angel-lsp` 是自研引擎的最优选择**。

# Neovim 接入 angel-lsp 最简配置（Lazy.nvim）

```lua
{
  "neovim/nvim-lspconfig",
  config = function()
    local lspconfig = require("lspconfig")
    -- 配置通用 AngelScript LSP
    lspconfig.angel_lsp.setup({
      cmd = { "node", "~/.local/share/nvim/lsp/angel-lsp/server/out/server.js" }, -- 指向编译后的server.js路径
      filetypes = { "angelscript" },
      root_dir = lspconfig.util.root_pattern("as.predefined", ".git"),
    })
  end
}
```

1. 拉取 `angel-lsp` 源码后执行 `npm install && npm run build` 编译；
2. 将编译产物 `server/out/server.js` 路径写入配置即可使用。

## 配套补充（语法插件）

官方语法高亮插件（必搭配 LSP）：
[https://github.com/angelcode/vim-angelscript](https://link.wtturl.cn/?target=https%3A%2F%2Fgithub.com%2Fangelcode%2Fvim-angelscript&scene=im&aid=497858&lang=zh)
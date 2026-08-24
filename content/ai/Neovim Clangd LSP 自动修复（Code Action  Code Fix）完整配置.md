---
title: Neovim Clangd LSP 自动修复（Code Action / Code Fix）完整配置
---

# Neovim Clangd LSP 自动修复（Code Action / Code Fix）完整配置

Clangd 的修复能力：头文件缺失、未使用变量、类型转换、`#include` 自动插入、命名空间补全、格式警告、语法小错误、`using namespace`、冗余代码清理等。
 分 **弹窗选择修复、一键自动修复、保存自动修复、快捷键绑定、trouble 联动**，适配你的 Windows MSVC 环境。

## 一、基础原生快捷键（nvim-lspconfig 默认）

LSP 挂载完成后，光标放在错误波浪线上，执行：

```vim
:lua vim.lsp.buf.code_action()
```

弹窗列出可用修复方案，回车应用。

### 绑定常用快捷键（写入 on_attach）

```lua
local on_attach = function(client, bufnr)
  local map = function(mode, lhs, rhs, desc)
    vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
  end

  -- 打开代码修复/代码操作
  map("n", "<leader>ca", vim.lsp.buf.code_action, "LSP Code Action 修复")
  -- 光标处【一键自动执行首选修复】（clangd 推荐 fix）
  map("n", "<leader>cf", function()
    vim.lsp.buf.code_action({ apply = true })
  end, "LSP 自动应用首选修复")
end
```

## 二、clangd 开启全部修复能力（关键配置）

在 `nvim-lspconfig` clangd 的 `cmd` 参数开启完整诊断与修复，放到你的 lspconfig 配置：

```lua
require("lspconfig").clangd.setup({
  on_attach = on_attach,
  cmd = {
    "clangd",
    "--compile-commands-dir=build/x64-debug", -- 指向CMake Preset编译数据库
    "--background-index",
    "--header-insertion=iwyu",        -- 智能自动添加#include（最强）
    "--clang-tidy",                   -- 启用clang-tidy，大量静态检查+修复
    "--clang-tidy-checks=*",          -- 开启全部tidy规则，按需裁剪
    "--all-scopes-completion",
    "--function-arg-placeholders",
    "--fallback-style=Microsoft",     -- Windows MSVC风格
  },
  root_dir = require("lspconfig.util").root_pattern("CMakePresets.json", "CMakeLists.txt", ".git"),
})
```

### 核心参数作用

1. `--clang-tidy`：开启静态分析，多出上百种可修复警告（性能、代码规范、C++17 规范、类型安全）
2. `--header-insertion=iwyu`：自动补全缺失头文件，`std::string` 自动插入 `#include <string>`
3. 必须保证 `compile_commands.json` 正常生成，否则 clangd 找不到系统头文件，修复完全失效。

## 三、保存文件自动修复（最实用）

方案 1：**lsp 保存时自动执行可自动修复的 tidy 问题**

```lua
-- 写入全局，所有LSP生效
vim.api.nvim_create_autocmd("BufWritePre", {
  pattern = { "*.c", "*.cpp", "*.h", "*.hpp" },
  callback = function()
    vim.lsp.buf.code_action({
      filter = function(action)
        -- 只选择可自动修复的clang-tidy action
        return action.kind == "quickfix"
      end,
      apply = true,
    })
  end,
})
```

方案 2：搭配 `null-ls` 过时，现在纯 clangd 原生完全够用，不需要额外插件。

## 四、批量文件全局修复（clangd 自带工具 clang-tidy）

单个文件修复用 LSP，**整个项目批量修复代码规范**，在 VS PowerShell 终端执行（带编译数据库）：

```powershell
clang-tidy -p build/x64-debug src/**/*.cpp --fix
```

`--fix` 自动批量应用所有修复，适合项目规范化。

## 五、常用可修复内容一览（clangd + clang-tidy）

1. **头文件相关** 缺失头文件自动 `#include`、多余头文件删除、前向声明优化
2. **变量语法错误** 未使用变量加 `[[maybe_unused]]`、多余分号、类型隐式转换、const 修饰建议
3. **C++ 现代规范** 原始指针替换智能指针、`nullptr` 替代 `NULL`、范围 for、auto 推导、移动语义优化
4. **编译小错误** 命名空间补全、函数参数缺失、函数声明定义不匹配、宏问题
5. **格式类** 配合 `clang-format` 自动缩进对齐

## 六、一键格式化代码（配套）

clangd 内置格式化，绑定快捷键：

```lua
map("n", "<leader>fm", function()
  vim.lsp.buf.format({ async = true })
end, "LSP clang-format 格式化")
```

## 七、与 Trouble 联动

所有可修复的错误 / 警告都会进入 Trouble diagnostics 窗口。
 把光标定位到条目，按 `<leader>ca` 直接打开修复，边看诊断边修复，流程闭环。

## 八、Windows 常见问题排查

### 1. 没有可用的 code action，修复灰色不可选

1. `compile_commands.json` 必须正常生成，执行一次 CMake Generate；
2. clangd 命令必须带 `--clang-tidy`，否则只有少量基础修复；
3. 重启 LSP：`:LspRestart`。

### 2. 无法自动添加系统头文件（windows.h 等）

必须在 **VS DevShell 环境启动 Neovim**，clangd 才能读取 Windows SDK 路径。

### 3. 不想开启全部 clang-tidy 规则，精简规则

把 `--clang-tidy-checks=*` 替换成自定义规则集，示例：

```plaintext
--clang-tidy-checks=-*,modernize-,readability-,performance-
```

`-*` 先关闭全部，再按需开启分类。

### 4. 修复不生效，clangd 找不到标准库

确认 clangd 版本较新，mason 一键更新：

```vim
:MasonUpdate clangd
```

## 九、极简工作流（你的日常 C++ 开发）

1. 代码出现黄色波浪警告 / 红色报错；
2. 光标停留，`<leader>ca` 查看可选修复，`<leader>cf` 一键应用首选修复；
3. 保存文件自动执行 quickfix 小问题修复；
4. 大批量代码规范优化，终端执行 clang-tidy --fix 全局批量修复。
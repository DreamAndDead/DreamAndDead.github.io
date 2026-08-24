---
title: Neovim 完整配置 AngelScript（.as 脚本）编辑方案
---

# Neovim 完整配置 AngelScript（.as 脚本）编辑方案

AngelScript 文件后缀：`.as`，filetype 默认 `angelscript`。整套配置包含：**语法高亮、Treesitter 解析、Angel-LSP 智能提示补全跳转、格式化、FT 专属快捷键、缩进**，适配 Lazy.nvim，Windows 可用。

## 一、整体环境说明

1. 官方主流 LSP：**angel-lsp（sashi0034/angelscript-language-server）**，VSCode 同款服务端，完整支持 AS 语法检查、跳转、补全、类型推断。
2. Treesitter 第三方解析器：`tree-sitter-angelscript`，提供高性能语法解析、折叠、文本对象。
3. 基础老式 Vim 语法脚本兜底，低版本兼容。

# 二、分步完整配置（Lazy.nvim）

## 步骤 1：安装基础语法高亮插件

### 插件 1：老式 Vim 语法（兜底必备）

仓库：`mrtazz/angelscript-vim`，提供原生正则高亮、文件识别。

### 插件 2：tree-sitter-angelscript（Treesitter 语法解析）

第三方 Parser，不在官方 TS 仓库，需要手动配置。

写入 `lua/plugins/angelscript.lua`

```lua
return {
  -- 1. 基础vim语法文件，识别*.as，基础高亮
  "mrtazz/angelscript-vim",
  -- 2. Treesitter 自定义Angelscript解析器
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      -- 自定义parser配置
      opts.parser_dir = vim.fn.stdpath("data") .. "/treesitter/parsers"
      opts.ensure_installed = opts.ensure_installed or {}
      table.insert(opts.ensure_installed, "angelscript")
      -- 手动注册tree-sitter-angelscript
      vim.treesitter.language.register("angelscript", "angelscript")
    end,
  },
  -- 3. LSP核心：AngelScript Language Server
  "neovim/nvim-lspconfig",
}
```

## 步骤 2：手动编译安装 tree-sitter-angelscript

1. 全局安装 `tree-sitter-cli`

```bash
# Windows(Chocolatey)/Linux(macOS)
cargo install tree-sitter-cli
```

2. 克隆 Parser 仓库，编译

```bash
git clone https://github.com/elliesec/tree-sitter-angelscript.git
cd tree-sitter-angelscript
tree-sitter generate
tree-sitter build --output angelscript.so
```

3. 将编译好的 `angelscript.so` 放入目录：

```plaintext
%LOCALAPPDATA%\nvim-data\treesitter\parsers\angelscript.so
```

重启 nvim，执行 `:TSInstall angelscript` 验证。

## 步骤 3：安装 angel-lsp 语言服务器（核心智能提示）

### 方式 A：手动下载二进制（Windows 首选）

Release 地址：[https://github.com/sashi0034/angelscript-language-server/releases](https://link.wtturl.cn/?target=https%3A%2F%2Fgithub.com%2Fsashi0034%2Fangelscript-language-server%2Freleases&scene=im&aid=497858&lang=zh)
 下载对应系统二进制，把 `angel-lsp.exe` 放入系统环境变量 `PATH`，保证终端输入 `angel-lsp` 可正常运行。

### 方式 B：从 VSCode 插件提取

下载 VSIX 插件解压，取出 `server/bin/angel-lsp.exe`，路径加入环境变量。

## 步骤 4：LSP 客户端配置（lspconfig）

在 lsp 配置文件添加 `angelscript` 服务启动代码：

```lua
local lspconfig = require("lspconfig")
local on_attach = function(client, bufnr)
  local bufopts = { noremap = true, silent = true, buffer = bufnr }
  -- AS语言通用LSP快捷键（ft专属）
  vim.keymap.set("n", "gd", vim.lsp.buf.definition, bufopts)
  vim.keymap.set("n", "K", vim.lsp.buf.hover, bufopts)
  vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, bufopts)
  vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, bufopts)
end

-- 启动angel-lsp
lspconfig.angelscript.setup({
  cmd = { "angel-lsp" }, -- 可写绝对路径，如 {"D:/tools/angel-lsp.exe"}
  filetypes = { "angelscript" },
  root_dir = lspconfig.util.root_pattern(".git", "*.as"),
  on_attach = on_attach,
  settings = {
    -- 引擎预制API配置（根据你的游戏引擎配置头文件目录）
    includePaths = {
      "./",
      "./include",
    },
    enableDiagnostics = true,
  }
})
```

## 步骤 5：FT 专属快捷键（Angelscript 专用按键）

打开 `.as` 文件才生效，写入 keymaps：

```lua
local map = vim.keymap.set
local ft_opt = { noremap = true, silent = true, buffer = 0 }

vim.api.nvim_create_autocmd("FileType", {
  pattern = "angelscript",
  callback = function()
    -- F5 运行脚本
    map("n", "<F5>", "<cmd>!angelscript %<CR>", ft_opt)
    -- F6 格式化（后续efm配置）
    map("n", "<F6>", function() vim.lsp.buf.format() end, ft_opt)
    -- F9 切换头文件/脚本（类比C/C++）
    map("n", "<F9>", "<cmd>vsplit %:r.h<CR>", ft_opt)
  end
})
```

## 步骤 6：代码格式化配置

### 方案 1：使用 `astyle` 格式化（AS 语法贴近 C++）

安装 astyle，搭配 efm-langserver 调用格式化。

### 方案 2：angel-lsp 内置格式化

开启 LSP 格式化，保存自动格式化：

```lua
vim.api.nvim_create_autocmd("BufWritePre", {
  pattern = "*.as",
  callback = function()
    vim.lsp.buf.format({ async = false })
  end
})
```

# 三、常用配套优化

## 1. 缩进配置（AS 标准 4 空格缩进）

```lua
vim.api.nvim_create_autocmd("FileType", {
  pattern = "angelscript",
  callback = function()
    vim.opt_local.expandtab = true
    vim.opt_local.shiftwidth = 4
    vim.opt_local.tabstop = 4
    vim.opt_local.softtabstop = 4
  end
})
```

## 2. 代码折叠（Treesitter 折叠）

开启 TS 折叠，`.as` 文件自动生效：

```lua
-- 在treesitter config内开启
highlight = { enable = true },
indent = { enable = true },
fold = { enable = true }
```

## 3. nvim-cmp 补全源

LSP 补全会自动接入 `cmp-nvim-lsp`，无需额外配置，打开 AS 文件自动加载 LSP 补全。

# 四、常见问题排查

1. **文件后缀.as 不识别为 angelscript** 执行 `:set filetype?`，如果显示 `cpp`/`c`，添加后缀绑定：

```lua
vim.filetype.add({
  extension = {
    as = "angelscript",
  }
})
```

2. **angel-lsp 无法启动** 检查 `angel-lsp.exe` 路径，cmd 测试能否直接运行，路径带空格用绝对路径配置 cmd。
3. **Treesitter parser 加载失败** 确认编译的系统架构匹配（Windows x64），`.so` 文件名与文件夹完全小写 `angelscript.so`。
4. **引擎内置 API 不识别** 在 lsp 的 `includePaths` 填入引擎 SDK 的头文件目录，angel-lsp 会解析预制类与全局函数。

# 五、极简备选低配方案（不想装 LSP）

只安装 `mrtazz/angelscript-vim` 基础语法插件，仅获得语法高亮、缩进、基础匹配，适合临时编辑，缺点**无补全、跳转、语法检查**。

# 六、完整工作流程

1. 打开 `xxx.as` 文件，自动识别 `filetype=angelscript`；
2. 自动挂载 angel-lsp LSP，获取实时报错、代码补全、跳转定义；
3. Treesitter 提供精准高亮、代码折叠、文本对象操作（vi {、va (等）；
4. FT 专属快捷键生效，一键运行、格式化、切换头文件。
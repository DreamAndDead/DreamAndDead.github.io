---
title: 一、BSP (Build Server Protocol) 配置（C++/CMake 必备，配合 clangd）
---

下面给你 **BSP 构建协议、ACP AI 协议、Nvim-RPC 简易示例、EFM 格式化协议** 全套 Lazy 可直接复制配置，适配你 C++ / Angelscript 整套开发环境，按顺序安装即可。

# 一、BSP (Build Server Protocol) 配置（C++/CMake 必备，配合 clangd）

作用：动态同步编译命令，完美解决头文件、宏、第三方库路径识别问题，弥补静态 `compile_commands.json` 的不足。
 插件：`bsp.nvim`

```lua
-- lua/plugins/bsp.lua
return {
  "nanotee/bsp.nvim",
  dependencies = { "nvim-lua/plenary.nvim" },
  config = function()
    local bsp = require("bsp")
    bsp.setup({
      -- 自动寻找项目根目录(.git/CMakeLists.txt)
      root_patterns = { ".git", "CMakeLists.txt", "meson.build" },
      -- 自动把BSP编译参数注入 clangd
      clangd_integration = true,
      -- 自动监听构建改动
      watch_build_changes = true,
    })
  end
}
```

配套 clangd LSP 开启 BSP 支持（写入你的 lspconfig clangd 配置）

```lua
lspconfig.clangd.setup({
  cmd = {
    "clangd",
    "--enable-config",
    "--compile-commands-dir=build",
    "--header-insertion=never",
    "--index-background",
  },
  on_attach = on_attach,
})
```

常用命令

```vim
:BspStart       启动构建服务
:BspTargets     查看编译目标
:BspCompile     执行编译
```

# 二、EFM 通用格式化协议（不依赖 LSP，统一管理所有格式化工具）

- [x] 研究EFMLS是否有使用的价值   暂时不要增加麻烦了 ✅ 2026-06-23

可以统一调用 `clang-format`、`astyle(Angelscript)`、`stylua` 等格式化程序。

```lua
-- lua/plugins/efm.lua
return {
  "creativenull/efmls-configs-nvim",
  dependencies = { "neovim/nvim-lspconfig" },
  config = function()
    local efmls_config = require("efmls-configs")
    local lspconfig = require("lspconfig")

    -- 加载格式化工具
    local clang_format = efmls_config.formatters.clang_format
    local astyle = efmls_config.formatters.astyle
    local stylua = efmls_config.formatters.stylua

    lspconfig.efm.setup({
      filetypes = { "cpp", "c", "lua", "angelscript" },
      init_options = {
        documentFormatting = true,
        documentRangeFormatting = true,
      },
      settings = {
        rootMarkers = { ".git/" },
        languages = {
          cpp = { clang_format },
          c = { clang_format },
          angelscript = { astyle }, -- Angelscript 格式化
          lua = { stylua },
        },
      },
    })
  end,
}
```

保存自动格式化（可选）

```lua
vim.api.nvim_create_autocmd("BufWritePre", {
  callback = function()
    vim.lsp.buf.format({ async = false })
  end,
})
```

# 三、ACP AI 协议 cline.nvim（现代 AI 编程标准，对接本地 / 云端大模型）

基于 JSON-RPC ACP 协议，对标 LSP，支持读取项目文件、执行终端命令、代码编辑、调试辅助，适合写 C++ DAP 适配器、Angelscript 脚本。

```lua
-- lua/plugins/cline.lua
return {
  "cline/cline.nvim",
  keys = {
    { "<leader>ai", "<cmd>ClineToggle<CR>", desc = "打开AI面板" },
  },
  config = function()
    require("cline").setup({
      -- 可配置 Ollama 本地模型 / OpenAI / Claude
      api_provider = "ollama",
      ollama_model = "qwen-coder",
      ollama_host = "http://127.0.0.1:11434",
      auto_approve_tools = false, -- 手动确认文件读写、命令执行，安全
    })
  end
}
```

功能：

1. 让 AI 帮你写 cppdap 适配器代码、解析 DAP 协议；
2. 直接读取当前 Angelscript 工程上下文补全逻辑；
3. 可以调用终端编译、运行、排查报错日志。

# 四、Nvim-RPC 简单演示（Neovim 原生底层 RPC 协议）

## 1）Lua 内部简易 RPC 服务示例

Neovim 自带 RPC，不需要额外插件。
 启动 TCP RPC 服务：

```vim
:call serverstart('127.0.0.1:6666')
```

## 2）外部 Python 客户端调用 Nvim RPC（示例）

```python
import pynvim
# 连接nvim rpc服务
nvim = pynvim.attach('tcp', address='127.0.0.1', port=6666)
# 新建文件
nvim.command('edit test.as')
# 写入内容
nvim.current.buffer.append(["// Angelscript test"])
# 执行快捷键、执行LSP命令都可以远程调用
```

用途：

- C++ 程序通过 RPC 远程控制 Neovim；
- 自研 GUI 编辑器对接 Neovim 内核；
- 游戏引擎联动编辑器，双向通信。

# 五、全套协议分工总结（贴合你的开发）

1. **编码静态分析** LSP (angel-lsp/clangd) + Treesitter 本地 AST 解析
2. **运行时调试** DAP（cppdap 内嵌引擎 TCP 服务）
3. **C++ 编译工程** BSP 构建协议，动态获取编译参数
4. **格式化美化** EFM 协议统一调度 astyle /clang-format
5. **AI 辅助编码** ACP 协议 cline.nvim 对接大模型
6. **跨进程远程通信** Nvim 原生 JSON-RPC

# 补充配套常用命令速查

```vim
:LspInfo           查看当前文件LSP状态
:BspInfo           查看BSP构建服务状态
:DapUI             打开调试面板
:Cline             打开AI对话窗口
:EfmLog            查看格式化日志
```

如果你接下来要落地 Angelscript + C++ 整套环境，我可以把上面所有插件整合进一份完整的 `lazy/plugins/` 模块化配置合集，直接导入即可整套启用，需要吗？
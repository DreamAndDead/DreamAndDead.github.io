---
title: Neovim 按文件类型 (ft) 专属快捷键完整写法
---

# Neovim 按文件类型 (ft) 专属快捷键完整写法

核心原理：监听 `FileType` 自动事件，打开对应类型文件时，注册**缓冲区局部映射（`buffer = 0`）**，只在当前类型文件生效，切换文件自动失效。
 下面给 **Lua 标准写法、Lazy 插件内写法、多文件类型批量、完整实战案例**。

## 核心关键点

1. 必须加 `buffer = 0`：映射绑定当前缓冲区，不会全局生效。
2. 标准配置 `{ noremap = true, silent = true }`。
3. 文件类型名用 `:set filetype?` 查看，比如 `lua、cpp、python、javascript、markdown`。

## 方式 1：全局 keymaps 内原生写法（通用首选）

写入你的 `lua/keymaps.lua`，统一管理所有文件类型快捷键。

```lua
local map = vim.keymap.set
local opts = { noremap = true, silent = true, buffer = 0 } -- buffer=0 局部生效

-- 注册自动命令：打开对应文件类型时执行
vim.api.nvim_create_autocmd("FileType", {
  pattern = "cpp,c,h,hpp", -- 匹配C/C++系列文件类型
  callback = function()
    -- C++专属快捷键
    map("n", "<F9>", "<cmd>ClangdSwitchSourceHeader<CR>", opts) -- .h/.cpp切换
    map("n", "<F10>", "<cmd>!g++ % -o %:r && ./%:r<CR>", opts)  -- 编译运行
  end,
})

-- Lua 文件专属快捷键
vim.api.nvim_create_autocmd("FileType", {
  pattern = "lua",
  callback = function()
    map("n", "<F5>", "<cmd>LuaReload<CR>", opts)
    map("n", "<leader>rr", function()
      dofile(vim.api.nvim_buf_get_name(0))
      vim.notify("Lua脚本执行完成")
    end, opts)
  end,
})

-- Markdown 专属
vim.api.nvim_create_autocmd("FileType", {
  pattern = "markdown",
  callback = function()
    map("n", "<F8>", "<cmd>MarkdownPreview<CR>", opts)
  end,
})
```

### 一次性匹配多个文件类型

`pattern = { "python", "py", "lua", "javascript" }` 数组写法。

## 方式 2：Lazy.nvim 插件配置内绑定（插件配套 ft 快捷键）

很多语言插件（lsp、格式化工具），在插件的 `config` 回调里注册专属按键，打开该文件才加载插件 + 按键，完美配合懒加载。
 示例：clangd C/C++ LSP 配套快捷键

```lua
return {
  "neovim/nvim-lspconfig",
  dependencies = { "williamboman/mason-lspconfig.nvim" },
  config = function()
    local lspconfig = require("lspconfig")
    -- clangd 配置
    lspconfig.clangd.setup({
      on_attach = function(client, bufnr)
        local bufopts = { noremap = true, silent = true, buffer = bufnr }
        -- 【LSP专属缓冲区快捷键，仅C/C++文件生效】
        map("n", "gd", vim.lsp.buf.definition, bufopts)       -- 跳转定义
        map("n", "K", vim.lsp.buf.hover, bufopts)             -- 悬浮文档
        map("n", "<leader>rn", vim.lsp.buf.rename, bufopts)   -- 重命名
      end
    })
  end
}
```

`on_attach` 的 `bufnr` 就是当前缓冲区编号，`buffer = bufnr` 是 LSP 标准写法。

## 方式 3：封装通用工具函数，简化重复代码

写一个工具函数，后续添加 ft 快捷键一行搞定，精简代码：

```lua
local function ft_map(filetypes, callback)
  vim.api.nvim_create_autocmd("FileType", {
    pattern = filetypes,
    callback = function()
      local buf_opt = { noremap = true, silent = true, buffer = 0 }
      callback(buf_opt)
    end
  })
end

-- 使用示例
ft_map("cpp,c,h", function(opt)
  map("n", "<F9>", "<cmd>ClangdSwitchSourceHeader<CR>", opt)
end)

ft_map("python", function(opt)
  map("n", "<F10>", "<cmd>!python %<CR>", opt)
end)
```

## 方式 4：Vimscript 老式写法（了解即可，新项目不用）

```vim
autocmd FileType cpp,c,h nnoremap <buffer> <F9> :ClangdSwitchSourceHeader<CR>
```

## 常用补充知识点

### 1. 如何查看当前文件的 filetype

打开文件执行命令：

```vim
:set filetype?
```

可以拿到准确的类型名，避免 pattern 写错不生效。

### 2. 局部映射的特点

1. 只绑定当前打开的缓冲区，**新开同类型文件需要重新触发事件生成快捷键**（原生自动执行）。
2. 关闭文件，映射自动销毁，不会污染全局按键。
3. 全局同名快捷键优先级：**局部 buffer 映射 > 全局映射**，ft 按键会覆盖全局按键。

### 3. 全局永久按键 vs ft 局部按键区分

- 全局按键：不带 `buffer` 参数，所有文件永久生效。
- FT 专属按键：必须带 `buffer = 0`，依托 `FileType` 事件创建。

### 4. 常见文件类型简写对照表

| 文⁠件 | filetype 值 |
| --- | --- |
| .lua | lua |
| .cpp/.h | cpp / c |
| .py | python |
| .js/ts | javascript / typescript |
| .md | markdown |
| .json | json |
| .sh | sh |

## 常见踩坑

1. **不加 `buffer=0`**：变成全局快捷键，所有文件都能用，失去 ft 专属意义。
2. `pattern` 文件类型拼写错误，大小写敏感，匹配不到。
3. 事件写在插件`init`里，插件懒加载未触发时，autocmd 未注册。
4. 重复打开文件会重复注册映射，无伤大雅；如需防重复，可以给 autocmd 设置分组：

```lua
local augroup = vim.api.nvim_create_augroup("CppKeymap", { clear = true })
vim.api.nvim_create_autocmd("FileType", {
  group = augroup, -- 同组自动清空旧事件
  pattern = "cpp,c",
  callback = function() end
})
```

## 最简工作流程

1. 用 `:set filetype?` 确认文件类型；
2. 使用上面封装的 `ft_map` 函数；
3. 在回调内写映射，固定带上 `buffer` 参数；
4. 测试：打开对应文件测试快捷键，切换其他文件验证按键失效。
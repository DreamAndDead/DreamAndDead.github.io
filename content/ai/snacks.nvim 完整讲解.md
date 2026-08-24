---
title: snacks.nvim 完整讲解
---

# snacks.nvim 完整讲解

## 一、基础介绍

仓库：`folke/snacks.nvim`（和 trouble.nvim 同一个作者 folke）
 定位：**单一插件整合 30 + 独立轻量化功能模块**，每个模块可单独开关、按需加载，解决传统配置插件碎片化、启动慢、配置分散冲突的痛点。
 核心优势：

1. 全部内置统一 UI 渲染、浮动窗口、动画、布局底层，模块之间无缝互通；
2. 纯 Lua 无多余依赖，速度远优于分散多插件；
3. 完全兼容你现有 `trouble.nvim`、LSP、DAP、CMake 工作流；
4. 内置模糊检索 `picker`，可替代 Telescope 日常绝大多数场景，原生支持一键发送结果到 Trouble。

## 二、核心常用模块（对应替代的老式插件）

### 1. picker（模糊检索，对标 telescope.nvim）

最强模块，内置文件查找、全局 grep、LSP 引用、缓冲区、Git 提交、命令搜索。

- 原生支持快捷键 `<C-t>` 将检索结果送入 Trouble；
- 异步搜索、treesitter 高亮检索内容、多种浮动 / 分屏布局；
- 轻量化，启动速度远超 telescope。

### 2. notifier（通知弹窗，替代 nvim-notify）

替换 Neovim 简陋原生通知，圆角浮动弹窗、消息历史、分层日志、自定义超时时间。

### 3. dashboard 启动页（替代 alpha.nvim）

自定义开机界面：快捷打开最近文件、CMake 编译命令、AI、LSP、项目快速入口、显示启动耗时。

### 4. explorer 文件树（替代 nvim-tree /neo-tree）

浮动 / 侧边树形文件浏览器，带 Git 标记、LSP 诊断、折叠、跟随当前文件，一键切换悬浮窗口。

### 5. terminal 浮动终端（替代 toggleterm/fterm）

一键弹出悬浮终端，底部 / 侧边 / 居中三种布局，自动进入插入模式，内置 lazygit 快速打开 Git 面板。

### 6. statuscolumn 侧边状态列（替代 indent-blankline + gitsigns 侧边标记）

行号栏整合：Git 增减标记、折叠图标、LSP 错误警告标记，一行搞定无需两个插件。

### 7. scratch 临时草稿缓冲区

永久缓存草稿笔记，不用新建临时文件，写代码片段、调试临时代码非常方便。

### 8. bigfile 大文件保护

打开超大日志 / 二进制文件自动关闭 LSP、treesitter、语法高亮，防止卡顿崩溃。

### 9. zen 专注模式

隐藏状态栏、标签栏、侧边标记，代码居中淡化背景，沉浸式写代码。

### 10. indent 缩进辅助线

彩色分层缩进线，区分代码块层级，适配 C++ 大括号嵌套。

### 11. input /select 美化输入弹窗

替换原生 `vim.ui.input`、`vim.ui.select`，LSP 重命名、输入参数弹窗更好看。

### 12. git 工具集

单行 blame、预览 diff、快速打开 lazygit 浮动窗口，和 gitsigns 互补。

## 三、和你现有工具联动关键点

1. **picker 检索结果 ↔ trouble.nvim** Snacks.picker 内同样 `<C-t>` 一键送入 Trouble 窗口，API 完全对齐 Telescope，不用改习惯。
2. 与 oil.nvim、neo-tree 共存 snacks.explorer 可按需开启，不用就关闭，不会冲突。
3. LSP、clangd、cmake-tools、DAP 完全兼容，无任何抢占逻辑。
4. 搭配 avante.nvim Ollama AI：dashboard 可配置快捷入口一键唤起 AI 对话。

## 四、最简可直接复制 Lazy 配置

```lua
return {
  "folke/snacks.nvim",
  priority = 1000,
  lazy = false,
  opts = {
    -- 按需开启模块，不用的直接设 enabled=false
    bigfile = { enabled = true },
    dashboard = { enabled = true },
    explorer = { enabled = true },
    indent = { enabled = true },
    input = { enabled = true },
    notifier = { enabled = true, timeout = 3000 },
    picker = {
      enabled = true,
      -- 绑定发送到 Trouble
      mappings = {
        ["<C-t>"] = "trouble_open",
        ["<C-S-t>"] = "trouble_add",
      },
    },
    scratch = { enabled = true },
    statuscolumn = { enabled = true },
    terminal = { enabled = true },
    zen = { enabled = true },
  },
  keys = {
    -- 文件检索
    { "<leader>ff", function() Snacks.picker.files() end, desc = "查找文件" },
    { "<leader>fg", function() Snacks.picker.grep() end, desc = "全局文本检索" },
    -- 浮动文件树
    { "<leader>E", function() Snacks.explorer() end, desc = "浮动文件树" },
    -- 浮动终端
    { "<leader>tt", function() Snacks.terminal() end, desc = "打开浮动终端" },
    -- Git lazygit
    { "<leader>gg", function() Snacks.lazygit() end, desc = "Lazygit 浮动窗口" },
    -- 草稿本
    { "<leader>s", function() Snacks.scratch() end, desc = "临时草稿缓冲区" },
  },
}
```

## 五、选型建议（针对你的 C++/Angelscript 开发）

1. 想要轻量化、少插件、启动快：**强烈推荐 snacks**，砍掉 telescope、alpha、nvim-notify、indent-blankline、toggleterm 五六个独立插件，统一由 snacks 实现。
2. 如果你已经熟练使用 telescope，可只开启 `picker=false` 保留 telescope，其余模块照常使用。
3. 追求极简、不想装一堆分散小插件的配置党首选，现代 Neovim 标配工具集。

## 六、常见区分

- telescope：只做检索单一功能，依赖 plenary，启动慢；
- snacks.picker：内置检索，配套全套 UI 工具集，一体化；
- mini 系列：模块化但分散多个仓库，维护分散；
- snacks：单仓库统一维护，作者 folke 长期稳定更新。
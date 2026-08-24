---
title: mini.nvim 完整讲解（mini 系列）
---

# mini.nvim 完整讲解（mini 系列）

## 一、基础定位

仓库：`echasnovski/mini.nvim`
 一句话：**一套独立、轻量化、纯粹编辑向的模块化工具集**，全部内置在单一仓库，40 + 独立模块，每个模块可单独启用 / 禁用，无强耦合，极简、性能极高、遵循原生 Vim 逻辑。
 和 snacks.nvim 最大区别：

- **mini**：侧重**文本编辑、基础工具**，UI 轻量化克制，偏向硬核 Vim 用户；
- **snacks**：侧重**一体化 UI、浮动窗口、IDE 全套面板**，视觉功能更丰富。

## 二、核心设计理念

1. **完全独立模块**：只用哪个开哪个，关闭无性能开销；
2. **原生 Vim 风格**：快捷键逻辑贴近原生，不搞花哨动画、复杂弹窗；
3. **零多余依赖**，纯 Lua，兼容 Neovim 0.10+；
4. **统一配置规范**，所有 mini 模块配置写法一致，上手成本低；
5. 替代大量老牌独立插件（vim-surround、nvim-autopairs、gitsigns、telescope、alpha 等）。

## 三、高频常用模块（按用途分类）

### 1. 文本编辑核心（写代码刚需，替代多款独立插件）

#### mini.surround

替代 `tpope/vim-surround`
 增 / 删 / 改引号、括号、标签 `ys`/`ds`/`cs`，性能更强，Lua 原生实现。

#### mini.pairs

替代 `windwp/nvim-autopairs`
 自动补全 `(){}[]""''`，轻量无卡顿，支持 LSP 函数括号联动。

#### mini.comment

替代 `numToStr/Comment.nvim`
 一键行 / 块注释，自动适配 C++/Lua/Angelscript 等多语言注释符。

#### mini.ai

替代 `nvim-treesitter-textobjects` 基础文本对象
 原生增强 `a`/`i` 文本对象：括号、引号、函数块、自定义匹配，支持 dot 重复、计数。

#### mini.operators

批量文本操作：交换、排序、求值、批量替换选区内容。

### 2. 文件 / 检索工作流（替代 telescope /oil/neo-tree）

#### mini.pick

轻量化模糊检索，替代 `telescope.nvim`
 文件查找、全局 grep、缓冲区、LSP 符号、Git 记录，非阻塞、启动极快；可对接 trouble 发送检索结果。

#### mini.files

轻量化列视图文件管理器，替代 oil /nvim-tree
 分栏浏览、剪切 / 重命名 / 删除，纯缓冲区操作，无常驻侧边栏。

#### mini.sessions

会话管理，保存 / 加载项目窗口布局，替代老式 mksession 脚本。

### 3. Git 变更可视化（替代 gitsigns.nvim）

#### mini.diff

侧边显示代码增减、单行 diff 预览、hunk 暂存 / 撤销、跳转变更行，轻量化无冗余渲染。

### 4. UI 辅助（极简，无花哨动画）

#### mini.notify

替代 `nvim-notify`，极简通知弹窗，LSP 进度、错误提示统一渲染。

#### mini.icons

统一图标提供器，给 pick/files/diff 提供文件 / 诊断图标，兼容 devicons。

#### mini.starter

极简启动页，替代 alpha.nvim，干净无多余装饰。

#### mini.hipatterns

高亮自定义模式：TODO、FIXME、数字、注释标记。

#### mini.indentmini

分层缩进辅助线，替代 indent-blankline。

### 5. 代码补全、片段

#### mini.completion

内置轻量补全（可替代 blink.cmp/nvim-cmp），内置 LSP、片段、路径来源。

#### mini.snippets

LSP 标准片段引擎，加载自定义代码模板。

## 四、mini.nvim vs snacks.nvim 核心对比

| 维⁠度 | mini.nvim | snacks.nvim |
| --- | --- | --- |
| 作⁠者 | echasnovski | folke（trouble 作⁠者） |
| 核⁠心⁠侧⁠重 | 文⁠本⁠编⁠辑、轻⁠量⁠化⁠工⁠具，原⁠生 Vim 风⁠格 | 一⁠体⁠化 IDE 浮⁠动 UI、面⁠板、动⁠画、多⁠功⁠能⁠弹⁠窗 |
| 视⁠觉⁠风⁠格 | 极⁠简⁠克⁠制，几⁠乎⁠无⁠动⁠画、简⁠约⁠布⁠局 | 圆⁠角⁠浮⁠动、动⁠画、多⁠面⁠板⁠布⁠局，VSCode 风 |
| 检⁠索⁠组⁠件 | mini.pick（轻⁠量、逻⁠辑⁠朴⁠素） | snacks.picker（功⁠能⁠丰⁠富、预⁠览⁠强、联⁠动 trouble 深⁠度⁠优⁠化） |
| 文⁠件⁠树 | mini.files（列⁠视⁠图，极⁠简） | snacks.explorer（树⁠形⁠侧⁠边 / 悬⁠浮，带⁠分⁠组） |
| 终⁠端 | 无⁠内⁠置⁠终⁠端⁠模⁠块 | 内⁠置⁠浮⁠动⁠终⁠端、lazygit 一⁠键⁠唤⁠起 |
| 适⁠合⁠人⁠群 | 硬⁠核 Vim 原⁠生⁠玩⁠家、追⁠求⁠极⁠简⁠低⁠占⁠用 | 想⁠要⁠完⁠整 IDE 一⁠体⁠化⁠界⁠面、频⁠繁⁠用⁠浮⁠动⁠窗⁠口 |
| 冲⁠突⁠概⁠率 | 极⁠低，贴⁠近⁠原⁠生 | 略⁠高，大⁠量 UI 模⁠块⁠容⁠易⁠和⁠状⁠态⁠栏 / 文⁠件⁠树⁠冲⁠突 |

## 五、最简 Lazy 可运行配置（按需开启模块）

```lua
return {
  "echasnovski/mini.nvim",
  config = function()
    local mini = require("mini")
    -- 按需启用，不用直接注释
    mini.setup({
      ai = {},
      comment = {},
      diff = {},
      files = {},
      icons = {},
      notify = {},
      pairs = {},
      pick = {},
      starter = {},
      surround = {},
    })

    -- 检索快捷键 mini.pick
    vim.keymap.set("n", "<leader>ff", "<cmd>Pick files<cr>", {desc="查找文件"})
    vim.keymap.set("n", "<leader>fg", "<cmd>Pick grep_live<cr>", {desc="全局检索"})
    -- 文件管理器
    vim.keymap.set("n", "-", "<cmd>MiniFiles<cr>", {desc="打开文件管理器"})
  end
}
```

## 六、选型建议（结合你的 C++/CMake/Angelscript 开发）

1. 选 **mini.nvim** 如果你：
   - 喜欢原生 Vim 简洁手感，讨厌过多浮动弹窗、动画；
   - 追求极致启动速度、低内存占用；
   - 只需要编辑、检索、Git 基础功能，不需要一站式 IDE 面板；
   - 不想装一堆分散小插件，统一一套轻量化工具。
2. 选 **snacks.nvim** 如果你：
   - 习惯 VSCode 式侧边 / 悬浮面板、需要浮动终端、lazygit、zen 专注模式；
   - 经常用 trouble，需要检索一键发送到 trouble 深度联动；
   - 想要一体化完整 UI 生态，启动页、状态栏标记、终端、检索一套搞定。
3. 二者可以共存：
   只开 mini 的编辑模块（surround/ai/comment），snacks 负责 picker、terminal、dashboard，互不冲突。
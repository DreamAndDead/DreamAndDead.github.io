---
title: Neovim 段落 (paragraph) 原生跳转 + 自定义按键配置
---

# Neovim 段落 (paragraph) 原生跳转 + 自定义按键配置

## 一、原生默认段落按键（无需任何配置，开箱即用）

Vim/Neovim 原生定义：**空行作为段落分隔符**，连续非空行视为一个段落

| 按⁠键 | 功⁠能 |
| --- | --- |
| `}` | **向⁠下⁠跳⁠转⁠到⁠下⁠一⁠个⁠段⁠落⁠开⁠头** |
| `{` | **向⁠上⁠跳⁠转⁠到⁠上⁠一⁠个⁠段⁠落⁠开⁠头** |

### 附加用法

1. 数字前缀：`3}` 向下跳 3 个段落，`2{` 向上跳 2 段
2. 配合操作命令（删除段落、复制段落）
   - `d{` 删除当前到上段开头
   - `d}` 删除当前到下段开头
   - `y}` 复制整段

## 二、自定义常用键位（把段落跳转映射到更顺手的按键）

推荐两套方案，直接加到你的 `init.lua`，适配纯键盘流：

### 方案 1：大写 `K / J` 对应段落上下（最常用）

```lua
local opts = { noremap = true, silent = true }
vim.keymap.set("n", "J", "}", opts) -- 大写J = 下一段
vim.keymap.set("n", "K", "{", opts) -- 大写K = 上一段
```

⚠️ 注意：原生 `K` 是查看函数文档，如果你日常要用 LSP 悬浮文档，不要用这套。

### 方案 2：Alt + j / Alt + k 段落跳转（不占用原有按键，推荐）

```lua
local opts = { noremap = true, silent = true }
vim.keymap.set("n", "<A-j>", "}", opts)
vim.keymap.set("n", "<A-k>", "{", opts)
```

### 方案 3：方向键 Ctrl + 上下（鼠标党友好）

```lua
vim.keymap.set("n", "<C-Down>", "}", opts)
vim.keymap.set("n", "<C-Up>", "{", opts)
```

## 三、可视模式（选中段落）同步映射

选区模式同样可以用快捷键选中整段：

```lua
local opts = { noremap = true, silent = true }
vim.keymap.set("v", "<A-j>", "}", opts)
vim.keymap.set("v", "<A-k>", "{", opts)
```

## 四、拓展：代码块「区块」跳转（区分段落，C/C++ 开发必备）

`{ }` 是**文本段落（空行分隔）**，而 `[[ ]]` 是**代码大括号块**，写 C++ 搭配使用：

| 按⁠键 | 作⁠用 |
| --- | --- |
| `[[` | 跳⁠到⁠上⁠一⁠个⁠函⁠数 /`{` 代⁠码⁠块⁠开⁠头 |
| `]]` | 跳⁠到⁠下⁠一⁠个⁠函⁠数 /`{` 代⁠码⁠块⁠开⁠头 |

## 五、修改段落分隔规则（进阶）

默认以**空行**判定段落，可修改 `paragraphs` 选项自定义段落分隔字符（极少改）

```lua
-- 默认配置，不用改
vim.o.paragraphs = "IPLPPPQPP TPHPLIPpLpIt np"
```

## 六、常见问题

1. `{ }` 跳转不动 当前已经是文档第一段 / 最后一段，会发出蜂鸣提示边界。
2. 想要**跳段同时自动滚动居中** 映射时拼接 `zz` 实现跳转后光标居中：

```lua
vim.keymap.set("n", "<A-j>", "}zz", opts)
vim.keymap.set("n", "<A-k>", "{zz", opts)
```

3. 和 LSP 悬浮 K 冲突 放弃大写 K 映射，固定使用 `Alt+k / Alt+j` 段落跳转即可。
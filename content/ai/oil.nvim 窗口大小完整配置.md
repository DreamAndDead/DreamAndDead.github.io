---
title: oil.nvim 窗口大小完整配置
---

# oil.nvim 窗口大小完整配置

分 **普通分割窗口（`:-` 打开）**、**悬浮浮动窗口（`:- --float`）**、**预览窗口** 三部分配置，直接复制完整 Lazy 配置。

## 完整配置文件

```lua
return {
  "stevearc/oil.nvim",
  opts = {
    -- ========== 1、普通水平分割窗口（默认 :Oil 打开）==========
    win_options = {
      winwidth = 35,  -- 固定最小宽度（字符数）
    },

    -- ========== 2、浮动窗口大小配置（:Oil --float 专用）==========
    float = {
      border = "rounded", -- 边框样式：rounded/single/double/solid/none
      winblend = 5,       -- 窗口透明度 0~100

      -- 核心尺寸设置
      max_width = 0.85,   -- 最大宽度：屏幕占比 85%
      min_width = 50,     -- 最小宽度：固定50字符
      max_height = 0.8,   -- 最大高度：屏幕占比 80%
      min_height = 15,    -- 最小高度：固定15行

      -- 精准固定宽高（二选一，写 width/height 会覆盖上面的最大最小值）
      -- width = 80,    -- 固定宽度80字符
      -- height = 25,   -- 固定高度25行

      -- 自定义窗口位置与尺寸（进阶精准控制）
      override = function(conf)
        -- conf 是原生 nvim_open_win 参数，可以手动改写坐标宽高
        -- conf.width = 70
        -- conf.height = 22
        -- conf.row = 2
        -- conf.col = 10
        return conf
      end,
    },

    -- ========== 3、侧边预览窗口大小 ==========
    preview_win = {
      max_width = 0.6,
      min_width = 40,
      max_height = 0.8,
      min_height = 10,
      preview_split = "right", -- 预览窗口在右侧
    },

    view_options = {
      show_hidden = true,
    },
  },
  keys = {
    { "-", "<cmd>Oil<CR>", desc = "打开目录（分割窗口）" },
    { "<leader>o", "<cmd>Oil --float<CR>", desc = "悬浮窗口打开目录" },
  },
}
```

## 参数详细说明

### 1、数值规则

- **数字整数** = 固定字符 / 行数，例 `width = 70` = 固定 70 列宽度
- **小数 0~1** = 屏幕百分比，例 `max_width = 0.8` = 最大占屏幕宽度 80%

### 2、普通分割窗口（默认打开）

默认是**当前窗口下方水平分割**，无法直接固定宽高，两个方案：

1. 设置 `winwidth = 35`，限制窗口最小宽度
2. 打开后手动快捷键调整尺寸 ```plaintext
   <C-w>+   加高高度
   <C-w>-   缩减高度
   ```

### 3、浮动窗口常用尺寸示例

#### 示例 A：居中适中窗口（日常推荐）

```lua
float = {
  max_width = 0.8,
  max_height = 0.7,
}
```

#### 示例 B：固定大小小弹窗

```lua
float = {
  width = 65,
  height = 20,
}
```

#### 示例 C：全屏超大窗口

```lua
float = {
  max_width = 0.95,
  max_height = 0.95,
}
```

## 常用命令

1. 常规下方分割打开

```vim
:Oil
```

2. 悬浮窗口打开（使用上面 float 尺寸配置）

```vim
:Oil --float
```

3. 回到原文件：直接按 `q` 关闭 oil 窗口

## 常见问题

1. 浮动窗口总是很小 检查 `max_width/max_height` 百分比数值，不要设置过小，百分比基于 Neovim 整个窗口尺寸。
2. 想要悬浮窗口靠左 / 靠右 修改 `override` 函数的 `col` 横坐标即可自定义位置。
3. 预览窗口过大过小 修改 `preview_win` 内的宽高参数。
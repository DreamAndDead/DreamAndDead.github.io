---
title: Neo-tree 完整浮动窗口 (Float) 配置
---

# Neo-tree 完整浮动窗口 (Float) 配置

两种用法：**临时命令打开悬浮窗口**、**默认全局永久设为浮动模式**，附带尺寸、边框、失去焦点自动关闭、快捷键全套 Lazy 配置。

## 完整配置文件（直接复制）

```lua
return {
  "nvim-neo-tree/neo-tree.nvim",
  branch = "v3.x",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-tree/nvim-web-devicons",
    "MunifTanjim/nui.nvim",
  },
  opts = {
    -- ===================== 浮动窗口核心配置 =====================
    popup_border_style = "rounded", -- 边框: rounded/single/double/solid/none
    popup = {
      -- 尺寸：百分比 0~1 或者固定数字
      size = {
        width = "35%",  -- 宽度占屏幕35%
        height = "80%", -- 高度占屏幕80%
      },
      position = "right", -- 位置：left / right / center
      win_options = {
        winblend = 5, -- 窗口透明度 0~100
      },
    },

    -- 普通侧边窗口默认配置（不影响float命令）
    window = {
      position = "left",
      width = 32,
    },

    filesystem = {
      follow_current_file = { enabled = true }, -- 跟随当前打开文件
      hijack_netrw = true,
      use_libuv_file_watcher = true,
    },
  },
  keys = {
    -- 常规左侧侧边树
    { "<leader>e", "<cmd>Neotree toggle<cr>", desc = "侧边文件树" },
    -- 【浮动窗口专用快捷键】一键打开悬浮neo-tree
    { "<leader>E", "<cmd>Neotree float toggle<cr>", desc = "悬浮浮动文件树" },
    -- 居中浮动窗口
    { "<leader>ec", "<cmd>Neotree float toggle position=center<cr>", desc = "居中悬浮文件树" },
  },
}
```

## 一、浮动窗口常用命令

1. 右侧浮动打开

```vim
:Neotree float
```

2. 居中浮动打开

```vim
:Neotree float position=center
```

3. 切换开关浮动窗口

```vim
:Neotree float toggle
```

4. 关闭：直接按 `q`

## 二、进阶常用优化设置

### 1. 失去焦点自动关闭浮动窗口（最实用）

在 `opts` 顶层添加事件配置：

```lua
opts = {
  -- 上面原有配置不动，追加事件
  event_handlers = {
    {
      event = "neo_tree_buffer_enter",
      handler = function(arg)
        local winid = vim.api.nvim_get_current_win()
        local bufid = vim.api.nvim_get_current_buf()
        -- 焦点离开时关闭浮动窗口
        vim.api.nvim_create_autocmd("WinLeave", {
          buffer = bufid,
          once = true,
          callback = function()
            if vim.api.nvim_win_is_valid(winid) then
              vim.api.nvim_win_close(winid, true)
            end
          end,
        })
      end,
    },
  },
}
```

效果：鼠标点到编辑区，浮动文件树自动关闭。

### 2. 自定义固定宽高（不使用百分比）

修改 `popup.size` 为固定数值：

```lua
popup = {
  size = {
    width = 42,
    height = 30,
  },
  position = "right",
}
```

### 3. 全局默认永久使用浮动窗口

不想用侧边栏，让 `:Neotree toggle` 默认就是浮动，修改 `window.position`：

```lua
window = {
  position = "float", -- 全局默认浮动模式
},
```

## 三、边框样式可选值

- `rounded` 圆角（最美观）
- `single` 单线边框
- `double` 双线边框
- `solid` 粗边框
- `none` 无边框

## 四、常见问题

1. 浮动窗口挡住代码 把 `position` 设为 `right` 靠右，或者缩小宽度 `width = "30%"`。
2. 打开文件后浮动窗口不自动关闭 可以绑定快捷键，打开文件自动执行关闭命令：

```lua
vim.api.nvim_create_autocmd("BufEnter", {
  callback = function()
    vim.cmd("Neotree float close")
  end
})
```

3. 透明度太高看不清文字 调低 `winblend`，改为 `winblend = 0` 完全不透明。
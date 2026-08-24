---
title: Neovim 文件外部修改后自动刷新缓冲区
---

# Neovim 文件外部修改后自动刷新缓冲区

## 一、最简全局配置（写在 init.lua 即可，无插件）

```lua
-- 检测文件外部变更，自动重载
vim.o.autoread = true

-- 自动触发刷新的时机：切窗口、聚焦回nvim、执行命令时
vim.api.nvim_create_autocmd({
  "BufEnter",
  "FocusGained",
  "TermClose",
  "TermLeave"
}, {
  callback = function()
    if vim.o.buftype ~= "nofile" then
      vim.cmd("checktime")
    end
  end,
})

-- 弹出提示：文件已外部修改，自动加载完成后提示
vim.api.nvim_create_autocmd("FileChangedShellPost", {
  callback = function()
    vim.notify("文件已外部更新，缓冲区已刷新", vim.log.levels.INFO)
  end,
})
```

### 参数说明

1. `autoread` 核心开关：开启后 Neovim 发现磁盘文件比缓冲区新时，允许读取磁盘覆盖 buffer。
2. `checktime` 手动检查所有文件磁盘状态，对比修改时间，自动重载变更文件。
3. 自动触发场景
   - `FocusGained`：切回 Neovim 窗口立刻刷新（最常用）
   - `BufEnter`：切换缓冲区时检查更新
   - 终端关闭 / 退出终端时检查

## 二、如果你想要「实时监听文件改动，不用切窗口也自动刷」

上面配置需要切窗口才刷新；需要实时监听用 `watch` 方案，二选一：

### 方案 1：内置 libuv 文件监听（nvim 0.10+ 原生，零插件）

```lua
local function watch_buf(bufnr)
  local path = vim.api.nvim_buf_get_name(bufnr)
  if path == "" or vim.o.buftype ~= "" then return end

  local watcher = vim.uv.new_fs_event()
  watcher:start(path, {}, function(err)
    if err then return end
    vim.schedule(function()
      vim.cmd({ cmd = "checktime", args = { bufnr } })
    end)
  end)

  -- 关闭buffer销毁监听器，避免内存泄漏
  vim.api.nvim_create_autocmd("BufDelete", {
    buffer = bufnr,
    once = true,
    callback = function()
      watcher:stop()
    end,
  })
end

-- 打开文件时自动注册监听
vim.api.nvim_create_autocmd("BufReadPost", {
  callback = function(ev)
    watch_buf(ev.buf)
  end,
})
```

效果：外部一保存文件，当前 nvim 缓冲区瞬间同步，不用切窗口。

### 方案 2：插件 fswatch.nvim（跨平台稳定）

```lua
return {
  "rktjmp/fwatch.nvim",
  config = function()
    local watch = require("fwatch")
    local function reload(buf)
      vim.cmd("checktime " .. buf)
      vim.notify("文件已自动刷新")
    end
    -- 打开buffer自动监听
    vim.api.nvim_create_autocmd("BufReadPost", {
      callback = function(e)
        watch.watch(vim.api.nvim_buf_get_name(e.buf), function()
          reload(e.buf)
        end)
      end
    })
  end
}
```

## 三、冲突场景处理

1. **缓冲区有未保存修改** autoread 不会覆盖你的本地改动，会弹窗提示文件冲突，不会丢失编辑内容。
2. **终端输出、临时缓存窗口** 配置里加了判断 `buftype ~= nofile`，不会刷新悬浮窗口 / 终端。
3. **Windows WSL / 外部编辑器同步** 上面两套原生方案都支持，无需额外配置。

## 四、手动命令

随时手动刷新当前缓冲区：

```vim
:checktime
```
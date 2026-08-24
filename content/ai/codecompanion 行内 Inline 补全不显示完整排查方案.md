---
title: codecompanion 行内 Inline 补全不显示完整排查方案
---

# codecompanion 行内 Inline 补全不显示完整排查方案

按顺序一步步排查，99% 的问题都能定位，附带**修复后的完整可用配置**。

## 前置必做 3 步验证（先排除环境问题）

### 1. Ollama 服务与模型必须正常可用

1. 浏览器打开 `http://127.0.0.1:11434` 能正常访问 Ollama 后台
2. CMD 执行验证模型存在：

```bash
ollama list
```

必须能看到 `qwen2.5-coder:7b/14b`，**必须是 coder 专属 FIM 填空模型**，通用大模型**不支持行内补全 FIM**，必然不显示。
 3. 测试接口连通性，CMD 执行：

```bash
curl http://127.0.0.1:11434/api/generate -d '{"model":"qwen2.5-coder:7b","prompt":"int main(){"}'
```

能正常返回代码内容，代表 Ollama 接口没问题。

### 2. 执行健康检查

Neovim 内执行命令，查看依赖报错：

```vim
:checkhealth codecompanion
```

必须满足：

- Neovim 版本 ≥ 0.9.5（建议 0.10+）
- `curl` 命令环境可用（Windows 必须把 curl 加入系统 PATH）
- Treesitter `markdown、markdown_inline` 解析器已安装 缺失依赖会直接导致 Inline 功能失效。

### 3. 区分功能

聊天窗口`CodeCompanionChat`能正常对话，仅**行内灰色幽灵补全无显示**，问题锁定在 `Inline/FIM配置`；
 聊天都报错，是 Ollama 网络 / 模型配置错误。

## 核心原因 + 对应修复方案

### 原因 1：Inline 开关、策略配置错误（最高发）

旧配置常见错误：`strategies.inline` 适配器未指定、fim 未开启、全局 inline 开关关闭。
 替换为**修复后的完整配置**，直接覆盖你的 `codecompanion.lua`：

```lua
return {
  "olimorris/codecompanion.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-treesitter",
  },
  opts = {
    -- 开启调试日志，报错可以看日志排查
    opts = {
      log_level = "DEBUG",
      timeout = 15000, -- 超时15秒，本地模型慢适当拉长
    },
    adapters = {
      ollama = function()
        return require("codecompanion.adapters").extend("ollama", {
          env = {
            url = "http://127.0.0.1:11434",
            model = "qwen2.5-coder:7b", -- 和ollama pull的模型名称完全一致
          },
          -- FIM填空【必须开启】，行内补全核心
          fim = {
            enabled = true,
            prefix = "<fim_prefix>",
            suffix = "<fim_suffix>",
            middle = "<fim_middle>",
            stop_words = { "\n\n", "}", ")", ";" },
          },
          schema = {
            temperature = 0.2,
            num_ctx = 4096,
            num_predict = 128, -- 单次补全行数，不要太大
          },
        })
      end,
    },
    -- 策略绑定：inline必须指定ollama
    strategies = {
      chat = { adapter = "ollama" },
      inline = {
        adapter = "ollama",
        enabled = true, -- 行内补全总开关
      },
    },
    -- 行内显示与按键
    inline = {
      enabled = true,
      debounce_delay = 300, -- 打字防抖延迟，单位毫秒，太低会卡顿
      keymaps = {
        accept = "<Tab>",
        accept_word = "<C-Right>",
        reject = "<C-e>",
      },
    },
  },
  keys = {
    { "<leader>ai", "<cmd>CodeCompanionChat Toggle<cr>", desc = "AI聊天面板", mode = {"n","v"} },
  },
}
```

修改配置后**重启 Neovim**生效。

### 原因 2：Neovim 内置 Inline 虚拟文本全局关闭

Neovim 原生行内提示被关闭，插件的幽灵文本无法渲染，在`init.lua`添加：

```lua
-- 开启内置inline虚拟提示（必须）
vim.opt.inccommand = "split"
vim.fn.sign_define("InlineSuggestion", { link = "Comment" })
```

### 原因 3：文件类型不匹配、上下文不足

1. 新建空白文件，只写前缀代码测试（如`.cpp`写`int main(`、`.as`写`void Func(`），**空白空行不会触发补全**，必须有上下文代码。
2. 右下角文件类型必须是`cpp/lua/angelscript`，不能是`plaintext`纯文本。
3. Markdown/TXT 等非代码文件，FIM 补全本身不会触发。

### 原因 4：显卡显存不足，模型加载超时

1. 7B 模型建议**6G 以上显存**，14B 建议 10G + 显存，显存不足会模型加载卡死，请求超时无响应。
2. 排查方案：任务管理器查看`ollama-runner.exe`是否占用 GPU 显存；
3. 低配显卡更换轻量模型：`ollama pull qwen2.5-coder:1.5b`，配置同步修改 model 名称。

### 原因 5：插件冲突（最常见 nvim-cmp、其他补全插件拦截）

1. 临时测试：注释禁用`cmp`、`copilot.lua`、`supermaven`等其他补全插件，重启 nvim 测试 Inline 是否出现。
2. nvim-cmp 会抢占 Tab 按键，和 inline 的`<Tab>`接受快捷键冲突，可临时改 inline 快捷键：

```lua
keymaps = {
  accept = "<C-Tab>", -- 避开原生Tab
  reject = "<C-e>",
},
```

## 手动强制触发 Inline 补全（测试链路通不通）

不用等待自动打字触发，手动执行命令强制请求 AI 行内补全：

```vim
:CodeCompanionInline
```

- 执行后立刻出现灰色提示：**自动触发的防抖、上下文问题**，调低`debounce_delay = 200`即可。
- 执行直接报错：看日志路径（`:checkhealth codecompanion`会打印日志文件地址），打开日志查看：
  - 连接超时：Ollama 后台未启动 / 11434 端口防火墙拦截
  - model 不存在：配置内模型名称和`ollama list`不一致（大小写、tag 后缀必须完全相同）
  - FIM 参数报错：模型不支持 FIM，必须更换`*-coder`系列专用代码模型。

## 补充最优参数调优

1. `debounce_delay`：网络 / 显卡弱设置`400~500`，性能好设置`200~300`；
2. `temperature=0.1~0.3`，数值越高 AI 越放飞，代码补全必须低值；
3. `num_predict=128`，限制单次生成长度，避免模型长文本阻塞响应。

## 兜底备用方案

如果始终无法开启自动 Inline 行内补全，可以使用**手动触发模式**：
 绑定快捷键，随时手动唤起 AI 补全当前行：

```lua
keys = {
  { "<leader>ii", "<cmd>CodeCompanionInline<cr>", desc = "手动AI行内补全", mode = "i" },
}
```
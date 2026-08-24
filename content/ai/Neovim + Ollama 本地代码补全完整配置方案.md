---
title: Neovim + Ollama 本地代码补全完整配置方案
---

# Neovim + Ollama 本地代码补全完整配置方案

两套主流方案，按需选择：

1. **inline 行内实时自动补全（对标 Copilot）**：`codecompanion.nvim + ollama FIM`，写代码自动弹出灰色 AI 建议，Tab 一键接受，**主力推荐写 C++/Angelscript**。
2. **nvim-cmp 下拉菜单 AI 补全**：把 Ollama 结果集成进 LSP 补全弹窗。
3. **ollama.nvim**：对话问答、代码解释、重构，适合选中代码提问。

## 前置准备（必须先完成）

### 1. 安装 Ollama 客户端（Windows）

官网下载：[https://ollama.com/](https://link.wtturl.cn/?target=https%3A%2F%2Follama.com%2F&scene=im&aid=497858&lang=zh) 安装，安装后自动后台常驻服务，默认地址 `http://127.0.0.1:11434`。

### 2. 拉取代码专用模型（必选 Qwen2.5-Coder）

打开 CMD 执行（根据显卡显存选择）

```bash
# 低配显卡 4G显存：轻量版
ollama pull qwen2.5-coder:7b
# 8G+显存：效果最佳
ollama pull qwen2.5-coder:14b
# 极致性能：deepseek-coder:6.7b
```

测试服务是否正常：

```bash
curl http://127.0.0.1:11434/api/tags
```

能返回模型列表即成功。

# 方案一：首选 行内实时 AI 自动补全（codecompanion.nvim）

最贴合编码手感，打字自动预测下一段代码，灰色虚拟文本，快捷键接受，完美兼容 LSP。

## Lazy 完整配置 `lua/plugins/codecompanion.lua`

```lua
return {
  "olimorris/codecompanion.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-treesitter",
  },
  config = function()
    require("codecompanion").setup({
      -- 核心配置Ollama本地模型
      adapters = {
        ollama = function()
          return require("codecompanion.adapters").extend("ollama", {
            env = {
              url = "http://127.0.0.1:11434",
              model = "qwen2.5-coder:14b", -- 换成你拉取的模型
            },
            -- FIM 填空补全配置（代码补全专用）
            fim = {
              enabled = true,
              stop_words = { "\n\n", "}", ")" },
            },
            schema = {
              model = {
                default = "qwen2.5-coder:14b",
              },
              temperature = 0.2, -- 越低代码越严谨，0.1~0.3适合编码
              num_ctx = 8192,    -- 上下文窗口
            },
          })
        end,
      },
      -- 默认使用ollama
      strategies = {
        chat = { adapter = "ollama" },
        inline = { adapter = "ollama" }, -- 行内自动补全开关
      },
      inline = {
        enabled = true,
        keymaps = {
          accept = "<Tab>",        -- Tab接受整行AI补全
          accept_word = "<C-Right>", -- 接受单个单词
          reject = "<C-e>",        -- 取消AI建议
        },
      },
      -- 全局系统提示词，优化C++/Angelscript代码风格
      prompts = {
        default = {
          system = [[你是专业C++与Angelscript开发工程师，只输出代码，不要解释。严格贴合当前上下文语法，变量命名规范，适配游戏引擎开发。]],
        },
      },
    })
  end,
  keys = {
    { "<leader>ai", "<cmd>CodeCompanionChat Toggle<cr>", desc = "打开AI对话窗口", mode = {"n","v"} },
    { "<leader>ac", "<cmd>CodeCompanionActions<cr>", desc = "AI操作菜单(重构/解释/优化)", mode = {"n","v"} },
  },
}
```

## 使用方法

1. 打开`.cpp`/`.as`文件，正常打字，**自动弹出灰色行内 AI 补全**
2. `<Tab>` 直接采纳完整建议，`<C-e>` 关闭
3. 选中代码，`<leader>ac` 可以：优化代码、解释逻辑、生成注释、修复报错。

# 方案二：nvim-cmp 下拉菜单集成 Ollama AI 补全

把 AI 结果放进常规补全下拉框，和 LSP、Snippet 一起混用，适合习惯原生 cmp 流程。
 插件：`tzachar/cmp-ai`

```lua
return {
  "tzachar/cmp-ai",
  dependencies = "hrsh7th/nvim-cmp",
  config = function()
    local cmp_ai = require("cmp_ai.config")
    cmp_ai:setup({
      max_lines = 600,
      run_on_every_keystroke = true,
      provider = "openai_compatible",
      provider_options = {
        openai_compatible = {
          endpoint = "http://127.0.0.1:11434/v1/completions",
          model = "qwen2.5-coder:7b",
          api_key = "dummy", -- ollama不需要密钥，随便填
          max_tokens = 128,
          temperature = 0.2,
        },
      },
    })
  end,
}
```

修改你的 `nvim-cmp` 配置，加入 AI 来源：

```lua
require("cmp").setup({
  sources = {
    { name = "nvim_lsp" },
    { name = "luasnip" },
    { name = "buffer" },
    { name = "path" },
    { name = "cmp_ai" }, -- 新增Ollama AI补全源
  },
})
```

# 方案三：ollama.nvim（纯对话问答）

适合选中代码提问、生成完整函数、解释报错，**不主打实时行内补全**。

```lua
return {
  "nomnivore/ollama.nvim",
  dependencies = { "nvim-lua/plenary.nvim" },
  cmd = { "Ollama", "OllamaModel", "OllamaServe" },
  keys = {
    { "<leader>oo", ":<c-u>lua require('ollama').prompt()<cr>", desc = "Ollama对话", mode = {"n","v"} },
    { "<leader>og", ":<c-u>lua require('ollama').prompt('Generate_Code')<cr>", desc = "生成代码", mode = {"n","v"} },
  },
  opts = {
    model = "qwen2.5-coder:14b",
    url = "http://127.0.0.1:11434",
    serve = { on_start = true },
  },
}
```

# 关键参数调优（必看，决定速度与效果）

1. **temperature 温度**
   - 编码固定 `0.1 ~ 0.3`：结果稳定、逻辑严谨，不会乱编代码
   - 写文案 / 思考调到 `0.6~0.8`，更有创造性。
2. **显存不足优化**
   - 选用 7b 小模型，关闭后台多余程序；
   - `num_ctx = 4096` 缩小上下文，降低显存占用。
3. **响应慢解决** Ollama 默认自动启用 GPU 加速，确认 NVIDIA 显卡已装 CUDA 驱动；AMD 显卡需额外配置 ROCm。

# 常用问题排查

## 1. 插件提示连接失败

1. 确认 Windows 后台 Ollama 服务正在运行，任务管理器查看`ollama-runner.exe`；
2. 浏览器打开 `http://127.0.0.1:11434` 能正常访问 Ollama 页面；
3. 防火墙放行 11434 端口。

## 2. AI 补全迟迟不出来

1. 模型首次加载会缓慢加载进显存，第一次使用等待 10~30 秒；
2. 检查模型名称和配置完全一致（区分 7b/14b）；
3. 降低上下文`num_ctx`数值。

## 3. 只想要 LSP 优先，AI 后置

在 codecompanion 里可以设置**触发时机**：延迟触发 AI 补全，优先显示 LSP 原生提示。

# 最终选型建议（贴合你的 Angelscript/C++ 游戏开发）

1. **日常写代码首选：codecompanion 行内自动补全**，和 Copilot 体验一致，实时预测函数、结构体、引擎 API，效率最高。
2. 想要融合进原有 cmp 补全列表：选方案二。
3. 代码调试、解释报错、批量生成代码：搭配`ollama.nvim`对话使用。
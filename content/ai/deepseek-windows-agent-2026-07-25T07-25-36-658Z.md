# DeepSeek Export
Conversation: Windows Agent终端推荐  
URL: https://chat.deepseek.com/a/chat/s/eb9a2460-aace-43ba-a59a-f2bacc692e25  
Exported: 2026-07-25T07:25:36.658Z

## User

minuet ai nvim 配置硅基流动的补全

## Assistant

要在 `minuet-ai.nvim` 中配置硅基流动（SiliconFlow）的代码补全，核心是利用它支持的 **FIM（Fill-In-the-Middle）补全能力**，通过 `openai_fim_compatible` 提供商来实现[-1](https://raw.githubusercontent.com/deepseek-ai/awesome-deepseek-integration/main/docs/minuet-ai.nvim/README.md)[-3](https://deepwiki.com/milanglacier/minuet-ai.nvim/5.2-provider-system)。

根据 SiliconFlow 的官方文档，它通过兼容 OpenAI 的 API 提供了 FIM 补全支持，您可以将 `prefix` 和 `suffix` 参数传递给模型来完成代码填空[-2](https://docs.siliconflow.cn/cn/userguide/guides/fim)[-5](https://docs.siliconflow.cn/en/userguide/guides/fim)。

### ⚙️ 配置方法

下面是具体的配置步骤和代码。你需要将 `"YOUR_SILICONFLOW_API_KEY"` 替换成你自己的 API 密钥[-8](https://www.siliconflow.com/zh-tw/blog/how-to-use-continue-in-vs-code-with-siliconflow-apis)。

lua

```lua
require('minuet').setup {
    -- 1. 选择 provider
    provider = 'openai_fim_compatible',

    -- 2. 配置 provider 选项
    provider_options = {
        openai_fim_compatible = {
            -- 硅基流动的 API 地址和你的密钥
            end_point = 'https://api.siliconflow.cn/v1/completions',
            api_key = 'YOUR_SILICONFLOW_API_KEY',
            -- 选择一个支持 FIM 的模型，例如 DeepSeek-V2.5 或 Qwen2.5-Coder 系列
            -- 注意：模型名称要与硅基流动控制台显示的完全一致[citation:2][citation:5]
            name = 'deepseek-ai/DeepSeek-V2.5',
            optional = {
                max_tokens = 256,
                top_p = 0.9,
            },
        },
    },

    -- 3. 选择你的前端显示方式（以下三选一）
    -- 选项 A: 虚拟文本
    virtualtext = {
        auto_trigger_ft = { 'python', 'lua' }, -- 在这些文件类型中自动触发
        keymap = {
            accept = '<A-A>',   -- 接受整个补全
            accept_line = '<A-a>', -- 接受一行
            next = '<A-]>',     -- 下一个补全建议
            prev = '<A-[>',     -- 上一个补全建议
            dismiss = '<A-e>',  -- 取消补全
        },
    },

    -- 选项 B: nvim-cmp (如果你在使用 nvim-cmp)
    -- 需要在 nvim-cmp 的 sources 中添加 { name = 'minuet' }
    -- cmp.enable_auto_complete = true,

    -- 选项 C: blink-cmp (如果你在使用 blink-cmp)
    -- 需要在 blink-cmp 的 sources 中添加 'minuet'
    -- blink.enable_auto_complete = true,
}
```

**关于模型选择**，请务必选择 SiliconFlow 明确支持 FIM 补全的模型。根据其文档，以下模型是确认支持的[-2](https://docs.siliconflow.cn/cn/userguide/guides/fim)[-5](https://docs.siliconflow.cn/en/userguide/guides/fim)：

-
  `deepseek-ai/DeepSeek-V2.5`
-
  `deepseek-ai/DeepSeek-R1`
-
  `deepseek-ai/DeepSeek-V3`
-
  `Qwen/Qwen2.5-Coder-7B-Instruct`
-
  `Qwen/Qwen2.5-Coder-32B-Instruct`

你可以从硅基流动的控制台获取 API 密钥。如果在配置中遇到问题，比如认证失败或模型不支持的报错，可以随时再问我～

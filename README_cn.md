# openaiRtools

<div align="center">

**OpenAI API 的完整 R 语言实现 —— 对标 Python 官方 SDK**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![R >= 4.0](https://img.shields.io/badge/R-%3E%3D%204.0-blue)](https://cran.r-project.org/)

</div>

---

## 目录

1. [功能概述](#功能概述)
2. [安装](#安装)
3. [客户端初始化 `OpenAI$new()`](#客户端初始化)
4. [对话补全 Chat Completions](#对话补全-chat-completions)
5. [流式输出 Streaming](#流式输出-streaming)
6. [函数调用 Function Calling](#函数调用-function-calling)
7. [多模态视觉 Multimodal](#多模态视觉-multimodal)
8. [文本嵌入 Embeddings](#文本嵌入-embeddings)
9. [图像生成 Images (DALL-E)](#图像生成-images-dall-e)
10. [语音处理 Audio](#语音处理-audio)
11. [模型管理 Models](#模型管理-models)
12. [微调 Fine-tuning](#微调-fine-tuning)
13. [文件管理 Files](#文件管理-files)
14. [内容审核 Moderations](#内容审核-moderations)
15. [Responses API（新）](#responses-api新)
16. [Legacy Completions API](#legacy-completions-api)
17. [错误处理](#错误处理)
18. [兼容第三方 API](#兼容第三方-api)

---

## 功能概述

`openaiRtools` 提供与 OpenAI Python SDK 完全对应的 R 接口，涵盖所有主要 API 端点：

| 模块 | 功能 |
|------|------|
| **Chat Completions** | GPT-4o/4/3.5 对话、流式输出、函数调用 |
| **Embeddings** | 文本向量化，支持批量输入 |
| **Images** | DALL-E 3/2 图像生成、编辑、变体 |
| **Audio** | Whisper 语音转文字、文字转语音（TTS） |
| **Models** | 列出、检索、删除模型 |
| **Fine-tuning** | 微调任务管理、事件追踪、检查点 |
| **Files** | 文件上传、列出、检索、删除 |
| **Moderations** | 内容安全审核 |
| **Responses API** | 新一代统一响应 API，支持多轮对话 |
| **Legacy Completions** | 旧版文本补全 API |
| **Streaming** | SSE 流式传输，支持回调函数 |
| **Multimodal** | 图文混合输入辅助函数 |

---

## 安装

```r
# 从 GitHub 安装
install.packages("remotes")
remotes::install_github("xiaoluolorn/openaiRtools")

# 安装依赖（如未安装）
install.packages(c("httr2", "jsonlite", "rlang", "glue", "R6"))
```

---

## 客户端初始化

### `OpenAI$new()` — 创建主客户端

这是使用所有功能的入口。所有子客户端（chat、embeddings 等）均通过主客户端访问。

#### 函数签名

```r
client <- OpenAI$new(
  api_key      = NULL,   # API 密钥
  base_url     = NULL,   # API 基础 URL
  organization = NULL,   # 组织 ID（可选）
  project      = NULL,   # 项目 ID（可选）
  timeout      = 600,    # 请求超时（秒）
  max_retries  = 2       # 最大重试次数
)
```

#### 参数详解

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `api_key` | `character` | `NULL` | API 密钥。为 NULL 时自动读取环境变量 `OPENAI_API_KEY` |
| `base_url` | `character` | `"https://api.openai.com/v1"` | API 基础地址，可替换为兼容 OpenAI 格式的第三方 API |
| `organization` | `character` | `NULL` | OpenAI 组织 ID，对应环境变量 `OPENAI_ORG_ID` |
| `project` | `character` | `NULL` | OpenAI 项目 ID，对应环境变量 `OPENAI_PROJECT_ID` |
| `timeout` | `numeric` | `600` | HTTP 请求超时秒数，长文本生成建议设置较大值 |
| `max_retries` | `integer` | `2` | 遇到 429/500/503 等临时错误时的最大重试次数，使用指数退避策略 |

#### 返回值

返回一个 `OpenAI` R6 对象，包含以下子客户端字段：

| 字段 | 类型 | 对应 API |
|------|------|----------|
| `client$chat` | `ChatClient` | 对话补全 |
| `client$embeddings` | `EmbeddingsClient` | 文本嵌入 |
| `client$images` | `ImagesClient` | 图像生成 |
| `client$audio` | `AudioClient` | 语音处理 |
| `client$models` | `ModelsClient` | 模型管理 |
| `client$fine_tuning` | `FineTuningClient` | 微调 |
| `client$files` | `FilesClient` | 文件管理 |
| `client$moderations` | `ModerationsClient` | 内容审核 |
| `client$completions` | `CompletionsClient` | 旧版补全 |
| `client$responses` | `ResponsesClient` | Responses API |

#### 使用示例

```r
library(openaiRtools)

# 方式一：直接传入密钥
client <- OpenAI$new(api_key = "sk-xxxxxx")

# 方式二：使用环境变量（推荐，避免密钥泄露）
Sys.setenv(OPENAI_API_KEY = "sk-xxxxxx")
client <- OpenAI$new()

# 方式三：连接第三方兼容 API（如 ModelScope、Azure 等）
client <- OpenAI$new(
  api_key  = "ms-xxxxxx",
  base_url = "https://api-inference.modelscope.cn/v1",
  timeout  = 600
)

# 方式四：完整参数配置
client <- OpenAI$new(
  api_key      = "sk-xxxxxx",
  base_url     = "https://api.openai.com/v1",
  organization = "org-xxxxxxxx",
  project      = "proj-xxxxxxxx",
  timeout      = 300,
  max_retries  = 3
)
```

---

## 对话补全 Chat Completions

> **访问路径**: `client$chat$completions`

### `$create()` — 创建对话补全

最核心的函数，支持单轮/多轮对话、流式输出、函数调用、多模态输入。

#### 函数签名

```r
response <- client$chat$completions$create(
  messages,
  model                = "gpt-3.5-turbo",
  frequency_penalty    = NULL,
  logit_bias           = NULL,
  logprobs             = NULL,
  top_logprobs         = NULL,
  max_tokens           = NULL,
  max_completion_tokens = NULL,
  n                    = NULL,
  presence_penalty     = NULL,
  response_format      = NULL,
  seed                 = NULL,
  stop                 = NULL,
  stream               = NULL,
  stream_options       = NULL,
  temperature          = NULL,
  top_p                = NULL,
  tools                = NULL,
  tool_choice          = NULL,
  parallel_tool_calls  = NULL,
  user                 = NULL,
  store                = NULL,
  metadata             = NULL,
  callback             = NULL
)
```

#### 输入参数详解

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `messages` | `list` | ✅ | 消息列表，每条消息为含 `role` 和 `content` 的 list |
| `model` | `character` | ✅ | 模型名称，如 `"gpt-4o"`、`"gpt-4"`、`"gpt-3.5-turbo"` |
| `temperature` | `numeric` | ❌ | 采样温度，范围 `0~2`。越高越随机，越低越确定。建议不要同时调整 `temperature` 和 `top_p` |
| `top_p` | `numeric` | ❌ | 核采样，范围 `0~1`。0.1 表示只考虑概率质量前 10% 的 token |
| `max_tokens` | `integer` | ❌ | 生成的最大 token 数（旧参数） |
| `max_completion_tokens` | `integer` | ❌ | 生成的最大 token 数（新参数，包含推理 token） |
| `n` | `integer` | ❌ | 每次请求生成的候选答案数量，默认 1 |
| `stream` | `logical` | ❌ | 是否启用流式输出（SSE），`TRUE` 或 `FALSE` |
| `callback` | `function` | ❌ | 流式输出时每个 chunk 的回调函数，仅在 `stream=TRUE` 时有效 |
| `stop` | `character/list` | ❌ | 停止序列，遇到该字符串则停止生成 |
| `frequency_penalty` | `numeric` | ❌ | 频率惩罚，范围 `-2~2`。正值降低已出现 token 的概率 |
| `presence_penalty` | `numeric` | ❌ | 存在惩罚，范围 `-2~2`。正值增加模型谈论新话题的概率 |
| `logit_bias` | `list` | ❌ | 指定 token ID 的概率偏置，如 `list("50256" = -100)` |
| `logprobs` | `logical` | ❌ | 是否返回 token 的 log 概率 |
| `top_logprobs` | `integer` | ❌ | 返回每个位置概率最高的前 N 个 token（需 `logprobs=TRUE`） |
| `response_format` | `list` | ❌ | 输出格式，如 `list(type="json_object")` 强制 JSON 输出 |
| `seed` | `integer` | ❌ | 随机种子，设置后输出更稳定（不保证完全确定） |
| `tools` | `list` | ❌ | 可用工具列表（函数调用），见"函数调用"章节 |
| `tool_choice` | `character/list` | ❌ | 工具选择策略：`"auto"`、`"none"`、`"required"` 或指定函数 |
| `parallel_tool_calls` | `logical` | ❌ | 是否允许并行调用多个工具 |
| `user` | `character` | ❌ | 终端用户唯一标识符，用于滥用检测 |
| `store` | `logical` | ❌ | 是否持久化存储该对话（用于后续检索） |
| `metadata` | `list` | ❌ | 存储对话时附加的元数据 |

#### `messages` 参数格式

```r
# 单条用户消息
messages <- list(
  list(role = "user", content = "你好，请介绍一下自己")
)

# 多轮对话（包含 system 提示和历史）
messages <- list(
  list(role = "system",    content = "你是一个专业的数据分析助手"),
  list(role = "user",      content = "什么是回归分析？"),
  list(role = "assistant", content = "回归分析是一种统计方法..."),
  list(role = "user",      content = "能给出 R 语言示例吗？")
)
```

#### 返回值结构

```r
response$id                              # 字符串，响应唯一 ID，如 "chatcmpl-xxxxx"
response$object                          # "chat.completion"
response$created                         # Unix 时间戳
response$model                           # 实际使用的模型名称
response$choices[[1]]$message$role       # "assistant"
response$choices[[1]]$message$content    # 模型生成的文本内容（最核心）
response$choices[[1]]$finish_reason      # 结束原因："stop"/"length"/"tool_calls"/"content_filter"
response$usage$prompt_tokens             # 输入 token 数
response$usage$completion_tokens         # 输出 token 数
response$usage$total_tokens              # 总 token 数
```

#### 实际应用案例

**案例 1：基础对话**

```r
library(openaiRtools)
client <- OpenAI$new(api_key = "sk-xxxxxx")

response <- client$chat$completions$create(
  messages = list(
    list(role = "user", content = "用一句话解释什么是机器学习")
  ),
  model = "gpt-4o"
)

cat(response$choices[[1]]$message$content)
```

**案例 2：带 system 提示的专业对话**

```r
response <- client$chat$completions$create(
  messages = list(
    list(role = "system", content = "你是一位计量经济学专家，回答请简洁专业"),
    list(role = "user",   content = "简述 OLS 估计的高斯-马尔可夫假设")
  ),
  model       = "gpt-4o",
  temperature = 0.3,      # 低温度保证学术准确性
  max_tokens  = 500
)

cat(response$choices[[1]]$message$content)
```

**案例 3：控制生成格式（JSON 输出）**

```r
response <- client$chat$completions$create(
  messages = list(
    list(role = "user", content = "列出 3 种机器学习算法，用 JSON 格式返回，包含 name 和 use_case 字段")
  ),
  model           = "gpt-4o",
  response_format = list(type = "json_object")
)

# 解析 JSON
result <- jsonlite::fromJSON(response$choices[[1]]$message$content)
print(result)
```

**案例 4：多轮对话管理**

```r
# 维护对话历史
history <- list(
  list(role = "system", content = "你是一个 R 语言编程助手")
)

# 第一轮
history <- c(history, list(list(role = "user", content = "如何读取 CSV 文件？")))
r1 <- client$chat$completions$create(messages = history, model = "gpt-4o")
assistant_reply <- r1$choices[[1]]$message$content
history <- c(history, list(list(role = "assistant", content = assistant_reply)))
cat("助手:", assistant_reply, "\n")

# 第二轮（自动包含上下文）
history <- c(history, list(list(role = "user", content = "如果文件很大怎么办？")))
r2 <- client$chat$completions$create(messages = history, model = "gpt-4o")
cat("助手:", r2$choices[[1]]$message$content, "\n")
```

**案例 5：生成多个候选答案**

```r
response <- client$chat$completions$create(
  messages = list(list(role = "user", content = "给一篇关于 AI 的文章起个标题")),
  model    = "gpt-4o",
  n        = 3,           # 生成 3 个候选
  temperature = 1.2       # 较高温度增加多样性
)

for (i in seq_along(response$choices)) {
  cat(sprintf("候选 %d: %s\n", i, response$choices[[i]]$message$content))
}
```

---

### `$retrieve()` — 检索存储的对话

```r
# 需先用 store=TRUE 创建
stored <- client$chat$completions$retrieve(completion_id = "chatcmpl-xxxxx")
cat(stored$choices[[1]]$message$content)
```

| 参数 | 类型 | 说明 |
|------|------|------|
| `completion_id` | `character` | 要检索的对话 ID（来自 `$create()` 返回的 `response$id`） |

---

### `$list()` — 列出存储的对话

```r
completions <- client$chat$completions$list(
  model  = "gpt-4o",   # 按模型过滤（可选）
  limit  = 20,         # 每页数量（默认 20，最大 100）
  order  = "desc",     # "asc" 或 "desc"
  after  = NULL        # 游标分页
)

# 遍历结果
for (c in completions$data) {
  cat(c$id, "-", c$model, "\n")
}
```

---

### `$update()` — 更新存储对话的元数据

```r
client$chat$completions$update(
  completion_id = "chatcmpl-xxxxx",
  metadata      = list(project = "研究项目A", version = "v2")
)
```

---

### `$delete()` — 删除存储的对话

```r
client$chat$completions$delete(completion_id = "chatcmpl-xxxxx")
```

---

### 便捷函数 `create_chat_completion()`

无需手动创建客户端，直接调用（自动读取 `OPENAI_API_KEY` 环境变量）：

```r
response <- create_chat_completion(
  messages = list(list(role = "user", content = "Hello!")),
  model    = "gpt-4o"
)
cat(response$choices[[1]]$message$content)
```

---

## 流式输出 Streaming

流式输出让模型逐字返回内容，适合长文本生成场景，提升用户体验。

### 方式一：使用 `callback` 实时打印（推荐）

```r
client$chat$completions$create(
  messages = list(list(role = "user", content = "写一篇 200 字的科技新闻")),
  model    = "gpt-4o",
  stream   = TRUE,
  callback = function(chunk) {
    # 每个 chunk 包含 delta（增量内容）
    content <- chunk$choices[[1]]$delta$content
    if (!is.null(content)) cat(content, sep = "")
  }
)
cat("\n")
```

**chunk 结构说明：**

```r
chunk$id                              # chunk ID
chunk$choices[[1]]$delta$role        # 仅首个 chunk 有 role = "assistant"
chunk$choices[[1]]$delta$content     # 当前增量文字（可能为 NULL）
chunk$choices[[1]]$finish_reason     # 仅末尾 chunk 有值："stop"/"length"
```

### 方式二：不提供 callback，直接获取完整内容

修复后，`stream=TRUE` 且不提供 `callback` 时，函数自动汇总所有 chunk，
返回与非流式模式**完全相同格式**的响应对象：

```r
response <- client$chat$completions$create(
  messages = list(list(role = "user", content = "Tell me a story")),
  model    = "MiniMax/MiniMax-M2.5",
  stream   = TRUE
)

# 与非流式完全相同的访问方式
cat(response$choices[[1]]$message$content)
cat("结束原因:", response$choices[[1]]$finish_reason, "\n")

# 高级用户：访问原始 StreamIterator
iter <- response$.stream_iterator
cat("共", length(iter$chunks), "个 chunk\n")
```

### StreamIterator 方法

| 方法 | 说明 |
|------|------|
| `iter$get_full_text()` | 拼接所有 delta 内容，返回完整字符串 |
| `iter$next_chunk()` | 获取下一个 chunk |
| `iter$has_more()` | 是否还有更多 chunk |
| `iter$reset()` | 重置到起始位置 |
| `iter$as_list()` | 返回所有 chunk 的列表 |

### 实际案例：流式生成研究摘要

```r
cat("正在生成摘要：\n")
client$chat$completions$create(
  messages = list(
    list(role = "system", content = "你是学术写作助手"),
    list(role = "user",   content = "为一篇关于大语言模型在经济学中应用的论文写摘要")
  ),
  model       = "gpt-4o",
  stream      = TRUE,
  temperature = 0.7,
  callback    = function(chunk) {
    delta <- chunk$choices[[1]]$delta$content
    if (!is.null(delta)) cat(delta, sep = "")
  }
)
cat("\n")
```

---

## 函数调用 Function Calling

允许模型调用您预定义的函数，是构建智能 Agent 的核心机制。

### 工具定义格式

```r
tools <- list(
  list(
    type     = "function",
    `function` = list(
      name        = "get_gdp_data",
      description = "获取指定国家和年份的 GDP 数据",
      parameters  = list(
        type       = "object",
        properties = list(
          country = list(
            type        = "string",
            description = "国家名称，如 'China'、'USA'"
          ),
          year = list(
            type        = "integer",
            description = "年份，如 2023"
          )
        ),
        required = list("country", "year")
      )
    )
  )
)
```

### 完整调用流程

```r
# 第一步：发送包含工具定义的请求
response <- client$chat$completions$create(
  messages    = list(list(role = "user", content = "中国 2022 年的 GDP 是多少？")),
  model       = "gpt-4o",
  tools       = tools,
  tool_choice = "auto"    # "auto"/"none"/"required" 或指定函数
)

# 第二步：检查模型是否调用了工具
if (response$choices[[1]]$finish_reason == "tool_calls") {
  tool_call <- response$choices[[1]]$message$tool_calls[[1]]
  func_name <- tool_call$`function`$name
  func_args <- jsonlite::fromJSON(tool_call$`function`$arguments)
  
  cat("模型调用函数:", func_name, "\n")
  cat("参数:", func_args$country, func_args$year, "\n")
  
  # 第三步：执行真实函数（您的业务逻辑）
  result <- get_gdp_data(func_args$country, func_args$year)  # 自定义函数
  
  # 第四步：把结果返回给模型
  messages_with_result <- list(
    list(role = "user",      content = "中国 2022 年的 GDP 是多少？"),
    response$choices[[1]]$message,     # 模型的工具调用消息
    list(
      role         = "tool",
      tool_call_id = tool_call$id,
      content      = jsonlite::toJSON(result, auto_unbox = TRUE)
    )
  )
  
  final_response <- client$chat$completions$create(
    messages = messages_with_result,
    model    = "gpt-4o"
  )
  
  cat("最终回答:", final_response$choices[[1]]$message$content, "\n")
}
```

---

## 多模态视觉 Multimodal

### 辅助函数

#### `image_from_url(url, detail)` — 网络图片

```r
img <- image_from_url(
  url    = "https://example.com/chart.png",
  detail = "high"   # "low"/"high"/"auto"，high 更精准但消耗更多 token
)
```

#### `image_from_file(file_path, mime_type, detail)` — 本地图片（Base64）

```r
img <- image_from_file(
  file_path = "path/to/figure.jpg",
  mime_type = NULL,    # NULL 则自动从扩展名检测：jpg/png/gif/webp
  detail    = "auto"
)
```

#### `create_multimodal_message(text, images, detail)` — 快速构建消息

```r
msg <- create_multimodal_message(
  text   = "请描述这张图中的趋势",
  images = list(
    "https://example.com/chart.png",  # URL 自动识别
    "local_figure.png"                # 本地文件自动 Base64 编码
  ),
  detail = "high"
)
```

### 实际案例：分析经济学图表

```r
# 分析本地保存的回归结果图
msg <- create_multimodal_message(
  text   = "这是一张计量回归的残差图，请分析是否存在异方差问题",
  images = list("regression_residuals.png")
)

response <- client$chat$completions$create(
  messages = list(msg),
  model    = "gpt-4o"    # 需要支持视觉的模型
)

cat(response$choices[[1]]$message$content)
```

---

## 文本嵌入 Embeddings

> **访问路径**: `client$embeddings`

### `$create()` — 创建文本嵌入向量

#### 函数签名

```r
response <- client$embeddings$create(
  input           = ,      # 必填：文本或文本列表
  model           = "text-embedding-ada-002",
  encoding_format = NULL,  # "float" 或 "base64"
  dimensions      = NULL,  # 向量维度（仅部分模型支持）
  user            = NULL
)
```

#### 参数说明

| 参数 | 类型 | 说明 |
|------|------|------|
| `input` | `character` 或 `list` | 单个文本字符串，或字符串列表（批量处理） |
| `model` | `character` | 嵌入模型：`"text-embedding-ada-002"` (1536维)、`"text-embedding-3-small"` (1536维)、`"text-embedding-3-large"` (3072维) |
| `encoding_format` | `character` | `"float"`（默认，返回浮点数组）或 `"base64"` |
| `dimensions` | `integer` | 截断维度，仅 `text-embedding-3-*` 系列支持 |

#### 返回值

```r
response$data[[1]]$embedding    # 数值向量（如 1536 维）
response$data[[1]]$index        # 输入索引（批量时使用）
response$usage$prompt_tokens    # 消耗的 token 数
response$usage$total_tokens
```

#### 实际案例

**案例 1：单文本嵌入**

```r
response <- client$embeddings$create(
  input = "大语言模型在经济学研究中的应用",
  model = "text-embedding-3-small"
)

vec <- response$data[[1]]$embedding
cat("向量维度:", length(vec), "\n")  # 1536
```

**案例 2：批量嵌入 + 语义相似度计算**

```r
texts <- list(
  "货币政策对通货膨胀的影响",
  "利率变动与经济增长的关系",
  "今天天气很好"
)

response <- client$embeddings$create(
  input = texts,
  model = "text-embedding-3-small"
)

# 提取所有向量
vecs <- lapply(response$data, function(d) unlist(d$embedding))

# 计算余弦相似度
cosine_sim <- function(a, b) sum(a * b) / (sqrt(sum(a^2)) * sqrt(sum(b^2)))

cat("文本1 vs 文本2 相似度:", cosine_sim(vecs[[1]], vecs[[2]]), "\n")  # 高
cat("文本1 vs 文本3 相似度:", cosine_sim(vecs[[1]], vecs[[3]]), "\n")  # 低
```

**案例 3：文献语义搜索**

```r
# 嵌入文献摘要
abstracts <- c("摘要1...", "摘要2...", "摘要3...")
abs_response <- client$embeddings$create(input = as.list(abstracts), model = "text-embedding-3-small")
abs_vecs <- lapply(abs_response$data, function(d) unlist(d$embedding))

# 嵌入查询
query <- "工具变量估计方法"
q_response <- client$embeddings$create(input = query, model = "text-embedding-3-small")
q_vec <- unlist(q_response$data[[1]]$embedding)

# 找最相关文献
similarities <- sapply(abs_vecs, function(v) cosine_sim(q_vec, v))
cat("最相关文献序号:", which.max(similarities), "\n")
```

---

## 图像生成 Images (DALL-E)

> **访问路径**: `client$images`

### `$create()` — 生成图像

#### 函数签名

```r
response <- client$images$create(
  prompt          = ,             # 必填：图像描述文字
  model           = "dall-e-3",
  n               = NULL,         # 生成数量
  quality         = NULL,         # "standard" 或 "hd"
  response_format = NULL,         # "url" 或 "b64_json"
  size            = NULL,         # 图像尺寸
  style           = NULL,         # "vivid" 或 "natural"
  user            = NULL
)
```

#### 参数说明

| 参数 | 类型 | 说明 |
|------|------|------|
| `prompt` | `character` | 图像描述，建议详细描述风格、内容、光线等 |
| `model` | `character` | `"dall-e-3"`（推荐）或 `"dall-e-2"` |
| `size` | `character` | DALL-E 3: `"1024x1024"`、`"1024x1792"`、`"1792x1024"`；DALL-E 2: `"256x256"`、`"512x512"`、`"1024x1024"` |
| `quality` | `character` | `"standard"` 或 `"hd"`（DALL-E 3 专属，hd 更精细但价格更贵） |
| `style` | `character` | `"vivid"`（鲜艳戏剧感）或 `"natural"`（真实自然感），DALL-E 3 专属 |
| `n` | `integer` | 生成数量；DALL-E 3 每次只能生成 1 张 |
| `response_format` | `character` | `"url"`（返回临时 URL）或 `"b64_json"`（返回 Base64 数据） |

#### 返回值

```r
response$data[[1]]$url           # 图片 URL（1小时内有效）
response$data[[1]]$b64_json      # Base64 图片数据（当 response_format="b64_json"）
response$data[[1]]$revised_prompt # DALL-E 3 自动优化后的实际提示词
```

#### 实际案例

```r
# 生成高质量图像并下载保存
response <- client$images$create(
  prompt  = "A professional data visualization chart showing GDP growth trends, clean white background, minimalist style",
  model   = "dall-e-3",
  size    = "1024x1024",
  quality = "hd",
  style   = "natural"
)

# 下载图片
url <- response$data[[1]]$url
download.file(url, "output.png", mode = "wb")
cat("实际使用的提示词:", response$data[[1]]$revised_prompt, "\n")
```

---

### `$edit()` — 编辑图像

在现有图像上进行局部修改（需提供遮罩，仅 DALL-E 2）。

```r
response <- client$images$edit(
  image  = "original.png",   # 原始图片路径（PNG，<4MB，需正方形）
  prompt = "Add a red hat to the person",
  mask   = "mask.png",       # 遮罩图片（透明区域=待修改区域），可选
  model  = "dall-e-2",
  size   = "1024x1024",
  n      = 1
)
```

---

### `$create_variation()` — 生成图像变体

基于原图生成多个风格变体（仅 DALL-E 2）。

```r
response <- client$images$create_variation(
  image = "source.png",   # PNG 格式，<4MB，正方形
  model = "dall-e-2",
  n     = 3,              # 最多 10 个变体
  size  = "1024x1024"
)

# 下载所有变体
for (i in seq_along(response$data)) {
  download.file(response$data[[i]]$url, sprintf("variation_%d.png", i), mode = "wb")
}
```

---

## 语音处理 Audio

> **访问路径**: `client$audio`

### `$transcriptions$create()` — 语音转文字（Whisper）

#### 函数签名

```r
result <- client$audio$transcriptions$create(
  file                    = ,              # 必填：音频文件路径
  model                   = "whisper-1",
  language                = NULL,          # ISO-639-1 语言代码
  prompt                  = NULL,          # 提示词
  response_format         = NULL,          # 输出格式
  temperature             = NULL,          # 采样温度
  timestamp_granularities = NULL           # 时间戳粒度
)
```

#### 参数说明

| 参数 | 类型 | 说明 |
|------|------|------|
| `file` | `character` | 音频文件路径，支持：mp3、mp4、mpeg、mpga、m4a、wav、webm，最大 25MB |
| `model` | `character` | 目前仅 `"whisper-1"` |
| `language` | `character` | 显式指定语言可提升速度和准确率，如 `"zh"`（中文）、`"en"`（英文） |
| `prompt` | `character` | 提示词，帮助模型识别专有名词、缩写等 |
| `response_format` | `character` | `"json"`（默认）、`"text"`、`"srt"`（字幕）、`"vtt"`（字幕）、`"verbose_json"` |
| `temperature` | `numeric` | 采样温度 0~1，越低越保守，默认 0 |
| `timestamp_granularities` | `list` | `list("word")` 或 `list("segment")` 或 `list("word","segment")` |

#### 返回值

```r
result$text             # 转录文字（最常用）
# verbose_json 格式时还有：
result$language         # 检测到的语言
result$duration         # 音频时长（秒）
result$words            # 单词级时间戳（需 timestamp_granularities）
result$segments         # 段落级时间戳
```

#### 实际案例

```r
# 转录中文会议录音
result <- client$audio$transcriptions$create(
  file            = "meeting_recording.mp3",
  model           = "whisper-1",
  language        = "zh",
  response_format = "verbose_json",
  prompt          = "以下是关于计量经济学的学术报告"
)

cat("转录文字:\n", result$text, "\n")
cat("时长:", result$duration, "秒\n")

# 生成 SRT 字幕文件
srt_result <- client$audio$transcriptions$create(
  file            = "lecture.mp4",
  model           = "whisper-1",
  response_format = "srt"
)
writeLines(srt_result, "subtitles.srt")
```

---

### `$translations$create()` — 语音翻译为英文

将任意语言的音频直接翻译成英文文字（无需先转录）。

```r
result <- client$audio$translations$create(
  file            = "chinese_speech.mp3",
  model           = "whisper-1",
  response_format = "json",
  prompt          = "Economics research presentation"
)

cat("英文翻译:", result$text, "\n")
```

---

### `$speech$create()` — 文字转语音（TTS）

#### 函数签名

```r
audio_data <- client$audio$speech$create(
  input           = ,           # 必填：要合成的文字
  model           = "tts-1",
  voice           = "alloy",
  response_format = NULL,       # 音频格式
  speed           = NULL        # 语速
)
```

#### 参数说明

| 参数 | 类型 | 说明 |
|------|------|------|
| `input` | `character` | 要合成的文字，最长 4096 个字符 |
| `model` | `character` | `"tts-1"`（标准，延迟低）或 `"tts-1-hd"`（高质量） |
| `voice` | `character` | 声音：`"alloy"`、`"echo"`、`"fable"`、`"onyx"`、`"nova"`、`"shimmer"` |
| `response_format` | `character` | `"mp3"`（默认）、`"opus"`、`"aac"`、`"flac"`、`"wav"`、`"pcm"` |
| `speed` | `numeric` | 语速，范围 `0.25~4.0`，默认 1.0 |

#### 返回值

**返回原始二进制数据（raw vector）**，需用 `writeBin()` 保存为文件。

```r
# 生成中文语音
audio_bytes <- client$audio$speech$create(
  input  = "欢迎使用 openaiRtools，这是一个强大的 R 语言 OpenAI 接口库。",
  model  = "tts-1-hd",
  voice  = "nova",
  speed  = 0.9
)

writeBin(audio_bytes, "output_speech.mp3")
cat("音频已保存\n")
```

---

## 模型管理 Models

> **访问路径**: `client$models`

### `$list()` — 列出所有可用模型

```r
models <- client$models$list()

# 查看所有模型 ID
model_ids <- sapply(models$data, function(m) m$id)
print(model_ids)

# 筛选 GPT-4 系列
gpt4_models <- Filter(function(m) grepl("gpt-4", m$id), models$data)
```

**返回值**: `models$data` 为列表，每项包含：

| 字段 | 说明 |
|------|------|
| `id` | 模型 ID，如 `"gpt-4o"` |
| `object` | `"model"` |
| `created` | 创建时间（Unix 时间戳） |
| `owned_by` | 所有者，如 `"openai"` |

### `$retrieve(model)` — 获取指定模型详情

```r
model <- client$models$retrieve("gpt-4o")
cat("模型 ID:", model$id, "\n")
cat("所有者:", model$owned_by, "\n")
```

### `$delete(model)` — 删除微调模型

```r
# 仅可删除您自己的微调模型
result <- client$models$delete("ft:gpt-3.5-turbo:my-org:custom-model:abc123")
cat("删除状态:", result$deleted, "\n")
```

---

## 微调 Fine-tuning

> **访问路径**: `client$fine_tuning$jobs`

### `$create()` — 创建微调任务

```r
job <- client$fine_tuning$jobs$create(
  training_file   = "file-abc123",       # 必填：训练文件 ID
  model           = "gpt-3.5-turbo",     # 必填：基础模型
  validation_file = NULL,                # 验证集文件 ID
  hyperparameters = NULL,                # 超参数
  suffix          = NULL,                # 模型名称后缀
  seed            = NULL,                # 随机种子
  method          = NULL                 # "supervised" 或 "dpo"
)
```

**`hyperparameters` 格式：**

```r
hyperparameters <- list(
  n_epochs              = 3,     # 训练轮数（"auto" 或整数）
  batch_size            = "auto",
  learning_rate_multiplier = "auto"
)
```

**返回值：**

```r
job$id              # 任务 ID，如 "ftjob-abc123"
job$status          # "validating_files"/"queued"/"running"/"succeeded"/"failed"
job$model           # 基础模型
job$fine_tuned_model # 微调后模型名称（完成后可用）
```

### `$list()` — 列出微调任务

```r
jobs <- client$fine_tuning$jobs$list(limit = 10)
for (j in jobs$data) {
  cat(j$id, "-", j$status, "\n")
}
```

### `$retrieve()` — 获取任务状态

```r
job <- client$fine_tuning$jobs$retrieve("ftjob-abc123")
cat("状态:", job$status, "\n")
if (job$status == "succeeded") {
  cat("微调模型:", job$fine_tuned_model, "\n")
}
```

### `$cancel()` — 取消任务

```r
client$fine_tuning$jobs$cancel("ftjob-abc123")
```

### `$list_events()` — 查看训练事件日志

```r
events <- client$fine_tuning$jobs$list_events("ftjob-abc123", limit = 20)
for (e in events$data) {
  cat(e$created_at, "-", e$message, "\n")
}
```

### `$checkpoints$list()` — 列出检查点

```r
checkpoints <- client$fine_tuning$jobs$checkpoints$list("ftjob-abc123")
for (cp in checkpoints$data) {
  cat("步骤:", cp$step_number, "模型:", cp$fine_tuned_model_checkpoint, "\n")
}
```

### 完整微调工作流案例

```r
# 1. 上传训练数据
file_resp <- client$files$create(
  file    = "train_data.jsonl",
  purpose = "fine-tune"
)
file_id <- file_resp$id

# 2. 创建微调任务
job <- client$fine_tuning$jobs$create(
  training_file   = file_id,
  model           = "gpt-3.5-turbo",
  hyperparameters = list(n_epochs = 3),
  suffix          = "economics-expert"
)

# 3. 轮询任务状态
repeat {
  status <- client$fine_tuning$jobs$retrieve(job$id)
  cat("状态:", status$status, "\n")
  if (status$status %in% c("succeeded", "failed", "cancelled")) break
  Sys.sleep(30)
}

# 4. 使用微调后的模型
if (status$status == "succeeded") {
  ft_model <- status$fine_tuned_model
  response <- client$chat$completions$create(
    messages = list(list(role = "user", content = "解释 IV 估计")),
    model    = ft_model
  )
  cat(response$choices[[1]]$message$content)
}
```

---

## 文件管理 Files

> **访问路径**: `client$files`

### `$create()` — 上传文件

```r
file_resp <- client$files$create(
  file    = "data.jsonl",    # 文件路径
  purpose = "fine-tune"      # "fine-tune" 或 "assistants" 或 "batch"
)
cat("文件 ID:", file_resp$id, "\n")
```

### `$list()` — 列出文件

```r
files <- client$files$list(purpose = "fine-tune")
for (f in files$data) {
  cat(f$id, f$filename, f$size, "bytes\n")
}
```

### `$retrieve()` — 获取文件信息

```r
file_info <- client$files$retrieve("file-abc123")
cat("文件名:", file_info$filename, "\n状态:", file_info$status, "\n")
```

### `$content()` — 下载文件内容

```r
raw_content <- client$files$content("file-abc123")
writeBin(raw_content, "downloaded_file.jsonl")
```

### `$delete()` — 删除文件

```r
result <- client$files$delete("file-abc123")
cat("已删除:", result$deleted, "\n")
```

---

## 内容审核 Moderations

> **访问路径**: `client$moderations`

检测文本是否违反 OpenAI 使用政策。

```r
result <- client$moderations$create(
  input = "这是一段需要审核的文字",
  model = "omni-moderation-latest"   # 可选，默认最新版本
)

# 检查结果
flagged <- result$results[[1]]$flagged
cat("是否违规:", flagged, "\n")

# 查看各类别分数
cats <- result$results[[1]]$categories
cat("仇恨内容:", cats$hate, "\n")
cat("暴力内容:", cats$violence, "\n")
cat("自残内容:", cats$`self-harm`, "\n")
```

**返回的类别：** `hate`、`hate/threatening`、`harassment`、`harassment/threatening`、`self-harm`、`self-harm/intent`、`self-harm/instructions`、`sexual`、`sexual/minors`、`violence`、`violence/graphic`

---

## Responses API（新）

> **访问路径**: `client$responses`
>
> OpenAI 新一代统一 API，更简洁的多轮对话设计。

### `$create()` — 创建响应

```r
response <- client$responses$create(
  model                = "gpt-4o",    # 必填
  input                = "...",       # 必填：文本或消息列表
  instructions         = NULL,        # system 提示词
  previous_response_id = NULL,        # 上轮响应 ID（多轮对话）
  temperature          = NULL,
  max_output_tokens    = NULL,
  tools                = NULL,
  store                = NULL         # 是否持久化
)

# 获取输出文本
cat(response$output[[1]]$content[[1]]$text)
```

### 多轮对话（无需维护 messages 列表）

```r
# 第一轮
r1 <- client$responses$create(
  model        = "gpt-4o",
  input        = "什么是向量自回归模型（VAR）？",
  instructions = "你是计量经济学专家，回答简洁准确"
)
cat(r1$output[[1]]$content[[1]]$text, "\n")

# 第二轮（只需传入上轮 ID）
r2 <- client$responses$create(
  model                = "gpt-4o",
  input                = "给出 R 语言实现代码",
  previous_response_id = r1$id          # 自动携带上下文
)
cat(r2$output[[1]]$content[[1]]$text, "\n")
```

### `$retrieve()` / `$delete()` / `$cancel()`

```r
resp  <- client$responses$retrieve("resp_abc123")
client$responses$delete("resp_abc123")
client$responses$cancel("resp_abc123")   # 取消正在进行的流式响应
```

---

## Legacy Completions API

> **访问路径**: `client$completions`
>
> ⚠️ 旧版 API，新项目建议使用 Chat Completions。

```r
response <- client$completions$create(
  prompt      = "Once upon a time",
  model       = "gpt-3.5-turbo-instruct",
  max_tokens  = 200,
  temperature = 0.7,
  stop        = list("\n"),
  n           = 1
)

cat(response$choices[[1]]$text)
```

---

## 错误处理

```r
tryCatch(
  {
    response <- client$chat$completions$create(
      messages = list(list(role = "user", content = "Hello")),
      model    = "gpt-4o"
    )
  },
  openai_api_error = function(e) {
    # API 层面的错误（4xx/5xx 响应）
    cat("API 错误:", e$message, "\n")
    cat("HTTP 状态码:", e$status_code, "\n")
    # 常见状态码：
    # 401 - API 密钥无效
    # 429 - 请求频率超限（会自动重试）
    # 404 - 模型不存在
    # 500 - 服务器内部错误（会自动重试）
  },
  openai_connection_error = function(e) {
    # 网络连接错误（超时、DNS 失败等）
    cat("网络错误:", e$message, "\n")
  },
  error = function(e) {
    # 其他 R 运行时错误
    cat("未知错误:", e$message, "\n")
  }
)
```

---

## 兼容第三方 API

凡是提供 OpenAI 兼容接口的服务，均可通过 `base_url` 参数直接使用：

```r
# ModelScope 魔搭社区
client <- OpenAI$new(
  api_key  = "ms-xxxxxx",
  base_url = "https://api-inference.modelscope.cn/v1",
  timeout  = 600
)

# 使用 MiniMax 模型（流式输出示例）
response <- client$chat$completions$create(
  messages = list(list(role = "user", content = "讲一个故事")),
  model    = "MiniMax/MiniMax-M2.5",
  stream   = TRUE
)
cat(response$choices[[1]]$message$content)
```

---

## 环境变量配置

推荐将密钥存储在 `.Renviron` 文件中，避免在代码中硬编码：

```bash
# 在 ~/.Renviron 中添加：
OPENAI_API_KEY=sk-xxxxxx
OPENAI_ORG_ID=org-xxxxxx       # 可选
OPENAI_PROJECT_ID=proj-xxxxxx  # 可选
```

```r
# 运行时重新加载
readRenviron("~/.Renviron")
client <- OpenAI$new()    # 自动读取环境变量
```

---

## 依赖说明

| 包 | 版本要求 | 用途 |
|----|---------|------|
| `R6` | >= 2.5 | 面向对象框架 |
| `httr2` | >= 1.0 | HTTP 请求与流式传输 |
| `jsonlite` | >= 1.8 | JSON 解析与序列化 |
| `rlang` | >= 1.0 | 错误处理 |
| `glue` | >= 1.6 | 字符串处理 |

---

## 作者

**ChaoyangLuo**  
GitHub: [@xiaoluolorn](https://github.com/xiaoluolorn)

## 许可证

MIT License © 2024

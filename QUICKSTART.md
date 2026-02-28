# openaiR 快速入门指南

## 1. 安装

### 从 GitHub 安装

```r
# 安装 remotes（如果尚未安装）
install.packages("remotes")

# 从 GitHub 安装 openaiR
remotes::install_github("xiaoluolorn/openaiR")
```

## 2. 设置 API 密钥

### 方法 1：环境变量（推荐）

```r
# 在 R 中设置
Sys.setenv(OPENAI_API_KEY = "sk-your-api-key-here")

# 或在 .Renviron 文件中设置（永久）
# 运行 usethis::edit_r_environ() 并添加：
# OPENAI_API_KEY=sk-your-api-key-here
```

### 方法 2：直接传递

```r
library(openaiR)
client <- OpenAI$new(api_key = "sk-your-api-key-here")
```

## 3. 基本使用

### 聊天补全

```r
library(openaiR)

# 创建客户端
client <- OpenAI$new()  # 会自动读取环境变量

# 发送消息
response <- client$chat$completions$create(
  messages = list(
    list(role = "user", content = "你好，请用 R 语言写一个斐波那契数列函数")
  ),
  model = "gpt-4"
)

# 查看回复
cat(response$choices[[1]]$message$content)
```

### 使用便捷函数

```r
# 更简单的调用方式
response <- create_chat_completion(
  messages = list(
    list(role = "user", content = "什么是机器学习？")
  ),
  model = "gpt-3.5-turbo"
)

cat(response$choices[[1]]$message$content)
```

## 4. 主要功能

### 聊天补全（Chat Completions）

```r
# 多轮对话
messages <- list(
  list(role = "system", content = "你是一个专业的 R 语言助手"),
  list(role = "user", content = "如何创建一个数据框？"),
  list(role = "assistant", content = "在 R 中，你可以使用 data.frame() 函数..."),
  list(role = "user", content = "能举个例子吗？")
)

response <- client$chat$completions$create(
  messages = messages,
  model = "gpt-4",
  temperature = 0.7
)
```

### 嵌入（Embeddings）

```r
# 创建文本嵌入
response <- client$embeddings$create(
  input = "R 语言是数据科学和统计分析的强大工具",
  model = "text-embedding-ada-002"
)

# 获取嵌入向量
embedding <- response$data[[1]]$embedding
cat("向量维度:", length(embedding))
```

### 图像生成（DALL-E）

```r
# 生成图像
response <- client$images$create(
  prompt = "一只穿着太空服的可爱猫咪，数字艺术风格",
  model = "dall-e-3",
  size = "1024x1024",
  quality = "hd"
)

# 获取图像 URL
image_url <- response$data[[1]]$url
cat("图像 URL:", image_url)

# 在 RStudio 中查看
# install.packages("magick")
library(magick)
img <- image_read(image_url)
image_display(img)
```

### 音频转录（Whisper）

```r
# 转录音频文件
transcription <- client$audio$transcriptions$create(
  file = "recording.mp3",
  model = "whisper-1"
)

cat("转录文本:", transcription$text)
```

### 文本转语音（TTS）

```r
# 生成语音
audio_data <- client$audio$speech$create(
  input = "你好，这是 openaiR 包的文本转语音功能测试",
  model = "tts-1",
  voice = "alloy"
)

# 保存为 MP3 文件
writeBin(audio_data, "speech.mp3")

# 播放音频（需要 system 命令）
# system("afplay speech.mp3")  # macOS
# system("start speech.mp3")   # Windows
```

### 模型管理

```r
# 列出所有可用模型
models <- client$models$list()
print(models$data)

# 获取特定模型信息
model <- client$models$retrieve("gpt-4")
cat("模型 ID:", model$id)
cat("创建时间:", model$created)
```

## 5. 高级功能

### 函数调用（Function Calling）

```r
# 定义可用函数
tools <- list(
  list(
    type = "function",
    function = list(
      name = "get_weather",
      description = "获取指定城市的天气",
      parameters = list(
        type = "object",
        properties = list(
          location = list(
            type = "string",
            description = "城市名称"
          )
        ),
        required = list("location")
      )
    )
  )
)

response <- client$chat$completions$create(
  messages = list(
    list(role = "user", content = "北京今天的天气怎么样？")
  ),
  model = "gpt-4",
  tools = tools
)

# 检查是否调用了函数
if (!is.null(response$choices[[1]]$message$tool_calls)) {
  cat("模型请求调用函数\n")
  print(response$choices[[1]]$message$tool_calls)
}
```

### 错误处理

```r
tryCatch(
  {
    response <- client$chat$completions$create(
      messages = list(list(role = "user", content = "测试")),
      model = "gpt-4"
    )
  },
  openai_api_error = function(e) {
    cat("API 错误:", e$message, "\n")
    cat("HTTP 状态码:", e$status_code, "\n")
  },
  openai_connection_error = function(e) {
    cat("连接错误:", e$message, "\n")
  },
  error = function(e) {
    cat("一般错误:", e$message, "\n")
  }
)
```

### 自定义配置

```r
# 使用自定义基础 URL（兼容 OpenAI 的 API）
client <- OpenAI$new(
  api_key = "your-key",
  base_url = "https://your-custom-api.com/v1",
  timeout = 300
)

# 设置组织和项目
client <- OpenAI$new(
  api_key = "your-key",
  organization = "org-123",
  project = "proj-456"
)
```

## 6. 常见问题

### Q: 如何获取 API 密钥？

A: 访问 https://platform.openai.com/api-keys 创建 API 密钥。

### Q: 出现 "No API key provided" 错误怎么办？

A: 确保已设置 `OPENAI_API_KEY` 环境变量：
```r
Sys.setenv(OPENAI_API_KEY = "sk-...")
```

### Q: 如何查看包的帮助文档？

A: 
```r
# 查看包的帮助
help(package = "openaiR")

# 查看特定函数的帮助
?OpenAI
?create_chat_completion
```

### Q: 如何更新包？

A:
```r
remotes::install_github("xiaoluolorn/openaiR", upgrade = "always")
```

## 7. 下一步

- 阅读完整文档：https://xiaoluolorn.github.io/openaiR/
- 查看示例代码：`vignette("introduction", package = "openaiR")`
- 报告问题：https://github.com/xiaoluolorn/openaiR/issues

## 8. 支持

如有问题或建议，欢迎：
- 提交 Issue: https://github.com/xiaoluolorn/openaiR/issues
- 邮件联系：xiaoluolorn@example.com

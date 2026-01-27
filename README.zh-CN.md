# gollama：用 Go 本地运行大模型

[![Go Reference](https://pkg.go.dev/badge/github.com/godeps/gollama.svg)](https://pkg.go.dev/github.com/godeps/gollama)

这是 [llama.cpp](https://github.com/ggml-org/llama.cpp) 的 Go 绑定，支持本地运行大语言模型并使用 GPU
加速。库已用于生产环境，支持线程安全的并发推理与完整的测试覆盖。你可以用一个干净、地道的 Go
API 将 LLM 推理集成进应用。

本项目是 [go-skynet/go-llama.cpp](https://github.com/go-skynet/go-llama.cpp) 的活跃分支（原项目自
2023 年 10 月以来基本停止维护）。目标是持续跟进 llama.cpp 的更新，同时为 Go 开发者提供更轻量、
更高性能的替代方案，避免使用诸如 PyTorch/vLLM 之类的重量级 Python 栈。

**文档**：

- **快速上手**：[安装指南](docs/getting-started.md) | [API 指南](docs/api-guide.md) |
  [构建选项](docs/building.md)
- **迁移**：[v1 到 v2 迁移指南](MIGRATION.md)
- **API 参考**：[pkg.go.dev](https://pkg.go.dev/github.com/godeps/gollama)
- **示例**：[examples/](examples/) 包含聊天、流式输出、向量、投机解码等示例
- **上游**：[llama.cpp](https://github.com/ggml-org/llama.cpp) 模型格式与引擎细节
- **英文版**：[README.md](README.md)

## 快速开始

```bash
# 克隆（包含子模块）
git clone --recurse-submodules https://github.com/godeps/gollama
cd gollama

# 下载测试模型
wget https://huggingface.co/Qwen/Qwen3-0.6B-GGUF/resolve/main/Qwen3-0.6B-Q8_0.gguf

# 运行示例（Linux）。macOS 请使用 DYLD_LIBRARY_PATH。
export LD_LIBRARY_PATH=$PWD/prebuilt/$(go env GOOS)_$(go env GOARCH)
go run ./examples/simple -m Qwen3-0.6B-Q8_0.gguf -p "Hello world" -n 50
```

## 预编译库

CPU 版本的预编译库位于 `prebuilt/<os>_<arch>`，已覆盖：

- linux/amd64
- linux/arm64
- darwin/amd64
- darwin/arm64
- windows/amd64

Go 构建默认会链接这些目录。如果你移动了动态库文件：

- **Linux**：设置 `LD_LIBRARY_PATH` 或将库文件放在可执行文件旁。
- **macOS**：将 `.dylib` 放在可执行文件旁（使用 `@loader_path` rpath）。
- **Windows**：将 `.dll` 放在 `.exe` 旁或加入 `PATH`。

如需重新构建并写入 `prebuilt/`，运行：

```bash
./scripts/build-prebuilt.sh
```

## 基础用法

```go
package main

import (
    "context"
    "fmt"
    llama "github.com/godeps/gollama"
)

func main() {
    // 加载模型权重（ModelOption：WithGPULayers、WithMLock 等）
    model, err := llama.LoadModel(
        "/path/to/model.gguf",
        llama.WithGPULayers(-1), // 将所有层卸载到 GPU
    )
    if err != nil {
        panic(err)
    }
    defer model.Close()

    // 创建执行上下文（ContextOption：WithContext、WithBatch 等）
    ctx, err := model.NewContext(
        llama.WithContext(2048),
        llama.WithF16Memory(),
    )
    if err != nil {
        panic(err)
    }
    defer ctx.Close()

    // Chat completion（使用模型的 chat template）
    messages := []llama.ChatMessage{
        {Role: "system", Content: "You are a helpful assistant."},
        {Role: "user", Content: "What is the capital of France?"},
    }
    response, err := ctx.Chat(context.Background(), messages, llama.ChatOptions{
        MaxTokens: llama.Int(100),
    })
    if err != nil {
        panic(err)
    }
    fmt.Println(response.Content)

    // 或者原始文本生成
    text, err := ctx.Generate("Hello world", llama.WithMaxTokens(50))
    if err != nil {
        panic(err)
    }
    fmt.Println(text)
}
```

构建时请设置以下环境变量：

```bash
export LIBRARY_PATH=$PWD C_INCLUDE_PATH=$PWD LD_LIBRARY_PATH=$PWD
```

## 主要能力

**文本生成与对话**：支持原生 chat completion（自动应用 chat template）与原始文本生成，亦可生成
embeddings 用于语义搜索、聚类与相似度计算。

**GPU 加速**：支持 NVIDIA（CUDA）、AMD（ROCm）、Apple Silicon（Metal）、Intel（SYCL）与跨平台
后端（Vulkan、OpenCL）。覆盖几乎所有现代 GPU，同时支持 RPC 分布式推理。

**面向生产**：接近 400 条测试用例与 CI 验证（包含 CUDA 构建）。持续跟进 llama.cpp 版本更新，
适合生产使用而非 demo 项目。

**高级特性**：模型/上下文分离可减少显存占用；可对常用 prompt 前缀进行缓存；单模型多上下文并发
推理；支持回调或缓冲通道的流式输出；支持投机解码以获得 2-3 倍的生成速度提升。

## 架构

库通过 CGO 连接 Go 与 C++，将 heavy computation 保持在 llama.cpp 的优化 C++ 中，同时提供整洁的 Go
API，最大化性能并降低 CGO 开销。

**模型/上下文分离**：模型权重（Model）与执行状态（Context）分开管理。模型只加载一次，可创建多
个不同配置的上下文，每个上下文独立维护 KV cache 与状态，用于并行推理。

关键组件：

- `wrapper.cpp`/`wrapper.h` - CGO 接口
- `model.go` - 模型加载与权重管理（线程安全）
- `context.go` - 推理上下文（每个 goroutine 一个）
- Go 侧完整的 godoc 注释
- `llama.cpp/` - 追踪上游的子模块

整体设计采用函数式选项（ModelOption/ContextOption），显式创建上下文确保线程安全，支持 KV cache
前缀复用以提升性能，并通过 cgo.Handle 实现安全的 Go-C 回调。

## 许可证

MIT

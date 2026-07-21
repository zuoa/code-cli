# code-cli

macOS 下 Claude Code 与 OpenAI Codex CLI 的增强包装脚本，支持代理、YOLO 模式、权限防护等常用场景。

## 包含脚本

| 脚本 | 安装后命令 | 说明 |
|------|-----------|------|
| `xclaude` | `claudex` / `xclaude` | Claude Code 的 bypass 模式包装 |
| `xcodex`  | `codexx`  / `xcodex`  | OpenAI Codex 的代理模式包装   |

---

## 快速安装（macOS）

**方式一：curl 一行命令安装（推荐）**

```bash
curl -fsSL https://raw.githubusercontent.com/zuoa/code-cli/main/install-macos.sh | bash
```

**方式二：克隆仓库后安装**

```bash
git clone https://github.com/zuoa/code-cli.git
cd code-cli
bash install-macos.sh
```

脚本会自动完成：

1. 检测并安装 Homebrew（如未安装）
2. 检测并安装 Node.js / npm（如未安装）
3. 全局安装 `@anthropic-ai/claude-code` 和 `@openai/codex`
4. 将包装脚本安装到 `~/.local/bin/`
5. 自动将 `~/.local/bin` 写入 shell 配置文件（`~/.zshrc` 等）

安装完成后，若当前终端还找不到命令，执行：

```bash
export PATH="$HOME/.local/bin:$PATH"
hash -r
```

---

## xclaude / claudex

以 `--dangerously-skip-permissions`（bypass / YOLO）模式运行 Claude Code 的包装脚本。

### 用法

```bash
claudex "帮我修复所有 lint 错误"
claudex -y "无人值守跑个重构任务"           # 跳过二次确认
claudex --proxy "需要代理时加这个"
claudex --safe "临时想用正常权限模式"
claudex --model opus "换个模型"
claudex --add-dir ../lib --add-dir ../apps  "跨目录协作"
claudex -- --permission-mode plan           # 原样透传 claude 原生参数
```

### 常用选项

| 选项 | 说明 |
|------|------|
| `-y` / `--yes` | 跳过危险模式的二次确认提示 |
| `--proxy` | 启用代理（默认不使用代理） |
| `--host HOST` | 指定代理主机（默认 `127.0.0.1`） |
| `--port PORT` | 指定代理端口（默认 `7897`） |
| `--type TYPE` | 代理协议：`http` / `socks5` / `socks5h`（默认 `socks5`） |
| `--model MODEL` | 指定 Claude 模型（`sonnet` / `opus` / `haiku` 等） |
| `--safe` | 不加 bypass，使用 Claude 的正常权限模式 |
| `--no-guard` | 关闭默认的 `--disallowedTools` 防护规则 |
| `--add-dir DIR` | 添加额外的工作目录（可重复使用） |
| `--` | 之后的参数原样透传给 `claude` |

### 环境变量

在 `~/.zshrc` 中设置可作为默认值：

```bash
export CLAUDEX_MODEL=sonnet          # 默认模型
export CLAUDEX_PROXY_HOST=127.0.0.1  # 代理主机
export CLAUDEX_PROXY_PORT=7897       # 代理端口
export CLAUDEX_PROXY_TYPE=socks5     # 代理协议
export CLAUDEX_NO_PROXY=localhost,127.0.0.1,::1
export CLAUDEX_SKIP_CONFIRM=1        # 始终跳过二次确认
```

### 安全设计

- **默认不使用代理**，仅在显式传 `--proxy` 时注入代理变量。
- **默认开启 `--disallowedTools` 防护**：即便在 bypass 模式下，仍拒绝 `rm -rf`、`rm -fr`、`sudo rm` 等毁灭性命令（`--disallowedTools` 是 bypass 模式下唯一仍然生效的安全阀）。
- **危险模式二次确认**：首次运行前打印醒目警告，需手动确认，防止手滑。

---

## xcodex / codexx

通过本地代理运行 OpenAI Codex CLI 的包装脚本。

### 用法

```bash
codexx "写一个快速排序"
codexx --port 7890 "帮我重构这个函数"
codexx --no-proxy "本地任务，不走代理"
codexx --check                        # 仅测试代理连通性，不运行 codex
```

### 常用选项

| 选项 | 说明 |
|------|------|
| `--host HOST` | 代理主机（默认 `127.0.0.1`） |
| `--port PORT` | 代理端口（默认 `7897`） |
| `--type TYPE` | 代理协议：`http` / `socks5` / `socks5h`（默认 `socks5`） |
| `--no-proxy` | 不使用代理，直接运行 codex |
| `--check` | 仅检测代理连通性，不启动 codex |
| `--model MODEL` | 指定 codex 模型 |
| `--` | 之后的参数原样透传给 `codex` |

### 环境变量

```bash
export CODEXX_PROXY_HOST=127.0.0.1
export CODEXX_PROXY_PORT=7897
export CODEXX_PROXY_TYPE=socks5
export CODEXX_NO_PROXY=localhost,127.0.0.1,::1
export CODEXX_MODEL=                  # 默认传给 codex 的 --model 参数
```

### 设计要点

- 代理变量仅在 codex 子进程中生效，不污染当前交互 shell。
- 大小写代理变量均设置，兼容不同工具。
- 运行前做轻量连通性检测，代理不可达时给出清晰提示，而不是让 codex 卡死。

---

## 前置依赖

- macOS（`install-macos.sh` 仅支持 macOS）
- Node.js >= 18 / npm（安装脚本会自动安装）
- `@anthropic-ai/claude-code`（安装脚本会自动安装）
- `@openai/codex`（安装脚本会自动安装）

---

## License

MIT

# code-cli

macOS 下 Claude Code、OpenAI Codex 与 Grok Build CLI 的增强包装脚本，支持代理、YOLO 模式、权限防护等常用场景。

## 包含脚本

| 脚本 | 安装后命令 | 说明 |
|------|-----------|------|
| `xclaude` | `xclaude` | Claude Code 的 bypass 模式包装 |
| `xcodex`  | `xcodex`  | OpenAI Codex 的代理模式包装   |
| `xgrok`   | `xgrok`   | Grok Build 的 YOLO / 代理包装 |

---

## 快速安装（macOS）

**方式一：curl 一行命令安装（推荐）**

```bash
curl -fsSL https://raw.githubusercontent.com/zuoa/code-cli/main/install-macos.sh | bash
```

curl pipe 模式下，安装脚本会自动从 GitHub 下载 `xclaude` / `xcodex` / `xgrok` 包装脚本，无需克隆仓库。

**方式二：克隆仓库后安装**

```bash
git clone https://github.com/zuoa/code-cli.git
cd code-cli
bash install-macos.sh
```

脚本会自动完成：

1. 检测并安装 Homebrew（如未安装）
2. 检测并安装 Node.js / npm（如未安装）
3. 全局安装 `@anthropic-ai/claude-code` 和 `@openai/codex`（已安装则跳过）
4. 通过官方脚本安装 Grok Build CLI（已安装则跳过）
5. 将包装脚本安装到 `~/.local/bin/`
6. 自动将 `~/.local/bin`（以及 `~/.grok/bin`）写入 shell 配置文件（`~/.zshrc` 等）

> **自定义安装目录**：可通过 `INSTALL_ROOT` 环境变量覆盖默认的 `~/.local`，例如：
> ```bash
> INSTALL_ROOT=/usr/local curl -fsSL https://raw.githubusercontent.com/zuoa/code-cli/main/install-macos.sh | bash
> ```

安装完成后，若当前终端还找不到命令，执行：

```bash
export PATH="$HOME/.local/bin:$PATH"
hash -r
```

---

## xclaude

以 `--dangerously-skip-permissions`（bypass / YOLO）模式运行 Claude Code 的包装脚本。

### 用法

```bash
xclaude "帮我修复所有 lint 错误"
xclaude -y "无人值守跑个重构任务"           # 跳过二次确认
xclaude --proxy "需要代理时加这个"
xclaude --safe "临时想用正常权限模式"
xclaude --model opus "换个模型"
xclaude --add-dir ../lib --add-dir ../apps  "跨目录协作"
xclaude -- --permission-mode plan           # 原样透传 claude 原生参数
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

## xcodex

通过本地代理运行 OpenAI Codex CLI 的包装脚本。

### 用法

```bash
xcodex "写一个快速排序"
xcodex --port 7890 "帮我重构这个函数"
xcodex --no-proxy "本地任务，不走代理"
xcodex --check                        # 仅测试代理连通性，不运行 codex
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

## xgrok

以 `--always-approve`（YOLO）模式运行 Grok Build，并默认走本地代理的包装脚本。

### 用法

```bash
xgrok "帮我修复所有 lint 错误"
xgrok -y "无人值守跑个重构任务"           # 跳过二次确认
xgrok --no-proxy "本地能直连 xAI 时用"
xgrok --safe "临时想用正常权限模式"
xgrok --model grok-4.6 "换个模型"
xgrok --check                            # 仅测试代理连通性，不运行 grok
xgrok login                              # 子命令原样透传（仍走代理）
xgrok -- --permission-mode auto          # 原样透传 grok 原生参数
```

### 常用选项

| 选项 | 说明 |
|------|------|
| `-y` / `--yes` / `--yolo` | 跳过危险模式的二次确认提示 |
| `--proxy` | 显式启用代理（默认已启用） |
| `--host HOST` | 指定代理主机（默认 `127.0.0.1`） |
| `--port PORT` | 指定代理端口（默认 `7897`） |
| `--type TYPE` | 代理协议：`http` / `socks5` / `socks5h`（默认自动检测） |
| `--no-proxy` | 不使用代理，直接运行 grok |
| `--check` | 仅检测代理连通性，不启动 grok |
| `--model` / `-m` MODEL | 指定 Grok 模型（`grok-4.6` / `grok-4.5` / `grok-build` 等） |
| `--cwd DIR` | 指定工作目录（传给 grok `--cwd`） |
| `--safe` | 不加 always-approve，使用 Grok 的正常权限模式 |
| `--no-guard` | 关闭默认的 `--deny` 防护规则 |
| `--` | 之后的参数原样透传给 `grok` |

### 环境变量

```bash
export GROKX_MODEL=grok-4.6          # 默认模型
export GROKX_PROXY_HOST=127.0.0.1    # 代理主机
export GROKX_PROXY_PORT=7897         # 代理端口
export GROKX_PROXY_TYPE=socks5       # 代理协议；不设则自动检测
export GROKX_NO_PROXY=localhost,127.0.0.1,::1
export GROKX_SKIP_CONFIRM=1          # 始终跳过二次确认
```

### 设计要点

- **默认使用代理**（与 `xcodex` 一致），未指定 `--type` 时先试 socks5，再回退 http。
- **默认开启 `--always-approve`**。首次运行前打印醒目警告，需手动确认；`login` / `models` / `update` 等子命令会跳过 YOLO 与确认。
- **默认开启 `--deny` 防护**：即便 always-approve，仍拒绝 `rm -rf`、`rm -fr`、`sudo rm` 等毁灭性命令。
- 代理变量仅在 grok 子进程中生效，不污染当前交互 shell。
- 若 PATH 里没有 `grok`，会回退查找 `~/.grok/bin/grok`。

---

## 前置依赖

- macOS（`install-macos.sh` 仅支持 macOS）
- Node.js >= 18 / npm（安装脚本会自动安装）
- `@anthropic-ai/claude-code`（安装脚本会自动安装）
- `@openai/codex`（安装脚本会自动安装）
- Grok Build CLI（安装脚本会通过官方 `https://x.ai/cli/install.sh` 安装）

---

## License

MIT

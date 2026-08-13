#!/usr/bin/env bash

set -euo pipefail

# When the script is piped via `curl | bash`, BASH_SOURCE[0] is unset.
# Fall back to an empty string so dirname returns ".", then resolve to pwd.
_src="${BASH_SOURCE[0]:-}"
if [[ -n "$_src" && -f "$_src" ]]; then
  SCRIPT_DIR="$(cd -- "$(dirname -- "$_src")" && pwd)"
else
  SCRIPT_DIR=""
fi
unset _src

REPO_RAW="https://raw.githubusercontent.com/zuoa/code-cli/main"
INSTALL_ROOT="${INSTALL_ROOT:-$HOME/.local}"
BIN_DIR="${INSTALL_ROOT}/bin"
CLAUDE_PACKAGE="@anthropic-ai/claude-code"
CODEX_PACKAGE="@openai/codex"
GROK_INSTALL_URL="https://x.ai/cli/install.sh"
GROK_BIN="${HOME}/.grok/bin/grok"

log() {
  printf '[install-macos] %s\n' "$*"
}

fail() {
  printf '[install-macos] %s\n' "$*" >&2
  exit 1
}

require_macos() {
  [[ "$(uname -s)" == "Darwin" ]] || fail '该脚本仅支持 macOS。'
}

ensure_homebrew() {
  if command -v brew >/dev/null 2>&1; then
    return
  fi

  log '未检测到 Homebrew，开始安装...'
  NONINTERACTIVE=1 /bin/bash -c \
    "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  else
    fail 'Homebrew 安装完成，但未找到 brew 命令。'
  fi
}

ensure_node_and_npm() {
  if command -v node >/dev/null 2>&1 && command -v npm >/dev/null 2>&1; then
    return
  fi

  ensure_homebrew
  log '未检测到 Node.js/npm，开始通过 Homebrew 安装 node...'
  brew list node >/dev/null 2>&1 || brew install node
}

install_cli_packages() {
  mkdir -p "$BIN_DIR"
  local need_claude=1 need_codex=1
  if command -v claude >/dev/null 2>&1; then
    log "检测到 claude 已安装，跳过安装 ${CLAUDE_PACKAGE}"
    need_claude=0
  fi
  if command -v codex >/dev/null 2>&1; then
    log "检测到 codex 已安装，跳过安装 ${CODEX_PACKAGE}"
    need_codex=0
  fi
  if [[ $need_claude -eq 1 || $need_codex -eq 1 ]]; then
    local pkgs=()
    [[ $need_claude -eq 1 ]] && pkgs+=("$CLAUDE_PACKAGE")
    [[ $need_codex -eq 1 ]] && pkgs+=("$CODEX_PACKAGE")
    log "安装 ${pkgs[*]} 到 ${INSTALL_ROOT} ..."
    npm install --global --prefix "$INSTALL_ROOT" "${pkgs[@]}"
  fi

  if command -v grok >/dev/null 2>&1 || [[ -x "$GROK_BIN" ]]; then
    log '检测到 grok 已安装，跳过安装 Grok Build'
    return
  fi
  log '未检测到 grok，开始安装 Grok Build CLI...'
  curl -fsSL "$GROK_INSTALL_URL" | bash
  if ! command -v grok >/dev/null 2>&1 && [[ ! -x "$GROK_BIN" ]]; then
    fail 'Grok Build 安装完成，但未找到 grok 命令。'
  fi
}

fetch_wrapper() {
  local name="$1"
  local dest="${BIN_DIR}/${name}"
  local local_src="${SCRIPT_DIR}/${name}"

  if [[ -n "$SCRIPT_DIR" && -f "$local_src" ]]; then
    install -m 0755 "$local_src" "$dest"
  else
    log "从 GitHub 下载 ${name} ..."
    curl -fsSL "${REPO_RAW}/${name}" -o "$dest"
    chmod 0755 "$dest"
  fi
}

install_wrappers() {
  install -d "$BIN_DIR"

  fetch_wrapper xclaude
  fetch_wrapper xcodex
  fetch_wrapper xgrok
}

detect_profile() {
  local candidate
  for candidate in \
    "${HOME}/.zprofile" \
    "${HOME}/.zshrc" \
    "${HOME}/.bash_profile" \
    "${HOME}/.bashrc" \
    "${HOME}/.profile"; do
    if [[ -f "$candidate" ]]; then
      printf '%s\n' "$candidate"
      return
    fi
  done

  printf '%s\n' "${HOME}/.zprofile"
}

ensure_path_dir() {
  local dir="$1"
  local profile export_dir line

  if printf ':%s:' "$PATH" | grep -Fq ":${dir}:"; then
    return
  fi

  case "$dir" in
    "${HOME}"/*) export_dir="\$HOME/${dir#"${HOME}/"}" ;;
    *) export_dir="$dir" ;;
  esac

  profile="$(detect_profile)"
  line="export PATH=\"${export_dir}:\$PATH\""

  touch "$profile"
  if ! grep -Fqx "$line" "$profile"; then
    printf '\n%s\n' "$line" >> "$profile"
    log "已将 ${dir} 写入 PATH: ${profile}"
  fi
}

ensure_path() {
  ensure_path_dir "$BIN_DIR"
  if [[ -x "$GROK_BIN" ]]; then
    ensure_path_dir "$(dirname "$GROK_BIN")"
  fi
}

print_summary() {
  cat <<EOF

安装完成：
  - claude   -> ${BIN_DIR}/claude
  - codex    -> ${BIN_DIR}/codex
  - grok     -> ${GROK_BIN}
  - xclaude  -> ${BIN_DIR}/xclaude
  - xcodex   -> ${BIN_DIR}/xcodex
  - xgrok    -> ${BIN_DIR}/xgrok

如果当前终端还找不到命令，请执行：
  export PATH="${BIN_DIR}:\$PATH"
  hash -r
EOF
}

main() {
  require_macos
  ensure_node_and_npm
  install_cli_packages
  install_wrappers
  ensure_path
  print_summary
}

main "$@"

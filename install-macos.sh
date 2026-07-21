#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_ROOT="${INSTALL_ROOT:-$HOME/.local}"
BIN_DIR="${INSTALL_ROOT}/bin"
CLAUDE_PACKAGE="@anthropic-ai/claude-code"
CODEX_PACKAGE="@openai/codex"

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
  log "安装 ${CLAUDE_PACKAGE} 和 ${CODEX_PACKAGE} 到 ${INSTALL_ROOT} ..."
  npm install --global --prefix "$INSTALL_ROOT" "$CLAUDE_PACKAGE" "$CODEX_PACKAGE"
}

install_wrappers() {
  [[ -f "${SCRIPT_DIR}/xclaude" ]] || fail "未找到 ${SCRIPT_DIR}/xclaude"
  [[ -f "${SCRIPT_DIR}/xcodex" ]] || fail "未找到 ${SCRIPT_DIR}/xcodex"

  install -d "$BIN_DIR"
  install -m 0755 "${SCRIPT_DIR}/xclaude" "${BIN_DIR}/claudex"
  install -m 0755 "${SCRIPT_DIR}/xcodex" "${BIN_DIR}/codexx"
  ln -sfn claudex "${BIN_DIR}/xclaude"
  ln -sfn codexx "${BIN_DIR}/xcodex"
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

ensure_path() {
  local profile export_dir line

  case "$BIN_DIR" in
    "${HOME}"/*) export_dir="\$HOME/${BIN_DIR#"${HOME}/"}" ;;
    *) export_dir="$BIN_DIR" ;;
  esac

  if printf ':%s:' "$PATH" | grep -Fq ":${BIN_DIR}:"; then
    return
  fi

  profile="$(detect_profile)"
  line="export PATH=\"${export_dir}:\$PATH\""

  touch "$profile"
  if ! grep -Fqx "$line" "$profile"; then
    printf '\n%s\n' "$line" >> "$profile"
    log "已将 ${BIN_DIR} 写入 PATH: ${profile}"
  fi
}

print_summary() {
  cat <<EOF

安装完成：
  - claude   -> ${BIN_DIR}/claude
  - codex    -> ${BIN_DIR}/codex
  - claudex  -> ${BIN_DIR}/claudex
  - codexx   -> ${BIN_DIR}/codexx
  - xclaude  -> ${BIN_DIR}/xclaude
  - xcodex   -> ${BIN_DIR}/xcodex

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

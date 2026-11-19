#!/bin/bash
# 一键安装：百炼用量圆环（SwiftBar 菜单栏插件）
#   curl -fsSL https://raw.githubusercontent.com/Dr1ll1/bailian-usage-monitor/main/install.sh | bash
# 可选环境变量：
#   MODEL=qwen-plus        指定要显示的模型（默认自动选最近 7 天用得最多的）
#   WITH_TERMINAL=1        同时把终端版监控放到桌面
set -e
REPO_RAW="https://raw.githubusercontent.com/Dr1ll1/bailian-usage-monitor/main"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd || echo "")"
say() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m!!\033[0m %s\n' "$*"; }

[ "$(uname)" = "Darwin" ] || { echo "只支持 macOS"; exit 1; }
export PATH="$HOME/.local/bin:/opt/homebrew/bin:/usr/local/bin:$PATH"

# 1. 百炼 CLI
if ! command -v bl >/dev/null 2>&1; then
  say "安装阿里云官方百炼 CLI（bl）…"
  curl -fsSL https://bailian.aliyun.com/cli/install.sh | bash
  export PATH="$HOME/.local/bin:$PATH"
fi
if ! bl usage free >/dev/null 2>&1; then
  say "需要登录阿里云（会打开浏览器授权）…"
  bl auth login --console </dev/tty || warn "登录没完成，稍后可以手动运行：bl auth login --console"
fi

# 2. SwiftBar
if [ ! -d /Applications/SwiftBar.app ]; then
  if command -v brew >/dev/null 2>&1; then
    say "用 Homebrew 安装 SwiftBar…"
    brew install --cask swiftbar
  else
    say "从 GitHub 下载 SwiftBar…"
    U=$(curl -fsSL https://api.github.com/repos/swiftbar/SwiftBar/releases/latest | grep -o 'https://[^"]*\.zip' | head -1)
    curl -fL "$U" -o /tmp/SwiftBar.zip && ditto -xk /tmp/SwiftBar.zip /Applications && rm -f /tmp/SwiftBar.zip
  fi
fi

# 3. 插件目录
DIR=$(defaults read com.ameba.SwiftBar PluginDirectory 2>/dev/null || true)
DIR="${DIR/#\~/$HOME}"
if [ -z "$DIR" ]; then
  DIR="$HOME/SwiftBar"
  defaults write com.ameba.SwiftBar PluginDirectory "$DIR" 2>/dev/null || true
fi
mkdir -p "$DIR"

# 4. 插件本体
DEST="$DIR/bailian.5m.sh"
if [ -n "$HERE" ] && [ -f "$HERE/swiftbar/bailian.5m.sh" ]; then
  cp "$HERE/swiftbar/bailian.5m.sh" "$DEST"
else
  curl -fsSL "$REPO_RAW/swiftbar/bailian.5m.sh" -o "$DEST"
fi
if [ -n "$MODEL" ]; then sed -i '' "s|^MODEL=\"\"|MODEL=\"$MODEL\"|" "$DEST"; fi
chmod +x "$DEST"
say "插件已放到：$DEST"

# 5. 终端版（可选）
if [ "${WITH_TERMINAL:-0}" = "1" ]; then
  T="$HOME/Desktop/百炼用量.command"
  if [ -n "$HERE" ] && [ -f "$HERE/terminal/bailian-usage.command" ]; then cp "$HERE/terminal/bailian-usage.command" "$T"
  else curl -fsSL "$REPO_RAW/terminal/bailian-usage.command" -o "$T"; fi
  if [ -n "$MODEL" ]; then sed -i '' "s|^MODEL=\"\"|MODEL=\"$MODEL\"|" "$T"; fi
  chmod +x "$T"; say "终端版已放到桌面：百炼用量.command"
fi

# 6. 启动并刷新
open -a SwiftBar 2>/dev/null || open /Applications/SwiftBar.app
sleep 2; open -g "swiftbar://refreshallplugins" 2>/dev/null || true
say "完成 ✅ 菜单栏应该出现圆环了。"
echo "   如果 SwiftBar 第一次启动时让你选插件文件夹，请选：$DIR"

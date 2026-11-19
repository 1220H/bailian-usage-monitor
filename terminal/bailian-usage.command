#!/bin/bash
# 百炼用量监控（终端版）：双击打开，显示免费额度余量和最近几天的 token 用量，自动刷新。
# 依赖阿里云官方百炼 CLI（bl）：先安装并执行一次 bl auth login --console

# ====== 可以按需修改 ======
MODEL=""        # 只看这个模型；留空 = 自动选最近 7 天用得最多的模型
DAYS=7          # 统计最近几天
REFRESH=120     # 自动刷新间隔（秒）
# ==========================

export PATH="$HOME/.local/bin:$HOME/.bailian/bin:/opt/homebrew/bin:/usr/local/bin:$PATH"
printf '\e[8;32;104t'; printf '\e]0;百炼用量\a'
B=$'\e[1m'; D=$'\e[2m'; R=$'\e[31m'; Y=$'\e[33m'; N=$'\e[0m'

if ! command -v bl >/dev/null 2>&1; then
  echo "${R}没有找到百炼 CLI（bl）${N}"
  echo "安装：curl -fsSL https://bailian.aliyun.com/cli/install.sh | bash"
  echo "登录：bl auth login --console"
  read -n 1 -s -p "按任意键关闭…"; exit 1
fi
need_login() { echo "$1" | grep -qiE 'not logged|unauthori|auth.*(fail|expire|invalid)|未登录|鉴权|过期'; }

if [ -z "$MODEL" ]; then
  MODEL=$(bl usage stats --days 7 2>&1 | sed $'s/\x1b\\[[0-9;]*[A-Za-z]//g' \
    | awk '/^[[:space:]]*[-─━]{5,}/{f=1; next} f && NF && $1 !~ /^Total/ {print $1; exit}')
fi

while true; do
  M=(); [ -n "$MODEL" ] && M=(--model "$MODEL")
  FREE=$(bl usage free "${M[@]}" 2>&1)
  STATS=$(bl usage stats --days "$DAYS" "${M[@]}" 2>&1)
  clear
  echo "${B}🪙 百炼用量${N}  ${D}${MODEL:-全部模型} · 更新于 $(date '+%H:%M:%S') · 每 ${REFRESH} 秒自动刷新${N}"
  echo "${D}按 R 立即刷新 · 按 Q 退出${N}"; echo
  echo "${Y}━━━━━━━━ 免费额度余量 ━━━━━━━━${N}"; echo "$FREE"; echo
  echo "${Y}━━━━━━━━ 最近 ${DAYS} 天用量 ━━━━━━━━${N}"; echo "$STATS"
  if need_login "$FREE$STATS"; then echo; echo "${R}登录可能过期了，请在终端运行：bl auth login --console${N}"; fi
  read -t "$REFRESH" -n 1 -s key
  case "$key" in q|Q) clear; exit 0;; esac
done

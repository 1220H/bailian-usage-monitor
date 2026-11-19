#!/bin/bash
# <xbar.title>百炼用量圆环 Bailian Usage Ring</xbar.title>
# <xbar.version>v1.0</xbar.version>
# <xbar.desc>在 macOS 菜单栏用圆环显示阿里云百炼模型的免费额度余量，点开查看今天 / 最近 7 天的 token 用量。依赖官方百炼 CLI（bl）。</xbar.desc>
# <xbar.dependencies>bl (Alibaba Cloud Model Studio CLI)</xbar.dependencies>
# <xbar.abouturl>__REPO_URL__</xbar.abouturl>
# <swiftbar.hideRunInTerminal>true</swiftbar.hideRunInTerminal>
# <swiftbar.hideDisablePlugin>true</swiftbar.hideDisablePlugin>

# ====== 可以按需修改 ======
MODEL=""                           # 要显示的模型名；留空 = 自动选最近 7 天用得最多的模型
                                   # 想同时看多个模型：复制本文件（改个文件名），分别填不同的模型名
SHOW_TEXT=1                        # 圆环旁边显示百分比：1 显示，0 只显示圆环
# 文件名里的 .5m. 表示每 5 分钟刷新一次，可改成 .2m. / .10m. 等
# ==========================

export PATH="$HOME/.local/bin:$HOME/.bailian/bin:/opt/homebrew/bin:/usr/local/bin:$PATH"
export COLUMNS=220 NO_COLOR=1 TERM=dumb
CONSOLE="https://bailian.console.aliyun.com/"

strip() { sed -e $'s/\x1b\\[[0-9;]*[A-Za-z]//g' -e 's/│/ /g' -e 's/┃/ /g' -e 's/|/ /g'; }
# 从一行里去掉模型名后，按顺序取出所有数字（带千分位逗号的整数或小数）
nums() { awk -v m="$MODEL" '{ i=index($0,m); if(i) $0=substr($0,1,i-1) substr($0,i+length(m)); while (match($0,/[0-9][0-9,]*(\.[0-9]+)?/)) { v=substr($0,RSTART,RLENGTH); gsub(",","",v); printf "%s ", v; $0=substr($0,RSTART+RLENGTH) } }'; }
fmt() { awk -v n="$1" 'BEGIN{ s=sprintf("%d",n); r=""; while(length(s)>3){ r="," substr(s,length(s)-2) r; s=substr(s,1,length(s)-3) } print s r }'; }
wan() { awk -v n="$1" 'BEGIN{ if(n>=10000) printf "%.1f 万", n/10000; else printf "%d", n }'; }

main() {
  if ! command -v bl >/dev/null 2>&1; then
    echo "⚠︎ bl"; echo "---"; echo "没有找到百炼 CLI（bl），请先安装 | color=red"; exit 0
  fi

  if [ -z "$MODEL" ]; then
    # 自动：取最近 7 天用量表里的第一个模型（表头分隔线之后的第一行）
    MODEL=$(bl usage stats --days 7 2>&1 | strip | awk '/^[[:space:]]*[-─━]{5,}/{f=1; next} f && NF && $1 !~ /^Total/ {print $1; exit}')
  fi
  if [ -z "$MODEL" ]; then
    echo "◌ | size=12"; echo "---"
    echo "最近 7 天没有调用记录 | color=gray"
    echo "可以在插件文件开头手动填写 MODEL= | color=gray size=11"
    echo "打开百炼控制台 | href=$CONSOLE"; exit 0
  fi

  FREE=$(bl usage free --model "$MODEL" 2>&1 | strip)
  TODAY=$(bl usage stats --days 1 --model "$MODEL" 2>&1 | strip)
  WEEK=$(bl usage stats --days 7 --model "$MODEL" 2>&1 | strip)

  # 取模型那一行，连同下一行（窄窗口时表格会折行）
  row=$(echo "$FREE" | awk -v m="$MODEL" 'f{print; exit} index($0,m){printf "%s ", $0; f=1}')
  read -r REMAIN TOTAL _ <<< "$(echo "$row" | nums)"
  AUTOSTOP=$(echo "$row" | awk '{for(i=1;i<=NF;i++) if($i=="ON"||$i=="OFF") a=$i} END{print a}')

  if [ -n "$REMAIN" ] && [ -n "$TOTAL" ] && [ "$TOTAL" -gt 0 ] 2>/dev/null; then
    PCT=$(awk -v r="$REMAIN" -v t="$TOTAL" 'BEGIN{ printf "%.1f", r*100/t }')
    IDX=$(awk -v r="$REMAIN" -v t="$TOTAL" 'BEGIN{ i=int(r*20/t+0.5); if(i<0)i=0; if(i>20)i=20; if(r>0&&i==0)i=1; print i }')
    TITLE=""; [ "$SHOW_TEXT" = "1" ] && TITLE="${PCT%.*}%"
    echo "${TITLE} | image=${RING_L[$IDX]},${RING_D[$IDX]} size=12"
  else
    echo "— | image=${RING_L[0]},${RING_D[0]} size=12"
  fi

  echo "---"
  echo "百炼免费额度 | size=12 color=gray"
  echo "$MODEL | font=Menlo size=12"
  if [ -n "$PCT" ]; then
    echo "剩余 $(fmt "$REMAIN") / $(fmt "$TOTAL") token（${PCT}%）"
    if [ "$AUTOSTOP" = "OFF" ]; then
      echo "⚠︎ 用完即停：未开启（用完会扣余额） | color=#d9534f href=$CONSOLE"
    elif [ "$AUTOSTOP" = "ON" ]; then
      echo "✓ 用完即停：已开启 | color=#2e9e5b"
    fi
  elif echo "$FREE" | grep -qiE 'login|auth|unauthori|登录|鉴权|过期'; then
    echo "登录可能过期了，请在终端运行 bl auth login --console | color=#d9534f"
  else
    echo "没有查到这个模型的免费额度（可能已用完或过期） | color=gray"
  fi

  echo "---"
  for period in "今天:TODAY" "最近 7 天:WEEK"; do
    label=${period%%:*}; var=${period##*:}; data=${!var}
    srow=$(echo "$data" | grep -F "$MODEL" | head -1)
    read -r CALLS TOT IN OUT CACHE <<< "$(echo "$srow" | nums)"
    if [ -n "$TOT" ]; then
      echo "${label}：$(wan "$TOT") token · ${CALLS} 次调用"
      echo "--输入 $(fmt "$IN")"
      echo "--输出 $(fmt "$OUT")"
      [ -n "$CACHE" ] && echo "--缓存命中 $(fmt "$CACHE")"
    else
      echo "${label}：0 token | color=gray"
    fi
  done

  echo "---"
  echo "更新于 $(date '+%H:%M') · 控制台数据为分钟级更新 | size=11 color=gray"
  echo "立即刷新 | refresh=true"
  echo "打开百炼控制台 | href=$CONSOLE"
}

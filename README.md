# 🪙 百炼用量圆环 · Bailian Usage Ring

在 macOS **菜单栏**用一个小圆环显示阿里云百炼（Model Studio）模型的**免费额度余量**，点开就能看到今天和最近 7 天的 token 用量，不用再登录控制台查看。

```
菜单栏：  ◔ 65%
点开后：
  百炼免费额度
  deepseek-v4.1-flash-1017
  剩余 654,935 / 1,000,000 token（65.5%）
  ⚠︎ 用完即停：未开启（用完会扣余额）
  ─────────────
  今天：11.7 万 token · 199 次调用   ▸ 输入 / 输出 / 缓存命中
  最近 7 天：34.5 万 token · 675 次调用
  ─────────────
  立即刷新 · 打开百炼控制台
```

- 圆环颜色随剩余额度变化：🟢 50% 以上，🟠 20%～50%，🔴 20% 以下。浅色和深色菜单栏各有一套配色。
- 默认每 5 分钟刷新一次。改文件名里的 `.5m.` 就能调整间隔，比如 `.2m.`、`.10m.`。
- 默认自动显示**最近 7 天用得最多的模型**，也可以手动指定。想同时看多个模型，就把插件复制几份。
- 「用完即停」没开时会标红提醒，点一下直接打开控制台。
- 数据来自阿里云官方 [百炼 CLI](https://help.aliyun.com/zh/model-studio/cli/)（`bl usage free` / `bl usage stats`）。插件只在本机运行，不会把任何信息发到别处。

> 第三方工具，与阿里云官方无关。

## 安装

### 一键安装

```bash
curl -fsSL https://raw.githubusercontent.com/1220H/bailian-usage-monitor/main/install.sh | bash
```

这个脚本会依次完成：
1. 如果还没装 `bl`，安装官方百炼 CLI，并打开浏览器让你登录阿里云（`bl auth login --console`）。
2. 如果还没装 [SwiftBar](https://github.com/swiftbar/SwiftBar)，安装它。有 Homebrew 就用 Homebrew，没有就从 GitHub 下载。
3. 把插件放进 SwiftBar 的插件文件夹，然后启动 SwiftBar。

可选参数：

```bash
# 指定模型，同时把终端版监控放到桌面
curl -fsSL https://raw.githubusercontent.com/1220H/bailian-usage-monitor/main/install.sh | MODEL=qwen-plus WITH_TERMINAL=1 bash
```

### 手动安装

1. 安装百炼 CLI 并登录：
   ```bash
   curl -fsSL https://bailian.aliyun.com/cli/install.sh | bash
   bl auth login --console
   ```
2. 安装 SwiftBar（`brew install --cask swiftbar`，或者从 GitHub 下载）。第一次启动时，选一个插件文件夹，比如 `~/SwiftBar`。
3. 把 `swiftbar/bailian.5m.sh` 放进这个文件夹，然后运行 `chmod +x`。

## 终端版

`terminal/bailian-usage.command` 是一个不依赖 SwiftBar 的版本。双击后会打开一个终端小窗口，显示 bl 输出的完整表格，每 2 分钟自动刷新。按 R 立即刷新，按 Q 退出。

> 如果是从浏览器下载的，第一次运行前要先执行：`chmod +x bailian-usage.command; xattr -c bailian-usage.command`

## 设置

两个脚本开头都有几项设置，用文本编辑器打开就能改：

| 设置项 | 作用 |
|---|---|
| `MODEL=""` | 要显示的模型名。留空表示自动选择。 |
| `SHOW_TEXT=1` | 设为 0 时，菜单栏只显示圆环，不显示百分比。 |
| `DAYS` / `REFRESH` | 仅终端版：统计天数和刷新间隔。 |

## 关于免费额度的小知识

- 百炼的扣费顺序是：**免费额度 → 资源包 → 节省计划 → 按量付费**。
- 免费额度是**按模型分别计算的**，带日期的快照版本也单独算一份。一个模型的额度用完后，可以换另一个模型继续用。用 `bl usage free --all --sort remaining` 能看到哪些模型还有额度。
- 建议在控制台打开「**免费额度用完即停**」，这样免费额度用完时会直接停下，避免意外扣费。

## 开发

修改 `tools/plugin.tpl.sh` 后运行：

```bash
pip install pillow
python3 tools/build_plugin.py   # 重新画圆环图标，生成 swiftbar/bailian.5m.sh
```

圆环图标是在构建时画好的：0%～100% 每隔 5% 一张，36px、144dpi（在 Retina 屏上显示为 18pt），以 base64 格式嵌进脚本。所以运行插件的电脑上不需要 Python 或任何图像库。

## English

A SwiftBar plugin that shows your **Alibaba Cloud Model Studio (Bailian)** free-tier quota as a ring in the macOS menu bar. Click it to see today's and the last 7 days' token usage. It is built on the official `bl` CLI and has no server and no tracking. Install with the one-liner above. Run `bl auth login --console` once to sign in.

## License

MIT

---

**Credits:** An idea of mine, turned into a working tool and refined together with Claude (Anthropic's AI assistant).

**致谢：** 这是我把自己的想法交给 Claude（Anthropic 的 AI 助手）之后，一起完善出来的小工具。

<div align="center">

<img src="assets/images/icon.png" alt="FlClashZ" width="100">

# FlClashZ

**适用于 Windows 的 Mihomo + Zapret 客户端**

[![Windows x64](https://img.shields.io/badge/Windows-x64-0078D4?style=flat-square&logo=windows)](https://github.com/geliopat/FlClashZ/releases/latest)
[![Release](https://img.shields.io/github/v/release/geliopat/FlClashZ?style=flat-square)](https://github.com/geliopat/FlClashZ/releases/latest)
[![Downloads](https://img.shields.io/github/downloads/geliopat/FlClashZ/total?style=flat-square)](https://github.com/geliopat/FlClashZ/releases)
[![License](https://img.shields.io/github/license/geliopat/FlClashZ?style=flat-square)](LICENSE)

[![下载安装版](https://img.shields.io/badge/%E4%B8%8B%E8%BD%BD%E5%AE%89%E8%A3%85%E7%89%88-EXE-0078D4?style=for-the-badge)](https://github.com/geliopat/FlClashZ/releases/latest/download/FlClashZ-windows-amd64-setup.exe) [![下载便携版](https://img.shields.io/badge/%E4%B8%8B%E8%BD%BD%E4%BE%BF%E6%90%BA%E7%89%88-ZIP-475569?style=for-the-badge)](https://github.com/geliopat/FlClashZ/releases/latest/download/FlClashZ-windows-amd64.zip)

[![v1.0.1 validated](https://img.shields.io/badge/v1.0.1-Windows%20validated-brightgreen?style=flat-square)](https://github.com/geliopat/FlClashZ/actions/runs/45790180974)

[订阅响应头](docs/headers.md) · [Zapret 设置](docs/flclashz-zapret-headers.md) · [同步](docs/upstream-sync.md)

[Русский](README.md) · [English](README_EN.md) · **中文**

</div>

FlClashZ 是 [FlClashX](https://github.com/pluralplay/FlClashX) 的独立分支，将基于 Mihomo 的代理客户端与 Zapret2 / Flowseal 管理集成在同一个应用中。当前面向 Windows x64，并兼容 Remnawave 订阅。它不是上游项目的官方客户端。

## 下载

稳定版 [1.0.1](https://github.com/geliopat/FlClashZ/releases/tag/v1.0.1) 已发布。安装版和便携版均已通过构建、启动、安装、运行中升级及与 FlClashX 隔离检查。

| 版本 | 格式 | 下载 |
| --- | --- | --- |
| Windows x64 安装版 | EXE | [FlClashZ-windows-amd64-setup.exe](https://github.com/geliopat/FlClashZ/releases/latest/download/FlClashZ-windows-amd64-setup.exe) |
| Windows x64 便携版 | ZIP | [FlClashZ-windows-amd64.zip](https://github.com/geliopat/FlClashZ/releases/latest/download/FlClashZ-windows-amd64.zip) |

建议使用安装版，以便通过应用安装更新。便携版解压到独立目录后运行 `FlClashZ.exe`，手动更新。当前发布目标为 Windows 10/11 x64，其他继承的平台不是当前发布目标。

## 功能

| Mihomo | Zapret |
| --- | --- |
| 订阅、本地配置及 YAML 编辑 | 集成 Zapret2 和 Flowseal |
| TUN、系统代理及路由规则 | 启动、停止和重启 |
| 代理组、DNS、连接及日志 | 内置 Lua/BAT 策略及导入 |
| 节点和代理组自动延迟测试 | 自动策略选择、历史及故障转移 |
| 配置覆盖和脚本 | 可用性诊断和列表更新 |

Mihomo 管理代理路由与 DNS，Zapret 按所选模式及策略能力工作。支持 STRICT SPLIT、FULL BYPASS、联动启动和自动恢复设置。

Windows 界面包含可自定义仪表盘、主题、玻璃卡片及亚克力托盘菜单。应用数据、Helper 服务和导入协议与 FlClashX 独立；免责声明确认保存在设置目录。

## 服务商集成

支持 Remnawave 标准订阅响应头、HWID，以及面板提供的 YAML 字段 `serverDescription`、`server-description` 和 `groupDescription`。自定义响应头使用 `flclashz-` 前缀，同时兼容旧的 `flclashx-*`，新名称优先。

```http
flclashz-view: app.theme:dark;app.glass:standard
flclashz-widgets: profiles,networkSpeed,networkTakeover,zapret
flclashz-zapret: autostart,mode:fullbypass,autofallback,autotune,tunemode:fast,tuneonfail
```

- [全部订阅响应头（俄语）](docs/headers.md)
- [Zapret 响应头（俄语）](docs/flclashz-zapret-headers.md)

安装版的订阅导入链接：

```text
flclashz://install-config?url=<URL 编码后的订阅地址>
```

## 更新

稳定版标签形如 `v1.0.1`。默认通过 [Latest 签名清单](https://github.com/geliopat/FlClashZ/releases/latest/download/manifest.json) 检查稳定版更新，其中包含版本、文件 URL、SHA-256 及 Ed25519 签名。指定版本的清单位于 `releases/download/v<版本>/manifest.json`。

安装程序在替换文件前结束正在运行的 FlClashZ，并保留设置。Windows CI 在发布前检查便携版启动、安装、运行中升级以及与 FlClashX 的隔离。

> [!IMPORTANT]
> 从 1.0.0 升级时，请手动覆盖安装 1.0.1 或更新版本：旧版本没有内置清单验证公钥。自 1.0.1 起已内置公钥。应用内更新与上游源码同步相互独立。

## 组件

| 组件 | 1.0.1 中的版本 | 来源 |
| --- | --- | --- |
| FlClashX（基础） | `0.5.8` | [pluralplay/FlClashX](https://github.com/pluralplay/FlClashX) |
| Mihomo（随 FlClashX 集成） | `v1.19.34` | [MetaCubeX/mihomo](https://github.com/MetaCubeX/mihomo) |
| Zapret2 | `v1.0.8` | [bol-van/zapret2](https://github.com/bol-van/zapret2) |
| Flowseal | `1.10.4` | [Flowseal/zapret-discord-youtube](https://github.com/Flowseal/zapret-discord-youtube) |
| Lua/BAT 策略 | `8dd17fcbcca4` | [geliopat/zapret2-gui](https://github.com/geliopat/zapret2-gui/tree/8dd17fcbcca405a50f497a6e2346ca263901d775) |

## 开发与同步

**仅手动同步。** `main` 是 FlClashX 的纯镜像；`fix/zapret2-stability` 是 FlClashZ 的开发分支。Mihomo 仅随 FlClashX 集成，包括其内核补丁和依赖。

[手动同步](https://github.com/geliopat/FlClashZ/actions/workflows/flclashz-upstream-sync.yml) 创建独立的 `sync/flclashz-*` 候选分支，检查 Zapret2 和 Flowseal 的固定版本，对本项目分支中的策略进行三方合并并记录冲突。无变化时跳过构建。合并和发布均由维护者另行决定。

[同步文档（俄语）](docs/upstream-sync.md) · [Windows 验证](https://github.com/geliopat/FlClashZ/actions/workflows/zapret-windows-validation.yml) · [发布工作流](https://github.com/geliopat/FlClashZ/actions/workflows/flclashz-release.yml)

## 从源码构建

需要 Flutter 3.47.6、Go 1.27.1、Rust（rustup）、带 C++ 桌面开发组件的 Visual Studio 以及 Inno Setup 6。

```powershell
git clone --branch fix/zapret2-stability https://github.com/geliopat/FlClashZ.git
cd FlClashZ
flutter pub get
./scripts/setup_zapret.ps1
dart setup.dart windows --env stable --arch amd64 --targets zip,exe -v
```

软件包位于 `dist/`。本地构建如需验证签名更新，需要通过 `FLCLASHZ_UPDATE_PUBLIC_KEY` 提供可信公钥。私钥保存在 GitHub Actions secrets 中，不进入源码。

[Windows 验证](https://github.com/geliopat/FlClashZ/actions/workflows/zapret-windows-validation.yml) · [发布工作流](https://github.com/geliopat/FlClashZ/actions/workflows/flclashz-release.yml)

## 致谢与许可证

分支维护者：[geliopat](https://github.com/geliopat)。保留上游作者及许可证信息：

- [FlClashX](https://github.com/pluralplay/FlClashX) — upstream client, pluralplay.
- [FlClash](https://github.com/chen08209/FlClash) — original client, chen08209.
- [Mihomo](https://github.com/MetaCubeX/mihomo)
- [Zapret2](https://github.com/bol-van/zapret2)
- [Flowseal](https://github.com/Flowseal/zapret-discord-youtube)
- [zapret2-gui](https://github.com/mqclass/zapret2-gui) / [strategy fork](https://github.com/geliopat/zapret2-gui)

[GPL-3.0](LICENSE)。第三方组件遵循其各自的许可条款。

[问题反馈](https://github.com/geliopat/FlClashZ/issues) · [版本历史](https://github.com/geliopat/FlClashZ/releases)

欢迎为项目点亮 ⭐。

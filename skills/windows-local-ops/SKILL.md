---
name: windows-local-ops
description: Windows 本地 Codex 任务的可靠 PowerShell 与 CLI 操作指南。涉及文件/日志读取、输出截断、中文编码、脚本运行、SSH/Codex 远程连接、命令路径、Python 环境和权限边界时使用；跨项目通用，与业务项目无关。
---

# Windows Local Operations

本 Skill 解决 **Windows 本地操作的可靠性问题**，不负责业务代码架构，也不要求每次先做全量环境扫描。当前任务的授权与工作范围仍以用户指令和适用的 `AGENTS.md` 为准。

## 执行前：确认真实环境

1. 区分本机 PowerShell、WSL、远端容器和 Codex 云沙盒。不要把沙盒结果当作 Windows 主机事实。
2. 必要时检查 `$PSVersionTable.PSVersion`、`(Get-Location).Path`、`Get-Command <tool> -All`、`where.exe <tool>`，使用经过确认的可执行文件。
3. Python 多环境时，确认 `py -0p`（若有）、`python -c "import sys; print(sys.executable)"` 和 `python -m pip --version`。始终通过选定的 Python 执行 `-m pip` / `-m pytest`。

## 文件与命令输出：**先界定范围，再读取**

1. 先搜目标：`Select-String` / `rg`（确认真实 `rg.exe` 可执行后）/ 文件元数据。不要直接倾倒整份大文件、完整 `pip list`、大 JSON、整个 `git diff` 或全量 kubectl 输出。
2. 优先读取少量相关行；文本可用 `scripts/Read-TextRange.ps1`，并检查输出**最后确实出现 `END_RANGE`** 以及其中的 `MORE` 与 `TRUNCATED`。若结束标记消失，视为执行工具输出再次截断，缩小范围重读。批量读取时逐段推进；即使文件读取完整，如果工具结果被截断，**仍不能宣称已完整检查**。
3. 区分 PowerShell 表格格式截断、命令输出工具截断、单行超长被主动限长、源文件本身不完整。加大 `Out-String -Width` 仅对第一种有效。
4. 对 JSON/CSV 使用结构化解析和精确字段选择，不依赖 `Format-Table` 或被省略的表格输出作为数据源。参考 [powershell-recipes.md](references/powershell-recipes.md)。

## 编码与路径

- 涉及中文文本时按文件原编码读取；对明确为 UTF-8 的文件显式使用 UTF-8。写 JSON/Markdown 通常用 UTF-8；Excel 中文 CSV 根据需要用 UTF-8 BOM。注意 Windows PowerShell 5.1 与 PowerShell 7 的编码默认行为不同。
- 如需临时初始化当前会话编码，才 dot-source `scripts/Set-Utf8Session.ps1`；**不要自动更改全局配置、注册表、PowerShell Profile 或所有命令的默认编码**。
- 对含空格、方括号等特殊字符的路径使用 `-LiteralPath`；使用 `Join-Path`，不要依赖某台电脑的固定盘符。

## 安全与失败处理

- 只在当前允许的工作区和权限内操作；遇到受限路径/沙盒权限，报告限制并申请必要授权，不尝试绕过。
- 对不存在、不可读或编码不明的文件，明确反馈，不能猜测或静默跳过；对非幂等写操作不要自动重试。
- 不因环境检查而擅自安装软件、修改 PATH、ExecutionPolicy、驱动、管理员权限或 Git 历史。若已审阅的仓库脚本仅因执行策略无法启动，可由用户明确触发一个独立 PowerShell 子进程并使用 `-ExecutionPolicy Bypass -File`；这不应修改系统或用户级策略。
- 结果说明具体是“已发现 / 已执行验证 / 未验证 / 失败”。
- 涉及 Kubernetes/Kubectl、集群 API 或监控数据采集，使用 `windows-kubectl-reliable-ops` 专项 Skill；不要把 `D:\kubectl` 等历史路径当作本机事实。

## SSH 与 Codex 远程连接

1. 按“网络路由 → SSH 握手 → 非交互认证 → 远端 Codex → 代理连通性 → App 进程”逐层定位；每次只验证一层，不把 SSH 可登录等同于远端 Codex 可用。
2. 先用 `ssh -G <host-alias>` 检查实际生效的用户、密钥、主机密钥策略、绑定地址和转发配置。基础 SSH 验证使用 `-o ClearAllForwardings=yes`，将连接/认证问题与端口转发隔离。
3. 多网卡、VPN 或 TUN 环境中，先收集实际源地址和路由证据；只有确认流量走错接口时，才为单一 Host 增加最小范围的 `BindAddress`。不要以全局路由修改替代诊断。
4. Codex App 使用的 SSH Host 不应携带 `RemoteForward`。若远端需经本地代理访问网络，使用独立的隧道 Host，避免 App 的并发 SSH 会话争用同一远端监听端口。
5. 远端前置条件须分别确认：主机密钥已信任、目标用户可用公钥非交互登录、登录 shell 的 `PATH` 能找到 `codex`、Codex 已登录、以及所需代理路径可访问。详见 [ssh-codex-remote-troubleshooting.md](references/ssh-codex-remote-troubleshooting.md)。

## 遇到新问题后的维护

- 首先在当前任务内解决并核对结果；不要把一次失败直接写成普适规则。
- 只有 **已经定位原因、可复现或有明确证据、对其他 Windows 任务也有价值** 的经验才值得进入本 Skill。
- 优先修改一条规则；重复且稳定的操作才抽成小脚本，并在 `tests/` 增加对应回归验证。更新前检查仓库 diff，按实际需求请求用户确认。
- 本 Skill 的 Git 源码仓库是唯一维护源；不要让已安装的副本与 Git 仓库静默分叉。维护约定见 [maintenance.md](references/maintenance.md)。

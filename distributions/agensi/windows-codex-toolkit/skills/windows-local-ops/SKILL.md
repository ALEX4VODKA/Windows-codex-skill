---
name: windows-local-ops
description: 在 Windows PowerShell 中可靠处理本地文件、日志、CLI、中文编码、路径、输出截断和受限执行环境；用于跨项目本地操作，不用于 Kubernetes 专项任务。
---

# Windows Local Operations

在 Windows 本机完成范围明确、可验证的 PowerShell 与 CLI 操作。先确认真实
运行环境，只收集当前任务需要的信息；不要把受限运行器、远端主机或 WSL 的
结果当作本机事实。

Requires: Windows PowerShell 5.1+ 或 PowerShell 7；任务所需的 CLI 需由用户
环境提供。

## MCP 分发约定

- 不假定 Skill 已安装到固定目录，也不依赖 `CODEX_HOME` 或宿主专有工具名。
- 需要包内脚本时，使用宿主从本 Skill 加载并提供的临时脚本文件，保持脚本
  内容不变后执行；不要重写、拼接或保存到用户项目。
- 每个脚本都能独立运行。脚本结束后按宿主规则清理临时副本。
- 若宿主不能执行 PowerShell，说明缺少的能力与未验证项，不伪造执行结果。

## 确认环境

只在任务需要时检查 PowerShell 版本、当前位置和目标命令的真实来源。多 Python
环境中，确认实际解释器后始终使用该解释器执行 `-m pip` 或 `-m pytest`。不要
为排障自动安装软件、修改 PATH、ExecutionPolicy、注册表或用户 Profile。

## 有界读取与结构化数据

先用文件元数据、文本搜索或少量尾部内容界定范围，再读取相关片段。大文件可
使用 `scripts/Read-TextRange.ps1`；只有输出末尾出现 `END_RANGE` 时，才把该段
视为完整，并继续检查 `MORE` 与 `TRUNCATED`。

区分 PowerShell 表格格式省略、宿主输出上限、单行字符预算与源文件本身不完整。
JSON 和 CSV 应结构化解析并只选择需要的字段，不把格式化表格当作数据源。
需要具体命令模式时读取 `references/powershell-recipes.md`。

## 编码与路径

- 按已确认的源编码读取文件；对明确的 UTF-8 文本显式指定 UTF-8。
- 中文 CSV 面向 Excel 时可使用 UTF-8 BOM；Markdown 和 JSON 通常使用 UTF-8。
- 只有当前任务确实需要时才运行 `scripts/Set-Utf8Session.ps1`。它只影响当前
  进程，不应被解释为修改系统配置的授权。
- 对含空格或特殊字符的路径使用字面路径语义；解析写入或删除目标后再操作。

## 权限与风险边界

优先执行只读、工作区内且范围明确的检查。需要额外权限、访问受保护路径、启动
GUI、改变外部系统或执行破坏性操作时，先说明具体动作和影响，并通过当前宿主的
授权机制获得用户确认。权限失败后只对同一个必要操作进行一次窄范围升级尝试，
不要通过复制路径、切换 shell 或降低安全设置绕过限制。

对不存在、不可读或编码不明的输入明确报错。非幂等写操作不自动重试。输出应
区分“已发现”“已执行验证”“静态审查”和“未验证”。

## SSH 与远端连接

Windows 上的 SSH、远端代理或 Codex 连接问题需要分层诊断时，读取
`references/ssh-codex-remote-troubleshooting.md`。任何密钥、令牌、代理凭据、
设备代码和敏感路径都不得进入输出或版本库。

## 路由到专项 Skill

涉及 kubectl、Kubernetes API、Prometheus/Grafana 采集或瞬时集群连接失败时，
使用同一 Skill Pack 中的 `windows-kubectl-reliable-ops`，不要把历史机器路径或
集群配置当作当前环境事实。

# Agensi MCP 开发说明

- 开发分支：`codex/develop-mcp-version`
- 分发源：`distributions/agensi/windows-codex-toolkit/`
- 原生兼容基线：仓库根目录下的 `skills/`

## 已确认的加载模型

Agensi 运行一个远程 Streamable HTTP MCP Server。仓库不需要实现或托管新的 MCP
Server；发布物是包含一个或多个 `SKILL.md` 的 ZIP。两个 `SKILL.md` 会作为 Skill
Pack，代理先根据名称和描述选择，再通过 `get_skill` 按需加载对应目录。

加载脚本时，Agensi 会把单个脚本原样写入临时文件，执行后移除。脚本不能读取
包内的相邻文件。因此 MCP 分发版的每个 PowerShell 脚本必须自包含，Skill 正文也
不能依赖固定安装目录、`CODEX_HOME`、Codex 专有工具名或持久化本地副本。

官方依据：

- [Package your skill](https://www.agensi.io/docs/packaging)
- [How agents load skills](https://www.agensi.io/docs/how-agents-load-skills)
- [MCP server and sign-in](https://www.agensi.io/docs/mcp-server)

## 包结构与兼容策略

```text
windows-codex-toolkit/
  README.md
  LICENSE.txt
  skills/
    windows-local-ops/
      SKILL.md
      references/
      scripts/
    windows-kubectl-reliable-ops/
      SKILL.md
      scripts/
```

原生 Skill 继续承担本地 Codex 安装与兼容行为；MCP 分发副本只处理 Agensi 的
临时加载约束。两者复用已验证的核心逻辑，但 MCP 版允许为以下边界做独立调整：

- 所有脚本独立运行，不 dot-source 相邻脚本。
- 用宿主能力和用户授权的通用描述替代专有沙箱参数名。
- 不携带 `agents/openai.yaml`、目录联接说明或本机维护流程。
- 不持久化 Skill 文件、脚本、凭据、kubeconfig 或机器快照。
- 基础设施操作默认只读；写操作和破坏性操作仍需单独明确授权。

## 验证范围

`tests/Smoke-Test.ps1` 覆盖：

- 包中恰好存在两个可发现的 `SKILL.md`。
- frontmatter 包含 `name` 和 `description`，且无 Agensi 禁止的可执行文件类型。
- 所有 MCP PowerShell 脚本语法可解析，且不依赖 `$PSScriptRoot`。
- MCP 版 `Read-TextRange.ps1` 在 Windows 实际运行，保留范围和截断标记。
- MCP 版环境预检在临时工作区实际运行并清理探测文件。

未在本地测试中访问真实 Kubernetes API、Prometheus/Grafana、Agensi OAuth 或
Creator 发布流程。上传、预览、审核和上线都是外部状态变更，只有用户明确要求并
提供已连接的 Agensi Creator 环境后才执行。

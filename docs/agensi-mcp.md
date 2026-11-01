# Agensi MCP 开发说明

- 当前分支：`feature/agensi-mcp`
- 分支用途：用于 Agensi 平台适配和 MCP 相关开发。

## 分发关系

原生 Windows Skill 是当前功能与兼容行为的维护基线。MCP 分发版本应在确认 Agensi 的执行和加载机制后进行适配，复用可兼容的 Skill 文档与脚本，不提前改变原生 Windows 版本的行为。

## 待确认的技术问题

- Agensi 是否支持原生 Windows Codex 环境。
- PowerShell 脚本的实际执行位置。
- 是否支持持久化本地配置。
- 脚本之间的依赖如何处理。
- MCP 加载与 Skill 文件分发机制。

## 后续测试要求

适配实现应覆盖 Skill 加载、脚本定位与依赖、配置持久化、PowerShell 实际执行和错误处理，并验证 MCP 分发版本与原生 Windows Skill 的关键行为保持兼容。无法在目标环境运行的部分必须标记为静态审查或待验证。

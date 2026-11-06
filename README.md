# Windows Codex Toolkit

独立、长期维护的 Windows Codex 通用 Skill 与 PowerShell 可靠操作规范仓库。它不包含任何业务项目约束、主机路径、凭据或集群配置。

## 内容

```text
skills/
  windows-local-ops/                 # 本地 PowerShell、编码、输出截断与路径操作
  windows-kubectl-reliable-ops/      # 已有 Kubernetes 专项 Skill 的归档
distributions/
  agensi/windows-codex-toolkit/      # 通过 Agensi MCP 按需分发的 Skill Pack
tests/
  Smoke-Test.ps1                     # Windows PowerShell 冒烟测试
```

`windows-kubectl-reliable-ops` 是本仓库维护的 Kubernetes 专项 Skill。

该 Skill 及其四个 PowerShell 脚本主要由 Codex 辅助生成，
维护者负责需求定义、修改、集成和验证。

修改脚本时应保持现有行为兼容，并增加最小回归验证。

## 安装 `windows-local-ops`

Git 仓库是唯一维护源。将仓库放在稳定的本地目录后，在 PowerShell 中创建目录联接；目标已存在时必须先人工核查，不能覆盖：

```powershell
$repo = (Get-Location).Path
$codexHome = if ($env:CODEX_HOME) { $env:CODEX_HOME } else { Join-Path $HOME '.codex' }
$source = Join-Path $repo 'skills\windows-local-ops'
$destination = Join-Path (Join-Path $codexHome 'skills') 'windows-local-ops'
if (Test-Path -LiteralPath $destination) {
    throw "已有安装目录：$destination；请先检查再决定是否迁移，勿直接覆盖。"
}
New-Item -ItemType Junction -Path $destination -Target $source
```

已有的 `windows-kubectl-reliable-ops` 不应被直接覆盖。先比较其内容，再决定是否以目录联接迁移，避免两个版本静默分叉。

## Agensi MCP 分发版

`distributions/agensi/windows-codex-toolkit/` 是独立的分发源。Agensi 自身提供
远程 MCP Server，并通过 `get_skill` 按需返回 `SKILL.md`、参考资料和单个脚本，
因此本仓库不另建 MCP Server。分发版脚本必须能从临时文件独立运行，不能依赖
固定安装路径、`CODEX_HOME` 或相邻脚本。

发布前先运行冒烟测试，再将分发目录的**内容**压缩为 ZIP；不要把仓库历史、
测试输出或主机配置放入包中。当前仓库只准备本地分发源，不自动上传或发布。

具体兼容性决策和目标环境待验证项见
[`docs/agensi-mcp.md`](docs/agensi-mcp.md)。

## 验证

```powershell
# 此测试只会在系统临时目录创建和删除测试文件/目录。
& .\tests\Smoke-Test.ps1

# 对大文件分段读取时，必须确认最后出现 END_RANGE，随后检查 MORE / TRUNCATED。
& .\skills\windows-local-ops\scripts\Read-TextRange.ps1 `
    -Path .\README.md -StartLine 1 -Count 30
```

若当前执行策略阻止未签名的测试脚本，可仅为该子进程使用：

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tests\Smoke-Test.ps1
```

这不会修改系统或用户执行策略。

## 维护约定

1. 先保留必要且去敏的现象与复现步骤，再定位根因。
2. 优先补充一条已验证的规则；仅将稳定、可复用的操作封装为脚本。
3. 行为变更必须有最小回归测试，并区分 Windows 运行验证和静态审查。
4. 提交前检查 diff；使用规范分支和 Conventional Commits。
5. 未经审核，不提交、推送或自动执行新脚本修改。

## License

This project is licensed under the MIT License.
See the [LICENSE](LICENSE) file for details.

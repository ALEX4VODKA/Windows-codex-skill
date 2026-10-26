# Windows Codex Toolkit

独立、长期维护的 Windows Codex 通用 Skill。目前实现了防止codex与powershell的屎山代码打架、ssh问题优先定位。

## 内容

```text
skills/
  windows-local-ops/                 # 本地 PowerShell、编码、输出截断与路径操作
  windows-kubectl-reliable-ops/      # 已有 Kubernetes 专项 Skill 的归档
tests/
  Smoke-Test.ps1                     # Windows PowerShell 冒烟测试
```

`windows-kubectl-reliable-ops` 的四个 PowerShell 脚本是导入代码：`Initialize-SessionUtf8.ps1`、`Invoke-WebRequestWithRetry.ps1`、`Invoke-WithRetry.ps1` 和 `Test-ExecutionEnvironment.ps1`。任何修改都应单独审查，保持 Kubernetes 能力兼容，并增加最小回归验证。

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

## 验证

```powershell
# 此测试只会在系统临时目录创建和删除测试文件。
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

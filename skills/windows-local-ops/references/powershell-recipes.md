# Windows / PowerShell 可靠操作速查

只在当前问题需要时读取本参考，不必每条命令都执行所有步骤。

## 识别当前终端和工具

```powershell
$PSVersionTable.PSVersion
(Get-Location).Path
Get-Command python, git, rg -All -ErrorAction SilentlyContinue | Select-Object Name, Source, CommandType
where.exe python
py -0p  # 仅在装有 Windows py Launcher 时执行
python -c "import sys; print(sys.executable)"
python -m pip --version
```

`Get-Command` 的候选列表不等同于所有项都可运行；对确实需要的程序再运行其 `--version` 或相应无副作用探测。

## 文件过大：先查再按行读取

```powershell
Get-Item -LiteralPath '.\logs\app.log' | Select-Object FullName, Length, LastWriteTime
Select-String -LiteralPath '.\logs\app.log' -Pattern 'ERROR' | Select-Object -First 30
Get-Content -LiteralPath '.\logs\app.log' -Tail 60 -Encoding UTF8

$skill = Join-Path $HOME '.codex\skills\windows-local-ops'
& (Join-Path $skill 'scripts\Read-TextRange.ps1') -Path '.\app.py' -StartLine 81 -Count 60
```

若设置了 `$env:CODEX_HOME`，上例中的 `$skill` 应改从真实 CODEX_HOME 定位；如果采用 junction，路径仍有效。

`Read-TextRange.ps1` 默认最多输出 6000 个字符，并提供 `END_RANGE`、`MORE`、`TRUNCATED`。**缺少 `END_RANGE` 即视为工具输出不完整**。读完整文件时，按 `MORE=true` 继续，遇到 `TRUNCATED=true` 缩小范围或提高单次限额（不要超过当前工具实际可承载的输出）。**不要把限长显示等同于文件的完整内容。**

## PowerShell 格式截断并非工具输出截断

```powershell
Get-Process | Select-Object -First 5 Name, Path | Format-List
Get-Process | Select-Object -First 5 Name, Path | Out-String -Width 240
```

上述命令只调整本地显示；若 Codex 工具本身设置了输出长度上限，应减少或分段输出。

## 处理 JSON / CSV

```powershell
$data = Get-Content -LiteralPath '.\result.json' -Raw -Encoding UTF8 | ConvertFrom-Json
$data.items | Select-Object -First 20 id, name

Import-Csv -LiteralPath '.\records.csv' -Encoding UTF8 | Select-Object -First 20
```

数据可能不是 UTF-8 时应先确认原始编码，不能直接重新保存覆盖。对需要 Excel 稳定识别中文的 CSV，推荐 Python 写入 `encoding='utf-8-sig'`。

## 文本编码临时初始化

```powershell
. (Join-Path $skill 'scripts\Set-Utf8Session.ps1')
```

该脚本只改变当前进程/PowerShell 会话的编码相关选项，不会修改系统级环境变量；在没有控制台句柄的运行器中，控制台编码设置可能受到限制。

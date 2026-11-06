# Windows / PowerShell 可靠操作速查

只在当前问题需要时使用对应片段，不必为每条命令执行全量环境扫描。

## 识别终端和工具

```powershell
$PSVersionTable.PSVersion
(Get-Location).Path
Get-Command python, git, rg -All -ErrorAction SilentlyContinue |
    Select-Object Name, Source, CommandType
where.exe python
py -0p
python -c "import sys; print(sys.executable)"
python -m pip --version
```

只有确认安装了 Windows Python Launcher 时才运行 `py -0p`。命令候选列表不
证明每一项都可执行；仅对任务需要的程序执行无副作用版本探测。

## 大文件：先查再按行读取

```powershell
Get-Item -LiteralPath '.\logs\app.log' |
    Select-Object FullName, Length, LastWriteTime
Select-String -LiteralPath '.\logs\app.log' -Pattern 'ERROR' |
    Select-Object -First 30
Get-Content -LiteralPath '.\logs\app.log' -Tail 60 -Encoding UTF8
```

需要精确分段时，加载本 Skill 的 `scripts/Read-TextRange.ps1`，由宿主提供临时
脚本路径后执行：

```powershell
& '<host-provided-temporary-script>' -Path '.\app.py' -StartLine 81 -Count 60
```

该脚本默认最多输出 6000 个字符。缺少 `END_RANGE` 表示宿主结果仍可能被截断；
`MORE=true` 时继续分段，`TRUNCATED=true` 时缩小范围或在宿主可承载范围内提高
字符预算。

## 显示截断与输出截断

```powershell
Get-Process | Select-Object -First 5 Name, Path | Format-List
Get-Process | Select-Object -First 5 Name, Path | Out-String -Width 240
```

调整 `Out-String` 宽度只处理 PowerShell 本地显示省略。若宿主有输出上限，应
减少字段或分段输出。

## JSON 与 CSV

```powershell
$data = Get-Content -LiteralPath '.\result.json' -Raw -Encoding UTF8 |
    ConvertFrom-Json
$data.items | Select-Object -First 20 id, name

Import-Csv -LiteralPath '.\records.csv' -Encoding UTF8 |
    Select-Object -First 20
```

编码不明时先确认，不直接覆盖源文件。面向 Excel 的中文 CSV 可用 Python 的
`encoding='utf-8-sig'`；Markdown 与 JSON 通常使用 UTF-8。

## 当前进程 UTF-8

需要统一当前 PowerShell 进程的输入输出编码时，加载
`scripts/Set-Utf8Session.ps1` 并执行宿主提供的临时脚本。它不会修改系统级
配置；在没有控制台句柄的运行器中，控制台编码设置可能受限。

---
name: windows-kubectl-reliable-ops
description: 在 Windows PowerShell 中可靠执行本地 kubectl、Prometheus/Grafana 数据采集和中文报告任务；用于权限边界、工具缺失、瞬时 API 失败和编码问题，不用于未经授权的集群变更。
---

# Windows kubectl Reliable Operations

在 Windows PowerShell 中执行范围明确、默认只读的 Kubernetes 与监控数据采集。
先收集证据，再验证假设；没有用户明确授权时，不修改集群资源、生产配置或服务
状态。

Requires: Windows PowerShell 5.1+ 或 PowerShell 7；集群操作需要可执行的
`kubectl`、目标集群访问权限与当前宿主允许的网络通路。

## MCP 分发约定

- 不假定 Skill 安装目录、`CODEX_HOME`、固定 kubeconfig 或宿主专有授权工具。
- 需要脚本时，使用宿主从本 Skill 加载并提供的临时文件，保持脚本内容不变后
  执行；不要重写脚本或保存到用户项目。
- 包内每个脚本都已自包含，不能依赖相邻文件。脚本结束后按宿主规则清理副本。
- 若宿主不支持 Windows PowerShell、本地进程或目标网络，明确标记未运行的部分。

## 编码初始化

只有命令会读取、转换或输出中文文本时，才运行
`scripts/Initialize-SessionUtf8.ps1`。即使已初始化，对文件读写仍显式指定编码。
面向 Excel 的中文 CSV 可使用 UTF-8 BOM；Markdown 与 JSON 通常使用 UTF-8。

## 权限、工具与预检

长时间采集前或环境改变后，可运行 `scripts/Test-ExecutionEnvironment.ps1`。只有
确实需要实时 API 证据时才传入 `-ProbeKubernetes`；其 JSON 结果是环境证据，
不是扩大权限的授权。

每次操作先分类：

1. 工作区内的只读或可回退操作，按当前宿主允许的最低权限执行。
2. 受保护路径、GUI、管理员动作或工作区外写入，先说明具体影响并请求授权。
3. 权限拒绝或明确的受限网络失败，只对同一个必要操作做一次窄范围升级尝试。
4. 破坏性操作必须解析并核对精确目标；用户未明确要求时不执行。

不安装缺失工具，不修改执行策略、PATH、系统 Profile 或沙箱设置。无法解析或运行
工具时，使用当前环境已有的安全替代能力，并说明降级方式。

## 瞬时故障重试

只有幂等、只读命令遇到已识别的瞬时错误时，才使用
`scripts/Invoke-WithRetry.ps1`。认证、授权、语法、校验和资源不存在错误立即停止。
重试必须有次数上限和退避，并报告最终错误。

幂等 HTTP 下载可使用 `scripts/Invoke-WebRequestWithRetry.ps1`。它先写部分文件，
成功后再替换目标；输出路径必须位于用户授权范围。不要对写集群、删除、发布或
其他非幂等动作自动重试。

## Kubernetes 与监控采集

- 大范围读取优先按 namespace 或目标资源拆分，避免无界的全集群 JSON。
- 远端 API 不稳定时可复用已验证快照，但必须标明采集时间和“缓存/实时”。
- 日志、指标和配置输出只保留当前问题所需字段，并对 Secret、令牌、Cookie、
  数据库密码、主机身份和内部拓扑脱敏。
- Prometheus/Grafana 查询先验证时间范围、采样步长、标签基数与时区；不把空结果
  自动解释为零。

## 验证结果

重新打开输出并确认编码、表头、行数、日期范围、空值率和关键计算不变量。检查
乱码替代字符，记录使用了实时 API、缓存快照、替代工具还是额外授权。必须区分
“Windows 实际运行”“静态审查”和“目标环境未验证”；必需命令仍受阻时不宣称
成功。

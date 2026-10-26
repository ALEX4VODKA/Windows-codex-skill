# SSH 与 Codex 远程连接排障

本参考用于 Windows 上的 Codex App 通过 SSH 使用远端 Codex 的场景。它只描述只读诊断和最小范围的配置原则；不假定特定 IP、用户名、端口、代理软件、安装目录或服务器操作系统。

## 排障顺序

按下列层级推进，并记录每层的实际结果。一个层级未通过时，不要用下一层的配置掩盖问题。

1. **网络路由**：目标的 TCP 端口是否可达，流量从哪个本地接口和源地址离开。
2. **SSH 握手**：远端是否返回 SSH banner，主机密钥是否已被正确校验。
3. **非交互认证**：目标用户是否能用预期密钥在无密码提示、无确认提示的条件下登录。
4. **远端 Codex**：登录 shell 是否能找到 `codex`，且当前远端用户的 Codex 登录状态是否有效。
5. **代理通路**：若远端没有直接出网，远端进程使用的代理地址是否在监听、可连接且能访问所需服务。
6. **App 进程**：Codex App 启动的 SSH/App Server 是否仍在运行，以及它实际继承了哪些环境变量和 SSH 配置。

## 最小只读检查

先查看 SSH 别名的有效解析结果，而不是根据 `~/.ssh/config` 的表面内容推断：

```powershell
ssh -G <host-alias>
```

重点检查 `hostname`、`user`、`identityfile`、`bindaddress`、`remoteforward`、`stricthostkeychecking` 与 `userknownhostsfile`。不要在输出或问题记录中复制私钥、公钥或敏感路径。

将基础连接与转发隔离，验证可否非交互执行无害命令：

```powershell
ssh -o ClearAllForwardings=yes -o BatchMode=yes <host-alias> "printf 'ssh-ok\n'"
```

成功意味着路由、握手、主机密钥和非交互认证已通过；失败时用 `ssh -vvv` 获取最小必要的诊断片段，并将密钥材料、用户名和主机信息脱敏。

再验证远端登录 shell 与 Codex，而不假定安装目录：

```powershell
ssh -o ClearAllForwardings=yes -o BatchMode=yes <host-alias> "command -v codex && codex --version && codex login status"
```

`command -v` 失败表示非交互登录 shell 的 `PATH` 不包含 Codex；这与本地桌面 App、SSH 认证或网络连通性无关。登录状态失败时，按当前官方 Codex 文档完成该远端用户的登录，不要在诊断输出中记录设备代码或令牌。

## 网络、接口与主机密钥

TCP 可达而 SSH 在认证前断开时，先区分本机沙盒限制、路由/源地址错误、远端访问控制和 SSH 服务故障。若本机有 VPN、TUN 或多个活动网卡，应检查目标路由和实际出站源地址；只有证据显示目标走错接口，才为该 Host 使用 `BindAddress`。不要据此修改默认路由、代理全局模式或其他 Host 的 SSH 行为。

后台 App 不能回答首次主机密钥确认。确认目标身份后，按 OpenSSH 的正常流程建立或修复 `known_hosts`；不要通过关闭主机密钥校验来解决连接失败。

## 认证与远端运行环境

Codex App 的远程连接依赖 SSH 后台启动远端 App Server，因此密码提示、首次确认提示、交互式多因素认证等都会使 App 失败。先单独证明目标用户能以所选密钥进行非交互 SSH 登录，再检查远端 Codex。

远端 `codex` 必须在 App 使用的同一用户及登录 shell 中可执行，并已完成该用户的登录。若需要代理，代理变量必须由实际启动 `codex app-server` 的进程继承；仅在交互 shell 中临时设置变量不足以证明 App Server 可用。

## 代理和反向隧道

仅当远端确实不能直接访问所需网络服务时，才考虑代理或反向隧道。先从远端测试代理端点和目标服务，再把它用于 Codex。代理凭据、代理 URL 中的密码、Cookie、设备代码和访问令牌不得写入日志、Skill 或版本库。

将职责拆分：

- App 的连接 Host 只负责 SSH 和远端 App Server，不能配置 `RemoteForward`。
- 独立的隧道 Host 才配置转发，并使用只绑定在远端回环地址的监听端口。
- 同一远端监听端口只能有一个隧道所有者。手工 SSH 调试使用 `ClearAllForwardings=yes`，不要抢占正在由 App 或隧道进程持有的端口。

隧道退出、网络切换、休眠和服务器重启会使代理通路失效。恢复前先确认远端端口是否监听、监听者归属以及本地 SSH 进程的父进程；不要盲目启动多个隧道或终止无法确认归属的进程。

## App 侧判断与恢复

当手工 SSH 和远端 `codex` 均成功而 App 仍失败时，检查 App 实际使用的 Host 别名及其 `ssh -G` 输出，并检查 App 发起的 SSH 进程、远端 App Server 是否保留了旧环境或控制 socket。只在确认进程属于当前用户、当前 App 且可以安全重启时，才按用户授权停止旧进程并让 App 重连。

不要把“App 已连上”归因于最近一次配置修改，除非已验证 App 使用的 Host、远端进程和代理环境都与该修改一致。

## 自动化边界

隧道守护、计划任务、wrapper 和自动重连都是可选运维配置，不是诊断的默认步骤。它们会创建持续进程或改变主机状态，必须先明确用户对启动时机、退出行为、重连策略和清理方式的要求，并经过单独审查。通用 Skill 不应保存任何特定主机、端口、用户、目录或凭据。

## Windows 执行策略

若已审阅的仓库脚本被执行策略阻止，用户可以仅对子进程使用：

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File <reviewed-script>
```

这不修改现有执行策略。不要通过改注册表、Profile 或系统/用户级 ExecutionPolicy 来规避一次脚本执行限制。

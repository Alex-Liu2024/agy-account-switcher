# Antigravity CLI Account Switcher (agy-switch)

![PowerShell](https://img.shields.io/badge/PowerShell-5.1+-blue.svg)
![License](https://img.shields.io/badge/License-MIT-green.svg)
![Platform](https://img.shields.io/badge/Platform-Windows-lightgrey.svg)

A lightweight, purely local PowerShell CLI tool to seamlessly manage and switch multiple accounts for the Google Antigravity CLI (gy).

[中文文档说明请见下方](#中文说明-chinese-documentation)

---

## 🌟 Why this tool?

The Antigravity CLI (gy) stores its OAuth credentials deeply within the Windows Credential Manager (gemini:antigravity), making it difficult to switch between multiple Google accounts (e.g., work vs. personal) without re-authenticating in the browser every time.

Unlike other third-party GUI managers that require installing external binaries (Rust/Node) or modules, **gy-switch.ps1 is a pure PowerShell script**. 
- 🔒 **100% Secure**: Uses C# P/Invoke to interact with the native Windows `advapi32.dll` API. Your tokens never leave your machine.
- 🪶 **Zero Dependencies**: No third-party modules or `.exe` files required.
- ⚡ **Lightning Fast**: Switch active accounts in milliseconds.

## 🚀 Usage

Download the gy-switch.ps1 script and run it via PowerShell.

``powershell
# 1. Check current logged-in account status
.\agy-switch.ps1 status

# 2. Save/Backup the currently active account (e.g. as "work")
.\agy-switch.ps1 save work

# 3. List all saved accounts
.\agy-switch.ps1 list

# 4. Seamlessly switch to another saved account
.\agy-switch.ps1 switch work

# 5. Remove a saved account
.\agy-switch.ps1 remove work
``

---

## 🇨🇳 中文说明 (Chinese Documentation)

轻量级、纯本地运行的 PowerShell 脚本，专为 **Antigravity CLI** 设计的多账号无缝切换工具。

### 为什么选择这个工具？
由于 Antigravity CLI 默认将认证 Token 保存在 Windows 凭据管理器（Keyring）中，频繁切换账号（如公司账号与个人账号）需要反复在浏览器重新授权。

市面上其他工具通常是庞大的第三方 GUI 软件，而 **gy-switch.ps1** 提供了最安全、最纯粹的解决方案：
- 🔒 **绝对安全**：底层直接调用 Win32 API (dvapi32.dll) 操作系统凭据，你的 Token 永远只存放在本地，没有任何窃取风险。
- 🪶 **零依赖**：不需要安装任何第三方语言环境或包。
- ⚡ **瞬间切换**：毫秒级一键切号，即刻生效。

### 使用方法

``powershell
# 1. 查看当前正在使用的账号状态
.\agy-switch.ps1 status

# 2. 将目前登录的账号保存备份起来（例如命名为 "work"）
.\agy-switch.ps1 save work

# 3. 列出所有已经保存的账号
.\agy-switch.ps1 list
# 输出示例:
# * main (user1@example.com) [ACTIVE]
#   work (user2@example.com)

# 4. 一键瞬间切换到某个账号
.\agy-switch.ps1 switch work

# 5. 删除某个不需要的账号备份
.\agy-switch.ps1 remove work
``

*提示：备份的账号配置文件会自动存放在 ~/.gemini/accounts/ 目录中。*

---

## 📜 License
MIT License

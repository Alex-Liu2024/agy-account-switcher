# Antigravity CLI Account Switcher (`agy-switch`)

![PowerShell](https://img.shields.io/badge/PowerShell-5.1+-blue.svg)
![License](https://img.shields.io/badge/License-MIT-green.svg)
![Platform](https://img.shields.io/badge/Platform-Windows-lightgrey.svg)
![Security](https://img.shields.io/badge/Security-Local_Keyring-success.svg)

A lightweight, purely local, and highly secure PowerShell CLI tool designed to seamlessly manage and switch multiple accounts for the [Google Antigravity CLI (`agy`)](https://github.com/google/antigravity).

[🇨🇳 中文详细说明请见下方 (Scroll down for Chinese)](#-中文详细说明-chinese-documentation)

---

## 🌟 Why build this tool?

The official Antigravity CLI (`agy`) stores its OAuth credentials deeply within the native **Windows Credential Manager** (under the target `gemini:antigravity`). While this is highly secure, it introduces a friction point for power users: **there is no built-in way to switch between multiple Google accounts (e.g., Work vs. Personal)** without re-authenticating and opening your browser every single time.

While there are third-party GUI account managers available, they often require installing large, external binaries (like Tauri/Rust/Node.js) and pose a security risk because they handle your raw OAuth tokens. 

**`agy-switch.ps1` solves this elegantly by being a pure, transparent PowerShell script.**

### ✨ Key Features
- 🔒 **100% Secure & Transparent**: Uses C# P/Invoke to natively interface with the Windows `advapi32.dll` API. Your OAuth tokens never leave your machine, and the source code is entirely readable.
- 🪶 **Zero Dependencies**: Requires absolutely no third-party libraries, modules, or `.exe` files. It runs out-of-the-box on standard Windows PowerShell.
- ⚡ **Lightning Fast Switching**: Swap active accounts in milliseconds directly from your terminal. No UI bloat, no background services.
- 🔄 **Smart Token Recovery**: Automatically queries the Google API to extract your email address from your current token.

---

## 🚀 Installation

Since it's just a single script, installation is incredibly simple:

1. Clone or download this repository to your local machine:
   ```powershell
   git clone https://github.com/Alex-Liu2024/agy-account-switcher.git
   ```
2. Navigate into the directory:
   ```powershell
   cd agy-account-switcher
   ```
3. (Optional) Add the folder to your system's `PATH` variable, or just run the script directly by calling `.\agy-switch.ps1`.

---

## 🛠️ Detailed Usage Guide

Run the script in your PowerShell console. The script automatically manages your saved accounts locally in the `~/.gemini/accounts/` directory.

### 1. Check Current Status
Displays the email and token expiration date of the currently active account logged into the CLI.
```powershell
.\agy-switch.ps1 status
```

### 2. Save / Backup the Active Account
Before switching, always save your current active session. You can give it a friendly name (like `work`, `personal`, or `dev`).
```powershell
.\agy-switch.ps1 save work
```
*Note: If your token has expired, the script will gracefully ask you to type the email manually.*

### 3. List All Saved Accounts
View all accounts you have backed up. The currently active one will be highlighted with `[ACTIVE]`.
```powershell
.\agy-switch.ps1 list
```
*Example Output:*
```text
Saved Accounts:
--------------------------------------------------
* work (work-email@example.com) [ACTIVE]
  personal (personal-email@example.com)
--------------------------------------------------
```

### 4. Switch Accounts Seamlessly
Swap the active token with one of your saved backups. The CLI will immediately use this new identity.
```powershell
.\agy-switch.ps1 switch personal
```

### 5. Remove a Saved Account
Delete a backup you no longer need.
```powershell
.\agy-switch.ps1 remove personal
```

---

## 🔒 How does it work? (Security Architecture)

1. When you run `save`, the script reads the raw credential blob directly from the Windows Vault (`gemini:antigravity`).
2. It wraps this encrypted-equivalent JSON string alongside metadata (your email) into a local `.json` backup file in `~/.gemini/accounts/`.
3. When you run `switch`, it reads the `.json` file and directly overwrites the Windows Vault entry using the native `CredWriteW` API.
4. **No external requests are made** except to `oauth2.googleapis.com` exclusively to fetch your email address for display purposes.

---
---

## 🇨🇳 中文详细说明 (Chinese Documentation)

**`agy-switch.ps1`** 是一个轻量级、纯本地运行的 PowerShell 脚本，专为 **Antigravity CLI** 设计的多账号无缝切换工具。

### 🌟 为什么开发这个工具？
默认情况下，Antigravity CLI 会将你的登录凭据（OAuth Token）深埋在底层的 **Windows 凭据管理器** (Keyring) 中。这虽然极其安全，但也带来了一个痛点：**当你需要在多个账号（如公司账号和个人账号）之间切换时，由于缺乏官方切换机制，你每次都必须重新在浏览器中进行授权。**

市面上现存的多账号切换工具通常是庞大的第三方 GUI 软件（需要安装额外的运行环境），甚至存在窃取高权限 Token 的潜在风险。**本工具通过纯 PowerShell 脚本完美解决了这个问题：**

### ✨ 核心优势
- 🔒 **绝对安全透明**：底层直接调用 Windows 原生的 `advapi32.dll` API 进行凭据读写。你的 Token 永远只存在于本地设备，且几百行脚本代码完全开源透明，无任何窃取后门风险。
- 🪶 **真正的零依赖**：不需要额外安装任何第三方语言环境、Node.js 或是杂乱的 `.exe` 可执行文件。
- ⚡ **毫秒级极速切换**：纯命令行操作，一键切号，即刻生效。无后台常驻进程，不占用任何系统资源。
- 🔄 **智能账号识别**：自动通过 Google 官方安全接口识别当前 Token 绑定的邮箱地址，方便你进行管理。

---

## 🚀 极简安装

因为它只是一个纯脚本，你无需“安装”任何复杂软件：

1. 克隆或下载本仓库到你的电脑：
   ```powershell
   git clone https://github.com/Alex-Liu2024/agy-account-switcher.git
   ```
2. 进入目录：
   ```powershell
   cd agy-account-switcher
   ```
3. (可选) 你可以将这个文件夹添加到系统的环境变量 `PATH` 中，或者直接通过 `.\agy-switch.ps1` 来调用它。

---

## 🛠️ 详细使用指南

本脚本会将你备份的账号文件安全地存放在 `~/.gemini/accounts/` 目录下。

### 1. 查看当前账号状态
快速显示当前 CLI 正在使用哪个邮箱，以及 Token 的过期时间。
```powershell
.\agy-switch.ps1 status
```

### 2. 保存/备份当前账号
在切换账号前，请先将当前已经登录的账号保存下来，并赋予一个好记的别名（例如 `work` 或 `personal`）。
```powershell
.\agy-switch.ps1 save work
```

### 3. 列出所有已保存的账号
查看当前系统里备份了哪些账号，并高亮显示**当前正在生效**的账号。
```powershell
.\agy-switch.ps1 list
```
*输出示例:*
```text
Saved Accounts:
--------------------------------------------------
* work (work-email@example.com) [ACTIVE]
  personal (personal-email@example.com)
--------------------------------------------------
```

### 4. 无缝切换账号
一键将系统底层的身份凭据替换为你保存的备份。Antigravity CLI 将会立刻无缝切换为新身份。
```powershell
.\agy-switch.ps1 switch personal
```

### 5. 删除账号备份
如果你不再需要某个账号备份，可以随时将其移除。
```powershell
.\agy-switch.ps1 remove personal
```

---

## 📜 许可证 (License)
基于 **MIT License** 开源。

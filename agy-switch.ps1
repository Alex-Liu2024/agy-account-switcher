# agy-switch.ps1
# CLI Account Manager for Google Antigravity CLI (agy)
# Usage: powershell -ExecutionPolicy Bypass -File .\agy-switch.ps1 [command] [args]

$AccountsDir = "$env:USERPROFILE\.gemini\accounts"
if (-not (Test-Path $AccountsDir)) {
    New-Item -Path $AccountsDir -ItemType Directory -Force | Out-Null
}

$code = @"
using System;
using System.Runtime.InteropServices;

public class CredMan {
    [DllImport("Advapi32.dll", SetLastError=true, EntryPoint="CredReadW", CharSet=CharSet.Unicode)]
    public static extern bool CredReadW(string target, uint type, int flag, out IntPtr credential);

    [DllImport("Advapi32.dll", SetLastError=true, EntryPoint="CredWriteW", CharSet=CharSet.Unicode)]
    public static extern bool CredWriteW(ref Credential credential, uint flags);

    [DllImport("Advapi32.dll", SetLastError=true, EntryPoint="CredDeleteW", CharSet=CharSet.Unicode)]
    public static extern bool CredDeleteW(string target, uint type, uint flags);

    [DllImport("Advapi32.dll", SetLastError=true, EntryPoint="CredFree")]
    public static extern bool CredFree(IntPtr credential);

    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
    public struct Credential {
        public uint Flags;
        public uint Type;
        public string TargetName;
        public string Comment;
        public System.Runtime.InteropServices.ComTypes.FILETIME LastWritten;
        public uint CredentialBlobSize;
        public IntPtr CredentialBlob;
        public uint Persist;
        public uint AttributeCount;
        public IntPtr Attributes;
        public string TargetAlias;
        public string UserName;
    }

    public static byte[] GetCredentialBlob(string target) {
        IntPtr p;
        if (CredReadW(target, 1, 0, out p)) {
            try {
                Credential c = (Credential)Marshal.PtrToStructure(p, typeof(Credential));
                if (c.CredentialBlobSize > 0 && c.CredentialBlob != IntPtr.Zero) {
                    byte[] blob = new byte[c.CredentialBlobSize];
                    Marshal.Copy(c.CredentialBlob, blob, 0, (int)c.CredentialBlobSize);
                    return blob;
                }
            } finally {
                CredFree(p);
            }
        }
        return null;
    }

    public static bool SetCredentialBlob(string target, string username, byte[] blob) {
        GCHandle pin = GCHandle.Alloc(blob, GCHandleType.Pinned);
        try {
            Credential c = new Credential();
            c.Type = 1; // CRED_TYPE_GENERIC
            c.TargetName = target;
            c.UserName = username;
            c.Persist = 2; // CRED_PERSIST_LOCAL_MACHINE
            c.CredentialBlobSize = (uint)blob.Length;
            c.CredentialBlob = pin.AddrOfPinnedObject();
            return CredWriteW(ref c, 0);
        } finally {
            pin.Free();
        }
    }

    public static bool DeleteCredential(string target) {
        return CredDeleteW(target, 1, 0);
    }
}
"@

# Suppress errors if Add-Type has already defined CredMan in the current session
try {
    Add-Type -TypeDefinition $code -ErrorAction Stop
} catch {}

function Get-ActiveCredential {
    $bytes = [CredMan]::GetCredentialBlob("gemini:antigravity")
    if ($bytes -eq $null) { return $null }
    $raw = [System.Text.Encoding]::UTF8.GetString($bytes)
    return ConvertFrom-Json $raw
}

function Get-EmailFromToken ($accessToken) {
    try {
        # Fetch token details from Google API
        $resp = Invoke-RestMethod -Uri "https://oauth2.googleapis.com/tokeninfo?access_token=$accessToken" -Method Get -TimeoutSec 3
        return $resp.email
    } catch {
        return $null
    }
}

function Show-Help {
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host "  Antigravity CLI Account Switcher Tool" -ForegroundColor Cyan
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host "Usage:"
    Write-Host "  powershell -File .\agy-switch.ps1 list            - List all saved accounts and active status"
    Write-Host "  powershell -File .\agy-switch.ps1 save <name>     - Save current active account as <name>"
    Write-Host "  powershell -File .\agy-switch.ps1 switch <name>   - Switch to saved account <name>"
    Write-Host "  powershell -File .\agy-switch.ps1 remove <name>   - Remove saved account <name>"
    Write-Host "  powershell -File .\agy-switch.ps1 status          - Display active account details"
    Write-Host ""
}

$command = $args[0]
$name = $args[1]

switch ($command) {
    "list" {
        $activeCred = Get-ActiveCredential
        $activeRefreshToken = if ($activeCred -ne $null) { $activeCred.token.refresh_token } else { $null }

        $files = Get-ChildItem -Path $AccountsDir -Filter *.json
        Write-Host "Saved Accounts:" -ForegroundColor Yellow
        Write-Host "--------------------------------------------------"
        if ($files.Count -eq 0) {
            Write-Host "  (No saved accounts found. Use 'save <name>' to save current account.)" -ForegroundColor Gray
        } else {
            foreach ($file in $files) {
                try {
                    $content = Get-Content -Path $file.FullName -Raw | ConvertFrom-Json
                    $credObj = ConvertFrom-Json $content.credential_blob
                    $isCurrent = ($activeRefreshToken -ne $null -and $credObj.token.refresh_token -eq $activeRefreshToken)
                    
                    $prefix = if ($isCurrent) { "* " } else { "  " }
                    $suffix = if ($isCurrent) { " [ACTIVE]" } else { "" }
                    $color = if ($isCurrent) { "Green" } else { "White" }
                    
                    Write-Host "$prefix$($content.name) ($($content.email))$suffix" -ForegroundColor $color
                } catch {
                    Write-Host "  Error reading $($file.Name)" -ForegroundColor Red
                }
            }
        }
        Write-Host "--------------------------------------------------"
    }

    "save" {
        if ([string]::IsNullOrEmpty($name)) {
            Write-Host "Error: Please specify a name to save the account as. (e.g. .\agy-switch.ps1 save work)" -ForegroundColor Red
            exit
        }

        # Check if active credential exists in Credential Manager
        $bytes = [CredMan]::GetCredentialBlob("gemini:antigravity")
        if ($bytes -eq $null) {
            Write-Host "Error: No active Antigravity login session found in system keyring." -ForegroundColor Red
            Write-Host "Please run 'agy auth login' or similar CLI command first to authenticate." -ForegroundColor Gray
            exit
        }

        $rawCred = [System.Text.Encoding]::UTF8.GetString($bytes)
        $credObj = ConvertFrom-Json $rawCred

        Write-Host "Retrieving account email from Google..." -ForegroundColor Gray
        $email = Get-EmailFromToken $credObj.token.access_token
        if ($email -eq $null) {
            Write-Host "Warning: Access token might be expired or offline. Cannot fetch email directly." -ForegroundColor Yellow
            $email = Read-Host "Please enter the email address for this account manually"
            if ([string]::IsNullOrEmpty($email)) {
                $email = "Unknown Email"
            }
        }

        $wrapper = @{
            name = $name
            email = $email
            saved_at = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
            credential_blob = $rawCred
        } | ConvertTo-Json

        $targetFile = Join-Path $AccountsDir "$name.json"
        $wrapper | Out-File -FilePath $targetFile -Encoding utf8 -Force
        Write-Host "Successfully saved account '$name' ($email)!" -ForegroundColor Green
    }

    "switch" {
        if ([string]::IsNullOrEmpty($name)) {
            Write-Host "Error: Please specify the account name to switch to. (e.g. .\agy-switch.ps1 switch work)" -ForegroundColor Red
            exit
        }

        $targetFile = Join-Path $AccountsDir "$name.json"
        if (-not (Test-Path $targetFile)) {
            Write-Host "Error: Saved account '$name' not found." -ForegroundColor Red
            exit
        }

        $content = Get-Content -Path $targetFile -Raw | ConvertFrom-Json
        $blobBytes = [System.Text.Encoding]::UTF8.GetBytes($content.credential_blob)

        # Write to Windows Credential Manager
        $res = [CredMan]::SetCredentialBlob("gemini:antigravity", "antigravity", $blobBytes)
        if ($res) {
            Write-Host "Successfully switched to account '$name' ($($content.email))!" -ForegroundColor Green
        } else {
            Write-Host "Error: Failed to write credentials to system keyring." -ForegroundColor Red
        }
    }

    "remove" {
        if ([string]::IsNullOrEmpty($name)) {
            Write-Host "Error: Please specify the account name to remove. (e.g. .\agy-switch.ps1 remove work)" -ForegroundColor Red
            exit
        }

        $targetFile = Join-Path $AccountsDir "$name.json"
        if (-not (Test-Path $targetFile)) {
            Write-Host "Error: Saved account '$name' not found." -ForegroundColor Red
            exit
        }

        Remove-Item -Path $targetFile -Force
        Write-Host "Successfully removed saved account '$name'." -ForegroundColor Green
    }

    "status" {
        $activeCred = Get-ActiveCredential
        if ($activeCred -eq $null) {
            Write-Host "Status: Not logged in" -ForegroundColor Red
        } else {
            $email = Get-EmailFromToken $activeCred.token.access_token
            if ($email -eq $null) {
                $email = "Unknown (Access token expired. Run any agy command to refresh it.)"
            }
            Write-Host "Active Account: $email" -ForegroundColor Green
            Write-Host "Auth Method:    $($activeCred.auth_method)"
            
            # Expiry date
            $exp = $activeCred.token.expiry
            if ($exp -match '^\d+$') {
                $expDate = [TimeZoneInfo]::ConvertTimeFromUtc((Get-Date "1970-01-01").AddMilliseconds([double]$exp), [TimeZoneInfo]::Local)
            } else {
                try {
                    $expDate = [DateTime]::Parse($exp).ToLocalTime()
                } catch {
                    $expDate = $exp
                }
            }
            Write-Host "Token Expiry:   $expDate"
        }
    }

    default {
        Show-Help
    }
}

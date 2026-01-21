function Test-SupportsRawUI { try { return $Host.UI.RawUI.CursorVisible -ne $null -and $Host.UI.RawUI.CanSetCursorPosition } catch { return $false } }

function Hide-Cursor { if (Test-SupportsRawUI) { $Host.UI.RawUI.CursorVisible = $false } }

function Show-Cursor { if (Test-SupportsRawUI) { $Host.UI.RawUI.CursorVisible = $true } }

function Pause {
    Write-Host "`nPress any key to continue..." -ForegroundColor DarkGray
    $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") | Out-Null
}

function Exit-Script {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline=$false)]
        [string]$Message = $("Exiting {0}..." -f ($script:Title -or 'Profile Manager'))
    )
    if (Get-Variable -Name 'OnExitCleanup' -Scope Script -ErrorAction SilentlyContinue) {
        try {
            if ($script:OnExitCleanup -is [scriptblock]) {
                & $script:OnExitCleanup
            } else {
                & $script:OnExitCleanup 2>$null
            }
        } catch {
            Write-Verbose "OnExitCleanup failed: $($_.Exception.Message)"
        }
    }
    Write-Host $Message
    return
}

function Quit-Script {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline=$false)]
        [int]$ExitCode = 0
    )
    if (Get-Variable -Name 'OnExitCleanup' -Scope Script -ErrorAction SilentlyContinue) {
        try {
            if ($script:OnExitCleanup -is [scriptblock]) {
                & $script:OnExitCleanup
            } else {
                & $script:OnExitCleanup 2>$null
            }
        } catch {
            Write-Verbose "OnExitCleanup failed: $($_.Exception.Message)"
        }
    }
    Write-Host 'Quitting PowerShell...'
    exit $ExitCode
}

function Stop-Script {
    [CmdletBinding()]
    param()
    Write-Host 'Stopping menu loop...'
    $script:MenuStop = $true
}

function Reset-Script {
    [CmdletBinding()]
    param()
    $script:MenuStop = $false
}
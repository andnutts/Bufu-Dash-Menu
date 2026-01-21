function Write-Log {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateSet('Info', 'Warning', 'Error', 'Debug')]
        [string]$Level,
        [Parameter(Mandatory=$true)]
        [string]$Message
    )
    $logFile = Get-CurrentLogFile
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "$timestamp [$Level] $Message"
    if (-not (Test-Path $LogDirectory)) {
        New-Item -Path $LogDirectory -ItemType Directory -Force | Out-Null
    }
    Add-Content -Path $logFile -Value $logEntry -Encoding UTF8
    Cleanup-LogFiles
}

function Get-CurrentLogFile { $datePart = Get-Date -Format "yyyyMMdd"; return Join-Path -Path $LogDirectory -ChildPath "ProfileMenu_$datePart.log" }

function Cleanup-LogFiles {
    $allLogs = Get-ChildItem -Path $LogDirectory -Filter $LogFilePattern | Sort-Object CreationTime -Descending
    #region --- Size Limit Check (optional: can be resource intensive on large directories) ---
    $maxSize = 5MB
    $largeFiles = $allLogs | Where-Object { $_.Length -gt $maxSize } | Sort-Object Length -Descending
    foreach ($file in $largeFiles) {
        Remove-Item -Path $file.FullName -Force -ErrorAction SilentlyContinue
    }
    #endregion
    #region --- Count Limit Check ---
    if ($allLogs.Count -gt $script:MaxLogFiles) {
        $filesToDelete = $allLogs | Select-Object -Skip $script:MaxLogFiles
        foreach ($file in $filesToDelete) {
            Remove-Item -Path $file.FullName -Force -ErrorAction SilentlyContinue
        }
    }
    #endregion
}
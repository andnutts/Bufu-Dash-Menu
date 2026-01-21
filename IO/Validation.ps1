function Test-File {
    param([string]$Path)
    if (-not (Test-Path $Path)) {
        Write-Err "File not found: $Path"
        return $false
    }
    return $true
}

function Confirm-YesNo {
    param(
        [string]$Message = 'Proceed?',
        [ScriptBlock]$ConfirmFunction = $null
    )
    if (-not $ConfirmFunction) {
        $ConfirmFunction = { param($m) (Read-Host "$m (y/N)") -match '^(y|Y)' }
    }
    return & $ConfirmFunction $Message
}
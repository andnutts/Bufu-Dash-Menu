function Read-Confirmation {
    param([string]$Message, [bool]$DefaultYes = $true)
    while ($true) {
        $def = if ($DefaultYes) { 'Y' } else { 'N' }
        Write-PromptLine "$Message [Y/N] (default $def)"
        $resp = Read-Host
        if ([string]::IsNullOrWhiteSpace($resp)) { return $DefaultYes }
        $c = $resp.Trim().Substring(0,1).ToUpper()
        if ($c -eq 'Y') { return $true }
        if ($c -eq 'N') { return $false }
    }
}
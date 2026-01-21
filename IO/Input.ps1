function Read-Path {
    [OutputType([string])]
    param(
        [string]$Message,
        [string]$DefaultPath = $global:LastPath
    )
    if ([string]::IsNullOrWhiteSpace($DefaultPath)) { $DefaultPath = (Get-Location).Path }
    while ($true) {
        $inputPath = Read-Host -Prompt "$Message (Default: '$DefaultPath')"
        if ([string]::IsNullOrWhiteSpace($inputPath)) { $inputPath = $DefaultPath }
        if ($inputPath -match '^\$[A-Za-z_]\w*') { Write-ColoredText "Invalid variable reference." -ForegroundColor Red; continue }
        if (Test-Path -Path $inputPath) { $global:LastPath = $inputPath; return $inputPath }
        else { Write-Color -Message "Path not found. Please try again." -ForegroundColor $Theme.PromptErrorColor }
    }
}

function Prompt-ChooseFile {
    param(
        [string]$Message = 'Choose a .psm1 file',
        [bool]$AllowFilesystemSearch = $true,
        [ScriptBlock]$PromptFunction = $null
    )
    if (-not $PromptFunction) {
        $PromptFunction = {
            param($m,$a)
            if (Get-Command Out-GridView -ErrorAction SilentlyContinue) {
                Get-ChildItem -Path (Get-Location) -Filter '*.psm1' -Recurse -ErrorAction SilentlyContinue |
                    Select-Object -ExpandProperty FullName | Out-GridView -Title $m -PassThru
            } else {
                Read-Host "$m`n(enter full path or blank to cancel)"
            }
        }
    }
    return & $PromptFunction $Message $AllowFilesystemSearch
}
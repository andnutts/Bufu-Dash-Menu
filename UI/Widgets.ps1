function Show-ProgressBar {
    param(
        [int]$Percent,
        [int]$Top,
        [int]$Left=0,
        [int]$Width=50,
        [string]$Label=""
    )
    $filledLength = [math]::Floor($Width * $Percent / 100)
    $emptyLength  = $Width - $filledLength
    $bar = "█" * $filledLength + "-" * $emptyLength
    Write-ColoredInline -Text "[$bar] $Percent% $Label" -FgColor Green -BgColor Black -Left $Left -Top $Top
}

function Show-ThroughputGraph {
    param([double]$BytesPerSec)
    $width = [math]::Min(50,$Host.UI.RawUI.WindowSize.Width-10)
    $barLength = [math]::Min($width, [math]::Floor($BytesPerSec / 1MB))
    $bar = '█' * $barLength
    $line = "{0,-6} MB/s |{1}" -f [math]::Round($BytesPerSec/1MB,1), $bar
    Write-ColoredInline $line -FgColor Cyan
    Write-Host ""
}
function Write-Blank {
    param(
        [int]$Count = 1
    )
    for ($i = 0; $i -lt $Count; $i++) { Write-Host "" }
}

function Write-Colored {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [AllowEmptyString()]
        [string[]]$Text,
        [ValidateSet('Left','Center','Right')]
        [string]$Align          = 'Center',
        [ConsoleColor]$FgColor  = 'White',
        [ConsoleColor]$BgColor  = 'Black',
        [int]$LeftPadding       = 0,
        [int]$BlockPadding      = 1,
        [switch]$VerticalCenter,
        [switch]$ToggleBlock,
        [switch]$NoNewline
    )
    begin {
        $ui     = $Host.UI.RawUI
        $width  = $ui.WindowSize.Width
        $height = $ui.WindowSize.Height
        $coerceColor = {
            param($c, $default)
            if ($null -eq $c) { return $default }
            if ($c -is [System.ConsoleColor]) { return $c }
            try { return [System.ConsoleColor]::Parse([System.ConsoleColor], [string]$c) } catch {
                try { return [System.ConsoleColor][string]$c } catch { return $default }
            }
        }
        $fgEnum = & $coerceColor $FgColor [ConsoleColor]::White
        $bgEnum = & $coerceColor $BgColor [ConsoleColor]::Black
    }
    process {
        if ($Text -and ($Text -is [System.Array]) -and ($Text.Count -gt 0) -and ($Text -join '') -eq '') {
            foreach ($i in 1..$Text.Count) { Write-Host "" }
            return
        }
        if (-not $Text -or ($Text -is [string] -and [string]::IsNullOrEmpty($Text))) {
            Write-Host ""
            return
        }
        $lines = $Text
        if ($VerticalCenter) {
            $topPadding = [math]::Max(0, [math]::Floor(($height - $lines.Count) / 2))
            for ($i = 0; $i -lt $topPadding; $i++) { Write-Host "" }
        }
        foreach ($line in $lines) {
            $lineText = if ($null -eq $line) { '' } else { [string]$line }
            if ($ToggleBlock) {
                $blockWidth = $lineText.Length + (2 * [math]::Max(0, $BlockPadding))
                switch ($Align) {
                    'Left'  { $left = $LeftPadding }
                    'Right' { $left = [math]::Max(0, $width - $blockWidth - $LeftPadding) }
                    'Center'{ $left = [math]::Max(0, [math]::Floor(($width - $blockWidth) / 2) + $LeftPadding) }
                }
                if ($left -gt 0) { Write-Host (' ' * $left) -NoNewline }
                if ($BlockPadding -gt 0) { Write-Host -NoNewline (' ' * $BlockPadding) -ForegroundColor $fgEnum -BackgroundColor $bgEnum }
                Write-Host -NoNewline $lineText -ForegroundColor $fgEnum -BackgroundColor $bgEnum
                if ($BlockPadding -gt 0) { Write-Host -NoNewline (' ' * $BlockPadding) -ForegroundColor $fgEnum -BackgroundColor $bgEnum }
                if (-not $NoNewline) { Write-Host "" }
            } else {
                $textLength = $lineText.Length
                switch ($Align) {
                    'Left'   { $left = $LeftPadding }
                    'Right'  { $left = [math]::Max(0, $width - $textLength - $LeftPadding) }
                    'Center' { $left = [math]::Max(0, [math]::Floor(($width - $textLength) / 2) + $LeftPadding) }
                }
                if ($left -gt 0) { Write-Host (' ' * $left) -NoNewline }
                if ($NoNewline) {
                    Write-Host -NoNewline $lineText -ForegroundColor $fgEnum -BackgroundColor $bgEnum
                } else {
                    Write-Host $lineText -ForegroundColor $fgEnum -BackgroundColor $bgEnum
                }
            }
        }
    }
    end { }
}

function Write-ColoredInline {
    param(
        [string]$Text,
        [ConsoleColor]$FgColor = 'White',
        [ConsoleColor]$BgColor = 'Black',
        [int]$Left = $null,
        [int]$Top = $null,
        [switch]$Blink
    )
    if ($Left -ne $null -and $Top -ne $null) {
        $Host.UI.RawUI.CursorPosition = @{X=$Left;Y=$Top}
    }
    if ($Blink) { $Text = "$([char]27)[5m$Text$([char]27)[25m" }
    Write-Host $Text -NoNewline -ForegroundColor $FgColor -BackgroundColor $BgColor
}
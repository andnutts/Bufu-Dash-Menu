function Start-Timer {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [int]$Seconds = 20
    )
    return (Get-Date).AddSeconds([math]::Max(0, [int]$Seconds))
}

function Pause-ForReview {
    [CmdletBinding()]
    param(
        [int]$TimeoutSeconds = 15,
        [string]$Prompt = "Press Enter to continue or wait {0} seconds...",
        [switch]$ShowCountdown
    )
    try {
        $infoCol = (Get-ThemeColor -Role 'Info').Fg
        $infoBg  = (Get-ThemeColor -Role 'Info').Bg
        $warnCol = (Get-ThemeColor -Role 'Warn').Fg
        $succCol = (Get-ThemeColor -Role 'Success').Fg
    } catch {
        $infoCol = 'White'; $infoBg = 'Black'; $warnCol = 'Yellow'; $succCol = 'Green'
    }
    $promptText = [string]::Format($Prompt, $TimeoutSeconds)
    Write-Colored -Text $promptText -FgColor $infoCol -BgColor $infoBg -Align $Config.Align
    $end = (Get-Date).AddSeconds([math]::Max(0, [int]$TimeoutSeconds))
    $keyPressed = $false
    # single-line countdown renderer using Write-Colored -NoNewline
    $renderCountdown = {
        param($remaining)
        $countMsg = "Continuing in $remaining s..."
        $cr = "`r"
        Write-Host -NoNewline $cr
        Write-Colored -Text $countMsg -FgColor $infoCol -BgColor $infoBg -Align $Config.Align -LeftPadding 0 -NoNewline
        Write-Host -NoNewline (' ' * 10)
    }
    if ($ShowCountdown) {
        $remaining = [math]::Ceiling(($end - (Get-Date)).TotalSeconds)
        & $renderCountdown $remaining
    }
    while ((Get-Date) -lt $end) {
        try {
            if ([Console]::KeyAvailable) {
                $cki = [Console]::ReadKey($true)
                $keyPressed = $true
                break
            }
        } catch {
            Start-Sleep -Milliseconds 200
        }
        if ($ShowCountdown) {
            $remaining = [math]::Ceiling(($end - (Get-Date)).TotalSeconds)
            & $renderCountdown $remaining
        }

        Start-Sleep -Milliseconds 500
    }
    # finalize: move to next line and print status
    Write-Host ""
    if ($keyPressed) {
        Write-Colored -Text "Key pressed, continuing..." -FgColor $succCol -Align $Config.Align
        return $true
    } else {
        Write-Colored -Text ("Timed out after {0} seconds, continuing..." -f $TimeoutSeconds) -FgColor $warnCol -Align $Config.Align
        return $false
    }
    Start-Sleep -Milliseconds 200
}

function Show-Help {
    param(
        [switch]$Pause
    )

    Clear-Host

    # Header
    Write-Title "Usage: .\ventoy_clonezilla_persist_colored.ps1 [options]"

    # Options
    Write-Menu ""
    Write-Menu "Options:"
    Write-Menu "  -h, --help           Show this help message and exit"
    Write-Menu "  -i, --interactive     Force interactive USB selection menu (useful when multiple removable drives present)"
    Write-Menu "  --theme              Launch interactive theme preview and picker before main flow"
    Write-Menu "  --theme <name>       Set theme non-interactively (Default, Dark, Light, Solarized)"
    Write-Menu "  --dry-run            Show actions without making changes"
    Write-Menu "  --debug              Enable verbose debug output"
    Write-Menu ""

    # Examples
    Write-Info "Examples:"
    Write-Info "  .\ventoy_clonezilla_persist_colored.ps1 --theme"
    Write-Info "  .\ventoy_clonezilla_persist_colored.ps1 --theme Dark"
    Write-Info "  .\ventoy_clonezilla_persist_colored.ps1 -h"
    Write-Info ""

    # Notes / tips
    Write-Menu "Notes:"
    Write-Menu "  Run this script as Administrator."
    Write-Menu "  Persistent defaults are saved to $env:USERPROFILE\.ventoy_clonezilla_config.json"
    Write-Menu ""

    # Optional pause so user can read help (uses Pause-ForReview if available)
    if ($Pause) {
        if (Get-Command Pause-ForReview -ErrorAction SilentlyContinue) {
            Pause-ForReview -TimeoutSeconds 15 -ShowCountdown
        } else {
            Read-Host -Prompt "Press Enter to continue"
        }
    }
}

function Invoke-CommandLine {
    param([string[]]$RawArgs)
    if ($PSBoundParameters.ContainsKey('Help') -or $PSBoundParameters.ContainsKey('H')) {
        Show-Help; exit 0
    }
    $argsList = @()
    if ($RawArgs) { $argsList = $RawArgs }
    foreach ($a in $argsList) {
        if ($a -in @('-h','--help','-help')) { Show-Help; exit 0 }
    }
    $themeArgIndex = $null
    for ($i = 0; $i -lt $argsList.Count; $i++) {
        $a = $argsList[$i].ToLower()
        if ($a -eq '--theme') { $themeArgIndex = $i; break }
    }
    if ($null -ne $themeArgIndex) {
        if ($themeArgIndex + 1 -lt $argsList.Count) {
            $candidate = $argsList[$themeArgIndex + 1]
            if ($candidate -notmatch '^-' ) {
                $candidateName = ($candidate.Substring(0,1).ToUpper() + $candidate.Substring(1).ToLower())
                if ($Themes.ContainsKey($candidateName)) {
                    $Config.Theme = $candidateName
                    Set-Theme
                    Write-Success "Theme set to '$candidateName' from command line."
                    return
                } else {
                    Write-Warn "Theme '$candidate' not found. Launching interactive picker."
                    $picked = Get-ThemeSelection
                    return
                }
            } else {
                $picked = Get-ThemeSelection
                return
            }
        } else {
            $picked = Get-ThemeSelection
            if ($null -ne $picked) {
                $Config.Theme = $picked
                Set-Theme
                Write-Success "Theme set to '$picked'."
            }
            return
        }
    }
    foreach ($a in $argsList) {
        if ($a -like '--theme=*') {
            $parts = $a.Split('=',2)
            $candidate = $parts[1]
            $candidateName = ($candidate.Substring(0,1).ToUpper() + $candidate.Substring(1).ToLower())
            if ($Themes.ContainsKey($candidateName)) {
                $Config.Theme = $candidateName
                Set-Theme
                Write-Success "Theme set to '$candidateName' from command line."
                return
            } else {
                Write-Warn "Theme '$candidate' not found. Launching interactive picker."
                $picked = Get-ThemeSelection
                return
            }
        }
        if ($a -eq '-theme') {
            $idx = [Array]::IndexOf($argsList, $a)
            if ($idx + 1 -lt $argsList.Count) {
                $candidate = $argsList[$idx + 1]
                if ($candidate -notmatch '^-' ) {
                    $candidateName = ($candidate.Substring(0,1).ToUpper() + $candidate.Substring(1).ToLower())
                    if ($Themes.ContainsKey($candidateName)) {
                        $Config.Theme = $candidateName
                        Set-Theme
                        Write-Success "Theme set to '$candidateName' from command line."
                        return
                    }
                }
            }
            $picked = Get-ThemeSelection
            return
        }
    }
}

function Get-MenuKeyAction {
    <#
      .SYNOPSIS
        Capture a single key press and convert it into a normalized menu action.
      .DESCRIPTION
        Uses the ConsoleKey ($key.Key) for matching. Handles arrows, Enter/Space,
        Home/End/PageUp/PageDown, digits (top row and numpad) mapped to Jump,
        printable letters (returned as Letter with uppercase value), Ctrl+C -> Exit.
        When -MultiSelect is $true the Spacebar returns Action = 'Toggle' so the caller
        can add/remove the current SelectedIndex from a selection set.
      .PARAMETER OptionsCount
        Total number of menu options (used for wrapping and numeric jumps). Default 0.
      .PARAMETER SelectedIndex
        Current selected index (0-based). Default 0.
      .PARAMETER MultiSelect
        When present/true, Spacebar will return Action = 'Toggle' instead of 'Enter'.
      .PARAMETER OnEnter
        Optional scriptblock invoked when Enter is pressed. Receives the SelectedIndex.
      .PARAMETER OnExit
        Optional scriptblock invoked when Exit is requested.
      .OUTPUTS
        PSCustomObject with keys: Action, SelectedIndex, RawKey, KeyName, Char, Letter (when Action = 'Letter').
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)][int]$OptionsCount = 0,
        [Parameter(Mandatory = $false)][int]$SelectedIndex = 0,
        [Parameter(Mandatory = $false)][switch]$MultiSelect,
        [Parameter(Mandatory = $false)][ScriptBlock]$OnEnter,
        [Parameter(Mandatory = $false)][ScriptBlock]$OnExit
    )
    $raw = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
    $keyName = $raw.Key.ToString()
    $ch = if ($raw.Character -and $raw.Character -ne [char]0) { $raw.Character } else { '' }
    if ($raw.ControlKeyState -band [System.ConsoleModifiers]::Control -and ($raw.Character -eq [char]3)) {
        if ($OnExit) { & $OnExit.Invoke() }
        return [PSCustomObject]@{
            Action        = 'Exit'
            SelectedIndex = $SelectedIndex
            RawKey        = $raw
            KeyName       = $keyName
            Char          = $ch
        }
    }
    switch ($keyName) {
        'Enter' {
            if ($OnEnter) { & $OnEnter.Invoke($SelectedIndex) }
            return [PSCustomObject]@{
                Action        = 'Enter'
                SelectedIndex = $SelectedIndex
                RawKey        = $raw
                KeyName       = $keyName
                Char          = $ch
            }
        }
        'Spacebar' {
            if ($MultiSelect) {
                return [PSCustomObject]@{
                    Action        = 'Toggle'
                    SelectedIndex = $SelectedIndex
                    RawKey        = $raw
                    KeyName       = $keyName
                    Char          = $ch
                }
            } else {
                if ($OnEnter) { & $OnEnter.Invoke($SelectedIndex) }
                return [PSCustomObject]@{
                    Action        = 'Enter'
                    SelectedIndex = $SelectedIndex
                    RawKey        = $raw
                    KeyName       = $keyName
                    Char          = $ch
                }
            }
        }
        'Escape' {
            if ($OnExit) { & $OnExit.Invoke() }
            return [PSCustomObject]@{
                Action        = 'Exit'
                SelectedIndex = $SelectedIndex
                RawKey        = $raw
                KeyName       = $keyName
                Char          = $ch
            }
        }
        'Home' {
            return [PSCustomObject]@{
                Action        = 'Jump'
                SelectedIndex = 0
                RawKey        = $raw
                KeyName       = $keyName
                Char          = $ch
            }
        }
        'End' {
            $last = [Math]::Max(0, $OptionsCount - 1)
            return [PSCustomObject]@{
                Action        = 'Jump'
                SelectedIndex = $last
                RawKey        = $raw
                KeyName       = $keyName
                Char          = $ch
            }
        }
        'PageUp' {
            $new = [System.Math]::Max(0, $SelectedIndex - 10)
            return [PSCustomObject]@{
                Action        = 'Jump'
                SelectedIndex = $new
                RawKey        = $raw
                KeyName       = $keyName
                Char          = $ch
            }
        }
        'PageDown' {
            $new = [System.Math]::Min([Math]::Max(0, $OptionsCount - 1), $SelectedIndex + 10)
            return [PSCustomObject]@{
                Action        = 'Jump'
                SelectedIndex = $new
                RawKey        = $raw
                KeyName       = $keyName
                Char          = $ch
            }
        }
        'UpArrow' {
            if ($OptionsCount -gt 0) {
                $new = $SelectedIndex - 1
                if ($new -lt 0) { $new = $OptionsCount - 1 }
            } else { $new = $SelectedIndex }
            return [PSCustomObject]@{
                Action        = 'Up'
                SelectedIndex = $new
                RawKey        = $raw
                KeyName       = $keyName
                Char          = $ch
            }
        }
        'DownArrow' {
            if ($OptionsCount -gt 0) {
                $new = $SelectedIndex + 1
                if ($new -ge $OptionsCount) { $new = 0 }
            } else { $new = $SelectedIndex }
            return [PSCustomObject]@{
                Action        = 'Down'
                SelectedIndex = $new
                RawKey        = $raw
                KeyName       = $keyName
                Char          = $ch
            }
        }
    }
    if ($keyName -match '^D([0-9])$' -or $keyName -match '^NumPad([0-9])$') {
        $m = [regex]::Match($keyName, '\d')
        if ($m.Success) {
            $digit = [int]$m.Value
            if ($digit -gt 0 -and $digit -le $OptionsCount) {
                return [PSCustomObject]@{
                    Action        = 'Jump'
                    SelectedIndex = $digit - 1
                    RawKey        = $raw
                    KeyName       = $keyName
                    Char          = $ch
                }
            } else {
                return [PSCustomObject]@{
                    Action        = 'NoOp'
                    SelectedIndex = $SelectedIndex
                    RawKey        = $raw
                    KeyName       = $keyName
                    Char          = $ch
                }
            }
        }
    }
    if ($ch) {
        try { $letter = $ch.ToString().ToUpperInvariant() } catch { $letter = $ch }
        return [PSCustomObject]@{
            Action        = 'Letter'
            SelectedIndex = $SelectedIndex
            RawKey        = $raw
            KeyName       = $keyName
            Char          = $ch
            Letter        = $letter
        }
    }
    return [PSCustomObject]@{
        Action        = 'NoOp'
        SelectedIndex = $SelectedIndex
        RawKey        = $raw
        KeyName       = $keyName
        Char          = $ch
    }
}

function Read-MenuKey {
    param(
        [Parameter(Mandatory)][array]$MenuSwitches,
        [Parameter(Mandatory)][ValidateSet('Arrow','Numeric')][string]$Mode
    )
    $raw = [System.Console]::ReadKey($true)
    $char = ''
    try { $char = $raw.KeyChar.ToString() } catch { $char = '' }
    $intent = 'Other'
    $switchId = $null
    $number = $null
    switch ($raw.Key) {
        'UpArrow'    { $intent = 'Up' }
        'DownArrow'  { $intent = 'Down' }
        'Enter'      { $intent = 'Enter' }
        'Escape'     { $intent = 'Escape' }
        'Q'          { $intent = 'Exit' }
        default      { }
    }
    if ($char) {
        $u = $char.ToUpper()
        if ($MenuSwitches -and ($MenuSwitches | Where-Object Id -EQ $u)) {
            $intent = 'Switch'
            $switchId = $u
        }
        if ($Mode -eq 'Numeric' -and $char -match '^\d$' -and $intent -ne 'Switch') {
            $n = [int]$char
            if ($n -ge 1) {
                $intent = 'Number'
                $number = $n
            }
        }
    }
    return [PSCustomObject]@{
        Key        = $raw.Key
        KeyChar    = $char
        Intent     = $intent
        SwitchId   = $switchId
        Number     = $number
        RawKeyInfo = $raw
    }
}

function Render-FullMenu {
    param(
        [int]$Selected,
        [string]$Mode,
        [array]$MenuSwitches,
        [array]$MenuItems,
        [string]$Title,
        [string]$ScriptDir
    )
    try { Clear-Host } catch { [Console]::Clear() }
    Show-Header -Title $Title -ScriptDir $ScriptDir -MenuSwitches $MenuSwitches
    Show-StatusBar -ScriptDir $ScriptDir -MenuSwitches $MenuSwitches
    Show-CenteredLine -Token '' -TokenColored:$false -Text ('─' * 40) -TextColored:$false -TextFg 'Gray'
    for ($i = 0; $i -lt $MenuItems.Count; $i++) {
        $itemName = $MenuItems[$i].Name
        if ($Mode -eq 'Arrow') {
            $indicator = if ($i -eq $Selected) { '->' } else { ' ' }
            $fg = if ($i -eq $Selected) { 'White' } else { 'White' }
            $bg = if ($i -eq $Selected) { 'DarkBlue' } else { 'Black' }
            if ($i -eq $Selected) {
                Show-CenteredLine -Token '->' -TokenColored:$true -Text $itemName -TokenFg 'Black' -TokenBg 'Yellow' -TextFg $fg -TextBg $bg -TextColored:$true
            } else {
                Show-CenteredLine -Token ' ' -TokenColored:$false -Text (" $($itemName)") -TextColored:$false -TextFg 'White'
            }
        } else {
            $label = ('{0}:' -f ($i + 1)).PadRight(3)
            $fg = if ($i -eq $Selected) { 'White' } else { 'White' }
            $bg = if ($i -eq $Selected) { 'DarkBlue' } else { 'Black' }
            if ($i -eq $Selected) {
                Show-CenteredLine -Token $label -TokenColored:$true -Text $itemName -TokenFg 'Black' -TokenBg 'Yellow' -TextFg $fg -TextBg $bg -TextColored:$true
            } else {
                Show-CenteredLine -Token $label -TokenColored:$true -Text $itemName -TokenFg 'Yellow' -TokenBg 'Black' -TextColored:$false -TextFg 'White'
            }
        }
    }
    Show-CenteredLine -Token '' -TokenColored:$false -Text ('-' * 45) -TextColored:$false -TextFg 'Gray'
    Show-Footer -Mode $Mode -MenuItems $MenuItems -MenuSwitches $MenuSwitches
}

function Invoke-MenuEntry {
    param(
        [Parameter(Mandatory)][object]$Entry,
        [Parameter(Mandatory)][string]$ScriptDir,
        [Parameter(Mandatory)][array]$MenuSwitches
    )
    $debugFlag = (Get-SwitchById -MenuSwitches $MenuSwitches -Id 'D').State
    $dryRunFlag = (Get-SwitchById -MenuSwitches $MenuSwitches -Id 'R').State
    if ($dryRunFlag) {
        Write-Host "DRY RUN MODE: Command not executed." -ForegroundColor Yellow
        if ($Entry.PSObject.Properties['File']) {
            Write-Host "Target: $($Entry.File) (Type: $($Entry.Type))`n" -ForegroundColor Yellow
        } elseif ($Entry.PSObject.Properties['Action']) {
            Write-Host "Action: $($Entry.Name)`n" -ForegroundColor Yellow
        }
        return $true
    }
    if ($Entry.PSObject.Properties['Action'] -and $Entry.Action -is [ScriptBlock]) {
        Write-Host "`n[Running: $($Entry.Name)...]`n" -ForegroundColor Yellow
        try {
            $result = & $Entry.Action
            if ($result -eq 'Exit') {
                return 'quit'
            }
            return $true
        } catch {
            Write-Colored -Text "`nERROR during action '$($Entry.Name)': $($_.Exception.Message)`n" -Fg 'White' -Bg 'DarkRed'
            return $false
        }
    }
    if (-not $Entry.PSObject.Properties['File']) {
        Write-Warning "Menu entry '$($Entry.Name)' has no 'Action' or 'File' defined."
        return $false
    }
    $scriptPath = Join-Path -Path $ScriptDir -ChildPath $Entry.File
    if (-not (Test-Path $scriptPath)) {
        Write-Colored -Text "Script not found: $scriptPath`n" -Fg 'White' -Bg 'DarkRed'
        return $false
    }
    Write-Host "`n[Running: $($Entry.Name)...]`n" -ForegroundColor Yellow
    switch ($Entry.Type) {
        'GUI' {
            Write-Host "Starting GUI script in new process..." -ForegroundColor DarkCyan
            Start-Process -FilePath "python" -ArgumentList @($scriptPath) -ErrorAction SilentlyContinue
        }
        'CMD' {
            Write-Host "Executing CMD script inline..." -ForegroundColor DarkCyan
            $argList = @($scriptPath)
            if ($debugFlag) { $argList += '--verbose' }
            & python @argList
        }
        'PS1' {
            Write-Host "Executing PowerShell script inline..." -ForegroundColor DarkCyan
            . $scriptPath
        }
        default {
            Write-Host "Starting generic process..." -ForegroundColor DarkCyan
            Start-Process -FilePath "python" -ArgumentList @($scriptPath) -ErrorAction SilentlyContinue
        }
    }
    return $true
}
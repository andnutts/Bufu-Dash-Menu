function Get-ThemeColor {
    param([string]$Role)
    $themeName = $Config.Theme
    if (-not $themeName -or -not $Themes.ContainsKey($themeName)) {
        $themeName = 'Default'
    }
    $roleMap = $Themes[$themeName]
    if (-not $roleMap) { $roleMap = $Themes['Default'] }
    # If role missing, fallback to Info role
    if (-not $roleMap.ContainsKey($Role)) {
        $Role = 'Info'
    }
    $entry = $roleMap[$Role]
    # Provide safe string defaults if missing
    $safeFg = 'White'
    $safeBg = 'Black'
    if ($entry -and $entry.Fg) { $safeFg = $entry.Fg }
    if ($entry -and $entry.Bg) { $safeBg = $entry.Bg }
    # Try to convert to ConsoleColor; fallback to safe enums
    try {
        $fgEnum = [ConsoleColor]::Parse([ConsoleColor], $safeFg)
    } catch {
        try { $fgEnum = [ConsoleColor]$safeFg } catch { $fgEnum = [ConsoleColor]::White }
    }
    try {
        $bgEnum = [ConsoleColor]::Parse([ConsoleColor], $safeBg)
    } catch {
        try { $bgEnum = [ConsoleColor]$safeBg } catch { $bgEnum = [ConsoleColor]::Black }
    }
    return @{ Fg = $fgEnum; Bg = $bgEnum }
}

function Set-Theme {
    [CmdletBinding(SupportsShouldProcess=$true)]
    param()
    $titleCol   = Get-ThemeColor -Role 'Title'
    $promptCol  = Get-ThemeColor -Role 'PromptLine'
    $readCol    = Get-ThemeColor -Role 'Read'
    $infoCol    = Get-ThemeColor -Role 'Info'
    $succCol    = Get-ThemeColor -Role 'Success'
    $warnCol    = Get-ThemeColor -Role 'Warn'
    $errCol     = Get-ThemeColor -Role 'Err'
    $menuCol    = Get-ThemeColor -Role 'Menu'
    Set-Item -Path Function:Write-Title -Value {
        param([string]$Text)
        $c = Get-ThemeColor -Role 'Title'
        Write-Colored -Text $Text -FgColor $c.Fg -BgColor $c.Bg -Align 'Center'
    }

    Set-Item -Path Function:Write-PromptLine -Value {
        param([string]$Text)
        $c = Get-ThemeColor -Role 'PromptLine'
        Write-Colored -Text $Text -FgColor $c.Fg -BgColor $c.Bg -Align 'Left' -LeftPadding 2
    }

    Set-Item -Path Function:Read-Prompt -Value {
        param([string]$PromptText, [string]$Default = $null)
        $c = Get-ThemeColor -Role 'Read'
        if ($Default) {
            Write-Colored -Text ("{0} [default: {1}]" -f $PromptText, $Default) -FgColor $c.Fg -BgColor $c.Bg -Align 'Left' -LeftPadding 2
        } else {
            Write-Colored -Text $PromptText -FgColor $c.Fg -BgColor $c.Bg -Align 'Left' -LeftPadding 2
        }
        return Read-Host ""
    }

    Set-Item -Path Function:Write-Info -Value {
        param([string]$Text)
        $c = Get-ThemeColor -Role 'Info'
        Write-Colored -Text $Text -FgColor $c.Fg -BgColor $c.Bg -Align 'Left' -LeftPadding 2
    }

    Set-Item -Path Function:Write-Success -Value {
        param([string]$Text)
        $c = Get-ThemeColor -Role 'Success'
        Write-Colored -Text $Text -FgColor $c.Fg -BgColor $c.Bg -Align 'Left' -LeftPadding 2
    }

    Set-Item -Path Function:Write-Warn -Value {
        param([string]$Text)
        $c = Get-ThemeColor -Role 'Warn'
        Write-Colored -Text $Text -FgColor $c.Fg -BgColor $c.Bg -Align 'Left' -LeftPadding 2
    }

    Set-Item -Path Function:Write-Err -Value {
        param([string]$Text)
        $c = Get-ThemeColor -Role 'Err'
        Write-Colored -Text $Text -FgColor $c.Fg -BgColor $c.Bg -Align 'Left' -LeftPadding 2
    }

    Set-Item -Path Function:Write-Menu -Value {
        param([string]$Text)
        $c = Get-ThemeColor -Role 'Menu'
        Write-Colored -Text $Text -FgColor $c.Fg -BgColor $c.Bg -Align 'Left' -LeftPadding 2
    }
    if ($Config.Debug) {
        # Use Get-ThemeColor for preview so we always have valid enums
        $menuPreview = Get-ThemeColor -Role 'Menu'
        Write-Colored -Text $Config.Theme -FgColor $menuPreview.Fg -BgColor $menuPreview.Bg -Align $Config.Align -LeftPadding $Config.Padding

        # Coerce toggle colors to safe enums for preview (fall back to Info/Err roles if missing)
        $onFg = try { [ConsoleColor]::Parse([ConsoleColor], [string]$Config.ToggleOnFg) } catch { (Get-ThemeColor -Role 'Success').Fg }
        $onBg = try { [ConsoleColor]::Parse([ConsoleColor], [string]$Config.ToggleOnBg) } catch { (Get-ThemeColor -Role 'Success').Bg }
        $offFg = try { [ConsoleColor]::Parse([ConsoleColor], [string]$Config.ToggleOffFg) } catch { (Get-ThemeColor -Role 'Err').Fg }
        $offBg = try { [ConsoleColor]::Parse([ConsoleColor], [string]$Config.ToggleOffBg) } catch { (Get-ThemeColor -Role 'Err').Bg }

        Write-Colored -Text $Config.SwitchOnText  -FgColor $onFg  -BgColor $onBg  -Align $Config.Align -LeftPadding $Config.Padding -ToggleBlock -BlockPadding 1
        Write-Colored -Text $Config.SwitchOffText -FgColor $offFg -BgColor $offBg -Align $Config.Align -LeftPadding 0           -ToggleBlock -BlockPadding 1
    } else {
        Write-Title (" Theme: " + $Config.Theme)
        Write-Colored -Text ("Title | PromptLine | Read | Info | Success | Warn | Err | Menu") -FgColor $menuCol.Fg -BgColor $menuCol.Bg -Align Center
    }
}

function Validate-Themes {
    foreach ($t in $Themes.Keys) {
        foreach ($role in $Themes[$t].Keys) {
            $entry = $Themes[$t][$role]
            if (-not $entry.Fg) { $Themes[$t][$role].Fg = 'White' }
            if (-not $entry.Bg) { $Themes[$t][$role].Bg = 'Black' }
            # Optionally test conversion and replace invalid names
            try { [ConsoleColor]::Parse([ConsoleColor], $entry.Fg) } catch { $Themes[$t][$role].Fg = 'White' }
            try { [ConsoleColor]::Parse([ConsoleColor], $entry.Bg) } catch { $Themes[$t][$role].Bg = 'Black' }
        }
    }
}

function Convert-ToConsoleColor {
    param([object]$Value, [ConsoleColor]$Default = [ConsoleColor]::White)
    if ($null -eq $Value) { return $Default }
    if ($Value -is [ConsoleColor]) { return $Value }
    try { return [ConsoleColor]::Parse([ConsoleColor], [string]$Value) } catch {
        try { return [ConsoleColor][string]$Value } catch { return $Default }
    }
}

function Get-Theme { return $Themes.Keys | Sort-Object }

function Get-ThemePreview {
    param([string]$ThemeName)
    if (-not $Themes.ContainsKey($ThemeName)) {
        Write-Warn "Theme '$ThemeName' not found."
        return $false
    }
    $prevTheme = $Config.Theme
    $Config.Theme = $ThemeName
    Set-Theme
    Write-Colored -Text " Theme preview: $ThemeName " -FgColor $((Get-ThemeColor -Role 'Title').Fg) -BgColor $((Get-ThemeColor -Role 'Title').Bg) -Align Center
    Write-Menu "Prompt line example"
    Write-Info "Informational message example"
    Write-Success "Success message example"
    Write-Warn "Warning message example"
    Write-Err "Error message example"
    Write-Menu ""
    Read-Host "Press Enter to continue preview (or Ctrl+C to abort)"
    $Config.Theme = $prevTheme
    Set-Theme
    return $true
}

function Get-ThemeSelection {
    $available = Get-Theme
    if (-not $available -or $available.Count -eq 0) {
        Write-Warn "No themes available."
        return $null
    }
    while ($true) {
        Clear-Host
        Write-Title "Theme picker"
        Write-Menu "Available themes:"
        for ($i = 0; $i -lt $available.Count; $i++) {
            $n = $i + 1
            Write-Colored -Text ("{0}) {1}" -f $n, $available[$i]) -FgColor (Get-ThemeColor -Role 'Menu').Fg -Align Left -LeftPadding 2
        }
        Write-Menu ""
        Write-Menu "Commands: [number] preview and choose  [p <n>] preview only  [q] quit  [c] cancel"
        $choice = Read-Host "Enter choice"
        if ([string]::IsNullOrWhiteSpace($choice)) { continue }
        $parts = $choice.Trim().Split(' ', [System.StringSplitOptions]::RemoveEmptyEntries)
        $cmd = $parts[0].ToLower()

        if ($cmd -eq 'q' -or $cmd -eq 'c') { return $null }

        if ($cmd -eq 'p' -and $parts.Count -ge 2) {
            if ([int]::TryParse($parts[1], [ref]$null)) {
                $idx = [int]$parts[1] - 1
                if ($idx -ge 0 -and $idx -lt $available.Count) {
                    Get-ThemePreview -ThemeName $available[$idx]
                    continue
                } else { Write-Warn "Number out of range"; continue }
            } else { Write-Warn "Invalid number"; continue }
        }
        if ([int]::TryParse($cmd, [ref]$null)) {
            $idx = [int]$cmd - 1
            if ($idx -ge 0 -and $idx -lt $available.Count) {
                $sel = $available[$idx]
                Get-ThemePreview -ThemeName $sel
                $confirm = Read-Confirmation "Set theme to '$sel' and continue?" $true
                if ($confirm) {
                    $Config.Theme = $sel
                    Set-Theme
                    Write-Success "Theme set to '$sel'."
                    return $sel
                } else { Write-Info "Not changed. Returning to theme list."; continue }
            } else { Write-Warn "Number out of range"; continue }
        }
        if ($available -contains $choice) {
            $sel = $choice
            Get-ThemePreview -ThemeName $sel
            if (Read-Confirmation "Set theme to '$sel' and continue?" $true) {
                $Config.Theme = $sel
                Set-Theme
                Write-Success "Theme set to '$sel'."
                return $sel
            } else { continue }
        }
        Write-Warn "Unrecognized input."
    }
}
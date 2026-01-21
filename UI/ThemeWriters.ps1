function Write-Title {
    param([string]$Text)
    $c = Get-ThemeColor -Role 'Title'
    Write-Colored -Text $Text -FgColor $c.Fg -BgColor $c.Bg -Align Center
}

function Write-PromptLine {
    param([string]$Text)
    $c = Get-ThemeColor -Role 'PromptLine'
    Write-Colored -Text $Text -FgColor $c.Fg -BgColor $c.Bg -Align Left -LeftPadding 2
}

function Read-Prompt {
    param(
        [string]$PromptText,
        [string]$Default = $null
    )
    $c = Get-ThemeColor -Role 'Read'
    if ($Default) {
        Write-Colored -Text ("{0} [default: {1}]" -f $PromptText, $Default) -FgColor $c.Fg -BgColor $c.Bg -Align Left -LeftPadding 2
    } else {
        Write-Colored -Text $PromptText -FgColor $c.Fg -BgColor $c.Bg -Align Left -LeftPadding 2
    }
    return Read-Host ""
}

function Write-Info {
    param([string]$Text)
    $c = Get-ThemeColor -Role 'Info'
    Write-Colored -Text $Text -FgColor $c.Fg -BgColor $c.Bg -Align Left -LeftPadding 2
}

function Write-Success {
    param([string]$Text)
    $c = Get-ThemeColor -Role 'Success'
    Write-Colored -Text $Text -FgColor $c.Fg -BgColor $c.Bg -Align Left -LeftPadding 2
}

function Write-Warn {
    param([string]$Text)
    $c = Get-ThemeColor -Role 'Warn'
    Write-Colored -Text $Text -FgColor $c.Fg -BgColor $c.Bg -Align Left -LeftPadding 2
}

function Write-Err {
    param([string]$Text)
    $c = Get-ThemeColor -Role 'Err'
    Write-Colored -Text $Text -FgColor $c.Fg -BgColor $c.Bg -Align Left -LeftPadding 2
}

function Write-Menu {
    param([string]$Text)
    $c = Get-ThemeColor -Role 'Menu'
    Write-Colored -Text $Text -FgColor $c.Fg -BgColor $c.Bg -Align Left -LeftPadding 2
}
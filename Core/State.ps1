function Get-SwitchById { param( [array]$MenuSwitches, [string]$Id ) $MenuSwitches | Where-Object { $_.Id -eq $Id } }

function Set-SwitchState {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][array]$MenuSwitches,
        [Parameter(Mandatory)][string]$Id,
        [Parameter()][object]$State
    )
    $s = Get-SwitchById -MenuSwitches $MenuSwitches -Id $Id
    if (-not $s) { throw "Switch '$Id' not found." }
    switch ($s.Type) {
        'Toggle' { $new = if ($PSBoundParameters.ContainsKey('State')) { [bool]$State } else { -not [bool]$s.State } }
        'Choice' { if (-not $PSBoundParameters.ContainsKey('State')) { throw "Must supply -State for Choice type." }; $new = $State }
        default { $new = if ($PSBoundParameters.ContainsKey('State')) { $State } else { -not [bool]$s.State } }
    }
    $s.State = $new
    return $s.State
}

function Save-SwitchStates {
    param([array]$MenuSwitches, [string]$Path)
    if ($Path) { $st = $MenuSwitches | Select-Object Id, State
        try { $st | ConvertTo-Json -Depth 3 | Out-File -FilePath $Path -Encoding UTF8 -Force ;              return $true }
        catch { Write-Host "Warning: Could not save switch states to $Path" -ForegroundColor DarkYellow ;   return $false }
    }
}

function Load-SwitchStates {
    param([array]$MenuSwitches, [string]$Path)
    if ($Path -and (Test-Path $Path)) {
        try { $json = Get-Content -Raw -Path $Path | ConvertFrom-Json
            foreach ($entry in $json) {
                $s = Get-SwitchById -MenuSwitches $MenuSwitches -Id $entry.Id
                if ($s) {
                    if ($s.Type -eq 'Toggle') { $s.State = [bool]$entry.State }
                    else { $s.State = $entry.State }
                }
            }
        } catch { Write-Host "Warning: Could not load switch states from $Path. Using defaults." -ForegroundColor DarkYellow }
    }
    return $MenuSwitches
}

function Save-Context {
    param([psobject]$Context, [string]$Path = (Join-Path $env:TEMP 'menu-context.json'))
    $Context | ConvertTo-Json -Depth 5 | Set-Content -Path $Path -Encoding UTF8
}

function Load-Context {
    param([string]$Path = (Join-Path $env:TEMP 'menu-context.json'))
    if (Test-Path $Path) { return Get-Content $Path -Raw | ConvertFrom-Json } else { return $null }
}
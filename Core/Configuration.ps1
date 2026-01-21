function Import-Config {
    if (Test-Path $ConfigPath) {
        try {
            $json = Get-Content $ConfigPath -Raw -ErrorAction Stop
            $c = $json | ConvertFrom-Json
            if ($c.VentoyExe) { $Config.VentoyExe = $c.VentoyExe }
            if ($c.ClonezillaISO) { $Config.ClonezillaISO = $c.ClonezillaISO }
            if ($c.LastUsb) { $Config.LastUsb = $c.LastUsb }
            return $c
        } catch {
            Write-Warn "Failed to read config file. Ignoring and continuing."
            return $null
        }
    }
    return $null
}

function Export-Config {
    param(
        [string]$VentoyExe,
        [string]$ClonezillaISO,
        [string]$LastUsb = $null
    )
    $obj = @{
        VentoyExe = $VentoyExe
        ClonezillaISO = $ClonezillaISO
        LastUsb = $LastUsb
    }
    $obj | ConvertTo-Json -Depth 3 | Out-File -FilePath $ConfigPath -Encoding ascii
    Write-Info "Saved defaults to $ConfigPath"
}

function Use-GlobalConfig { param([hashtable]$Config) foreach ($k in $Config.Keys) { $gvName = "Global:$k"; Set-Variable -Name $k -Value $Config[$k] -Scope Global -Force } }
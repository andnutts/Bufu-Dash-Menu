function Copy-File-WithProgress {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$SourcePath,
        [Parameter(Mandatory)][string]$DestinationPath,
        [int]$BufferKB = 64
    )

    $src = Get-Item -LiteralPath $SourcePath -ErrorAction Stop
    $total = [int64]$src.Length
    $bufferSize = [math]::Max(4096, $BufferKB * 1024)

    $readStream = [System.IO.File]::OpenRead($src.FullName)
    try {
        $destStream = [System.IO.File]::Open($DestinationPath, [System.IO.FileMode]::Create, [System.IO.FileAccess]::Write, [System.IO.FileShare]::None)
        try {
            $buffer = New-Object byte[] $bufferSize
            $bytesCopied = 0
            $lastReportTime = Get-Date
            $lastBytes = 0

            while (($read = $readStream.Read($buffer, 0, $bufferSize)) -gt 0) {
                $destStream.Write($buffer, 0, $read)
                $bytesCopied += $read

                $now = Get-Date
                if (($now - $lastReportTime).TotalMilliseconds -ge 250 -or $bytesCopied -eq $total) {
                    $elapsed = ($now - $lastReportTime).TotalSeconds
                    $delta = $bytesCopied - $lastBytes
                    $bps = if ($elapsed -gt 0) { $delta / $elapsed } else { 0 } # bytes/sec

                    $percent = [math]::Round(($bytesCopied / $total) * 100)
                    Show-ProgressBar -Percent $percent -Top 0 -Left 0 -Width 50 -Label (Split-Path $src.Name -Leaf)
                    Show-ThroughputGraph -BytesPerSec $bps

                    $lastReportTime = $now
                    $lastBytes = $bytesCopied
                }
            }
            Show-ProgressBar -Percent 100 -Top 0 -Left 0 -Width 50 -Label (Split-Path $src.Name -Leaf)
            Show-ThroughputGraph -BytesPerSec 0
            return $true
        } finally {
            $destStream.Close()
        }
    } finally {
        $readStream.Close()
    }
}

function Monitor-FileGrowth {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$FilePath,
        [Parameter(Mandatory)][int64]$ExpectedBytes,
        [int]$PollIntervalMs = 500
    )

    $prevSize = 0
    $start = Get-Date
    while (-not (Test-Path $FilePath)) {
        Start-Sleep -Milliseconds 200
    }
    while ($true) {
        $info = Get-Item -LiteralPath $FilePath -ErrorAction SilentlyContinue
        $size = if ($info) { [int64]$info.Length } else { 0 }
        $elapsed = (Get-Date) - $start
        $bps = if ($elapsed.TotalSeconds -gt 0) { ($size) / $elapsed.TotalSeconds } else { 0 }
        $percent = if ($ExpectedBytes -gt 0) { [math]::Round(($size / $ExpectedBytes) * 100) } else { 0 }

        Show-ProgressBar -Percent $percent -Top 0 -Left 0 -Width 50 -Label (Split-Path $FilePath -Leaf)
        Show-ThroughputGraph -BytesPerSec $bps

        if ($size -ge $ExpectedBytes -and $ExpectedBytes -gt 0) { break }
        Start-Sleep -Milliseconds $PollIntervalMs
    }
    Show-ProgressBar -Percent 100 -Top 0 -Left 0 -Width 50 -Label (Split-Path $FilePath -Leaf)
    Show-ThroughputGraph -BytesPerSec 0
}

function Invoke-Process-WithFileProgress {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$FilePathToWatch,
        [Parameter(Mandatory)][string]$Exe,
        [string[]]$Args,
        [int64]$ExpectedBytes = 0
    )

    $proc = Start-Process -FilePath $Exe -ArgumentList $Args -PassThru -NoNewWindow

    while (-not $proc.HasExited) {
        if (Test-Path $FilePathToWatch) {
            $info = Get-Item -LiteralPath $FilePathToWatch
            $size = $info.Length
            $percent = if ($ExpectedBytes -gt 0) { [math]::Round(($size / $ExpectedBytes) * 100) } else { 0 }
            Start-Sleep -Milliseconds 500
            $info2 = Get-Item -LiteralPath $FilePathToWatch -ErrorAction SilentlyContinue
            $size2 = if ($info2) { $info2.Length } else { $size }
            $bps = (($size2 - $size) / 0.5)
            Show-ProgressBar -Percent $percent -Top 0 -Left 0 -Width 50 -Label (Split-Path $FilePathToWatch -Leaf)
            Show-ThroughputGraph -BytesPerSec $bps
        } else {
            Show-ProgressBar -Percent 0 -Top 0 -Left 0 -Width 50 -Label "Waiting for output..."
            Show-ThroughputGraph -BytesPerSec 0
            Start-Sleep -Milliseconds 500
        }
    }

    if (Test-Path $FilePathToWatch) {
        $final = Get-Item -LiteralPath $FilePathToWatch
        $bps = 0
        Show-ProgressBar -Percent 100 -Top 0 -Left 0 -Width 50 -Label (Split-Path $FilePathToWatch -Leaf)
        Show-ThroughputGraph -BytesPerSec $bps
    }
    return $proc.ExitCode
}
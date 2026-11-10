# Stop ADI processes started by start.ps1 (falls back to port ownership).
[CmdletBinding()]
param()

$ErrorActionPreference = "SilentlyContinue"
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$pidFile = Join-Path $root ".adi.pids"
$stopped = $false

if (Test-Path $pidFile) {
    foreach ($line in Get-Content $pidFile) {
        $parts = $line.Split("=")
        if ($parts.Length -ne 2) { continue }
        $name = $parts[0]
        $processId = 0
        if (-not [int]::TryParse($parts[1], [ref]$processId)) { continue }
        $proc = Get-Process -Id $processId -ErrorAction SilentlyContinue
        if ($proc) {
            Write-Host "Stopping $name (PID $processId)..." -ForegroundColor Yellow
            Stop-Process -Id $processId -Force
            $stopped = $true
        }
    }
    Remove-Item $pidFile -Force
}

function Stop-Port([int]$Port, [string]$Label) {
    $connections = Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue
    foreach ($connection in $connections) {
        $proc = Get-Process -Id $connection.OwningProcess -ErrorAction SilentlyContinue
        if ($proc) {
            Write-Host "Stopping $Label listener $($proc.ProcessName) (PID $($proc.Id))..." -ForegroundColor Yellow
            Stop-Process -Id $proc.Id -Force
            $script:stopped = $true
        }
    }
}

Stop-Port 8000 "backend"
Stop-Port 3000 "frontend"

Start-Sleep -Milliseconds 400

$remaining = @()
if (Get-NetTCPConnection -LocalPort 8000 -State Listen -ErrorAction SilentlyContinue) { $remaining += "8000" }
if (Get-NetTCPConnection -LocalPort 3000 -State Listen -ErrorAction SilentlyContinue) { $remaining += "3000" }

if ($remaining.Count -gt 0) {
    Write-Host "Still listening on: $($remaining -join ', ')" -ForegroundColor Red
    exit 1
}

if ($stopped) {
    Write-Host "ADI stopped." -ForegroundColor Green
} else {
    Write-Host "Nothing was running on ports 8000 or 3000." -ForegroundColor DarkGray
}

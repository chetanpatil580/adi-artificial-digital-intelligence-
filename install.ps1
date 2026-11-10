# ADI dependency installer (Windows, PowerShell 5.1+).
[CmdletBinding()]
param(
    [switch]$SkipTests
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$backend = Join-Path $root "backend"
$frontend = Join-Path $root "frontend"
$venv = Join-Path $backend ".venv"
$venvPython = Join-Path $venv "Scripts\python.exe"

function Resolve-Python {
    foreach ($candidate in @("python", "py")) {
        $command = Get-Command $candidate -ErrorAction SilentlyContinue
        if (-not $command) { continue }
        try {
            if ($candidate -eq "py") {
                & py -3 --version | Out-Null
                return @("py", "-3")
            }
            & python --version | Out-Null
            return @("python")
        } catch {
            continue
        }
    }
    throw "Python 3.10+ was not found. Install it from https://www.python.org/downloads/ and enable 'Add python.exe to PATH'."
}

function Resolve-Node {
    $node = Get-Command node -ErrorAction SilentlyContinue
    if (-not $node) {
        throw "Node.js 18+ was not found. Install the LTS build from https://nodejs.org/."
    }
    $major = [int]((& node --version).TrimStart("v").Split(".")[0])
    if ($major -lt 18) {
        throw "Node.js 18 or newer is required (found $major)."
    }
    if (-not (Get-Command npm -ErrorAction SilentlyContinue)) {
        throw "npm was not found on PATH."
    }
}

Write-Host "ADI installer" -ForegroundColor Cyan
Write-Host "Repository: $root"

if (-not (Test-Path (Join-Path $backend ".env"))) {
    Write-Host "Running first-time setup..." -ForegroundColor Yellow
    & (Join-Path $root "setup.ps1")
}

Resolve-Node

if (-not (Test-Path $venvPython)) {
    $pythonParts = Resolve-Python
    Write-Host "Creating Python virtual environment..." -ForegroundColor Yellow
    $pythonExe = $pythonParts[0]
    $pythonArgs = @()
    if ($pythonParts.Length -gt 1) { $pythonArgs += $pythonParts[1..($pythonParts.Length - 1)] }
    $pythonArgs += @("-m", "venv", $venv)
    & $pythonExe @pythonArgs
    if ($LASTEXITCODE -ne 0) { throw "Could not create the virtual environment." }
} else {
    Write-Host "Reusing backend/.venv." -ForegroundColor Green
}

Write-Host "Installing backend dependencies..." -ForegroundColor Yellow
& $venvPython -m pip install --upgrade pip --quiet
& $venvPython -m pip install -r (Join-Path $backend "requirements.txt")
if ($LASTEXITCODE -ne 0) { throw "Backend dependency installation failed." }

Write-Host "Installing frontend dependencies..." -ForegroundColor Yellow
Push-Location $frontend
try {
    & npm install --no-audit --no-fund
    if ($LASTEXITCODE -ne 0) { throw "Frontend dependency installation failed." }
} finally {
    Pop-Location
}

if (-not $SkipTests) {
    Write-Host "Running backend tests..." -ForegroundColor Yellow
    Push-Location $backend
    try {
        & $venvPython -m pytest -q
        if ($LASTEXITCODE -ne 0) {
            Write-Warning "Backend tests reported failures. The app can still start, but review the output above."
        }
    } finally {
        Pop-Location
    }
}

Write-Host ""
Write-Host "Install complete." -ForegroundColor Green
Write-Host "Start ADI with: .\start.ps1" -ForegroundColor Cyan

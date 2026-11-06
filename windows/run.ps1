# TheMVP PC health check - Windows starter. Paste into Command Prompt or PowerShell:
#   powershell -NoProfile -ExecutionPolicy Bypass -c "& ([scriptblock]::Create((irm https://raw.githubusercontent.com/KoushikMVP/pc-health-check/main/windows/run.ps1))) -Ticket SID000616"
# It downloads bench_collect.ps1 (same repo) to a temp folder, runs it with admin rights,
# saves the report to a folder on the Desktop, then deletes the downloaded script.
param([string]$Ticket = "", [string]$Base = "https://raw.githubusercontent.com/KoushikMVP/pc-health-check/main")
$ErrorActionPreference = "Stop"
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

$Ticket = $Ticket -replace '[^A-Za-z0-9_-]', ''   # it becomes part of a folder name
$ps1 = Join-Path $env:TEMP "themvp-bench_collect.ps1"
Write-Host "Downloading the TheMVP health check from $Base ..."
Invoke-WebRequest "$Base/windows/bench_collect.ps1" -OutFile $ps1 -UseBasicParsing

$name = "TheMVP-diag-" + $(if ($Ticket) { "$Ticket-" } else { "" }) + (Get-Date -Format "yyyyMMdd-HHmm")
$out = Join-Path ([Environment]::GetFolderPath("Desktop")) $name
$argList = "-NoProfile -ExecutionPolicy Bypass -File `"$ps1`" -Out `"$out`""

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
$done = $false
if (-not $isAdmin) {
    Write-Host "Windows will now ask for administrator rights (needed to read crash reports, start-up times and TPM)."
    try { Start-Process powershell -Verb RunAs -Wait -ArgumentList $argList; $done = $true }
    catch { Write-Host "No administrator rights - running anyway, a few checks will be skipped." }
}
if (-not $done) { Start-Process powershell -NoNewWindow -Wait -ArgumentList $argList }
Remove-Item $ps1 -ErrorAction SilentlyContinue

if (Get-ChildItem $out -Filter *.json -ErrorAction SilentlyContinue) {
    Write-Host ""
    Write-Host "Done. Your report is in: $out"
    Write-Host "Please send the files in that folder to TheMVP (reply to your ticket email or WhatsApp)."
    Start-Process explorer $out
} else {
    Write-Host "The check did not finish. Please send TheMVP a screenshot of this window."
}

@echo off
REM ClearCache.bat - single-file interactive cache cleanup. Right-click > Run as administrator (or just double-click).
fltmc >nul 2>&1 || (echo Requesting administrator privileges... & powershell -NoProfile -Command "Start-Process '%~f0' -Verb RunAs" & exit /b)
set "P=%TEMP%\CC_%RANDOM%.ps1"
powershell -NoProfile -Command "$m='::PS_'+'PAYLOAD_BEGIN';$l=@(Get-Content -LiteralPath '%~f0');$i=[array]::IndexOf($l,$m);if($i-lt 0){exit 2};$l[($i+1)..($l.Count-1)]|Set-Content -LiteralPath '%P%' -Encoding UTF8"
powershell -NoProfile -ExecutionPolicy Bypass -File "%P%"
del "%P%" 2>nul
pause
exit /b 0
::PS_PAYLOAD_BEGIN
# N=name, Procs=apps to close first, Paths=folders to clear
$targets = @(
    @{ N="User Temp";           Procs=@();                    Paths=@("$env:TEMP\*") }
    @{ N="Windows Temp";        Procs=@();                    Paths=@("C:\Windows\Temp\*") }
    @{ N="Edge Cache";          Procs=@("msedge");            Paths=@("$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Cache\*") }
    @{ N="Chrome Cache";        Procs=@("chrome");            Paths=@("$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cache\*") }
    @{ N="Classic Teams Cache"; Procs=@("Teams");             Paths=@("$env:APPDATA\Microsoft\Teams\Application Cache\Cache\*","$env:APPDATA\Microsoft\Teams\Cache\*","$env:APPDATA\Microsoft\Teams\GPUCache\*","$env:APPDATA\Microsoft\Teams\IndexedDB\*","$env:APPDATA\Microsoft\Teams\Local Storage\*","$env:APPDATA\Microsoft\Teams\tmp\*") }
    @{ N="New Teams Cache";     Procs=@("ms-teams","MSTeams"); Paths=@("$env:LOCALAPPDATA\Packages\MSTeams_8wekyb3d8bbwe\LocalCache\*") }
)
# Disabled (kept commented): Prefetch and Recycle Bin. To enable Prefetch, add a trailing comma above.
# Prefetch:    @{ N="Prefetch"; Procs=@(); Paths=@("C:\Windows\Prefetch\*") }
# Recycle Bin: Clear-RecycleBin -Force -ErrorAction SilentlyContinue

function Clear-Target($t) {
    Write-Host "Clearing $($t.N)..." -ForegroundColor Yellow
    $existed = $false; $hadItems = $false; $locked = 0
    foreach ($path in $t.Paths) {
        $folder = Split-Path $path -Parent
        if (-not (Test-Path $folder)) { continue }
        $existed = $true
        $items = @(Get-ChildItem -Path $path -Force -ErrorAction SilentlyContinue)
        if (-not $items.Count) { continue }
        $hadItems = $true
        Remove-Item $path -Recurse -Force -ErrorAction SilentlyContinue -ErrorVariable e
        $locked += @($e).Count
    }
    if (-not $existed)      { Write-Host "   not found - skipped" -ForegroundColor DarkGray }
    elseif (-not $hadItems) { Write-Host "   already empty - nothing to clear" -ForegroundColor Gray }
    elseif ($locked -gt 0)  { Write-Host "   cleared, but $locked item(s) were in use" -ForegroundColor DarkYellow }
    else                    { Write-Host "   cleared successfully" -ForegroundColor Green }
}

while ($true) {
    Write-Host "`nSelect what to clear:" -ForegroundColor Cyan
    for ($i=0; $i -lt $targets.Count; $i++) { Write-Host ("  [{0}] {1}" -f ($i+1), $targets[$i].N) }
    Write-Host "  [A] All    [Q] Abort"
    $a = (Read-Host "Choice").Trim().ToLower()
    if ($a -in "q","quit","abort") { Write-Host "Aborted." -ForegroundColor Red; exit }
    if ($a -in "a","all") { $sel = 0..($targets.Count-1); break }
    $sel = @(foreach ($p in $a -split ',') { $n = $p.Trim() -as [int]; if ($n -ge 1 -and $n -le $targets.Count) { $n-1 } })
    if ($sel.Count) { break }
}
$chosen = @($targets[$($sel | Select-Object -Unique)])
Write-Host "`nSelected: $(($chosen.N) -join ', ')" -ForegroundColor Cyan
if ((Read-Host "Proceed? (Y/N)") -notmatch '^y') { Write-Host "Aborted." -ForegroundColor Red; exit }

$procs = @($chosen.Procs | Sort-Object -Unique)
foreach ($p in $procs) {
    if (Get-Process $p -ErrorAction SilentlyContinue) {
        Write-Host "Closing $p..." -ForegroundColor Yellow
        Stop-Process -Name $p -Force -ErrorAction SilentlyContinue
    }
}
Start-Sleep 2
$skip = $false
while (-not $skip -and ($run = @($procs | Where-Object { Get-Process $_ -ErrorAction SilentlyContinue })).Count) {
    Write-Host "Still running: $($run -join ', ')" -ForegroundColor Red
    switch -Regex (Read-Host "[C]lose again, [S]kip, [A]bort") {
        '^c' { $run | ForEach-Object { Stop-Process -Name $_ -Force -ErrorAction SilentlyContinue }; Start-Sleep 2 }
        '^s' { $skip = $true }
        '^a' { Write-Host "Aborted." -ForegroundColor Red; exit }
    }
}

Write-Host "`nStarting cache cleanup..." -ForegroundColor Cyan
foreach ($t in $chosen) { Clear-Target $t }
Write-Host "Cache cleanup completed." -ForegroundColor Cyan

do { $r = (Read-Host "`nRestart now? (Y/N)").Trim().ToLower() } until ($r -in "y","yes","n","no")
if ($r[0] -eq "y") { Restart-Computer -Force } else { Write-Host "Restart skipped." -ForegroundColor Gray }

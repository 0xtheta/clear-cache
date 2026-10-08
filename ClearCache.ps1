# ClearCache.ps1
# Purpose: Clear common temporary/chache files to improve laptop performance.
# Note: Run Powershell as Administrator to execute this script.

Write-Host "Starting cache cleanup..." -ForegroundColor Cyan

# Function to safely clear a path

function Clear-Path {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Path,

        [Parameter(Mandatory=$true)]
        [string]$Description
    )

    if (Test-Path $Path) {
        Write-Host "Clearing $Description...." -ForegroundColor Yellow
        try {
            Remove-Item -Path $Path -Recurse -Force -ErrorAction SilentlyContinue
            Write-Host "$Description cleared." -ForegroundColor Green
        } catch {
            Write-Host "Could not fully clear $Description. Some files may be in use" -ForegroundColor DarkYellow
        }
    } else {
        Write-Host "$Description path not found. Skipping." -ForegroundColor Gray
    }
}


# Clear Windows temporary files
Clear-Path -Path "$env:TEMP\*" -Description "User Temp files"
Clear-Path -Path "C:\Windows\Temp\*" -Description "Windows Temp files"

# Clear Microsoft Edge cache
Clear-Path -Path "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Cache\*" -Description "Microsoft Edge cache"

# Clear Google Chrome cache
Clear-Path -Path "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cache\*" -Description "Google Chrome cache"


# Clear Microsoft Teams cache - Classic Teams
Clear-Path -Path "$env:APPDATA\Microsoft\Teams\Application Cache\Cache\*" -Description "Classic Teams Application cache"
Clear-Path -Path "$env:APPDATA\Microsoft\Teams\Cache\*" -Description "Classic Teams cache"
Clear-Path -Path "$env:APPDATA\Microsoft\Teams\GPUCache\*" -Description "Classic Teams GPU cache"
Clear-Path -Path "$env:APPDATA\Microsoft\Teams\IndexedDB\*" -Description "Classic Teams IndexedDB cache"
Clear-Path -Path "$env:APPDATA\Microsoft\Teams\Local Storage\*" -Description "Classic Teams Local Storage cache"
Clear-Path -Path "$env:APPDATA\Microsoft\Teams\tmp\*" -Description "Classic Teams temporary files"                                

# Clear Microsoft Teams cache - New Teams
Clear-Path -Path "$env:LOCALAPPDATA\Packages\MSTeams_8wekyb3d8bbwe\LocalCache\*" -Description "New Teams Local Cache"



# Clear Windows Prefetch files
Clear-Path -Path "C:\Windows\Prefetch\*" -Description "Windows Prefetch files"

# Empty Recycle Bin
# Write-Host "Emptying Recycle Bin..." -ForegroundColor Yellow
# try {
#     Clear-RecycleBin -Force -ErrorAction SilentlyContinue
#     Write-Host "Recycle Bin emptied." -ForegroundColor Green
# } 
# catch {
#     Write-Host "Could not empty Recycle Bin or it is empty already" -ForegroundColor DarkYellow
# }

Write-Host "Cache cleanup completed." -ForegroundColor Cyan
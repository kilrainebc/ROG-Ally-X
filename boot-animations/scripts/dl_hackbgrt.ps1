# Download and Setup HackBGRT
# Run as Administrator

# Check if running as administrator
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
$isAdmin = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "This script requires Administrator privileges." -ForegroundColor Red
    Write-Host "Please right-click the script and select 'Run as administrator'." -ForegroundColor Red
    exit
}

# Define paths with relative structure
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Split-Path -Parent (Split-Path -Parent $scriptDir)
$toolsPath = Join-Path -Path $repoRoot -ChildPath "boot-animations\tools"

# Create tools directory
New-Item -Path $toolsPath -ItemType Directory -Force | Out-Null
Write-Host "Created tools directory: $toolsPath" -ForegroundColor Cyan

# Download HackBGRT
$hackbgrtUrl = "https://github.com/Metabolix/HackBGRT/releases/download/v1.8/HackBGRT-v1.8.zip"
$hackbgrtZip = "$toolsPath\HackBGRT.zip"
$hackbgrtDir = "$toolsPath\HackBGRT"

# Create extraction directory
New-Item -Path $hackbgrtDir -ItemType Directory -Force | Out-Null

try {
    # Download the file
    Write-Host "Downloading HackBGRT..." -ForegroundColor Yellow
    $progressPreference = 'SilentlyContinue'  # Hide progress bar for faster downloads
    Invoke-WebRequest -Uri $hackbgrtUrl -OutFile $hackbgrtZip
    $progressPreference = 'Continue'  # Restore progress preference
    
    # Extract the ZIP file
    Write-Host "Extracting HackBGRT..." -ForegroundColor Yellow
    Expand-Archive -Path $hackbgrtZip -DestinationPath $hackbgrtDir -Force
    
    # Success
    Write-Host "HackBGRT has been downloaded and extracted to: $hackbgrtDir" -ForegroundColor Green
    
    # Clean up ZIP file
    Remove-Item -Path $hackbgrtZip -Force
}
catch {
    Write-Host "Error setting up HackBGRT: $_" -ForegroundColor Red
}
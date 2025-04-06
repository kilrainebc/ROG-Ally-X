# Updated HackBGRT Download Script
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

# Current latest version as of April 2025
$hackbgrtVersion = "1.9.0"
$hackbgrtDir = "$toolsPath\HackBGRT"
New-Item -Path $hackbgrtDir -ItemType Directory -Force | Out-Null

# Updated direct download link (dynamically formatted with version)
$hackbgrtUrl = "https://github.com/Metabolix/HackBGRT/releases/download/v$hackbgrtVersion/HackBGRT-v$hackbgrtVersion.zip"
$hackbgrtZip = "$toolsPath\HackBGRT.zip"

try {
    Write-Host "Attempting to download HackBGRT v$hackbgrtVersion..." -ForegroundColor Yellow
    
    # Force TLS 1.2
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    
    # Use direct WebClient for download
    $webClient = New-Object System.Net.WebClient
    $webClient.Headers.Add("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.88 Safari/537.36")
    $webClient.DownloadFile($hackbgrtUrl, $hackbgrtZip)
    
    # Check if file exists and has content
    if ((Test-Path $hackbgrtZip) -and (Get-Item $hackbgrtZip).Length -gt 0) {
        # Extract the ZIP file
        Write-Host "Extracting HackBGRT..." -ForegroundColor Yellow
        Expand-Archive -Path $hackbgrtZip -DestinationPath $hackbgrtDir -Force
        
        # Success
        Write-Host "HackBGRT has been downloaded and extracted to: $hackbgrtDir" -ForegroundColor Green
        
        # Clean up ZIP file
        Remove-Item -Path $hackbgrtZip -Force
    } else {
        throw "Downloaded file is empty or does not exist"
    }
} catch {
    Write-Host "Automated download failed: $_" -ForegroundColor Red
    
    # Manual instructions
    Write-Host "`n===== MANUAL DOWNLOAD INSTRUCTIONS =====" -ForegroundColor Cyan
    Write-Host "Please follow these steps to download HackBGRT manually:" -ForegroundColor Yellow
    Write-Host "1. Visit: https://github.com/Metabolix/HackBGRT/releases/latest" -ForegroundColor White
    Write-Host "2. Download the ZIP file (currently HackBGRT-v$hackbgrtVersion.zip)" -ForegroundColor White
    Write-Host "3. Extract the contents to: $hackbgrtDir" -ForegroundColor White
    Write-Host "4. Continue with the boot animation setup" -ForegroundColor White
    Write-Host "================================================" -ForegroundColor Cyan
}

# Create a convenience script to install HackBGRT (for after download)
$installScriptPath = "$hackbgrtDir\install-hackbgrt.ps1"
@"
# HackBGRT Installation Script
# Run as Administrator after downloading HackBGRT

# Check if running as administrator
`$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
`$isAdmin = `$currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not `$isAdmin) {
    Write-Host "This script requires Administrator privileges." -ForegroundColor Red
    Write-Host "Please right-click the script and select 'Run as administrator'." -ForegroundColor Red
    exit
}

# Define paths
`$scriptDir = Split-Path -Parent `$MyInvocation.MyCommand.Path
`$hackbgrtPath = "`$scriptDir\bootx64.efi"

# Check if HackBGRT files exist
if (-not (Test-Path `$hackbgrtPath)) {
    Write-Host "HackBGRT files not found in `$scriptDir" -ForegroundColor Red
    Write-Host "Please make sure you've downloaded and extracted HackBGRT first." -ForegroundColor Red
    exit
}

# Run the HackBGRT installer
try {
    Write-Host "Installing HackBGRT..." -ForegroundColor Yellow
    & "`$scriptDir\install.bat"
    
    Write-Host "`nHackBGRT installation complete." -ForegroundColor Green
    Write-Host "You may need to restart your computer for changes to take effect." -ForegroundColor Cyan
} catch {
    Write-Host "Error installing HackBGRT: `$_" -ForegroundColor Red
}
"@ | Out-File -FilePath $installScriptPath -Encoding utf8

# Create a script for customizing the boot animation
$customizeScriptPath = "$hackbgrtDir\customize-boot-animation.ps1"
@"
# Boot Animation Customization Script for HackBGRT
# Run after installing HackBGRT

# Define paths
`$scriptDir = Split-Path -Parent `$MyInvocation.MyCommand.Path
`$repoRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent `$scriptDir))
`$videosPath = Join-Path -Path `$repoRoot -ChildPath "boot-animations\videos"

# This script will help prepare your video for use with HackBGRT

Write-Host "Boot Animation Customization Helper" -ForegroundColor Cyan
Write-Host "=================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "This script will help you prepare your videos for use with HackBGRT." -ForegroundColor Yellow
Write-Host ""
Write-Host "HackBGRT uses BMP image files for boot animations." -ForegroundColor White
Write-Host "To use a video, you'll need to convert it to a BMP image." -ForegroundColor White
Write-Host ""
Write-Host "Available videos:" -ForegroundColor Cyan

# List available videos
`$videos = Get-ChildItem -Path `$videosPath -Filter "*.mp4"
if (`$videos.Count -eq 0) {
    Write-Host "No MP4 videos found in `$videosPath" -ForegroundColor Red
    exit
}

# Display videos
foreach (`$i in 0..(`$videos.Count-1)) {
    Write-Host "[`$i] `$(`$videos[`$i].Name)" -ForegroundColor White
}

Write-Host ""
`$selectedIndex = Read-Host "Enter the number of the video you want to use"

# Validate selection
if (-not (`$selectedIndex -match '^\d+$') -or [int]`$selectedIndex -lt 0 -or [int]`$selectedIndex -ge `$videos.Count) {
    Write-Host "Invalid selection." -ForegroundColor Red
    exit
}

`$selectedVideo = `$videos[[int]`$selectedIndex]
Write-Host "Selected: `$(`$selectedVideo.Name)" -ForegroundColor Green

# Instructions for conversion
Write-Host ""
Write-Host "To use this video as a boot animation:" -ForegroundColor Yellow
Write-Host "1. Extract a frame from the video to use as your boot image" -ForegroundColor White
Write-Host "2. Convert the frame to a BMP file (1920x1080 or your screen resolution)" -ForegroundColor White
Write-Host "3. Name it bmp0.bmp and place it in the HackBGRT ESP directory" -ForegroundColor White
Write-Host "4. Edit config.txt to set your preferences" -ForegroundColor White
Write-Host ""
Write-Host "Would you like to extract a frame now? (Y/N)" -ForegroundColor Cyan
`$extractFrame = Read-Host

if (`$extractFrame -eq "Y" -or `$extractFrame -eq "y") {
    # Check for ffmpeg
    `$ffmpegPath = "ffmpeg"
    try {
        `$null = & ffmpeg -version
    } catch {
        Write-Host "FFmpeg not found. Please install FFmpeg first." -ForegroundColor Red
        exit
    }
    
    # Extract frame
    `$frameTime = Read-Host "Enter the time to extract (e.g., 00:00:05 for 5 seconds into the video)"
    `$outputBmp = "`$scriptDir\bmp0.bmp"
    
    try {
        & ffmpeg -i `$(`$selectedVideo.FullName) -ss `$frameTime -vframes 1 -q:v 1 `$outputBmp
        
        if (Test-Path `$outputBmp) {
            Write-Host "Frame extracted to `$outputBmp" -ForegroundColor Green
            Write-Host "You can now configure HackBGRT to use this image." -ForegroundColor Green
        } else {
            Write-Host "Failed to extract frame." -ForegroundColor Red
        }
    } catch {
        Write-Host "Error extracting frame: `$_" -ForegroundColor Red
    }
}
"@ | Out-File -FilePath $customizeScriptPath -Encoding utf8

Write-Host "`nCreated helper scripts:" -ForegroundColor Green
Write-Host "- $installScriptPath" -ForegroundColor White
Write-Host "- $customizeScriptPath" -ForegroundColor White
Write-Host "`nAfter downloading HackBGRT, run the install script to set it up." -ForegroundColor Yellow
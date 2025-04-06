# Fixed HackBGRT Download Script
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

# Method 1: Try direct download with fixed URL
try {
    # Download HackBGRT using updated URL
    $hackbgrtUrl = "https://github.com/Metabolix/HackBGRT/releases/download/v1.8.0/HackBGRT-v1.8.0.zip"
    $hackbgrtZip = "$toolsPath\HackBGRT.zip"
    $hackbgrtDir = "$toolsPath\HackBGRT"
    
    # Create extraction directory
    New-Item -Path $hackbgrtDir -ItemType Directory -Force | Out-Null
    
    # Download the file
    Write-Host "Downloading HackBGRT using method 1..." -ForegroundColor Yellow
    
    # Force TLS 1.2
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    
    Invoke-WebRequest -Uri $hackbgrtUrl -OutFile $hackbgrtZip -UseBasicParsing
    
    # Check if the download was successful
    if (Test-Path $hackbgrtZip) {
        # Extract the ZIP file
        Write-Host "Extracting HackBGRT..." -ForegroundColor Yellow
        Expand-Archive -Path $hackbgrtZip -DestinationPath $hackbgrtDir -Force
        
        # Success
        Write-Host "HackBGRT has been downloaded and extracted to: $hackbgrtDir" -ForegroundColor Green
        
        # Clean up ZIP file
        Remove-Item -Path $hackbgrtZip -Force
        
        # Done - exit the script
        exit
    }
}
catch {
    Write-Host "Method 1 failed: $_" -ForegroundColor Yellow
    Write-Host "Trying alternative method..." -ForegroundColor Yellow
}

# Method 2: Use an alternative approach with System.Net.WebClient
try {
    $hackbgrtUrl = "https://github.com/Metabolix/HackBGRT/releases/download/v1.8.0/HackBGRT-v1.8.0.zip"
    $hackbgrtZip = "$toolsPath\HackBGRT.zip"
    $hackbgrtDir = "$toolsPath\HackBGRT"
    
    # Create extraction directory if it doesn't exist
    if (-not (Test-Path $hackbgrtDir)) {
        New-Item -Path $hackbgrtDir -ItemType Directory -Force | Out-Null
    }
    
    Write-Host "Downloading HackBGRT using method 2..." -ForegroundColor Yellow
    
    # Use WebClient instead of Invoke-WebRequest
    $webClient = New-Object System.Net.WebClient
    $webClient.Headers.Add("User-Agent", "PowerShell Script")
    $webClient.DownloadFile($hackbgrtUrl, $hackbgrtZip)
    
    # Check if download succeeded
    if (Test-Path $hackbgrtZip) {
        # Extract the ZIP file
        Write-Host "Extracting HackBGRT..." -ForegroundColor Yellow
        Expand-Archive -Path $hackbgrtZip -DestinationPath $hackbgrtDir -Force
        
        # Success
        Write-Host "HackBGRT has been downloaded and extracted to: $hackbgrtDir" -ForegroundColor Green
        
        # Clean up ZIP file
        Remove-Item -Path $hackbgrtZip -Force
        
        # Done - exit the script
        exit
    }
}
catch {
    Write-Host "Method 2 failed: $_" -ForegroundColor Yellow
    Write-Host "Trying manual instructions..." -ForegroundColor Yellow
}

# Method 3: Provide manual instructions
Write-Host "`n===== MANUAL DOWNLOAD INSTRUCTIONS =====" -ForegroundColor Cyan
Write-Host "Could not automatically download HackBGRT. Please follow these steps:" -ForegroundColor Yellow
Write-Host "1. Visit: https://github.com/Metabolix/HackBGRT/releases/latest" -ForegroundColor White
Write-Host "2. Download the ZIP file (HackBGRT-vX.X.X.zip)" -ForegroundColor White
Write-Host "3. Extract the contents to: $hackbgrtDir" -ForegroundColor White
Write-Host "4. Continue with the next steps of the boot animation setup" -ForegroundColor White
Write-Host "================================================" -ForegroundColor Cyan
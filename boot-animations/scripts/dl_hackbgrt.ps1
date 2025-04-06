# Simple HackBGRT Download Script
# This script only downloads HackBGRT from GitHub - no installation

# Define paths
$toolsPath = ".\tools"
$hackbgrtDir = "$toolsPath\HackBGRT"

# Create directories
New-Item -Path $toolsPath -ItemType Directory -Force | Out-Null
New-Item -Path $hackbgrtDir -ItemType Directory -Force | Out-Null

Write-Host "Created directory: $hackbgrtDir"

# Latest version as of April 2025
$version = "1.9.0"
$downloadUrl = "https://github.com/Metabolix/HackBGRT/releases/download/v$version/HackBGRT-v$version.zip"
$outputFile = "$toolsPath\HackBGRT.zip"

Write-Host "Downloading HackBGRT v$version from GitHub..."

try {
    # Force TLS 1.2
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    
    # Download the file
    Invoke-WebRequest -Uri $downloadUrl -OutFile $outputFile -UseBasicParsing
    
    # Extract if successful
    if (Test-Path $outputFile) {
        Write-Host "Download successful. Extracting..."
        Expand-Archive -Path $outputFile -DestinationPath $hackbgrtDir -Force
        Remove-Item -Path $outputFile -Force
        Write-Host "Done! HackBGRT extracted to: $hackbgrtDir"
    }
} catch {
    Write-Host "Download failed: $_"
    Write-Host "Please download manually from: $downloadUrl"
}
# GBA ROM Mover and Extractor
# This script moves zip files from Downloads to G:\ROMs\GBA and extracts them to subdirectories

# Define paths
$downloadDir = "$env:USERPROFILE\Downloads"
$destinationDir = "G:\ROMs\GBA"

# Ensure destination directory exists
if (!(Test-Path -Path $destinationDir)) {
    New-Item -ItemType Directory -Path $destinationDir -Force
    Write-Host "Created destination directory: $destinationDir"
}

# Get all zip files in the Downloads directory
$zipFiles = Get-ChildItem -Path $downloadDir -Filter "*.zip"

# Check if any zip files were found
if ($zipFiles.Count -eq 0) {
    Write-Host "No zip files found in $downloadDir"
    exit
}

# Process each zip file
foreach ($zipFile in $zipFiles) {
    Write-Host "Processing: $($zipFile.Name)"
    
    # Create the subfolder name (same as zip file without extension)
    $subfolderName = [System.IO.Path]::GetFileNameWithoutExtension($zipFile.Name)
    $subfolderPath = Join-Path -Path $destinationDir -ChildPath $subfolderName
    
    # Create subfolder if it doesn't exist
    if (!(Test-Path -Path $subfolderPath)) {
        New-Item -ItemType Directory -Path $subfolderPath -Force
        Write-Host "Created subfolder: $subfolderPath"
    }
    
    # Copy the zip file to destination
    $destinationZipPath = Join-Path -Path $destinationDir -ChildPath $zipFile.Name
    Copy-Item -Path $zipFile.FullName -Destination $destinationZipPath -Force
    Write-Host "Copied zip file to: $destinationZipPath"
    
    # Extract the zip file to the subfolder
    try {
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        [System.IO.Compression.ZipFile]::ExtractToDirectory($destinationZipPath, $subfolderPath)
        Write-Host "Extracted to: $subfolderPath"
        
        # Optional: Remove the zip file after extraction
        Remove-Item -Path $destinationZipPath -Force
        Write-Host "Removed zip file from destination"
        
        # Optional: Remove the original zip file from Downloads
        Remove-Item -Path $zipFile.FullName -Force
        Write-Host "Removed original zip file from Downloads"
    }
    catch {
        Write-Host "Error extracting $($zipFile.Name): $_" -ForegroundColor Red
    }
}

Write-Host "Operation completed successfully!" -ForegroundColor Green
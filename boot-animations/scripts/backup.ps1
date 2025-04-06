# EFI System Partition Backup Script for ROG Ally X
# This script mounts the EFI partition, backs up boot files, and unmounts the partition
# IMPORTANT: Run as Administrator!

# Check if running as administrator
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
$isAdmin = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "This script requires Administrator privileges." -ForegroundColor Red
    Write-Host "Please right-click the script and select 'Run as administrator'." -ForegroundColor Red
    Write-Host "Press any key to exit..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit
}

# Define paths
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Split-Path -Parent (Split-Path -Parent $scriptDir)
$backupPath = Join-Path -Path $repoRoot -ChildPath "boot-animations\backups"
$dateString = (Get-Date).ToString("yyyy-MM-dd_HHmmss")
$backupDir = "$backupPath\$dateString"

# Create backup directory
New-Item -Path $backupDir -ItemType Directory -Force | Out-Null
Write-Host "Creating backup directory: $backupDir" -ForegroundColor Cyan

# Log file
$logFile = "$backupDir\efi_backup_log.txt"
"EFI Boot Files Backup - $dateString" | Out-File -FilePath $logFile
"======================================" | Out-File -FilePath $logFile -Append
"" | Out-File -FilePath $logFile -Append

# Step 1: Find the EFI System Partition
try {
    Write-Host "Locating EFI System Partition..." -ForegroundColor Cyan
    $efiPartition = Get-Partition | Where-Object { $_.GptType -eq '{c12a7328-f81f-11d2-ba4b-00a0c93ec93b}' } | Select-Object -First 1
    
    if (-not $efiPartition) {
        Write-Host "EFI System Partition not found. Looking for alternatives..." -ForegroundColor Yellow
        $efiPartition = Get-Partition | Where-Object { $_.Type -eq 'System' } | Select-Object -First 1
    }
    
    if (-not $efiPartition) {
        Write-Host "Could not locate EFI System Partition." -ForegroundColor Red
        "Could not locate EFI System Partition." | Out-File -FilePath $logFile -Append
        exit
    }
    
    "EFI Partition found: Disk $($efiPartition.DiskNumber) Partition $($efiPartition.PartitionNumber)" | Out-File -FilePath $logFile -Append
} catch {
    Write-Host "Error locating EFI partition: $_" -ForegroundColor Red
    "Error locating EFI partition: $_" | Out-File -FilePath $logFile -Append
    exit
}

# Step 2: Mount the EFI System Partition
$driveLetter = $null
try {
    Write-Host "Mounting EFI System Partition..." -ForegroundColor Cyan
    
    # Check if the partition is already mounted
    if ($efiPartition.DriveLetter) {
        $driveLetter = $efiPartition.DriveLetter
        Write-Host "EFI partition is already mounted at $($driveLetter):" -ForegroundColor Green
    } else {
        # Find an available drive letter
        $usedDriveLetters = (Get-PSDrive -PSProvider FileSystem).Name
        foreach ($letter in 'ZYXWVUTSRQPONMLKJIHGFED'.ToCharArray()) {
            if ($usedDriveLetters -notcontains $letter) {
                $driveLetter = $letter
                break
            }
        }
        
        if (-not $driveLetter) {
            Write-Host "Could not find an available drive letter." -ForegroundColor Red
            "Could not find an available drive letter." | Out-File -FilePath $logFile -Append
            exit
        }
        
        # Mount the partition
        $tempDriveLetter = "$($driveLetter):"
        $mountResult = Add-PartitionAccessPath -DiskNumber $efiPartition.DiskNumber -PartitionNumber $efiPartition.PartitionNumber -AccessPath $tempDriveLetter -PassThru
        if (-not $mountResult) {
            Write-Host "Failed to mount EFI partition." -ForegroundColor Red
            "Failed to mount EFI partition." | Out-File -FilePath $logFile -Append
            exit
        }
        
        Write-Host "EFI partition mounted at $($driveLetter):" -ForegroundColor Green
    }
    
    "EFI partition mounted at $($driveLetter):" | Out-File -FilePath $logFile -Append
} catch {
    Write-Host "Error mounting EFI partition: $_" -ForegroundColor Red
    "Error mounting EFI partition: $_" | Out-File -FilePath $logFile -Append
    exit
}

# Step 3: Backup bootmgfw.efi and boot.stl from EFI partition
$efiSearchPaths = @(
    "$($driveLetter):\EFI\Microsoft\Boot",
    "$($driveLetter):\EFI\Boot",
    "$($driveLetter):\Boot"
)

$efiFilesToBackup = @(
    "bootmgfw.efi",
    "boot.stl"
)

$efiFilesCopied = $false

foreach ($searchPath in $efiSearchPaths) {
    if (Test-Path $searchPath) {
        Write-Host "Searching for boot files in $searchPath..." -ForegroundColor Cyan
        "Searching for boot files in $searchPath..." | Out-File -FilePath $logFile -Append
        
        foreach ($file in $efiFilesToBackup) {
            $sourcePath = "$searchPath\$file"
            $destPath = "$backupDir\$file"
            
            if (Test-Path $sourcePath) {
                try {
                    # Create directories to maintain the same structure
                    $relativePath = $searchPath.SubString(3)  # Remove drive letter (X:\)
                    $targetDir = "$backupDir\EFI_Partition$relativePath"
                    New-Item -Path $targetDir -ItemType Directory -Force | Out-Null
                    
                    # Copy file
                    Copy-Item -Path $sourcePath -Destination "$targetDir\$file" -Force
                    Copy-Item -Path $sourcePath -Destination $destPath -Force  # Also copy to root backup dir
                    
                    $status = "SUCCESS"
                    Write-Host "Backed up: $file from $searchPath" -ForegroundColor Green
                    $efiFilesCopied = $true
                }
                catch {
                    $status = "FAILED: $_"
                    Write-Host "Failed to backup: $file from $searchPath" -ForegroundColor Red
                    Write-Host $_.Exception.Message -ForegroundColor Red
                }
                
                "$file ($searchPath): $status" | Out-File -FilePath $logFile -Append
            }
        }
    }
}

if (-not $efiFilesCopied) {
    Write-Host "No EFI boot files were found in the standard locations." -ForegroundColor Yellow
    "No EFI boot files were found in the standard locations." | Out-File -FilePath $logFile -Append
    
    # Try to search the entire EFI partition as a last resort
    Write-Host "Searching entire EFI partition for boot files..." -ForegroundColor Cyan
    "Searching entire EFI partition for boot files..." | Out-File -FilePath $logFile -Append
    
    foreach ($file in $efiFilesToBackup) {
        $foundFiles = Get-ChildItem -Path "$($driveLetter):\" -Recurse -Filter $file -ErrorAction SilentlyContinue
        
        foreach ($foundFile in $foundFiles) {
            try {
                # Create directories to maintain the same structure
                $relativePath = $foundFile.DirectoryName.SubString(3)  # Remove drive letter (X:\)
                $targetDir = "$backupDir\EFI_Partition$relativePath"
                New-Item -Path $targetDir -ItemType Directory -Force | Out-Null
                
                # Copy file
                Copy-Item -Path $foundFile.FullName -Destination "$targetDir\$($foundFile.Name)" -Force
                Copy-Item -Path $foundFile.FullName -Destination "$backupDir\$($foundFile.Name)" -Force  # Also copy to root backup dir
                
                $status = "SUCCESS"
                Write-Host "Backed up: $($foundFile.Name) from $($foundFile.DirectoryName)" -ForegroundColor Green
                $efiFilesCopied = $true
            }
            catch {
                $status = "FAILED: $_"
                Write-Host "Failed to backup: $($foundFile.Name) from $($foundFile.DirectoryName)" -ForegroundColor Red
                Write-Host $_.Exception.Message -ForegroundColor Red
            }
            
            "$($foundFile.Name) ($($foundFile.DirectoryName)): $status" | Out-File -FilePath $logFile -Append
        }
    }
}

# Step 4: Unmount the EFI System Partition if we mounted it
if ($efiPartition.DriveLetter -ne $driveLetter) {
    try {
        Write-Host "Unmounting EFI System Partition..." -ForegroundColor Cyan
        
        $mountPoint = "$($driveLetter):"
        Remove-PartitionAccessPath -DiskNumber $efiPartition.DiskNumber -PartitionNumber $efiPartition.PartitionNumber -AccessPath $mountPoint
        
        Write-Host "EFI partition unmounted successfully." -ForegroundColor Green
        "EFI partition unmounted successfully." | Out-File -FilePath $logFile -Append
    } catch {
        Write-Host "Error unmounting EFI partition: $_" -ForegroundColor Red
        "Error unmounting EFI partition: $_" | Out-File -FilePath $logFile -Append
    }
}

# Summary
if ($efiFilesCopied) {
    Write-Host "`nBackup completed successfully!" -ForegroundColor Green
    Write-Host "Files were backed up to: $backupDir" -ForegroundColor Cyan
} else {
    Write-Host "`nNo EFI boot files were found or backed up." -ForegroundColor Yellow
}

Write-Host "See log file for details: $logFile" -ForegroundColor Cyan
Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
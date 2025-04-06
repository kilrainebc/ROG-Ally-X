# Comprehensive Boot Files Backup Script for ROG Ally X
# This script backs up Windows boot files and EFI partition files
# Run as Administrator!

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

# Define paths with relative structure
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Split-Path -Parent (Split-Path -Parent $scriptDir)
$backupPath = Join-Path -Path $repoRoot -ChildPath "boot-animations\backups"
$systemPath = "$env:SystemRoot\System32"
$bootResourcesPath = "$env:SystemRoot\Boot\Resources"
$dateString = (Get-Date).ToString("yyyy-MM-dd_HHmmss")
$backupDir = "$backupPath\$dateString"

# Create backup directory
New-Item -Path $backupDir -ItemType Directory -Force | Out-Null
Write-Host "Creating backup directory: $backupDir" -ForegroundColor Cyan

# Log file
$logFile = "$backupDir\backup_log.txt"
"Boot Files Backup - $dateString" | Out-File -FilePath $logFile
"======================================" | Out-File -FilePath $logFile -Append
"" | Out-File -FilePath $logFile -Append

#region PART 1: Backup Windows System Files

# Files to backup from System32
$system32FilesToBackup = @(
    "winload.exe",
    "winload.efi"
)

# Files to backup from Boot\Resources
$bootResourcesToBackup = @(
    "bootres.dll"
)

# Backup System32 files
Write-Host "Backing up files from $systemPath..." -ForegroundColor Cyan
"PART 1: Windows System Files" | Out-File -FilePath $logFile -Append
"---------------------------" | Out-File -FilePath $logFile -Append

foreach ($file in $system32FilesToBackup) {
    $sourcePath = "$systemPath\$file"
    $destPath = "$backupDir\$file"
    
    # Check if file exists
    if (Test-Path -Path $sourcePath) {
        try {
            # Copy file
            Copy-Item -Path $sourcePath -Destination $destPath -Force
            $status = "SUCCESS"
            Write-Host "Backed up: $file" -ForegroundColor Green
        }
        catch {
            $status = "FAILED: $_"
            Write-Host "Failed to backup: $file" -ForegroundColor Red
            Write-Host $_.Exception.Message -ForegroundColor Red
        }
    }
    else {
        $status = "NOT FOUND"
        Write-Host "File not found: $file" -ForegroundColor Yellow
    }
    
    # Log the result
    "$file : $status" | Out-File -FilePath $logFile -Append
}

# Backup Boot\Resources files
Write-Host "Backing up files from $bootResourcesPath..." -ForegroundColor Cyan
foreach ($file in $bootResourcesToBackup) {
    $sourcePath = "$bootResourcesPath\$file"
    $destPath = "$backupDir\$file"
    
    # Check if file exists
    if (Test-Path -Path $sourcePath) {
        try {
            # Copy file
            Copy-Item -Path $sourcePath -Destination $destPath -Force
            $status = "SUCCESS"
            Write-Host "Backed up: $file" -ForegroundColor Green
        }
        catch {
            $status = "FAILED: $_"
            Write-Host "Failed to backup: $file" -ForegroundColor Red
            Write-Host $_.Exception.Message -ForegroundColor Red
        }
    }
    else {
        $status = "NOT FOUND"
        Write-Host "File not found: $file" -ForegroundColor Yellow
    }
    
    # Log the result
    "$file : $status" | Out-File -FilePath $logFile -Append
}

# Also backup bootres.dll.mui if it exists (localized resources)
$muiPath = "$systemPath\en-US\bootres.dll.mui"
if (Test-Path -Path $muiPath) {
    $muiDir = "$backupDir\en-US"
    New-Item -Path $muiDir -ItemType Directory -Force | Out-Null
    
    try {
        Copy-Item -Path $muiPath -Destination $muiDir -Force
        Write-Host "Backed up: en-US\bootres.dll.mui" -ForegroundColor Green
        "en-US\bootres.dll.mui : SUCCESS" | Out-File -FilePath $logFile -Append
    }
    catch {
        Write-Host "Failed to backup: en-US\bootres.dll.mui" -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
        "en-US\bootres.dll.mui : FAILED: $_" | Out-File -FilePath $logFile -Append
    }
}

#endregion

#region PART 2: Backup EFI Partition Files

# Add a separator in the log
"" | Out-File -FilePath $logFile -Append
"PART 2: EFI Partition Files" | Out-File -FilePath $logFile -Append
"------------------------" | Out-File -FilePath $logFile -Append

# Step 1: Find the EFI System Partition
try {
    Write-Host "`nLocating EFI System Partition..." -ForegroundColor Cyan
    $efiPartition = Get-Partition | Where-Object { $_.GptType -eq '{c12a7328-f81f-11d2-ba4b-00a0c93ec93b}' } | Select-Object -First 1
    
    if (-not $efiPartition) {
        Write-Host "EFI System Partition not found. Looking for alternatives..." -ForegroundColor Yellow
        $efiPartition = Get-Partition | Where-Object { $_.Type -eq 'System' } | Select-Object -First 1
    }
    
    if (-not $efiPartition) {
        Write-Host "Could not locate EFI System Partition." -ForegroundColor Red
        "Could not locate EFI System Partition." | Out-File -FilePath $logFile -Append
        # Continue with the rest of the script even if EFI partition is not found
        $efiPartitionFound = $false
    } else {
        $efiPartitionFound = $true
        "EFI Partition found: Disk $($efiPartition.DiskNumber) Partition $($efiPartition.PartitionNumber)" | Out-File -FilePath $logFile -Append
    }
} catch {
    Write-Host "Error locating EFI partition: $_" -ForegroundColor Red
    "Error locating EFI partition: $_" | Out-File -FilePath $logFile -Append
    $efiPartitionFound = $false
}

# Only continue with EFI backup if the partition was found
if ($efiPartitionFound) {
    # Step 2: Mount the EFI System Partition
    $driveLetter = $null
    $newlyMounted = $false
    try {
        Write-Host "Mounting EFI System Partition..." -ForegroundColor Cyan
        
        # Check if the partition is already mounted
        if ($efiPartition.DriveLetter) {
            $driveLetter = $efiPartition.DriveLetter
            Write-Host "EFI partition is already mounted at $($driveLetter):" -ForegroundColor Green
            $newlyMounted = $false
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
                $efiPartitionMounted = $false
            } else {
                # Mount the partition
                $tempDriveLetter = "$($driveLetter):"
                $mountResult = Add-PartitionAccessPath -DiskNumber $efiPartition.DiskNumber -PartitionNumber $efiPartition.PartitionNumber -AccessPath $tempDriveLetter -PassThru
                if (-not $mountResult) {
                    Write-Host "Failed to mount EFI partition." -ForegroundColor Red
                    "Failed to mount EFI partition." | Out-File -FilePath $logFile -Append
                    $efiPartitionMounted = $false
                } else {
                    Write-Host "EFI partition mounted at $($driveLetter):" -ForegroundColor Green
                    $efiPartitionMounted = $true
                    $newlyMounted = $true
                }
            }
        }
        
        if ($driveLetter) {
            "EFI partition mounted at $($driveLetter):" | Out-File -FilePath $logFile -Append
            $efiPartitionMounted = $true
        }
    } catch {
        Write-Host "Error mounting EFI partition: $_" -ForegroundColor Red
        "Error mounting EFI partition: $_" | Out-File -FilePath $logFile -Append
        $efiPartitionMounted = $false
    }

    # Step 3: Backup EFI files if the partition was mounted
    if ($efiPartitionMounted) {
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
        if ($newlyMounted) {
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
    } else {
        Write-Host "EFI partition could not be mounted. Skipping EFI file backup." -ForegroundColor Yellow
        "EFI partition could not be mounted. Skipping EFI file backup." | Out-File -FilePath $logFile -Append
    }
} else {
    Write-Host "EFI partition not found. Skipping EFI file backup." -ForegroundColor Yellow
    "EFI partition not found. Skipping EFI file backup." | Out-File -FilePath $logFile -Append
}

#endregion

#region Create Restore Script

# Create a restore script in the backup directory
$restoreScriptPath = "$backupDir\restore.ps1"
@"
# Boot Files Restore Script
# This script restores Windows boot files from backup
# Run as Administrator!

# Check if running as administrator
`$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
`$isAdmin = `$currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not `$isAdmin) {
    Write-Host "This script requires Administrator privileges." -ForegroundColor Red
    Write-Host "Please right-click the script and select 'Run as administrator'." -ForegroundColor Red
    Write-Host "Press any key to exit..."
    `$null = `$Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit
}

# Define paths
`$systemPath = "`$env:SystemRoot\System32"
`$bootResourcesPath = "`$env:SystemRoot\Boot\Resources"
`$backupDir = "`$PSScriptRoot"
`$logFile = "`$backupDir\restore_log.txt"

# Create log file
"Boot Files Restore - `$(Get-Date)" | Out-File -FilePath `$logFile
"======================================" | Out-File -FilePath `$logFile -Append
"" | Out-File -FilePath `$logFile -Append

# Restore System32 files
`$system32FilesToRestore = @(
    "winload.exe",
    "winload.efi"
)

foreach (`$file in `$system32FilesToRestore) {
    `$sourcePath = "`$backupDir\`$file"
    `$destPath = "`$systemPath\`$file"
    
    # Check if backup file exists
    if (Test-Path -Path `$sourcePath) {
        try {
            # Copy file back to system directory
            Copy-Item -Path `$sourcePath -Destination `$destPath -Force
            `$status = "SUCCESS"
            Write-Host "Restored: `$file" -ForegroundColor Green
        }
        catch {
            `$status = "FAILED: `$_"
            Write-Host "Failed to restore: `$file" -ForegroundColor Red
            Write-Host `$_.Exception.Message -ForegroundColor Red
        }
    }
    else {
        `$status = "NOT FOUND IN BACKUP"
        Write-Host "Backup file not found: `$file" -ForegroundColor Yellow
    }
    
    # Log the result
    "`$file : `$status" | Out-File -FilePath `$logFile -Append
}

# Restore Boot\Resources files
`$bootResourcesToRestore = @(
    "bootres.dll"
)

foreach (`$file in `$bootResourcesToRestore) {
    `$sourcePath = "`$backupDir\`$file"
    `$destPath = "`$bootResourcesPath\`$file"
    
    # Check if backup file exists
    if (Test-Path -Path `$sourcePath) {
        try {
            # Copy file back to boot resources directory
            Copy-Item -Path `$sourcePath -Destination `$destPath -Force
            `$status = "SUCCESS"
            Write-Host "Restored: `$file" -ForegroundColor Green
        }
        catch {
            `$status = "FAILED: `$_"
            Write-Host "Failed to restore: `$file" -ForegroundColor Red
            Write-Host `$_.Exception.Message -ForegroundColor Red
        }
    }
    else {
        `$status = "NOT FOUND IN BACKUP"
        Write-Host "Backup file not found: `$file" -ForegroundColor Yellow
    }
    
    # Log the result
    "`$file : `$status" | Out-File -FilePath `$logFile -Append
}

# Also restore bootres.dll.mui if it exists
`$muiBackupPath = "`$backupDir\en-US\bootres.dll.mui"
if (Test-Path -Path `$muiBackupPath) {
    `$muiDestDir = "`$systemPath\en-US"
    
    # Ensure destination directory exists
    if (-not (Test-Path -Path `$muiDestDir)) {
        New-Item -Path `$muiDestDir -ItemType Directory -Force | Out-Null
    }
    
    try {
        Copy-Item -Path `$muiBackupPath -Destination "`$muiDestDir\bootres.dll.mui" -Force
        Write-Host "Restored: en-US\bootres.dll.mui" -ForegroundColor Green
        "en-US\bootres.dll.mui : SUCCESS" | Out-File -FilePath `$logFile -Append
    }
    catch {
        Write-Host "Failed to restore: en-US\bootres.dll.mui" -ForegroundColor Red
        Write-Host `$_.Exception.Message -ForegroundColor Red
        "en-US\bootres.dll.mui : FAILED: `$_" | Out-File -FilePath `$logFile -Append
    }
}

# EFI files require mounting the EFI partition - warning only
`$efiFiles = @("bootmgfw.efi", "boot.stl")
foreach (`$file in `$efiFiles) {
    `$sourcePath = "`$backupDir\`$file"
    if (Test-Path -Path `$sourcePath) {
        Write-Host "NOTE: `$file was backed up but requires manual restoration to the EFI partition." -ForegroundColor Yellow
        "NOTE: `$file requires manual restoration to the EFI partition." | Out-File -FilePath `$logFile -Append
    }
}

Write-Host "`nRestore complete. See `$logFile for details." -ForegroundColor Cyan
Write-Host "Press any key to exit..."
`$null = `$Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
"@ | Out-File -FilePath $restoreScriptPath -Encoding utf8

#endregion

# Summary
Write-Host "`nBackup completed successfully!" -ForegroundColor Green
Write-Host "Files were backed up to: $backupDir" -ForegroundColor Cyan
Write-Host "A restore script has been created in the backup directory." -ForegroundColor Cyan
Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
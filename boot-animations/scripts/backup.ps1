   # Boot Files Backup Script for ROG Ally X
# This script creates backups of critical Windows boot files
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
$dateString = (Get-Date).ToString("yyyy-MM-dd_HHmmss")
$backupDir = "$backupPath\$dateString"

# Create backup directory
New-Item -Path $backupDir -ItemType Directory -Force | Out-Null
Write-Host "Creating backup directory: $backupDir" -ForegroundColor Cyan

# Files to backup
$filesToBackup = @(
    "bootres.dll",
    "winload.exe",
    "winload.efi",
    "boot.stl",
    "bootmgfw.efi"
)

# Log file
$logFile = "$backupDir\backup_log.txt"
"Boot Files Backup - $dateString" | Out-File -FilePath $logFile
"======================================" | Out-File -FilePath $logFile -Append
"" | Out-File -FilePath $logFile -Append

# Backup each file
foreach ($file in $filesToBackup) {
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
`$backupDir = "`$PSScriptRoot"
`$logFile = "`$backupDir\restore_log.txt"

# Create log file
"Boot Files Restore - `$(Get-Date)" | Out-File -FilePath `$logFile
"======================================" | Out-File -FilePath `$logFile -Append
"" | Out-File -FilePath `$logFile -Append

# Restore each file
`$filesToRestore = @(
    "bootres.dll",
    "winload.exe",
    "winload.efi",
    "boot.stl",
    "bootmgfw.efi"
)

foreach (`$file in `$filesToRestore) {
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

Write-Host "`nRestore complete. See `$logFile for details." -ForegroundColor Cyan
Write-Host "Press any key to exit..."
`$null = `$Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
"@ | Out-File -FilePath $restoreScriptPath -Encoding utf8

Write-Host ""
Write-Host "Backup completed successfully!" -ForegroundColor Green
Write-Host "Files were backed up to: $backupDir" -ForegroundColor Cyan
Write-Host "A restore script has been created in the backup directory." -ForegroundColor Cyan
Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
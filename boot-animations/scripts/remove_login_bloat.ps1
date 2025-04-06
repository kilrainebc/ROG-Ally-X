# Disable Login Screen Bloat Script
# Removes weather, markets, and trending content from Windows login screen
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

Write-Host "Disabling login screen bloat (weather, markets, trending)..." -ForegroundColor Cyan

# Create backup of registry keys before modification
$backupFolder = "$env:USERPROFILE\Documents\RegistryBackups"
$timestamp = Get-Date -Format "yyyy-MM-dd_HHmmss"
$backupFile = "$backupFolder\LoginScreenBackup_$timestamp.reg"

# Create backup folder if it doesn't exist
if (-not (Test-Path $backupFolder)) {
    New-Item -Path $backupFolder -ItemType Directory -Force | Out-Null
}

# Create system policies key if it doesn't exist
$systemPoliciesPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System"
if (-not (Test-Path $systemPoliciesPath)) {
    New-Item -Path $systemPoliciesPath -Force | Out-Null
}

# Backup current settings
Write-Host "Creating registry backup at: $backupFile" -ForegroundColor Yellow
reg export "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" "$backupFile" /y | Out-Null
reg export "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" "$backupFile" /y | Out-Null

# Step 1: Configure login screen background settings
Write-Host "Configuring login screen background settings..." -ForegroundColor Green
Set-ItemProperty -Path $systemPoliciesPath -Name "DisableLogonBackgroundImage" -Value 0 -Type DWord -Force

# Step 2: Disable content delivery and suggestions
$contentDeliveryPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
if (-not (Test-Path $contentDeliveryPath)) {
    New-Item -Path $contentDeliveryPath -Force | Out-Null
}

# Define all the content delivery values to disable
$contentSettings = @(
    "ContentDeliveryAllowed",
    "FeatureManagementEnabled", 
    "OemPreInstalledAppsEnabled",
    "PreInstalledAppsEnabled",
    "SilentInstalledAppsEnabled",
    "SystemPaneSuggestionsEnabled",
    "SubscribedContent-310093Enabled",
    "SubscribedContent-314559Enabled", 
    "SubscribedContent-338387Enabled",
    "SubscribedContent-338388Enabled",
    "SubscribedContent-338389Enabled",
    "SubscribedContent-338393Enabled"
)

# Set all content delivery settings to 0 (disabled)
Write-Host "Disabling content delivery and suggestions..." -ForegroundColor Green
foreach ($setting in $contentSettings) {
    Set-ItemProperty -Path $contentDeliveryPath -Name $setting -Value 0 -Type DWord -Force
    Write-Host "  Disabled: $setting" -ForegroundColor Gray
}

# Step 3: Additional cleanup for good measure
# Disable Spotlight features
$spotlightPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
if (Test-Path $spotlightPath) {
    Write-Host "Disabling Windows Spotlight features..." -ForegroundColor Green
    Set-ItemProperty -Path $spotlightPath -Name "RotatingLockScreenEnabled" -Value 0 -Type DWord -Force
    Set-ItemProperty -Path $spotlightPath -Name "RotatingLockScreenOverlayEnabled" -Value 0 -Type DWord -Force
    Set-ItemProperty -Path $spotlightPath -Name "SubscribedContent-338387Enabled" -Value 0 -Type DWord -Force
}

# Disable lock screen suggestions and rotating pictures (user-specific)
$personalizeRegPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize"
if (Test-Path $personalizeRegPath) {
    Set-ItemProperty -Path $personalizeRegPath -Name "EnableTransparency" -Value 1 -Type DWord -Force
}

Write-Host "`nAll login screen bloat has been disabled!" -ForegroundColor Green
Write-Host "A registry backup was created at: $backupFile" -ForegroundColor Yellow
Write-Host "`nPlease restart your computer for changes to take effect." -ForegroundColor Cyan
Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
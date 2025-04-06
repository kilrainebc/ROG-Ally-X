# Aggressive Disable Login Screen Bloat Script
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

Write-Host "Aggressively disabling login screen bloat (weather, markets, trending)..." -ForegroundColor Cyan

# Method 1: System Registry Modifications
Write-Host "Method 1: Applying system registry modifications..." -ForegroundColor Green

# Create or modify system policies
$systemPoliciesPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System"
if (-not (Test-Path $systemPoliciesPath)) {
    New-Item -Path $systemPoliciesPath -Force | Out-Null
}

# Configure custom logon background
Set-ItemProperty -Path $systemPoliciesPath -Name "DisableLogonBackgroundImage" -Value 1 -Type DWord -Force

# Force disable content delivery manager
$contentDeliveryPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
if (-not (Test-Path $contentDeliveryPath)) {
    New-Item -Path $contentDeliveryPath -Force | Out-Null
}

# Forcefully disable all content delivery features
$contentSettings = @(
    "ContentDeliveryAllowed",
    "FeatureManagementEnabled", 
    "OemPreInstalledAppsEnabled",
    "PreInstalledAppsEnabled",
    "PreInstalledAppsEverEnabled",
    "SilentInstalledAppsEnabled",
    "SubscribedContent-310091Enabled",
    "SubscribedContent-310092Enabled",
    "SubscribedConten
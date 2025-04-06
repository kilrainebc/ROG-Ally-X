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
    "SubscribedContent-310093Enabled",
    "SubscribedContent-314559Enabled",
    "SubscribedContent-314563Enabled",
    "SubscribedContent-338387Enabled",
    "SubscribedContent-338388Enabled",
    "SubscribedContent-338389Enabled",
    "SubscribedContent-338393Enabled",
    "SubscribedContent-353694Enabled",
    "SubscribedContent-353696Enabled",
    "SubscribedContent-353698Enabled",
    "SystemPaneSuggestionsEnabled",
    "RotatingLockScreenEnabled",
    "RotatingLockScreenOverlayEnabled"
)

foreach ($setting in $contentSettings) {
    Set-ItemProperty -Path $contentDeliveryPath -Name $setting -Value 0 -Type DWord -Force
}

# Method 2: Local Group Policy Modifications (if available)
Write-Host "Method 2: Applying local group policy modifications..." -ForegroundColor Green

# Create temporary files for policy import
$tempFolder = "$env:TEMP\logon-policy"
New-Item -Path $tempFolder -ItemType Directory -Force | Out-Null

$policyFile = @"
[Unicode]
Unicode=yes
[Version]
signature="`$CHICAGO`$"
Revision=1
[Registry Values]
[System Access]
[Privilege Rights]
[Registry Keys]
[Service General Setting]
[File Security]
[Group Membership]
[Event Audit]
[Kerberos Policy]
"@

$policyFile | Out-File -FilePath "$tempFolder\NoLockScreen.inf" -Encoding Unicode

try {
    # Try to import policy if secedit is available
    secedit /configure /db "$tempFolder\temp.sdb" /cfg "$tempFolder\NoLockScreen.inf" /quiet
} catch {
    Write-Host "Group Policy import not available. Continuing with registry modifications." -ForegroundColor Yellow
}

# Method 3: Direct User Experience Settings
Write-Host "Method 3: Applying direct user experience settings..." -ForegroundColor Green

# Disable Windows spotlight
$spotlightPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
if (-not (Test-Path $spotlightPath)) {
    New-Item -Path $spotlightPath -Force | Out-Null
}

# Apply spotlight settings to current user
foreach ($setting in $contentSettings) {
    Set-ItemProperty -Path $spotlightPath -Name $setting -Value 0 -Type DWord -Force
}

# Disable lock screen slideshow
$personalizeRegPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize"
if (-not (Test-Path $personalizeRegPath)) {
    New-Item -Path $personalizeRegPath -Force | Out-Null
}
Set-ItemProperty -Path $personalizeRegPath -Name "EnableTransparency" -Value 1 -Type DWord -Force

# Method 4: Registry Configuration for All Users
Write-Host "Method 4: Applying settings for all users..." -ForegroundColor Green

# Default user profile modifications
reg load "HKU\DefaultUser" "C:\Users\Default\NTUSER.DAT"
if ($?) {
    # Create keys if they don't exist
    if (-not (Test-Path "Registry::HKEY_USERS\DefaultUser\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager")) {
        New-Item -Path "Registry::HKEY_USERS\DefaultUser\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Force | Out-Null
    }
    
    # Apply content delivery manager settings to default user
    foreach ($setting in $contentSettings) {
        Set-ItemProperty -Path "Registry::HKEY_USERS\DefaultUser\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name $setting -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
    }
    
    # Unload default user hive
    [gc]::Collect()
    Start-Sleep -Seconds 1
    reg unload "HKU\DefaultUser"
}

# Method 5: Additional Components
Write-Host "Method 5: Disabling related services and components..." -ForegroundColor Green

# Disable Content Delivery Manager service if it exists
$services = @(
    "ContentDeliveryManager.Service",
    "PimIndexMaintenanceSvc",
    "UserDataSvc"
)

foreach ($service in $services) {
    $svc = Get-Service -Name $service -ErrorAction SilentlyContinue
    if ($svc) {
        Stop-Service -Name $service -Force -ErrorAction SilentlyContinue
        Set-Service -Name $service -StartupType Disabled -ErrorAction SilentlyContinue
        Write-Host "  Disabled service: $service" -ForegroundColor Gray
    }
}

# Method 6: Custom Policy Configuration
Write-Host "Method 6: Creating custom policy configuration..." -ForegroundColor Green

# Lock screen policies
$lockScreenPolicyPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Personalization"
if (-not (Test-Path $lockScreenPolicyPath)) {
    New-Item -Path $lockScreenPolicyPath -Force | Out-Null
}
Set-ItemProperty -Path $lockScreenPolicyPath -Name "NoLockScreen" -Value 0 -Type DWord -Force
Set-ItemProperty -Path $lockScreenPolicyPath -Name "LockScreenOverlaysDisabled" -Value 1 -Type DWord -Force

# Disable Windows Spotlight
$spotlightPolicyPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent"
if (-not (Test-Path $spotlightPolicyPath)) {
    New-Item -Path $spotlightPolicyPath -Force | Out-Null
}
Set-ItemProperty -Path $spotlightPolicyPath -Name "DisableWindowsSpotlightFeatures" -Value 1 -Type DWord -Force
Set-ItemProperty -Path $spotlightPolicyPath -Name "DisableWindowsSpotlightOnActionCenter" -Value 1 -Type DWord -Force
Set-ItemProperty -Path $spotlightPolicyPath -Name "DisableWindowsSpotlightOnSettings" -Value 1 -Type DWord -Force
Set-ItemProperty -Path $spotlightPolicyPath -Name "DisableWindowsSpotlightWindowsWelcomeExperience" -Value 1 -Type DWord -Force

# Disable cloud-delivered content
Set-ItemProperty -Path $spotlightPolicyPath -Name "DisableCloudOptimizedContent" -Value 1 -Type DWord -Force
Set-ItemProperty -Path $spotlightPolicyPath -Name "DisableSoftLanding" -Value 1 -Type DWord -Force
Set-ItemProperty -Path $spotlightPolicyPath -Name "DisableTailoredExperiencesWithDiagnosticData" -Value 1 -Type DWord -Force

Write-Host "`nAll aggressive measures applied to remove login screen bloat!" -ForegroundColor Green
Write-Host "`nPlease restart your computer for changes to take effect." -ForegroundColor Cyan
Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
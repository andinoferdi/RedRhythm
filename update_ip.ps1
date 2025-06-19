# RedRhythm IP Address Auto-Update Script
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "   RedRhythm IP Address Auto-Update" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Detect local IP address
Write-Host "Detecting your laptop IP address..." -ForegroundColor Yellow

# Try multiple methods to get IP
$localIP = $null

# Method 1: Get from WiFi adapter (try common interface names)
try {
    $wifiInterfaces = @("Wi-Fi*", "WiFi*", "Wireless*", "WLAN*")
    foreach ($interface in $wifiInterfaces) {
        $localIP = (Get-NetIPAddress -AddressFamily IPv4 -InterfaceAlias $interface -ErrorAction SilentlyContinue | Where-Object {$_.IPAddress -like "192.168.*" -or $_.IPAddress -like "10.*" -or $_.IPAddress -like "172.*"}).IPAddress | Select-Object -First 1
        if ($localIP) { break }
    }
} catch {}

# Method 2: Get from any DHCP-assigned IPv4 address
if (-not $localIP) {
    try {
        $localIP = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object {$_.IPAddress -ne "127.0.0.1" -and $_.PrefixOrigin -eq "Dhcp"}).IPAddress | Select-Object -First 1
    } catch {}
}

# Method 3: Fallback using ipconfig
if (-not $localIP) {
    try {
        $ipconfig = ipconfig | Select-String "IPv4"
        if ($ipconfig) {
            $localIP = ($ipconfig[0] -split ':')[1].Trim()
        }
    } catch {}
}

if (-not $localIP) {
    Write-Host "❌ ERROR: Could not detect IP address!" -ForegroundColor Red
    Write-Host "Please check your network connection." -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host "Local IP Address: $localIP" -ForegroundColor Green
Write-Host "Server URL will be: http://$localIP`:8090" -ForegroundColor Green
Write-Host ""

# Update app_config.dart file
$configFile = "lib\utils\app_config.dart"
Write-Host "Updating $configFile..." -ForegroundColor Yellow

if (-not (Test-Path $configFile)) {
    Write-Host "❌ ERROR: File $configFile not found!" -ForegroundColor Red
    Write-Host "Make sure you're running this from the project root directory." -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

# Create backup
$backupFile = "$configFile.backup"
Copy-Item $configFile $backupFile
Write-Host "Created backup: $backupFile" -ForegroundColor Gray

try {
    # Read file content
    $content = Get-Content $configFile -Raw
    
    # Replace the physicalDeviceUrl line
    $pattern = "static const String physicalDeviceUrl = 'http://.*:8090';"
    $replacement = "static const String physicalDeviceUrl = 'http://$localIP`:8090';"
    
    $newContent = $content -replace $pattern, $replacement
    
    # Write back to file
    Set-Content -Path $configFile -Value $newContent -NoNewline
    
    Write-Host "✅ Successfully updated app_config.dart" -ForegroundColor Green
    Write-Host "   New URL: http://$localIP`:8090" -ForegroundColor White
    
} catch {
    Write-Host "❌ Failed to update file. Restoring backup..." -ForegroundColor Red
    Copy-Item $backupFile $configFile
    Write-Host "Error: $_" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "   NEXT STEPS:" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "1. Start PocketBase server manually:" -ForegroundColor White
Write-Host "   cd Backend" -ForegroundColor Gray
Write-Host "   ./pocketbase serve" -ForegroundColor Gray
Write-Host ""
Write-Host "2. Build app for your phone:" -ForegroundColor White
Write-Host "   flutter build apk --release" -ForegroundColor Gray
Write-Host ""
Write-Host "3. Install app on your phone" -ForegroundColor White
Write-Host ""
Write-Host "4. Test connection from phone browser:" -ForegroundColor White
Write-Host "   http://$localIP`:8090/_/" -ForegroundColor Gray
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Read-Host "Press Enter to continue" 
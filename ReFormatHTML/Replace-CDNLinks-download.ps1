# PowerShell script to replace CDN links with local file paths in HTML
# Usage: .\Replace-CDNLinks.ps1 -HtmlFilePath "path\to\index.html" [-DownloadDependencies]

param(
    [Parameter(Mandatory=$true)]
    [string]$HtmlFilePath,
    
    [Parameter(Mandatory=$false)]
    [string]$BackupSuffix = "_backup",
    
    [Parameter(Mandatory=$false)]
    [switch]$DownloadDependencies
)

# Check if file exists
if (-not (Test-Path $HtmlFilePath)) {
    Write-Error "HTML file not found: $HtmlFilePath"
    exit 1
}

Write-Host "🔧 Starting CDN to Local Links Replacement..." -ForegroundColor Green
Write-Host "📁 Processing file: $HtmlFilePath" -ForegroundColor Cyan

# Create backup
$backupPath = $HtmlFilePath -replace '\.html$', "$BackupSuffix.html"
try {
    Copy-Item $HtmlFilePath $backupPath -Force
    Write-Host "✅ Backup created: $backupPath" -ForegroundColor Yellow
} catch {
    Write-Error "Failed to create backup: $_"
    exit 1
}

# Read the HTML file
try {
    $htmlContent = Get-Content $HtmlFilePath -Raw -Encoding UTF8
    Write-Host "📖 HTML file read successfully" -ForegroundColor Green
} catch {
    Write-Error "Failed to read HTML file: $_"
    exit 1
}

# Define replacement mappings (CDN URL -> Local Path)
$replacements = @{
    # Bootstrap CSS
    'https://stackpath.bootstrapcdn.com/bootstrap/4.5.2/css/bootstrap.min.css' = 'static/css/bootstrap.min.css'
    
    # jQuery
    'https://ajax.googleapis.com/ajax/libs/jquery/3.6.4/jquery.min.js' = 'static/js/jquery.min.js'
    
    # Bootstrap JS
    'https://stackpath.bootstrapcdn.com/bootstrap/4.5.2/js/bootstrap.min.js' = 'static/js/bootstrap.min.js'
    
    # Chart.js
    'https://cdnjs.cloudflare.com/ajax/libs/Chart.js/3.5.1/chart.min.js' = 'static/js/chart.min.js'
}

# Function to download dependencies
function Download-Dependencies {
    param (
        [hashtable]$ReplacementMap,
        [string]$BaseDir
    )
    
    Write-Host "📥 Starting dependency downloads..." -ForegroundColor Green
    
    # Ensure directories exist
    $cssDir = Join-Path $BaseDir "static\css"
    $jsDir = Join-Path $BaseDir "static\js"
    
    if (!(Test-Path $cssDir)) {
        New-Item -Path $cssDir -ItemType Directory -Force | Out-Null
        Write-Host "📁 Created directory: $cssDir" -ForegroundColor Yellow
    }
    
    if (!(Test-Path $jsDir)) {
        New-Item -Path $jsDir -ItemType Directory -Force | Out-Null
        Write-Host "📁 Created directory: $jsDir" -ForegroundColor Yellow
    }
    
    $downloadCount = 0
    $totalFiles = $ReplacementMap.Count
    
    foreach ($cdnUrl in $ReplacementMap.Keys) {
        $localPath = $ReplacementMap[$cdnUrl]
        $fullLocalPath = Join-Path $BaseDir $localPath
        $fileName = Split-Path $localPath -Leaf
        
        Write-Host "⏬ Downloading $fileName..." -ForegroundColor Cyan
        
        try {
            # Download with progress
            $webClient = New-Object System.Net.WebClient
            
            # Add user agent to avoid blocking
            $webClient.Headers.Add("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36")
            
            # Download the file
            $webClient.DownloadFile($cdnUrl, $fullLocalPath)
            $webClient.Dispose()
            
            # Verify download
            if (Test-Path $fullLocalPath) {
                $fileSize = (Get-Item $fullLocalPath).Length
                Write-Host "  ✅ Downloaded: $fileName ($([math]::Round($fileSize/1KB, 2)) KB)" -ForegroundColor Green
                $downloadCount++
            } else {
                Write-Host "  ❌ Failed to download: $fileName" -ForegroundColor Red
            }
            
        } catch {
            Write-Host "  ❌ Error downloading $fileName : $($_.Exception.Message)" -ForegroundColor Red
            
            # Try alternative method using Invoke-WebRequest
            try {
                Write-Host "  🔄 Trying alternative download method..." -ForegroundColor Yellow
                Invoke-WebRequest -Uri $cdnUrl -OutFile $fullLocalPath -UserAgent "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"
                
                if (Test-Path $fullLocalPath) {
                    $fileSize = (Get-Item $fullLocalPath).Length
                    Write-Host "  ✅ Downloaded: $fileName ($([math]::Round($fileSize/1KB, 2)) KB)" -ForegroundColor Green
                    $downloadCount++
                } else {
                    Write-Host "  ❌ Alternative method also failed: $fileName" -ForegroundColor Red
                }
            } catch {
                Write-Host "  ❌ Alternative method failed: $($_.Exception.Message)" -ForegroundColor Red
            }
        }
        
        # Small delay to be respectful to servers
        Start-Sleep -Milliseconds 500
    }
    
    Write-Host "" -ForegroundColor White
    if ($downloadCount -eq $totalFiles) {
        Write-Host "🎉 All dependencies downloaded successfully! ($downloadCount/$totalFiles)" -ForegroundColor Green
    } elseif ($downloadCount -gt 0) {
        Write-Host "⚠️  Partial success: $downloadCount out of $totalFiles dependencies downloaded" -ForegroundColor Yellow
        Write-Host "   You may need to manually download the failed ones" -ForegroundColor Yellow
    } else {
        Write-Host "❌ No dependencies were downloaded successfully" -ForegroundColor Red
        Write-Host "   Please check your internet connection and try again" -ForegroundColor Red
    }
    
    return $downloadCount
}

# Get the directory containing the HTML file
$htmlDir = Split-Path $HtmlFilePath -Parent
if ([string]::IsNullOrEmpty($htmlDir)) {
    $htmlDir = "."
}

# Download dependencies if requested
if ($DownloadDependencies) {
    Write-Host "🔧 Download mode enabled - Dependencies will be downloaded" -ForegroundColor Green
    $downloadsSuccessful = Download-Dependencies -ReplacementMap $replacements -BaseDir $htmlDir
    Write-Host "" -ForegroundColor White
} else {
    Write-Host "ℹ️  Download mode not enabled (use -DownloadDependencies to download files)" -ForegroundColor DarkGray
    Write-Host "" -ForegroundColor White
}

# Track changes
$changesCount = 0
$originalContent = $htmlContent

# Perform replacements
Write-Host "🔄 Performing replacements..." -ForegroundColor Cyan

foreach ($cdn in $replacements.Keys) {
    $localPath = $replacements[$cdn]
    
    # Count occurrences before replacement
    $beforeCount = ([regex]::Matches($htmlContent, [regex]::Escape($cdn))).Count
    
    if ($beforeCount -gt 0) {
        # Perform replacement
        $htmlContent = $htmlContent.Replace($cdn, $localPath)
        
        # Verify replacement
        $afterCount = ([regex]::Matches($htmlContent, [regex]::Escape($cdn))).Count
        $replaced = $beforeCount - $afterCount
        
        if ($replaced -gt 0) {
            Write-Host "  ✅ Replaced $replaced occurrence(s): $cdn" -ForegroundColor Green
            Write-Host "     → $localPath" -ForegroundColor Gray
            $changesCount += $replaced
        }
    } else {
        Write-Host "  ℹ️  No occurrences found: $cdn" -ForegroundColor DarkGray
    }
}

# Check if any changes were made
if ($changesCount -eq 0) {
    Write-Host "ℹ️  No CDN links found to replace" -ForegroundColor Yellow
    
    # Remove backup since no changes were made
    Remove-Item $backupPath -Force
    Write-Host "🗑️  Backup removed (no changes made)" -ForegroundColor DarkGray
    exit 0
}

# Write the modified content back to file
try {
    Set-Content $HtmlFilePath -Value $htmlContent -Encoding UTF8 -NoNewline
    Write-Host "💾 Modified HTML file saved successfully" -ForegroundColor Green
} catch {
    Write-Error "Failed to write modified HTML file: $_"
    
    # Restore from backup
    Copy-Item $backupPath $HtmlFilePath -Force
    Write-Host "🔄 Restored from backup due to error" -ForegroundColor Yellow
    exit 1
}

# Summary
Write-Host "" -ForegroundColor White
Write-Host "🎉 Replacement completed successfully!" -ForegroundColor Green
Write-Host "📊 Summary:" -ForegroundColor Cyan
Write-Host "  • Total replacements made: $changesCount" -ForegroundColor White
Write-Host "  • Original file backed up as: $backupPath" -ForegroundColor White
Write-Host "  • Modified file: $HtmlFilePath" -ForegroundColor White

# Validation
Write-Host "" -ForegroundColor White
Write-Host "🔍 Validation - Checking for remaining CDN links..." -ForegroundColor Cyan

$remainingCDNs = @()
foreach ($cdn in $replacements.Keys) {
    if ($htmlContent.Contains($cdn)) {
        $remainingCDNs += $cdn
    }
}

if ($remainingCDNs.Count -eq 0) {
    Write-Host "✅ Validation passed: No CDN links remain" -ForegroundColor Green
} else {
    Write-Host "⚠️  Warning: Some CDN links still remain:" -ForegroundColor Yellow
    foreach ($cdn in $remainingCDNs) {
        Write-Host "   • $cdn" -ForegroundColor Yellow
    }
}

# Final instructions
Write-Host "" -ForegroundColor White
Write-Host "📋 Next Steps:" -ForegroundColor Cyan

if ($DownloadDependencies) {
    if ($downloadsSuccessful -eq $replacements.Count) {
        Write-Host "  ✅ All dependencies downloaded and HTML updated!" -ForegroundColor Green
        Write-Host "  🧪 Test your HTML file offline to verify everything works" -ForegroundColor White
    } else {
        Write-Host "  ⚠️  Some dependencies may be missing. Please check:" -ForegroundColor Yellow
        Write-Host "     • static/css/bootstrap.min.css" -ForegroundColor Gray
        Write-Host "     • static/js/jquery.min.js" -ForegroundColor Gray
        Write-Host "     • static/js/bootstrap.min.js" -ForegroundColor Gray
        Write-Host "     • static/js/chart.min.js" -ForegroundColor Gray
        Write-Host "  📥 Download missing files manually if needed" -ForegroundColor White
        Write-Host "  🧪 Test your HTML file offline to verify everything works" -ForegroundColor White
    }
} else {
    Write-Host "  1. Download dependency files to the correct locations:" -ForegroundColor White
    Write-Host "     • static/css/bootstrap.min.css" -ForegroundColor Gray
    Write-Host "     • static/js/jquery.min.js" -ForegroundColor Gray
    Write-Host "     • static/js/bootstrap.min.js" -ForegroundColor Gray
    Write-Host "     • static/js/chart.min.js" -ForegroundColor Gray
    Write-Host "  2. Test your HTML file offline to verify everything works" -ForegroundColor White
}

Write-Host "  🔄 If issues arise, restore from backup: $backupPath" -ForegroundColor White

Write-Host "" -ForegroundColor White
Write-Host "🏁 Script execution completed!" -ForegroundColor Green
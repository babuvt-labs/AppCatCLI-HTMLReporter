# PowerShell script to replace CDN links with local file paths in HTML
# Usage: .\Replace-CDNLinks.ps1 -HtmlFilePath "path\to\index.html"

param(
    [Parameter(Mandatory=$true)]
    [string]$HtmlFilePath,
    
    [Parameter(Mandatory=$false)]
    [string]$BackupSuffix = "_backup"
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
Write-Host "  1. Ensure all dependency files are downloaded to the correct locations:" -ForegroundColor White
Write-Host "     • static/css/bootstrap.min.css" -ForegroundColor Gray
Write-Host "     • static/js/jquery.min.js" -ForegroundColor Gray
Write-Host "     • static/js/bootstrap.min.js" -ForegroundColor Gray
Write-Host "     • static/js/chart.min.js" -ForegroundColor Gray
Write-Host "  2. Test your HTML file offline to verify everything works" -ForegroundColor White
Write-Host "  3. If issues arise, restore from backup: $backupPath" -ForegroundColor White

Write-Host "" -ForegroundColor White
Write-Host "🏁 Script execution completed!" -ForegroundColor Green
# AppCat HTML Report Generator
# This script generates an attractive HTML report from AppCat results.json

param(
    [Parameter(Mandatory=$false)]
    [string]$JsonFilePath = "results.json",
    
    [Parameter(Mandatory=$false)]
    [string]$OutputPath = "AppCat_Report.html"
)


# Function to generate issue details HTML
function Generate-IssueDetails {
    param(
        [object]$Project,
        [hashtable]$Rules
    )
    
    $issueGroups = @{}
    
    # Group issues by rule ID first, then by severity
    $ruleGroups = @{}
    foreach ($ruleInstance in $Project.ruleInstances) {
        $ruleId = $ruleInstance.ruleId
        if (-not $ruleGroups.ContainsKey($ruleId)) {
            $ruleGroups[$ruleId] = @()
        }
        $ruleGroups[$ruleId] += $ruleInstance
    }
    
    # Now group by severity
    foreach ($ruleId in $ruleGroups.Keys) {
        if ($Rules.ContainsKey($ruleId)) {
            $rule = $Rules[$ruleId]
            $severity = $rule.severity
            if (-not $issueGroups.ContainsKey($severity)) {
                $issueGroups[$severity] = @()
            }
            $issueGroups[$severity] += @{
                RuleId = $ruleId
                Rule = $rule
                Instances = $ruleGroups[$ruleId]
            }
        }
    }
    
    $html = ""
    $severityOrder = @("Mandatory", "Optional", "Potential", "Information")
    $severityColors = @{
        "Mandatory" = "#dc3545"
        "Optional" = "#fd7e14"
        "Potential" = "#ffc107"
        "Information" = "#17a2b8"
    }
    $severityIcons = @{
        "Mandatory" = "❗"
        "Optional" = "⚠️"
        "Potential" = "🔶"
        "Information" = "💡"
    }
    
    foreach ($severity in $severityOrder) {
        if ($issueGroups.ContainsKey($severity)) {
            $color = $severityColors[$severity]
            $icon = $severityIcons[$severity]
            $html += @"
            <div class="severity-section">
                <h3 style="color: $color; border-bottom: 2px solid $color; padding-bottom: 10px;">
                    $icon $severity Issues
                </h3>
"@
            
            foreach ($issue in $issueGroups[$severity]) {
                $rule = $issue.Rule
                $instances = $issue.Instances
                $instanceCount = if ($instances) { $instances.Count } else { 0 }
                
                $html += @"
                <div class="issue-card">
                    <div class="issue-header" onclick="toggleIssue('$($issue.RuleId)')">
                        <span class="issue-id" style="background-color: $color;">$($issue.RuleId)</span>
                        <span class="issue-title">$($rule.label)</span>
                        <span class="issue-count">$instanceCount incidents</span>
                        <span class="toggle-icon" id="icon-$($issue.RuleId)">▼</span>
                    </div>
                    <div class="issue-details" id="details-$($issue.RuleId)" style="display: none;">
                        <div class="issue-description">
                            <strong>Description:</strong><br>
                            $($rule.description -replace "`n", "<br>")
                        </div>
                        <div class="issue-metadata">
                            <span class="effort-badge">Effort: $($rule.effort) story points</span>
                        </div>
"@
                
                # Add links if they exist
                if ($rule.links -and $rule.links.Count -gt 0) {
                    $html += "<div class='links-section'>"
                    $html += "<strong>📚 Learn More:</strong>"
                    foreach ($link in $rule.links) {
                        if ($link.url) {
                            $html += "<a href='$($link.url)' target='_blank' class='info-link'>"
                            $html += "🔗 Microsoft Documentation"
                            $html += "</a>"
                        }
                    }
                    $html += "</div>"
                }
                
                $html += @"
"@
                
                if ($instances -and $instances.Count -gt 0) {
                    $html += @"
                        <div class="instances-section">
                            <div class="instances-header" onclick="toggleInstances('$($issue.RuleId)')">
                                <strong>📁 Affected Locations ($($instances.Count) files)</strong>
                                <span class="instances-toggle-icon" id="instances-icon-$($issue.RuleId)">▼</span>
                            </div>
                            <div class="instances-content" id="instances-$($issue.RuleId)" style="display: none;">
                                <ul class="instances-list">
"@
                    foreach ($instance in $instances) {
                        $locationPath = if ($instance.location.path) { $instance.location.path } else { "Unknown location" }
                        $html += "<li><code>$locationPath</code>"
                        if ($instance.location.line) {
                            $html += " (Line: $($instance.location.line))"
                        }
                        $html += "</li>"
                    }
                    $html += "</ul></div></div>"
                }
                
                $html += "</div></div>"
            }
            
            $html += "</div>"
        }
    }
    
    return $html
}

# Main script execution
try {
    # Read and parse JSON file
    if (-not (Test-Path $JsonFilePath)) {
        Write-Error "JSON file not found: $JsonFilePath"
        exit 1
    }
    
    Write-Host "Reading JSON file: $JsonFilePath" -ForegroundColor Green
    $jsonContent = Get-Content $JsonFilePath -Raw -Encoding UTF8
    $data = $jsonContent | ConvertFrom-Json
    
    # Extract summary information
    $summary = $data.stats.summary
    
    # Handle date parsing safely
    $analysisStart = "N/A"
    $analysisEnd = "N/A"
    
    try {
        if ($data.analysisStartTime) {
            # Handle ISO 8601 format dates
            $analysisStart = [DateTime]::Parse($data.analysisStartTime, $null, [System.Globalization.DateTimeStyles]::RoundtripKind).ToString("yyyy-MM-dd HH:mm:ss UTC")
        }
    } catch {
        try {
            # Try alternative parsing for different date formats
            $analysisStart = ([DateTime]$data.analysisStartTime).ToString("yyyy-MM-dd HH:mm:ss UTC")
        } catch {
            Write-Warning "Could not parse analysis start time: $($data.analysisStartTime)"
            $analysisStart = $data.analysisStartTime
        }
    }
    
    try {
        if ($data.analysisEndTime) {
            $analysisEnd = [DateTime]::Parse($data.analysisEndTime, $null, [System.Globalization.DateTimeStyles]::RoundtripKind).ToString("yyyy-MM-dd HH:mm:ss UTC")
        }
    } catch {
        try {
            $analysisEnd = ([DateTime]$data.analysisEndTime).ToString("yyyy-MM-dd HH:mm:ss UTC")
        } catch {
            Write-Warning "Could not parse analysis end time: $($data.analysisEndTime)"
            $analysisEnd = if ($data.analysisEndTime) { $data.analysisEndTime } else { "N/A" }
        }
    }
    
    # Convert rules to hashtable for easier lookup
    $rulesHash = @{}
    $data.rules.PSObject.Properties | ForEach-Object { $rulesHash[$_.Name] = $_.Value }
    
    # Generate issue details for the first project (assuming single project)
    $project = $data.projects[0]
    $issueDetailsHtml = Generate-IssueDetails -Project $project -Rules $rulesHash
    
    # Generate complete HTML report
    $htmlContent = @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Azure App Modernization Assessment Report</title>
    <!-- Chart.js removed: using SVG charts instead -->
    <!-- Font Awesome removed: using Unicode icons instead -->
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            line-height: 1.6;
            color: #333;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
        }
        
        .container {
            max-width: 1200px;
            margin: 0 auto;
            padding: 20px;
        }
        
        .header {
            background: white;
            border-radius: 15px;
            padding: 30px;
            margin-bottom: 30px;
            box-shadow: 0 10px 30px rgba(0,0,0,0.1);
            text-align: center;
        }
        
        .header h1 {
            color: #2c3e50;
            font-size: 2.5rem;
            margin-bottom: 10px;
        }
        
        .header .subtitle {
            color: #7f8c8d;
            font-size: 1.1rem;
        }
        
        .summary-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 20px;
            margin-bottom: 30px;
        }
        
        .summary-card {
            background: white;
            border-radius: 15px;
            padding: 25px;
            text-align: center;
            box-shadow: 0 10px 30px rgba(0,0,0,0.1);
            transition: transform 0.3s ease;
        }
        
        .summary-card:hover {
            transform: translateY(-5px);
        }
        
        .summary-card h3 {
            font-size: 2rem;
            margin-bottom: 10px;
            color: #2c3e50;
        }
        
        .summary-card p {
            color: #7f8c8d;
            font-weight: 500;
        }
        
        .summary-card.projects h3 { color: #3498db; }
        .summary-card.issues h3 { color: #e74c3c; }
        .summary-card.incidents h3 { color: #f39c12; }
        .summary-card.effort h3 { color: #9b59b6; }
        
        .charts-section {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(400px, 1fr));
            gap: 30px;
            margin-bottom: 30px;
        }
        
        .chart-container {
            background: white;
            border-radius: 15px;
            padding: 30px;
            box-shadow: 0 10px 30px rgba(0,0,0,0.1);
            height: 400px;
        }
        
        .chart-container h3 {
            text-align: center;
            margin-bottom: 20px;
            color: #2c3e50;
            font-size: 1.3rem;
        }
        
        .chart-container canvas {
            max-height: 300px;
        }
        
        .issues-section {
            background: white;
            border-radius: 15px;
            padding: 30px;
            box-shadow: 0 10px 30px rgba(0,0,0,0.1);
        }
        
        .issues-section h2 {
            color: #2c3e50;
            margin-bottom: 20px;
            font-size: 1.8rem;
        }
        
        .severity-section {
            margin-bottom: 30px;
        }
        
        .issue-card {
            border: 1px solid #e9ecef;
            border-radius: 8px;
            margin-bottom: 15px;
            overflow: hidden;
            transition: all 0.3s ease;
        }
        
        .issue-card:hover {
            box-shadow: 0 5px 15px rgba(0,0,0,0.1);
        }
        
        .issue-header {
            padding: 15px 20px;
            background: #f8f9fa;
            cursor: pointer;
            display: flex;
            align-items: center;
            gap: 15px;
            transition: background-color 0.3s ease;
        }
        
        .issue-header:hover {
            background: #e9ecef;
        }
        
        .issue-id {
            background: #007bff;
            color: white;
            padding: 5px 10px;
            border-radius: 5px;
            font-weight: bold;
            font-size: 0.9rem;
            min-width: 100px;
            text-align: center;
        }
        
        .issue-title {
            flex: 1;
            font-weight: 600;
            color: #2c3e50;
        }
        
        .issue-count {
            background: #6c757d;
            color: white;
            padding: 3px 8px;
            border-radius: 12px;
            font-size: 0.8rem;
        }
        
        .toggle-icon {
            font-size: 1.2rem;
            color: #6c757d;
            transition: transform 0.3s ease;
        }
        
        .issue-details {
            padding: 20px;
            border-top: 1px solid #e9ecef;
            animation: slideDown 0.3s ease;
        }
        
        @keyframes slideDown {
            from { opacity: 0; max-height: 0; }
            to { opacity: 1; max-height: 1000px; }
        }
        
        .issue-description {
            margin-bottom: 15px;
            line-height: 1.6;
        }
        
        .issue-metadata {
            margin-bottom: 15px;
        }
        
        .effort-badge {
            background: #17a2b8;
            color: white;
            padding: 5px 10px;
            border-radius: 15px;
            font-size: 0.9rem;
        }
        
        .links-section {
            margin-top: 15px;
            padding-top: 15px;
            border-top: 1px solid #e9ecef;
        }
        
        .info-link {
            display: inline-block;
            background: #007bff;
            color: white;
            text-decoration: none;
            padding: 8px 12px;
            border-radius: 5px;
            margin: 5px 5px 5px 0;
            font-size: 0.9rem;
            transition: all 0.3s ease;
        }
        
        .info-link:hover {
            background: #0056b3;
            text-decoration: none;
            color: white;
            transform: translateY(-2px);
            box-shadow: 0 3px 8px rgba(0,123,255,0.3);
        }
        
        .info-link i {
            margin-right: 5px;
        }
        
        .instances-section {
            margin-top: 15px;
        }
        
        .instances-header {
            cursor: pointer;
            padding: 8px 12px;
            background: #f8f9fa;
            border: 1px solid #dee2e6;
            border-radius: 5px;
            display: flex;
            justify-content: space-between;
            align-items: center;
            transition: all 0.3s ease;
            user-select: none;
        }
        
        .instances-header:hover {
            background: #e9ecef;
            border-color: #adb5bd;
        }
        
        .instances-toggle-icon {
            font-size: 1.2rem;
            color: #6c757d;
            transition: transform 0.3s ease;
        }
        
        .instances-content {
            border: 1px solid #dee2e6;
            border-top: none;
            border-radius: 0 0 5px 5px;
            padding: 10px;
            background: #fff;
            animation: slideDown 0.3s ease;
        }
        
        .instances-list {
            list-style: none;
            margin: 0;
            padding: 0;
        }
        
        .instances-list li {
            background: #f8f9fa;
            margin: 5px 0;
            padding: 8px 12px;
            border-radius: 5px;
            border-left: 3px solid #007bff;
        }
        
        .instances-list code {
            font-family: 'Courier New', monospace;
            font-size: 0.9rem;
        }
        
        .analysis-info {
            background: white;
            border-radius: 15px;
            padding: 20px;
            margin-bottom: 20px;
            box-shadow: 0 5px 15px rgba(0,0,0,0.1);
        }
        
        .analysis-info h3 {
            color: #2c3e50;
            margin-bottom: 15px;
        }
        
        .analysis-info p {
            color: #6c757d;
            margin: 5px 0;
        }
        
        .footer {
            text-align: center;
            color: white;
            margin-top: 40px;
            padding: 20px;
            opacity: 0.8;
        }
        
        @media (max-width: 768px) {
            .charts-section {
                grid-template-columns: 1fr;
            }
            
            .issue-header {
                flex-wrap: wrap;
                gap: 10px;
            }
            
            .header h1 {
                font-size: 2rem;
            }
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>☁️ Azure App Modernization Assessment</h1>
            <p class="subtitle">Comprehensive analysis report for cloud migration readiness</p>
        </div>
        
        <div class="analysis-info">
            <h3>ℹ️ Analysis Information</h3>
            <p><strong>Analysis Start:</strong> $analysisStart</p>
            <p><strong>Analysis End:</strong> $analysisEnd</p>
            <p><strong>Project Path:</strong> $($project.path)</p>
            <p><strong>Privacy Mode:</strong> $($data.privacyMode)</p>
        </div>
        
        <div class="summary-grid">
            <div class="summary-card projects">
                <h3>$($summary.projects)</h3>
                <p>Projects Analyzed</p>
            </div>
            <div class="summary-card issues">
                <h3>$($summary.issues)</h3>
                <p>Unique Issues</p>
            </div>
            <div class="summary-card incidents">
                <h3>$($summary.incidents)</h3>
                <p>Total Incidents</p>
            </div>
            <div class="summary-card effort">
                <h3>$($summary.effort)</h3>
                <p>Story Points</p>
            </div>
        </div>
        

        
        <div class="issues-section">
            <h2>📝 Detailed Issues Analysis</h2>
            $issueDetailsHtml
        </div>
        
        <div class="footer">
            <p>Report generated on $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') | Azure App Modernization Assessment Tool</p>
            <p style="font-size: 0.7rem; color: rgba(255,255,255,0.6); margin-top: 5px;">Author: Babu Thangaratinam (babu.thangaratinam@kyndryl.com)</p>
        </div>
    </div>
    
    <script>
        function toggleIssue(ruleId) {
            var details = document.getElementById('details-' + ruleId);
            var icon = document.getElementById('icon-' + ruleId);
            
            if (details.style.display === 'none') {
                details.style.display = 'block';
                icon.innerHTML = '▲';
                icon.style.transform = 'rotate(180deg)';
            } else {
                details.style.display = 'none';
                icon.innerHTML = '▼';
                icon.style.transform = 'rotate(0deg)';
            }
        }
        
        function toggleInstances(ruleId) {
            var instances = document.getElementById('instances-' + ruleId);
            var icon = document.getElementById('instances-icon-' + ruleId);
            
            if (instances.style.display === 'none') {
                instances.style.display = 'block';
                icon.innerHTML = '▲';
                icon.style.transform = 'rotate(180deg)';
            } else {
                instances.style.display = 'none';
                icon.innerHTML = '▼';
                icon.style.transform = 'rotate(0deg)';
            }
        }
        
        // Add smooth scrolling
        document.querySelectorAll('a[href^="#"]').forEach(anchor => {
            anchor.addEventListener('click', function (e) {
                e.preventDefault();
                document.querySelector(this.getAttribute('href')).scrollIntoView({
                    behavior: 'smooth'
                });
            });
        });
    </script>
</body>
</html>
"@

    # Write HTML file
    Write-Host "Generating HTML report: $OutputPath" -ForegroundColor Green
    $htmlContent | Out-File -FilePath $OutputPath -Encoding UTF8
    
    Write-Host "HTML report generated successfully!" -ForegroundColor Green
    Write-Host "Report saved to: $(Resolve-Path $OutputPath)" -ForegroundColor Yellow
    
    # Open the report in default browser (optional)
    $openReport = Read-Host "Would you like to open the report in your default browser? (Y/N)"
    if ($openReport -eq 'Y' -or $openReport -eq 'y') {
        Start-Process $OutputPath
    }
}
catch {
    Write-Error "Error generating HTML report: $($_.Exception.Message)"
    exit 1
}
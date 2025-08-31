# AppCat HTML Report Generator

This PowerShell script generates an attractive HTML report from Azure App Modernization Assessment (AppCat) results.json files.

## Features

- **Summary Dashboard**: Displays key metrics including projects analyzed, issues found, incidents, and effort estimation
- **Detailed Issue Analysis**: Expandable sections showing:
  - Issue descriptions from the rules database
  - Severity levels (Mandatory, Optional, Potential, Information)
  - Story points and effort estimation
  - **Collapsible affected file locations** - Click to expand/collapse the list of affected files
  - **Microsoft documentation links** - Direct links to relevant Microsoft Learn articles and documentation
- **Modern UI**: Responsive design with hover effects and smooth animations
- **Export Ready**: Self-contained HTML file with embedded CSS (no external JS or chart dependencies)

## Usage

### Basic Usage
```powershell
.\GenReport.ps1
```
This will look for `results.json` in the current directory and generate `AppCat_Report.html`.

### Advanced Usage
```powershell
.\GenReport.ps1 -JsonFilePath "path\to\your\results.json" -OutputPath "MyReport.html"
```

## Parameters

- **JsonFilePath** (optional): Path to the AppCat results.json file. Default: `results.json`
- **OutputPath** (optional): Path where the HTML report will be saved. Default: `AppCat_Report.html`

## Requirements

- PowerShell 5.1 or later
- Valid AppCat results.json file

## Output

The generated HTML report includes:

1. **Header Section**: Title and subtitle
2. **Analysis Information**: Start/end times, project path, privacy mode
3. **Summary Cards**: Key metrics in a grid layout
4. **Issues Section**: Detailed breakdown of all issues grouped by severity
5. **Footer**: Generation timestamp

## Issue Categorization

Issues are grouped by severity levels:
- 🔴 **Mandatory**: Must be addressed for cloud migration
- 🟠 **Optional**: Recommended improvements
- 🟡 **Potential**: May cause issues in cloud environment
- 🔵 **Information**: Informational items for consideration

## Example

```powershell
# Generate report from specific JSON file
.\GenReport.ps1 -JsonFilePath "C:\AppCat\WebApp_Results.json" -OutputPath "C:\Reports\WebApp_Assessment.html"
```

The script will automatically open the generated report in your default browser (with confirmation).

## Troubleshooting

- Ensure the JSON file is valid and follows AppCat format
- Check that you have write permissions to the output directory

## File Structure Expected

The script expects the following JSON structure:
- `stats.summary`: Project metrics
- `projects[].ruleInstances`: Individual rule violations
- `rules`: Rule definitions and descriptions

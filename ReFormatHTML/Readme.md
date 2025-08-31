
---

# PowerShell Script: Replace CDN Links with Local Paths

This script automatically replaces CDN links in your HTML file with local file paths and includes robust features for backup, validation, and optional dependency downloads.

---

## ✅ Features

* **Automatic Backup** – Creates a backup before making changes.
* **Safe Replacement** – Only replaces exact CDN URLs.
* **Validation** – Checks if replacements were successful.
* **Error Handling** – Restores from backup if something goes wrong.
* **Detailed Logging** – Shows exactly what was replaced.
* **Optional Downloads** – Can download all required CSS/JS files locally into `static/css/` and `static/js/` directories.
* **Automatic Folder Creation** – Creates the `static/css/` and `static/js/` directories if they don't exist.
* **Robust Download Logic** – Handles fallback, user-agent setup, download progress, and adds small delays to be respectful to servers.

---

## 🔧 How to Use

1. **Save the script** as `Replace-CDNLinks.ps1`.
2. **Run the script** in PowerShell:

   ```powershell
   .\Replace-CDNLinks.ps1 -HtmlFilePath "C:\path\to\your\index.html"
   ```
3. **Optional: Custom backup suffix**

   ```powershell
   .\Replace-CDNLinks.ps1 -HtmlFilePath "index.html" -BackupSuffix "_original"
   ```

---

## 🔍 What It Does

The script replaces the following exact CDN URLs with local paths:

| **CDN URL**                                                                | **Replaced With**              |
| -------------------------------------------------------------------------- | ------------------------------ |
| `https://stackpath.bootstrapcdn.com/bootstrap/4.5.2/css/bootstrap.min.css` | `static/css/bootstrap.min.css` |
| `https://ajax.googleapis.com/ajax/libs/jquery/3.6.4/jquery.min.js`         | `static/js/jquery.min.js`      |
| `https://stackpath.bootstrapcdn.com/bootstrap/4.5.2/js/bootstrap.min.js`   | `static/js/bootstrap.min.js`   |
| `https://cdnjs.cloudflare.com/ajax/libs/Chart.js/3.5.1/chart.min.js`       | `static/js/chart.min.js`       |

A backup file (e.g., `index_backup.html`) is automatically created so you can restore your original file anytime.

---

## ▶ Usage Examples

**1. Replace links only (no downloads):**

```powershell
.\Replace-CDNLinks.ps1 -HtmlFilePath "index.html"
```

**2. Replace links AND download dependencies:**

```powershell
.\Replace-CDNLinks.ps1 -HtmlFilePath "index.html" -DownloadDependencies
```

**3. With custom backup suffix and downloads:**

```powershell
.\Replace-CDNLinks.ps1 -HtmlFilePath "index.html" -BackupSuffix "_original" -DownloadDependencies
```

---

## ✅ What Happens with `-DownloadDependencies`

1. Creates folder structure (`static/css/` and `static/js/`).
2. Downloads all 4 required files (Bootstrap CSS/JS, jQuery, Chart.js).
3. Displays download progress, file sizes, and ensures all files are downloaded.
4. Verifies each download and reports success or failure.
5. Replaces the CDN URLs in the HTML file with local paths.
6. Provides next steps based on the success or failure of the downloads.

---

**The script now offers a complete solution**: run it with `-DownloadDependencies`, and it will handle the entire process from downloading dependencies to replacing the links with local file paths.

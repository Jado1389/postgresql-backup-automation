#requires -Version 5.1

<#
.SYNOPSIS
    Removes PostgreSQL backup files older than the configured retention period.

.DESCRIPTION
    Loads the backup configuration, identifies backup files older than
    RETENTION_DAYS, and removes them from the backup directory.

.NOTES
    Project: PostgreSQL Backup Automation
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# ------------------------------------------------------------
# Paths
# ------------------------------------------------------------

$ProjectRoot = Split-Path -Parent $PSScriptRoot
$ConfigFile = Join-Path $ProjectRoot "config\backup.conf"

Write-Host "PostgreSQL backup retention cleanup starting..."
Write-Host "Project root: $ProjectRoot"
Write-Host "Configuration file: $ConfigFile"

# ------------------------------------------------------------
# Load configuration
# ------------------------------------------------------------

if (-not (Test-Path $ConfigFile)) {

    Write-Error "Configuration file not found: $ConfigFile"
    exit 1
}

$config = @{}

Get-Content $ConfigFile | ForEach-Object {

    $line = $_.Trim()

    # Ignore comments and blank lines
    if ($line -and -not $line.StartsWith("#")) {

        $parts = $line -split "=", 2

        if ($parts.Count -eq 2) {

            $key = $parts[0].Trim()
            $value = $parts[1].Trim()

            $config[$key] = $value
        }
    }
}

Write-Host "Configuration loaded successfully."

# ------------------------------------------------------------
# Validate required settings
# ------------------------------------------------------------

$RequiredSettings = @(
    "BACKUP_ROOT",
    "RETENTION_DAYS"
)

foreach ($setting in $RequiredSettings) {

    if (-not $config.ContainsKey($setting)) {

        Write-Error "Missing configuration setting: $setting"
        exit 1
    }
}

# ------------------------------------------------------------
# Read configuration
# ------------------------------------------------------------

$BackupRoot = $config["BACKUP_ROOT"]
$RetentionDays = [int]$config["RETENTION_DAYS"]

Write-Host "Backup directory: $BackupRoot"
Write-Host "Retention period: $RetentionDays days"

# ------------------------------------------------------------
# Validate backup directory
# ------------------------------------------------------------

if (-not (Test-Path $BackupRoot)) {

    Write-Error "Backup directory does not exist: $BackupRoot"
    exit 1
}

# ------------------------------------------------------------
# Calculate retention cutoff
# ------------------------------------------------------------

$CutoffDate = (Get-Date).AddDays(-$RetentionDays)

Write-Host "Retention cutoff: $CutoffDate"

# ------------------------------------------------------------
# Find old backups
# ------------------------------------------------------------

$OldBackups = Get-ChildItem `
    -Path $BackupRoot `
    -Filter "*.sql" `
    -File |
    Where-Object {
        $_.LastWriteTime -lt $CutoffDate
    }

# ------------------------------------------------------------
# Cleanup
# ------------------------------------------------------------

if (-not $OldBackups) {

    Write-Host "No backup files require cleanup."
}
else {

    Write-Host "Backup files eligible for deletion: $($OldBackups.Count)"

    foreach ($Backup in $OldBackups) {

        Write-Host "Deleting: $($Backup.FullName)"

        Remove-Item `
            -Path $Backup.FullName `
            -Force
    }

    Write-Host "Old backup cleanup completed successfully."
}

# ------------------------------------------------------------
# Completion
# ------------------------------------------------------------

Write-Host "PostgreSQL backup retention cleanup completed."

exit 0
#requires -Version 5.1

<#
.SYNOPSIS
    Runs the complete PostgreSQL backup automation workflow.

.DESCRIPTION
    Executes the logical backup, automated restore validation,
    and backup retention cleanup in sequence.

.NOTES
    Project: PostgreSQL Backup Automation
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# ------------------------------------------------------------
# Paths
# ------------------------------------------------------------

$ProjectRoot = Split-Path -Parent $PSScriptRoot

$BackupScript = Join-Path `
    $ProjectRoot `
    "scripts\backup_logical.ps1"

$VerifyScript = Join-Path `
    $ProjectRoot `
    "scripts\verify_backup.ps1"

$CleanupScript = Join-Path `
    $ProjectRoot `
    "scripts\cleanup_old_backups.ps1"

# ------------------------------------------------------------
# Start
# ------------------------------------------------------------

Write-Host ""
Write-Host "=========================================="
Write-Host "PostgreSQL Backup Automation"
Write-Host "=========================================="
Write-Host "Start time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Write-Host ""

# ------------------------------------------------------------
# Validate scripts
# ------------------------------------------------------------

$RequiredScripts = @(
    $BackupScript,
    $VerifyScript,
    $CleanupScript
)

foreach ($Script in $RequiredScripts) {

    if (-not (Test-Path $Script)) {

        Write-Error "Required script not found: $Script"
        exit 1
    }
}

Write-Host "All required scripts found."
Write-Host ""

# ------------------------------------------------------------
# Step 1 - Create backup
# ------------------------------------------------------------

Write-Host "------------------------------------------"
Write-Host "STEP 1 - Creating PostgreSQL backup"
Write-Host "------------------------------------------"

& powershell.exe `
    -ExecutionPolicy Bypass `
    -File $BackupScript

if ($LASTEXITCODE -ne 0) {

    Write-Error "Backup creation failed. Automation stopped."
    exit 1
}

Write-Host ""
Write-Host "STEP 1 completed successfully."
Write-Host ""

# ------------------------------------------------------------
# Step 2 - Verify backup
# ------------------------------------------------------------

Write-Host "------------------------------------------"
Write-Host "STEP 2 - Restoring and validating backup"
Write-Host "------------------------------------------"

& powershell.exe `
    -ExecutionPolicy Bypass `
    -File $VerifyScript

if ($LASTEXITCODE -ne 0) {

    Write-Error "Backup verification failed. Automation stopped."
    exit 1
}

Write-Host ""
Write-Host "STEP 2 completed successfully."
Write-Host ""

# ------------------------------------------------------------
# Step 3 - Cleanup old backups
# ------------------------------------------------------------

Write-Host "------------------------------------------"
Write-Host "STEP 3 - Applying backup retention"
Write-Host "------------------------------------------"

& powershell.exe `
    -ExecutionPolicy Bypass `
    -File $CleanupScript

if ($LASTEXITCODE -ne 0) {

    Write-Error "Backup retention cleanup failed."
    exit 1
}

Write-Host ""
Write-Host "STEP 3 completed successfully."
Write-Host ""

# ------------------------------------------------------------
# Completion
# ------------------------------------------------------------

Write-Host "=========================================="
Write-Host "BACKUP AUTOMATION SUCCESSFUL"
Write-Host "=========================================="
Write-Host "End time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Write-Host ""

exit 0
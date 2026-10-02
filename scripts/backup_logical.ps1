#requires -Version 5.1

<#
.SYNOPSIS
    Creates a logical PostgreSQL backup using pg_dump.

.DESCRIPTION
    Loads backup configuration, validates the PostgreSQL environment,
    creates a timestamped SQL backup, verifies the backup file,
    and records the result in a log file.

.NOTES
    Project: PostgreSQL Backup Automation
    Database: backup_lab
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# ------------------------------------------------------------
# Paths
# ------------------------------------------------------------

$ProjectRoot = Split-Path -Parent $PSScriptRoot
$ConfigFile = Join-Path $ProjectRoot "config\backup.conf"
$LogRoot = Join-Path $ProjectRoot "logs"

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

# ------------------------------------------------------------
# Required configuration
# ------------------------------------------------------------

$RequiredSettings = @(
    "PGHOST",
    "PGPORT",
    "PGUSER",
    "PGDATABASE",
    "PGBIN",
    "BACKUP_ROOT",
    "LOG_ROOT"
)

foreach ($setting in $RequiredSettings) {

    if (-not $config.ContainsKey($setting)) {
        Write-Error "Missing configuration setting: $setting"
        exit 1
    }
}

$PGHost = $config["PGHOST"]
$PGPort = $config["PGPORT"]
$PGUser = $config["PGUSER"]
$PGDatabase = $config["PGDATABASE"]
$PGBin = $config["PGBIN"]
$BackupRoot = $config["BACKUP_ROOT"]
$LogRoot = $config["LOG_ROOT"]

# ------------------------------------------------------------
# Create directories if they don't exist
# ------------------------------------------------------------

New-Item -ItemType Directory -Path $BackupRoot -Force | Out-Null
New-Item -ItemType Directory -Path $LogRoot -Force | Out-Null

# ------------------------------------------------------------
# Logging
# ------------------------------------------------------------

$Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"

$LogFile = Join-Path `
    $LogRoot `
    "backup_$($Timestamp).log"

function Write-Log {
    param (
        [string]$Message
    )

    $LogTimestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

    $LogMessage = "[$LogTimestamp] $Message"

    Write-Host $LogMessage

    Add-Content `
        -Path $LogFile `
        -Value $LogMessage
}

Write-Log "=========================================="
Write-Log "PostgreSQL logical backup started"
Write-Log "Database: $PGDatabase"
Write-Log "Host: $PGHost"
Write-Log "Port: $PGPort"
Write-Log "User: $PGUser"

# ------------------------------------------------------------
# Validate pg_dump
# ------------------------------------------------------------

$PgDump = Join-Path $PGBin "pg_dump.exe"

if (-not (Test-Path $PgDump)) {

    Write-Log "ERROR: pg_dump.exe not found at $PgDump"

    exit 1
}

Write-Log "pg_dump found: $PgDump"

# ------------------------------------------------------------
# Validate PostgreSQL connection
# ------------------------------------------------------------

$Psql = Join-Path $PGBin "psql.exe"

if (-not (Test-Path $Psql)) {

    Write-Log "ERROR: psql.exe not found at $Psql"

    exit 1
}

Write-Log "Testing PostgreSQL connection..."

$ConnectionTest = & $Psql `
    -h $PGHost `
    -p $PGPort `
    -U $PGUser `
    -d $PGDatabase `
    -c "SELECT 1;" 2>&1

if ($LASTEXITCODE -ne 0) {

    Write-Log "ERROR: PostgreSQL connection test failed."
    Write-Log "$ConnectionTest"

    exit 1
}

Write-Log "PostgreSQL connection successful."

# ------------------------------------------------------------
# Backup filename
# ------------------------------------------------------------

$BackupFile = Join-Path `
    $BackupRoot `
    "$($PGDatabase)_$($Timestamp).sql"

Write-Log "Backup file: $BackupFile"

# ------------------------------------------------------------
# Run pg_dump
# ------------------------------------------------------------

Write-Log "Starting pg_dump..."

& $PgDump `
    -h $PGHost `
    -p $PGPort `
    -U $PGUser `
    -d $PGDatabase `
    -F p `
    -f $BackupFile

if ($LASTEXITCODE -ne 0) {

    Write-Log "ERROR: pg_dump failed."

    if (Test-Path $BackupFile) {
        Remove-Item $BackupFile -Force
    }

    exit 1
}

Write-Log "pg_dump completed successfully."

# ------------------------------------------------------------
# Verify backup
# ------------------------------------------------------------

if (-not (Test-Path $BackupFile)) {

    Write-Log "ERROR: Backup file was not created."

    exit 1
}

$BackupSize = (Get-Item $BackupFile).Length

if ($BackupSize -le 0) {

    Write-Log "ERROR: Backup file is empty."

    Remove-Item $BackupFile -Force

    exit 1
}

Write-Log "Backup verification successful."
Write-Log "Backup size: $BackupSize bytes"

# ------------------------------------------------------------
# Completion
# ------------------------------------------------------------

Write-Log "PostgreSQL logical backup completed successfully."
Write-Log "=========================================="

exit 0
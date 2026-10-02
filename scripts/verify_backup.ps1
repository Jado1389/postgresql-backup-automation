#requires -Version 5.1

<#
.SYNOPSIS
    Restores the latest PostgreSQL backup and validates the restored database.

.DESCRIPTION
    Finds the latest logical backup, prepares a clean restore database,
    restores the backup, validates expected tables and row counts,
    and reports success or failure.

.NOTES
    Project: PostgreSQL Backup Automation
    Source Database: backup_lab
    Restore Database: backup_restore_test
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# ------------------------------------------------------------
# Paths
# ------------------------------------------------------------

$ProjectRoot = Split-Path -Parent $PSScriptRoot
$ConfigFile = Join-Path $ProjectRoot "config\backup.conf"

Write-Host "PostgreSQL backup verification starting..."
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
# Validate required configuration
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

Write-Host "Required configuration settings validated successfully."

# ------------------------------------------------------------
# Read configuration
# ------------------------------------------------------------

$PGHost = $config["PGHOST"]
$PGPort = $config["PGPORT"]
$PGUser = $config["PGUSER"]
$PGDatabase = $config["PGDATABASE"]
$PGBin = $config["PGBIN"]
$BackupRoot = $config["BACKUP_ROOT"]

Write-Host "PostgreSQL host: $PGHost"
Write-Host "PostgreSQL port: $PGPort"
Write-Host "Source database: $PGDatabase"
Write-Host "Backup directory: $BackupRoot"

# ------------------------------------------------------------
# PostgreSQL tools
# ------------------------------------------------------------

$Psql = Join-Path $PGBin "psql.exe"

if (-not (Test-Path $Psql)) {

    Write-Error "psql.exe not found at: $Psql"
    exit 1
}

Write-Host "psql found: $Psql"

# ------------------------------------------------------------
# Find latest backup
# ------------------------------------------------------------

$LatestBackup = Get-ChildItem `
    -Path $BackupRoot `
    -Filter "*.sql" `
    -File |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 1

if (-not $LatestBackup) {

    Write-Error "No SQL backup files found in: $BackupRoot"
    exit 1
}

$BackupFile = $LatestBackup.FullName

Write-Host "Latest backup found:"
Write-Host "Backup file: $BackupFile"
Write-Host "Backup size: $($LatestBackup.Length) bytes"
Write-Host "Backup timestamp: $($LatestBackup.LastWriteTime)"

# ------------------------------------------------------------
# Restore database
# ------------------------------------------------------------

$RestoreDatabase = "backup_restore_test"

Write-Host "Restore database: $RestoreDatabase"

# ------------------------------------------------------------
# Prepare clean restore database
# ------------------------------------------------------------

Write-Host "Preparing restore database..."

$TerminateConnectionsSql = @"
SELECT pg_terminate_backend(pid)
FROM pg_stat_activity
WHERE datname = '$RestoreDatabase'
  AND pid <> pg_backend_pid();
"@

& $Psql `
    -h $PGHost `
    -p $PGPort `
    -U $PGUser `
    -d "postgres" `
    -c $TerminateConnectionsSql

if ($LASTEXITCODE -ne 0) {

    Write-Error "Failed to terminate connections to $RestoreDatabase"
    exit 1
}

& $Psql `
    -h $PGHost `
    -p $PGPort `
    -U $PGUser `
    -d "postgres" `
    -c "DROP DATABASE IF EXISTS `"$RestoreDatabase`";"

if ($LASTEXITCODE -ne 0) {

    Write-Error "Failed to drop restore database: $RestoreDatabase"
    exit 1
}

& $Psql `
    -h $PGHost `
    -p $PGPort `
    -U $PGUser `
    -d "postgres" `
    -c "CREATE DATABASE `"$RestoreDatabase`";"

if ($LASTEXITCODE -ne 0) {

    Write-Error "Failed to create restore database: $RestoreDatabase"
    exit 1
}

Write-Host "Restore database prepared successfully."

# ------------------------------------------------------------
# Restore backup
# ------------------------------------------------------------

Write-Host "Starting backup restore..."

& $Psql `
    -h $PGHost `
    -p $PGPort `
    -U $PGUser `
    -d $RestoreDatabase `
    -v ON_ERROR_STOP=1 `
    -f $BackupFile

if ($LASTEXITCODE -ne 0) {

    Write-Error "Backup restore failed."
    exit 1
}

Write-Host "Backup restored successfully."

# ------------------------------------------------------------
# Validate restored tables
# ------------------------------------------------------------

Write-Host "Validating restored database..."

$ExpectedTables = @(
    "customers",
    "accounts",
    "transactions"
)

foreach ($Table in $ExpectedTables) {

    $TableCheck = & $Psql `
        -h $PGHost `
        -p $PGPort `
        -U $PGUser `
        -d $RestoreDatabase `
        -t `
        -A `
        -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public' AND table_name = '$Table';"

    if ($LASTEXITCODE -ne 0) {

        Write-Error "Failed to validate table: $Table"
        exit 1
    }

    $TableExists = $TableCheck.Trim()

    if ($TableExists -ne "1") {

        Write-Error "Validation failed: table '$Table' does not exist."
        exit 1
    }

    Write-Host "Table validated: $Table"
}

# ------------------------------------------------------------
# Validate row counts
# ------------------------------------------------------------

$CustomersCount = & $Psql `
    -h $PGHost `
    -p $PGPort `
    -U $PGUser `
    -d $RestoreDatabase `
    -t `
    -A `
    -c "SELECT COUNT(*) FROM customers;"

if ($LASTEXITCODE -ne 0) {
    Write-Error "Failed to validate customers."
    exit 1
}

$AccountsCount = & $Psql `
    -h $PGHost `
    -p $PGPort `
    -U $PGUser `
    -d $RestoreDatabase `
    -t `
    -A `
    -c "SELECT COUNT(*) FROM accounts;"

if ($LASTEXITCODE -ne 0) {
    Write-Error "Failed to validate accounts."
    exit 1
}

$TransactionsCount = & $Psql `
    -h $PGHost `
    -p $PGPort `
    -U $PGUser `
    -d $RestoreDatabase `
    -t `
    -A `
    -c "SELECT COUNT(*) FROM transactions;"

if ($LASTEXITCODE -ne 0) {
    Write-Error "Failed to validate transactions."
    exit 1
}

Write-Host "customers: $($CustomersCount.Trim()) rows"
Write-Host "accounts: $($AccountsCount.Trim()) rows"
Write-Host "transactions: $($TransactionsCount.Trim()) rows"

# ------------------------------------------------------------
# Final validation
# ------------------------------------------------------------

if ($CustomersCount.Trim() -ne "5") {

    Write-Error "Validation failed: expected 5 customers."
    exit 1
}

if ($AccountsCount.Trim() -ne "5") {

    Write-Error "Validation failed: expected 5 accounts."
    exit 1
}

if ($TransactionsCount.Trim() -ne "7") {

    Write-Error "Validation failed: expected 7 transactions."
    exit 1
}

Write-Host ""
Write-Host "=========================================="
Write-Host "BACKUP VERIFICATION SUCCESSFUL"
Write-Host "=========================================="

exit 0
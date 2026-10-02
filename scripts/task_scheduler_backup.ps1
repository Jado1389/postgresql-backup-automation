#requires -Version 5.1

$ProjectRoot = Split-Path -Parent $PSScriptRoot

$MasterScript = Join-Path `
    $ProjectRoot `
    "scripts\run_backup_automation.ps1"

$LogDirectory = Join-Path `
    $ProjectRoot `
    "logs\task_scheduler"

$OutputLog = Join-Path `
    $LogDirectory `
    "scheduled_backup.log"

New-Item `
    -ItemType Directory `
    -Path $LogDirectory `
    -Force |
    Out-Null

"==========================================" | Out-File $OutputLog -Append
"Scheduled PostgreSQL backup started: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" | Out-File $OutputLog -Append

try {

    & powershell.exe `
        -NoProfile `
        -ExecutionPolicy Bypass `
        -File $MasterScript 2>&1 |
        Tee-Object -FilePath $OutputLog -Append

    $ExitCode = $LASTEXITCODE

    "Scheduled PostgreSQL backup finished: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" | Out-File $OutputLog -Append
    "Exit code: $ExitCode" | Out-File $OutputLog -Append

    exit $ExitCode
}
catch {

    "ERROR: $($_.Exception.Message)" | Out-File $OutputLog -Append

    exit 1
}
# PostgreSQL Backup Automation

A hands-on PostgreSQL database backup and restore automation project designed to demonstrate practical PostgreSQL DBA skills, including logical backups, backup validation, retention management, logging, and restore testing.

## Project Overview

This project automates and validates PostgreSQL database backups using PostgreSQL native utilities and PowerShell on Windows.

The objective is to build a repeatable backup workflow that can:

* Create PostgreSQL logical backups using `pg_dump`
* Apply compression to backup files
* Validate backup configuration and backup files
* Maintain backup logs for operational tracking
* Apply configurable backup retention
* Restore backups into a separate test database
* Verify that restored data is accessible and consistent
* Provide a foundation for scheduled backup automation and monitoring

## Technologies

* PostgreSQL 18
* PowerShell 5.1+
* `pg_dump`
* `pg_restore`
* `pg_basebackup`
* `psql`
* Windows
* Git / GitHub

## Project Structure

```text
postgresql-backup-automation/
│
├── config/
│   └── backup.conf
│
├── scripts/
│   ├── backup_logical.ps1
│   └── verify_backup.ps1
│
├── restore/
│
├── monitoring/
│
├── sql/
│
├── docker/
│
├── tests/
│
├── backups/
│
├── logs/
│
└── docs/
```

## Configuration

The backup configuration is maintained separately from the PowerShell scripts.

Example configuration:

```text
PGHOST=localhost
PGPORT=5432
PGUSER=postgres
PGDATABASE=backup_lab

PGBIN=C:\Program Files\PostgreSQL\18\bin

BACKUP_ROOT=backups
LOG_ROOT=logs

RETENTION_DAYS=7
COMPRESSION_LEVEL=6
```

Sensitive credentials should never be stored directly in the configuration file. PostgreSQL authentication can be handled using a secure `.pgpass` configuration.

## Logical Backup

The project uses PostgreSQL's native `pg_dump` utility to create logical database backups.

Example:

```powershell
pg_dump -h localhost -p 5432 -U postgres `
  -d backup_lab `
  -F p `
  -Z 6 `
  -f backup.sql
```

The PowerShell automation records the start time, completion status, backup location, and backup size in the project logs.

## Backup Validation

The validation process checks the latest generated backup and verifies information such as:

* Backup file existence
* File size
* Backup timestamp
* Configured database
* Backup directory
* Required PostgreSQL utilities
* Backup execution status

This helps detect failed or incomplete backup jobs before relying on the backup for recovery.

## Restore Testing

Backups are restored into a separate test database rather than overwriting the source database.

Example validation environment:

```text
Source Database:
backup_lab

Restore/Test Database:
backup_restore_test
```

The restored database can then be queried to verify that expected tables and records are available.

Example tables:

```text
customers
accounts
transactions
```

## Recovery Testing

A backup is only useful if it can be restored successfully.

The project therefore includes restore testing as part of the backup workflow. The goal is to demonstrate that a generated backup can be used to recreate database objects and data in a separate PostgreSQL database.

## Operational Logging

Backup operations are logged to support troubleshooting and operational review.

Example events include:

```text
Backup started
Backup completed
Backup file created
Backup validation started
Backup validation completed
Restore started
Restore completed
```

## Retention

Backup retention is configurable through:

```text
RETENTION_DAYS=7
```

This provides a foundation for automatically removing backup files older than the configured retention period.

## Future Enhancements

Planned improvements include:

* Automated backup retention cleanup
* Automated restore verification
* Backup integrity checks
* Scheduled execution
* Monitoring and alerting
* PostgreSQL physical backup using `pg_basebackup`
* GitHub Actions for automated testing
* Docker-based PostgreSQL test environment
* Recovery documentation and disaster-recovery runbook

## Skills Demonstrated

This project demonstrates practical experience with:

* PostgreSQL administration
* Backup and recovery
* `pg_dump` / `pg_restore`
* `pg_basebackup`
* PowerShell automation
* Database restore testing
* Backup validation
* Retention management
* Operational logging
* Git and GitHub
* Database recovery procedures
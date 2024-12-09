$backupPath = "backup"
$changePath = "change"

$backup_server = "localhost"
$backup_database = "Northwind"
$backup_username = "sa"
$backup_password = ""

$backup_server = "localhost"
$backup_database = "Northwind"
$backup_username = "sa"
$backup_password = ""

if (-not Test-Path -LiteralPath $backupPath)
{
    New-Item -Path $backupPath -ItemType "Directory" -ErrorAction Stop
}
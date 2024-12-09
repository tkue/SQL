
/*==========  GET RESTORE DATES  ==========*/

USE master
GO

/* SCRIPT 1 */

SELECT
	RowNum = ROW_NUMBER() OVER (PARTITION BY rsh.destination_database_name ORDER BY rsh.restore_date DESC)
	,rsh.destination_database_name
	,rsh.restore_date
	,rsh.[user_name]
	,bs.database_name [Source_DB_Name]
	,bmf.physical_device_name
FROM msdb.dbo.restorehistory rsh
JOIN msdb.dbo.backupset bs ON rsh.backup_set_id = bs.backup_set_id
JOIN msdb.dbo.restorefile rf ON rsh.restore_history_id = rf.restore_history_id
JOIN msdb.dbo.backupmediafamily bmf ON bs.media_set_id = bmf.media_set_id
WHERE
	rsh.restore_type = 'D'
	AND destination_database_name IN
						(
							'db_name'
						)
ORDER BY
	rsh.restore_date DESC


/* SCRIPT 2 */

;WITH LastRestores AS
(
SELECT
    DatabaseName = [d].[name] ,
    [d].[create_date] ,
    [d].[compatibility_level] ,
    [d].[collation_name] ,
    r.*,
    RowNum = ROW_NUMBER() OVER (PARTITION BY d.Name ORDER BY r.[restore_date] DESC)
FROM master.sys.databases d
LEFT OUTER JOIN msdb.dbo.[restorehistory] r ON r.[destination_database_name] = d.Name
)
SELECT *
FROM [LastRestores]
WHERE [RowNum] = 1
	 AND DatabaseName IN
				(
					'db_name'
				)

ORDER BY restore_date ASC


/* DB SIZES */

;WITH cte_db_sizes AS
(

SELECT
    DB_NAME( dbid ) AS DatabaseName,
    CAST( ( SUM( size ) * 8 ) / ( 1024.0 * 1024.0 ) AS decimal( 10, 2 ) ) AS DbSizeGb
FROM
    sys.sysaltfiles
GROUP BY
    DB_NAME( dbid )
)

SELECT *
FROM cte_db_sizes
WHERE DatabaseName IN
				(
					'db_name'
				)
ORDER BY DbSizeGb
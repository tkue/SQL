/*
	Source:
	edx - Microsoft: DAT217x Implementing ETL with SQL Server Integration Services
	Module 2 | ETL With SQL Programming > Transformations > Setup and Renaming Columns for Legibility
*/

USE master
GO

IF NOT EXISTS ( 
	SELECT * FROM sys.procedures WHERE name = 'sp_GetMetaDataByTable' AND type = 'P'
)
BEGIN
	EXEC ( 'CREATE PROCEDURE sp_GetMetaDataByTable AS SELECT ''1'' ' )
END
GO

ALTER PROCEDURE [sp_GetMetaDataByTable] ( @TableName nvarchar(200) )
AS
 BEGIN -- procedure code
	SELECT
	  [ColumnFullName] = C.TABLE_SCHEMA  + '.' +  C.TABLE_NAME  + '.' + COLUMN_NAME
	, DataType = Case 
	  When DATA_TYPE in ( 'Money', 'Decimal') 
		Then IsNull(DATA_TYPE,'') 
		+ ' (' +  Cast(NUMERIC_PRECISION as nvarchar(50)) 
		+  ',' +  Cast(NUMERIC_SCALE as nvarchar(50)) 
		+ ' )'
	  When DATA_TYPE in ('bit', 'int', 'tinyint','bigint', 'datetime', 'uniqueidentifier') 
		Then IsNull(DATA_TYPE,'') 
	  Else  IsNull(DATA_TYPE,'') + ' (' +  Cast(IsNull(CHARACTER_MAXIMUM_LENGTH,'') as nvarchar(50)) + ')'
	  End
	, IsNullable = IsNull(IS_NULLABLE,'')
	--, ORDINAL_POSITION
	--, COLUMN_DEFAULT = IsNull(COLUMN_DEFAULT,'')
	FROM [INFORMATION_SCHEMA].[COLUMNS] as C
	JOIN [INFORMATION_SCHEMA].[TABLES] as T
	  ON C.TABLE_NAME = T.TABLE_NAME
	WHERE C.TABLE_NAME in (@TableName)
	Order by C.TABLE_SCHEMA, C.TABLE_NAME, C.ORDINAL_POSITION
 END
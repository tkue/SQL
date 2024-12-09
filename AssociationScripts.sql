USE cwwebapp_beta
GO



IF OBJECT_ID('tempdb..#usp_GetAssociations_AllTables') IS NOT NULL
	DROP PROCEDURE #usp_GetAssociations_AllTables;
GO

IF OBJECT_ID('tempdb..#usp_GetAssociations_SelectTables') IS NOT NULL
	DROP PROCEDURE #usp_GetAssociations_SelectTables;
GO

IF OBJECT_ID('tempdb..#usp_GetAssociations_TableColumnSpecificValue') IS NOT NULL
	DROP PROCEDURE #usp_GetAssociations_TableColumnSpecificValue;
GO

IF OBJECT_ID('tempdb..#usp_GetAssociations_CountAssociations') IS NOT NULL
	DROP PROCEDURE #usp_GetAssociations_CountAssociations;;
GO


-- GET ALL TABLES 
/*
    Get all tables that might remotely match target column
        > (Usually) Want to remove included tables from this match later 
        
        e.g. %contact%id%
*/
CREATE PROCEDURE #usp_GetAssociations_AllTables (
	@columnNameToMatch nvarchar(128)
)
AS

-- GET TABLES AND COLUMNS ATTACHED TO @columnNameToMatch
IF OBJECT_ID('tempdb..#Table_Col') IS NOT NULL
	DROP TABLE #Table_Col;

SELECT *
FROM
(
	SELECT c.name AS Column_Name, t.name AS Table_Name
	FROM sys.columns c
		JOIN sys.tables t ON c.object_id = t.object_id
	WHERE c.name LIKE '%' + @columnNameToMatch + '%'

	UNION

	SELECT 
		 CFU.Column_Name AS Column_Name
		,TC2.TABLE_NAME AS Table_Name
	FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS TC
	INNER JOIN INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE CU ON TC.TABLE_NAME = CU.TABLE_NAME
		AND TC.TABLE_SCHEMA = CU.TABLE_SCHEMA
		AND Tc.CONSTRAINT_NAME = CU.CONSTRAINT_NAME
	LEFT JOIN INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS RC1 ON TC.CONSTRAINT_NAME = RC1.UNIQUE_CONSTRAINT_NAME
	LEFT JOIN INFORMATION_SCHEMA.TABLE_CONSTRAINTS TC2 ON TC2.CONSTRAINT_NAME = RC1.CONSTRAINT_NAME
	LEFT JOIN INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE CFU ON RC1.CONSTRAINT_NAME = CFU.CONSTRAINT_NAME
	WHERE TC.CONSTRAINT_TYPE = 'PRIMARY KEY'
		AND TC.TABLE_NAME = 'Contact'
) v
GO

-- GET SELECTED TABLES 
/*
    Gets the final matches for tables to update 
    Includes the tables to exclude 
*/
CREATE PROCEDURE #usp_GetAssociations_SelectTables (
	@columnNameToMatch nvarchar(128)
	,@exclusionQuery nvarchar(4000)		-- Ex)	'Table_Name_1', 'Table_Name_2', 'Table_Name_3'
										--		Used in WHERE NOT IN ('Table_Name_1', 'Table_Name_2', 'Table_Name_3')
                                        ----      'WHERE ColumnName IN  (' + @exclusionQuery + ')'
	,@isVerbose bit = 1
)
AS

DECLARE 
	@sql nvarchar(max)

IF OBJECT_ID('tempdb..#TablesColumns') IS NOT NULL
	DROP TABLE #TablesColumns;

CREATE TABLE #TablesColumns (
	 TableName nvarchar(128)
	,ColumnName nvarchar(128) 
)


-- Get all tables 
/*

*/
SET @sql =
	'INSERT INTO #TablesColumns ' +
	'EXEC #usp_GetAssociations_AllTables ' + @columnNameToMatch;

IF @isVerbose = 1
	PRINT CHAR(10) + @sql

EXEC(@sql)


-- Delete select tables to exclude 
IF EXISTS (
	SELECT * FROM #TablesColumns
)
BEGIN
	
	IF ISNULL(@exclusionQuery, '') <> ''
	BEGIN 

		SET @sql = 
			'DELETE FROM #TablesColumns ' + 
			'WHERE ColumnName IN  (' + @exclusionQuery + ')'

		IF @isVerbose = 1
			PRINT CHAR(10) + @sql
		
		EXEC (@sql)
	END
	ELSE 
	BEGIN 
		PRINT CHAR(10) + 'No excluded tables' + CHAR(10);
	END
	

	SELECT * FROM #TablesColumns;
END
ELSE
BEGIN
	PRINT CHAR(10) +  N'No tables for associations found in #TablesColumns'
	RETURN 1;
END

RETURN 0;
GO 


-- GET ALL TABLES WITH SPECIFIED NAME AND VALUE 
CREATE PROCEDURE #usp_GetAssociations_TableColumnSpecificValue (
	 @column1 nvarchar(128)
	,@column2 nvarchar(128)
	,@value nvarchar(128)
    ,@tablesToSelectFrom TABLE 
	,@isVerbose bit = 1
)	
AS

declare @SQL nvarchar(max)
	,@count int 

select @SQL = 
(
  select 'union all '+
         'select top(1) '''+t.name+''' as TableName '+
         'from '+quotename(t.name)+' '+
         'where ' + QUOTENAME(@column2) + '=' + QUOTENAME(@value) + ' '
  from sys.columns c
    inner join sys.tables t
      on c.object_id = t.object_id
  where c.name = @column1
  for xml path(''), type
).value('substring(./text()[1], 11)', 'nvarchar(max)')


IF @isVerbose = 1
	PRINT @SQL;

--SET @SQL = 
--	'DECLARE @result TABLE (Count int)  ' + 
--	'INSERT INTO @result ' 

IF OBJECT_ID('tempdb..#TableResults') IS NOT NULL 
    DROP TABLE #TableResults;
GO 

CREATE TABLE #TableResults (
     Table_Name nvarchar(128)
    ,Column_Name nvarchar(128)    
)

EXEC @SQL INTO #TableResults;

IF EXISTS ( SELECT * FROM @tablesToSelectFrom )
BEGIN 
    DELETE FROM tr 
    FROM #TableResults tr 
    LEFT JOIN @tablesToSelectFrom f ON tr.Table_Name = f.Table_Name 
                                        AND tr.Column_Name = f.Column_Name 
    WHERE 
        Table_Name IS NULL 
        AND Column_Name IS NULL 
END

GO


-- GET COUNT OF NUMBER OF ASSOCATIONS 
CREATE PROCEDURE #usp_GetAssociations_CountAssociations (
	
)	
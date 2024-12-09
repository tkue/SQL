USE Util
GO

--CREATE OR ALTER PROCEDURE dbo.ExecuteSql (
DECLARE
	@sql varchar(max)
	,@nsql nvarchar(max)
	,@isUseTransaction bit = 0
	,@isLogOnlyExceptions bit = 0
	,@loggingId int
--)
--AS
--SET FMTONLY ON

SET 
	@sql = 'DELETE FROM [Test_1].[dbo].[Employees]

INSERT INTO [Test_1].[dbo].[Employees] (
      [LastName]
      ,[FirstName]
      ,[Title]
      ,[TitleOfCourtesy]
      ,[BirthDate]
      ,[HireDate]
      ,[Address]
      ,[City]
      ,[Region]
      ,[PostalCode]
      ,[Country]
      ,[HomePhone]
      ,[Extension]
      ,[Photo]
      ,[Notes]
      ,[ReportsTo]
      ,[PhotoPath]
	)
'

SET @sql = 'SELECT * FROM sys.columns'

SELECT 
	@sql = NULLIF(TRIM(@sql), '')
	,@nsql = NULLIF(TRIM(@nsql), '')



DECLARE 
	@start datetime
	,@end datetime
	,@rowCount int


IF @sql IS NULL AND @nsql IS NULL 
BEGIN 
	RAISERROR(N'Both SQL params are NULL', 16, 1)
	SELECT -1 AS "1"
END

IF @sql IS NOT NULL AND @nsql IS NOT NULL 
BEGIN 
	RAISERROR(N'Both SQL params are NOT NULL - they must be mutually exclusive', 16, 1)
	SELECT -2 "2"
END

-- EXEC - No transaction 
IF @isUseTransaction = 0
BEGIN
	SET @start = GETUTCDATE()
	
	BEGIN TRY
		--IF @isLogOnlyExceptions = 0
		--BEGIN
		--	INSERT INTO Logging.Logging ( 
		--		SqlStatement
		--		,ExecutionStartUTC	
		--	)
		--	SELECT 
		--		SqlStmt = CONCAT('<?query -- ', CHAR(10),  @sql, CHAR(10), '--?>')
		--		,@start

		--	SET @loggingId = @@IDENTITY
		--END

		-- Exec
		IF @sql IS NOT NULL
			EXEC(@sql)

		-- sp_executesql
		IF @nsql IS NOT NULL
		BEGIN
			EXEC sp_executesql @nsql
			SELECT @rowCount = @@ROWCOUNT
		END
			
		
		SET @rowCount = @@ROWCOUNT
		SET @end = GETUTCDATE()


		-- Log execution end
		--IF @isLogOnlyExceptions	 = 0
		--BEGIN
		--	UPDATE l
		--	SET 
		--		l.ExecutionEndUTC = GETUTCDATE()
		--	FROM Logging.Logging l
		--	WHERE
		--		l.LoggingId = @loggingId
		--END
	END TRY 
	BEGIN CATCH 
		EXEC Logging.uspLogError @loggingId

		UPDATE Logging.Logging
		SET 
			ExecutionStartUTC = @start
			,ExecutionEndUTC = GETUTCDATE()
		WHERE
			LoggingId = @loggingId

		SELECT 1
	END CATCH
END 

-- Log query
IF @isLogOnlyExceptions = 0
BEGIN
	INSERT INTO Logging.Logging ( 
		SqlStatement
		,ExecutionStartUTC	
		,ExecutionEndUTC
		,SqlRowCount
	)
	SELECT 
		SqlStmt = CONCAT(	'<?query -- '
							,CHAR(10)
							,ISNULL(@sql, @nsql)
							,CHAR(10)
							,'--?>')
		,@start
		,@end
		,@rowCount


	SET @loggingId = @@IDENTITY
END

SELECT 0
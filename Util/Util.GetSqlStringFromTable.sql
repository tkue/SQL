CREATE OR ALTER PROCEDURE Util.GetSqlStringFromTable (
	@stringTable dbo.StringTable READONLY
	,@valOut nvarchar(max) OUTPUT
	,@separateStringsWithChar varchar(20) = ' '
)
AS
SET NOCOUNT ON

DECLARE 
	@sql nvarchar(max)
	,@line nvarchar(max)
	,@objectName nvarchar(128)
	,@objectText nvarchar(max)
	,@id int

DECLARE @varname NVARCHAR(MAX)

DECLARE cur CURSOR LOCAL STATIC FORWARD_ONLY
FOR
    SELECT 
		Val
	FROM @stringTable	

OPEN cur

FETCH NEXT
FROM cur
INTO
    @line

WHILE @@FETCH_STATUS = 0
BEGIN
	SET @valOut = CONCAT(@valOut, @line, @separateStringsWithChar)


    nextrow:
    FETCH NEXT
    FROM cur
    INTO
        @line

END
CLOSE cur
DEALLOCATE cur

--SELECT @valOut

GO



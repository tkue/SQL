DECLARE @varname NVARCHAR(MAX)

DECLARE cur CURSOR LOCAL STATIC FORWARD_ONLY
FOR
    SELECT var
    FROM dbo.TableName
    INTO
        @varname

OPEN cur

FETCH NEXT
FROM cur
INTO
    @varname

WHILE @@FETCH_STATUS = 0
BEGIN


    nextrow:
    FETCH NEXT
    FROM cur
    INTO
        @varname

END
CLOSE cur
DEALLOCATE cur
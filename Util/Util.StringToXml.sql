USE Util
GO

CREATE OR ALTER FUNCTION Util.StringToXml (
	@str varchar(max)
	,@nstr nvarchar(max)
)
RETURNS xml
AS
BEGIN
	RETURN CONCAT(	'<?query -- '
						,CHAR(10)
						,ISNULL(@str, @nstr)
						,CHAR(10)
						,'--?>')
END
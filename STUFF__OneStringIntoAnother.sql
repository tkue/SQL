-- Source
-- http://www.sql-server-helper.com/tips/tip-of-the-day.aspx?tkey=3934817c-1a03-4ac9-a0ba-55b2bfbaea0f&tkw=uses-of-the-stuff-string-function

--  Insert One String Into Another String at a Specific Location
DECLARE @FullName       VARCHAR(100)
DECLARE @Alias          VARCHAR(20)

SET @FullName = 'Clark Kent'
SET @Alias = ' "Superman" '

SELECT STUFF(@FullName, CHARINDEX(' ', @FullName), 1, @Alias) AS [FullName]

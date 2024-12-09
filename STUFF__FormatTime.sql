-- Source
-- http://www.sql-server-helper.com/tips/tip-of-the-day.aspx?tkey=3934817c-1a03-4ac9-a0ba-55b2bfbaea0f&tkw=uses-of-the-stuff-string-function


-- Format Time From HHMM to HH:MM
DECLARE @Time			VARCHAR(10)
SET @Time = '1030'

SELECT STUFF(@Time, 3, 0, ':') AS [HH:MM]
-- Source
-- http://www.sql-server-helper.com/tips/tip-of-the-day.aspx?tkey=3934817c-1a03-4ac9-a0ba-55b2bfbaea0f&tkw=uses-of-the-stuff-string-function


-- Format Date from MMDDYYYY to MM/DD/YYYY
DECLARE @MMDDYYYY		VARCHAR(10)
SET @MMDDYYYY = '07042013'

SELECT STUFF(STUFF(@MMDDYYYY, 3, 0, '/'), 6, 0, '/') AS [MM/DD/YYYY]

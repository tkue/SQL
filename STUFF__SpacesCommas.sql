-- Source
-- http://www.sql-server-helper.com/tips/tip-of-the-day.aspx?tkey=3934817c-1a03-4ac9-a0ba-55b2bfbaea0f&tkw=uses-of-the-stuff-string-function

-- Put Spaces or Commas Between Letters in a String
DECLARE @String1         VARCHAR(100)
DECLARE @String2         VARCHAR(100)
SET @String1 = 'ABCDEFGHIJ'
SET @String2 = 'ABCDEFGHIJ'

SELECT @String1 = STUFF(@String1, [Number] * 2, 0, ' '),
       @String2 = STUFF(@String2, [Number] * 2, 0, ',')
FROM [master].[dbo].[spt_values]
WHERE [Type] = 'P' AND
      [Number] BETWEEN 1 AND 9

SELECT @String1 AS [Output1], @String2 AS [Output2]

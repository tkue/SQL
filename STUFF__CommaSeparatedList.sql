-- Source
-- http://www.sql-server-helper.com/tips/tip-of-the-day.aspx?tkey=3934817c-1a03-4ac9-a0ba-55b2bfbaea0f&tkw=uses-of-the-stuff-string-function

--  Generate a Comma-Separated List
DECLARE @Heroes TABLE (
    [HeroName]      VARCHAR(20)
)

INSERT INTO @Heroes ( [HeroName] )
VALUES ( 'Superman' ), ( 'Batman' ), ('Ironman'), ('Wolverine')

SELECT STUFF((SELECT ',' + [HeroName]
			  FROM @Heroes
			  ORDER BY [HeroName]
			  FOR XML PATH('')), 1, 1, '') AS [Output]
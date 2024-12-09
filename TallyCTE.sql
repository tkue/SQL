;WITH Tally (n) AS
(
    SELECT ROW_NUMBER() OVER (ORDER BY (SELECT NULL))
    FROM (VALUES(0),(0),(0),(0),(0),(0),(0),(0),(0),(0)) a(n)
    CROSS JOIN (VALUES(0),(0),(0),(0),(0),(0),(0),(0),(0),(0)) b(n)
    CROSS JOIN (VALUES(0),(0),(0),(0),(0),(0),(0),(0),(0),(0)) c(n)
	CROSS JOIN (VALUES(0),(0),(0),(0),(0),(0),(0),(0),(0),(0)) d(n)
	CROSS JOIN (VALUES(0),(0),(0),(0),(0),(0),(0),(0),(0),(0)) e(n)
	CROSS JOIN (VALUES(0),(0),(0),(0),(0),(0),(0),(0),(0),(0)) f(n)
)
SELECT *
FROM Tally t
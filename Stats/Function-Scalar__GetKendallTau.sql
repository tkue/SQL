

DROP FUNCTION IF EXISTS Stat.GetKendallTau
GO


-- https://www.red-gate.com/simple-talk/blogs/statistics-sql-kendalls-tau-rank-correlation/
CREATE FUNCTION Stat.GetKendallTau(
	@Input dbo.PlotType READONLY
)
RETURNS NUMERIC(8, 2) 
AS
BEGIN
	DECLARE @Data TABLE (
		Id INT IDENTITY PRIMARY KEY
		,x numeric(18, 8)
		,y numeric(18, 8)
	)
	INSERT INTO @Data ( x, y )
	SELECT x, y
	FROM @Input
	ORDER BY
		x

	DECLARE 
		@n1 NUMERIC(18, 6)
		,@n2 NUMERIC(18, 6)
		,@n0 NUMERIC(18, 6)
		,@nc NUMERIC(18, 6)
		,@nd NUMERIC(18, 6)


  SELECT @n1 = COALESCE(SUM(ties.t * (ties.t - 1)) / 2, 0)
    FROM
      (SELECT COUNT(*) AS t
         FROM @Data
         GROUP BY [@Data].x
         HAVING COUNT(*) > 1
      ) ties;

  SELECT @n2 = COALESCE(SUM(ties.t * (ties.t - 1)) / 2, 0)
    FROM
      (SELECT COUNT(*) AS t
         FROM @Data
         GROUP BY [@Data].y
         HAVING COUNT(*) > 1
      ) ties;

  SELECT @n0 = COUNT(*),
  	   @nc = SUM(CASE WHEN (i.x < j.x AND i.y < j.y) OR (i.x > j.x AND i.y > j.y) THEN 1 ELSE 0 END), -- concordant
  	   @nd =  SUM(CASE WHEN (i.x < j.x AND i.y > j.y) OR (i.x > j.x AND i.y < j.y) THEN 1 ELSE 0 END) -- discordant
    FROM @Data i
      CROSS JOIN @Data j
    WHERE i.Id <> j.Id;

  RETURN CONVERT(NUMERIC(8, 2), (@nc - @nd) / SQRT((@n0 - @n1) * (@n0 - @n2)))
END
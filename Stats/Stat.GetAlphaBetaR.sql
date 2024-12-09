

-- https://www.red-gate.com/simple-talk/blogs/statistics-sql-simple-linear-regressions/
CREATE FUNCTION Stat.GetAlphaBetaR (
	@Input dbo.PlotType READONLY
)
RETURNS TABLE AS RETURN
(
  SELECT 
    ((Sy * Sxx) - (Sx * Sxy))
    / ((N * (Sxx)) - (Sx * Sx)) AS a,
    ((N * Sxy) - (Sx * Sy))
    / ((N * Sxx) - (Sx * Sx)) AS b,
    ((N * Sxy) - (Sx * Sy))
    / SQRT(
        (((N * Sxx) - (Sx * Sx))
         * ((N * Syy - (Sy * Sy))))) AS r
    FROM
      (
      SELECT SUM([@Input].x) AS Sx, SUM([@Input].y) AS Sy,
        SUM([@Input].x * [@Input].x) AS Sxx,
        SUM([@Input].x * [@Input].y) AS Sxy,
        SUM([@Input].y * [@Input].y) AS Syy,
        COUNT(*) AS N
        FROM @Input
      ) sums
)
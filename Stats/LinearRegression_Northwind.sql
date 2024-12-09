USE Util
GO

SET ARITHABORT ON

DECLARE @Input AS dbo.PlotType

;WITH c AS (
	SELECT
		OrderDate = CAST(ord.OrderDate AS date)
		--,OrderDateInt = CAST(CAST(DATEPART(year, ord.OrderDate) AS varchar(4)) 
		--				+  CAST(DATEPART(month, ord.OrderDate) AS varchar(2))
		--				+ CAST(DATEPART(day, ord.OrderDate) AS varchar(2)) AS int)
		,Amount = SUM(( od.UnitPrice * od.Quantity ) - od.Discount)
	FROM Northwind.dbo.[Order Details] od
	JOIN Northwind.dbo.Orders ord ON od.OrderID = ord.OrderID
	GROUP BY
		ord.OrderDate
	--ORDER BY
	--	od.OrderID
)

INSERT INTO @Input
SELECT
	tally.N
	,c.Amount 
FROM c 
JOIN Stat.TallyDay tally ON c.OrderDate = tally.[Date]

--SELECT *
--FROM @Input

--RETURN 

DECLARE 
	@minDate date
	,@maxDate date
	,@numYearsToForecast tinyint = 5

-- Get alpha/beta/r
DECLARE
	@alpha numeric(38,8)
	,@beta numeric(38,8)
	,@r float

SELECT
	@alpha = alpha
	,@beta = beta
	,@r = rho
FROM Stat.GetAlphaBetaR(@Input)

-- Get min/max dates for forecast
SELECT @minDate = MIN(tally.Date)
	,@maxDate = MAX(tally.[Date])
FROM @Input i
JOIN Stat.TallyDay tally ON i.x = tally.N

;WITH c_Tally AS (
	SELECT *
	FROM Stat.TallyDay t
	WHERE
		t.[Date] >= @minDate
		AND t.[Year] <= DATEPART(year, @maxDate) + @numYearsToForecast
) 

SELECT 
	t.[Date] AS x
	,y = @alpha + (@beta * t.N)
	,IsForecast = 1
FROM c_Tally t
LEFT JOIN @Input i ON t.N = i.x
WHERE
	i.x IS NULL 
--ORDER BY
--	t.Date

UNION

SELECT
	t.[Date] AS x
	,i.y
	,IsForecast = 0
FROM @Input i
JOIN Stat.TallyDay t ON i.x = t.N
--ORDER BY
--	i.x

SELECT Stat.GetKendallTau(@Input)


--;WITH c_Tally AS (
--	SELECT *
--	FROM Stat.TallyDay
--)


SELECT @alpha "alpha"
	,@beta "beta"
	,@r "r"

SELECT 
	alpha, 
	beta, 
	rho,
    Minx AS xLineMin, 
	alpha + (beta * Minx) AS yLineMin, 
	Maxx AS xLineMax,  
	alpha + (beta * Maxx) AS yLineMax
  FROM
      (
      SELECT --Sx,Sy,Sxx,Sxy,Syy,N,
        Maxx, Minx, Maxy, Miny,
        ((Sy * Sxx) - (Sx * Sxy))
        / ((N * (Sxx)) - (Sx * Sx)) AS alpha,
        ((N * Sxy) - (Sx * Sy))
        / ((N * Sxx) - (Sx * Sx)) AS beta,
        ((N * Sxy) - (Sx * Sy))
        / SQRT((((N * Sxx) - (Sx * Sx))
                * ((N * Syy - (Sy * Sy)))
               )
              ) AS rho
        FROM
          (
          SELECT 
			SUM([@Input].x) AS Sx, SUM([@Input].y) AS Sy,
            SUM([@Input].x * [@Input].x) AS Sxx,
            SUM([@Input].x * [@Input].y) AS Sxy,
            SUM([@Input].y * [@Input].y) AS Syy, 
			COUNT(*) AS N,
            MAX([@Input].x) AS Maxx, MIN([@Input].x) AS Minx,
            MAX([@Input].y) AS Maxy, MIN([@Input].y) AS Miny
            FROM @Input
          ) sums
      ) AlphaBetaRho;
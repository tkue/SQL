
DECLARE 
	@start date
	,@end date 

SELECT 
	@start = '2020-01-01'
	,@end = '2021-01-01'

SELECT 
	--tally.N
	--,dt.Dt
	----,[Day] = DATEPART(day, dt.Dt)
	----,[Month] = DATEPART(month, dt.Dt)
	----,[MonthName] = DATENAME(month, dt.Dt)
	----,[Year] = DATEPART(year, dt.Dt)
	----,FirstOfMonth = 
	--,dateParts.*
	--,firstOfMonth.FirstOfMonth
	--,adjacentMonths.*
	*
FROM (
	SELECT 
		ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS N
	FROM sys.all_columns c1
	CROSS JOIN sys.all_columns c2
) tally
CROSS APPLY (
	SELECT DATEDIFF(day, @start, @end) AS DateRange
) dateRange
CROSS APPLY (
	SELECT DATEADD(day, tally.N - 1, @start) AS Dt
) dt
CROSS APPLY (
	SELECT 
		[Day] = DATEPART(day, dt.Dt)
		,[Week] = DATEPART(week, dt.Dt)
		,[Month] = DATEPART(month, dt.Dt)
		,[MonthName] = DATENAME(month, dt.Dt)
		,[Quarter] = DATEPART(quarter, dt.Dt)
		,[Year] = DATEPART(year, dt.Dt)
		,[WeekDay] = DATEPART(weekday, dt.Dt)
) dateParts
CROSS APPLY (
	SELECT
		FirstOfMonth = CAST(
							CAST(dateParts.[Year] AS char(4)) 
							+ '-' 
							+ CAST(dateParts.[Month] AS char(2))
							+ '-01'
						AS date)
) firstOfMonth
CROSS APPLY (
	SELECT
		NextMonthStart = DATEADD(month, 1, firstOfMonth.FirstOfMonth)
		,PreviousMonthStart = DATEADD(month, -1, firstOfMonth.FirstOfMonth)
) adjacentMonths
CROSS APPLY (
	SELECT 
		FirstDayOfWeekMonday = DATEADD(day, -(dateParts.[WeekDay] -1), dt.Dt)
) firstDayOfWeekMonday
CROSS APPLY (
	SELECT
		FirstDayOfWeekSunday = DATEADD(day, -1, firstDayOfWeekMonday.FirstDayOfWeekMonday)
) firstDayOfWeekSunday 
CROSS APPLY (
	SELECT 
		LastDayOfWeekFriday = DATEADD(day, 5, firstDayOfWeekMonday.FirstDayOfWeekMonday) 
) lastFridayOfWeek
WHERE
	tally.N <= dateRange.DateRange

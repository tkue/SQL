/*
	Use ROW_NUMBER() to create an IDENTITY column in a SELECT statement
*/
SELECT [Excel Row Number] = ROW_NUMBER() OVER (ORDER BY (SELECT NULL)), *
INTO tempdb..temp_table
FROM Table_Name
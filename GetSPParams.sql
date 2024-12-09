drop table if exists #t

select  
   'Parameter_name' = p.name,  
   'Type'   = type_name(user_type_id),  
   'Length'   = max_length,  
   'Prec'   = case when type_name(system_type_id) = 'uniqueidentifier' 
              then precision  
              else OdbcPrec(system_type_id, max_length, precision) end,  
   'Scale'   = OdbcScale(system_type_id, scale),  
   'Param_order'  = parameter_id,  
   'Collation'   = convert(sysname, 
                   case when system_type_id in (35, 99, 167, 175, 231, 239)  
                   then ServerProperty('collation') end)  
	,QUOTENAME(SCHEMA_NAME(o.schema_id)) + '.' + QUOTENAME(o.name) AS ObjName
	,o.object_id
	,o.type_desc
	,o.type AS ObjType
INTO #t 
  from sys.parameters p
  JOIN sys.objects o ON p.object_id = o.object_id

SELECT
	SqlStmt = CASE 
				WHEN t.type = 'P'
					THEN 'EXEC ' + t.ObjName + (SELECT STRING_AGG(CASE
																		WHEN t1.type IN ('date', 'datetime')
																			THEN , ' ')
												FROM #t t1
												WHERE
													t1.object_id = t.object_id
FROM #t t
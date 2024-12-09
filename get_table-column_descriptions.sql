SELECT      
	u.name + '.' + t.name AS [table],
    td.value AS [table_desc],
    c.name AS [column],
    cd.value AS [column_desc]
FROM sysobjects t
INNER JOIN  sysusers u 
	ON u.uid = t.uid
LEFT OUTER JOIN sys.extended_properties td 
	ON td.major_id = t.id
	AND td.minor_id = 0
	AND td.name = 'MS_Description'
INNER JOIN syscolumns c
    ON c.id = t.id
LEFT OUTER JOIN sys.extended_properties cd 
	ON cd.major_id = c.id
	AND cd.minor_id = c.colid
	AND cd.name = 'MS_Description'
WHERE t.type = 'u'
ORDER BY    t.name, c.colorder
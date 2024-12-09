/*
Find all tables with certain column name and values for that column name

https://stackoverflow.com/questions/12882616/t-sql-combine-table-metadata-and-column-values
http://sqlfiddle.com/#!6/dcbf6/1/0
*/
/*
Builds query similar to this:

select top(1) 'Table1' as TableName
from [Table1]
where Column2 = 3
union all
select top(1) 'Table2' as TableName
from [Table2] 
where Column2 = 3
union all 
select top(1) 'Table3' as TableName
from [Table3] 
where Column2 = 3 

*/
declare @Col2Value int = 3
declare @SQL nvarchar(max)

select @SQL = 
(
  select 'union all '+
         'select top(1) '''+t.name+''' as TableName '+
         'from '+quotename(t.name)+' '+
         'where Column2 = '+cast(@Col2Value as nvarchar(10))+' '
  from sys.columns c
    inner join sys.tables t
      on c.object_id = t.object_id
  where c.name = 'Column1'
  for xml path(''), type
).value('substring(./text()[1], 11)', 'nvarchar(max)')

--print @SQL
exec (@SQL)
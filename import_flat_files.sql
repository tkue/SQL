use db_name
go

set quoted_identifier off
go
Create procedure usp_ImportMultipleFilesBCP @servername varchar(128),
@DatabaseName varchar(128), @filepath varchar(500), @pattern varchar(100),
@TableName varchar(128)
as
declare @query varchar(1000)
declare @max1 int
declare @count1 int
Declare @filename varchar(100)
set @count1 =0
create table #x (name varchar(200))
set @query ='master.dbo.xp_cmdshell "dir '+@filepath+@pattern +' /b"'
insert #x exec (@query)
delete from #x where name is NULL
select identity(int,1,1) as ID, name into #y from #x
drop table #x
set @max1 = (select max(ID) from #y)
--print @max1
--print @count1
--select * from #y
While @count1 <= @max1
begin
set @count1=@count1+1
set @filename = (select name from #y where [id] = @count1)
set @Query ='bcp "'+ @databasename+'.dbo.'+@Tablename + '"
	in "'+ @Filepath+@Filename+'" -S' + @servername + ' -T -c -r\n -t,'
set @Query = 'MASTER.DBO.xp_cmdshell '+ "'"+  @query +"'"
--print @query
EXEC ( @query)
insert into logtable (query) select @query
end

drop table #y

exec sp_configure 'xp_cmdshell', '1'

use cwwebapp_beta
EXEC sp_configure'xp_cmdshell', 1
 GO

 EXEC sp_configure 'show advanced options', 1
 exec reconfigure
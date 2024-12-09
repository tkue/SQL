declare @DayOfMonth as varchar(20)
declare @DayOfYear as varchar(20)
declare @DayOfWeek as varchar(20)
declare @DayName as varchar(20)
declare @WeekOfYear as varchar(20) 
declare @WeekName as varchar(20)
declare @MonthOfYear as varchar(20)
declare @MonthName as varchar(20)
declare @Quarter as varchar(20)
declare @Year as varchar(20)
declare @Hour as varchar(20)
declare @Minute as varchar(20)
declare @Second as varchar(20)

set @Year=(select DATEPART(yy, getdate())) --Year
set @DayOfYear = (select DATEPART(dy, getdate())) --DayOfYear
set @MonthOfYear= (select DATEPART(mm, getdate())) --MonthOfYear
set @MonthName= (select DATENAME(mm, getdate())) --MonthName
set @DayOfMonth =(select DATEPART(dd, getdate())) --DayOfMonth
set @WeekOfYear= (select DATEPART(ww, getdate())) --WeekOfYear
set @WeekName= (select 'Week ' + RIGHT('0' + DATENAME(ww, getdate()), 2)) --WeekName
set @DayOfWeek = (select DATEPART(dw, getdate())) --DayOfWeek
set @DayName= (select DATENAME(dw, getdate())) --DayName
set @Quarter=(select 'Q' + DATENAME(qq, getdate()) + ' ' + DATENAME(yy, getdate())) --Quarter
set @Hour=(select DATEPART(hh, getdate())) --Hour
set @Minute=(select DATEPART(mi, getdate()) ) --Minute
set @Second=(select DATEPART(ss, getdate())) --Second

print 'Year :'+@Year
print 'YearDay :' + @DayOfYear
print 'MonthOfYear:'+@MonthOfYear
print 'MonthName :'+@MonthName
print 'MonthDay :' + @DayOfMonth
print 'WeekOfYear :'+ @WeekOfYear
print 'WeekName :'+ @WeekName
print 'DayOfWeek :' + @DayOfWeek
print 'DayName :'+ @DayName
print 'Quarter :'+@Quarter
print 'Hour :'+@Hour+':'+@Minute +':'+@second 
print 'Minute :'+@Minute
print 'Second :'+@Second

select convert(varchar(20),getdate(),101) --1 --MM/DD/YYYY 
select REPLACE(convert(varchar(20),getdate(),101),'/','-') --2 --MM-DD-YYYY 
select convert(varchar(20),getdate(),103) --3 --DD/MM/YYYY 
select convert(varchar(20),getdate(),104) --4 --DD.MM.YYYY 
select convert(varchar(20),getdate(),105) --5 --DD-MM-YYYY 
select convert(varchar(20),getdate(),106) --6 --DD MMM YYYY 
select convert(varchar(20),getdate(),107) --7 --MMM DD, YYYY 
select convert(varchar(20),getdate(),108) --8 --CURRENT TIME HH:MM:SS
select convert(varchar(30),getdate(),109) --9 --CURRENT DATE AND TIME MMM DD YYY H:MM:SS AM/PM
select convert(varchar(20),getdate(),110) --10 --MM/DD/YYYY 
select convert(varchar(20),getdate(),111) --11 --YYYY/MM/DD 
select convert(varchar(20),getdate(),112) --12 --YYYYMMDD 
select convert(varchar(30),getdate(),113) --13 --CURRENT DATE AND TIME DD MMM YYY HH:MM:SS:MMM 
select convert(varchar(30),getdate(),114) --14 --CURRENT TIME HH:MM:SS:MMM

select convert(varchar(30),getdate(),120) --20 --CURRENT DATE AND TIME YYYY-MM-DD HH:MM:SS

select convert(varchar(30),getdate(),121) --21 --CURRENT DATE AND TIME YYYY-MM-DD HH:MM:SS:MMM
select convert(varchar(30),getdate(),126) --26 --CURRENT DATE AND TIME YYYY-MM-DD HH:MM:SS:MMM
select convert(varchar(30),getdate(),130) --30 --CURRENT DATE AND TIME YYYY-MM-DD HH:MM:SS:MMM
select convert(varchar(30),getdate(),131) --31 --CURRENT DATE AND TIME YYYY-MM-DD HH:MM:SS:MMM




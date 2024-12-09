/*
	GET SQL IP CONNECTION INFORMATION

		FOR
			SERVER
			SPECIFIC CLIENT CONNECTIONS
*/

SELECT
   CONNECTIONPROPERTY('net_transport') AS net_transport,
   CONNECTIONPROPERTY('protocol_type') AS protocol_type,
   CONNECTIONPROPERTY('auth_scheme') AS auth_scheme,
   CONNECTIONPROPERTY('local_net_address') AS local_net_address,
   CONNECTIONPROPERTY('local_tcp_port') AS local_tcp_port,
   CONNECTIONPROPERTY('client_net_address') AS client_net_address


   SELECT @@SERVERNAME;



-- http://stackoverflow.com/questions/9941074/how-to-get-the-client-ip-address-from-sql-server-2008-itself

 CREATE FUNCTION [dbo].[GetCurrentIP] ()
RETURNS varchar(255)
AS
BEGIN
    DECLARE @IP_Address varchar(255);

    SELECT @IP_Address = client_net_address
    FROM sys.dm_exec_connections
    WHERE Session_id = @@SPID;

    Return @IP_Address;
END



-----------------

select CONNECTIONPROPERTY('client_net_address') AS client_net_address


-----------------


 SELECT CONVERT(char(15), CONNECTIONPROPERTY('client_net_address'))


 -----------------


 SELECT  hostname,
        net_library,
        net_address,
        client_net_address
FROM    sys.sysprocesses AS S
INNER JOIN    sys.dm_exec_connections AS decc ON S.spid = decc.session_id
WHERE   spid = @@SPID



------------------------

-- http://sqlmag.com/site-files/sqlmag.com/files/archive/sqlmag.com/content/content/48303/listing_01.txt
-- Listing 1: The getSQL_IPaddr.sql Procedure

create Procedure sp_get_ip_address (@ip varchar(40) out)
as
begin
Declare @ipLine varchar(200)
Declare @pos int
set nocount on
  set @ip = NULL
  Create table #temp (ipLine varchar(200))
  Insert #temp exec master..xp_cmdshell 'ipconfig'
  select @ipLine = ipLine
  from #temp
  where upper (ipLine) like '%IP ADDRESS%'
  if (isnull (@ipLine,'***') != '***')
  begin
    set @pos = CharIndex (':',@ipLine,1);
    set @ip = rtrim(ltrim(substring (@ipLine ,
    @pos + 1 ,
    len (@ipLine) - @pos)))
  end
drop table #temp
set nocount off
end
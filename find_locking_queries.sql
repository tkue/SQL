

SELECT tl.resource_type
    , database_name = DB_NAME(tl.resource_database_id)
    , assoc_entity_id = tl.resource_associated_entity_id
    , lock_req = tl.request_mode
    , waiter_sid = tl.request_session_id
    , wait_duration = wt.wait_duration_ms
    , wt.wait_type
    , waiter_batch = wait_st.text
    , waiter_stmt = substring(wait_st.text,er.statement_start_offset/2 + 1,
                abs(case when er.statement_end_offset = -1
                then len(convert(nvarchar(max), wait_st.text)) * 2
                else er.statement_end_offset end - er.statement_start_offset)/2 + 1)
    , waiter_host = es.host_name
    , waiter_user = es.login_name
    , blocker_sid = wt.blocking_session_id
    , blocker_stmt = block_st.text
    , blocker_host = block_es.host_name
    , blocker_user = block_es.login_name
FROM sys.dm_tran_locks tl (nolock)
    INNER JOIN sys.dm_os_waiting_tasks wt (nolock) ON tl.lock_owner_address = wt.resource_address
    INNER JOIN sys.dm_os_tasks ot (nolock) ON tl.request_session_id = ot.session_id AND tl.request_request_id = ot.request_id AND tl.request_exec_context_id = ot.exec_context_id
    INNER JOIN sys.dm_exec_requests er (nolock) ON tl.request_session_id = er.session_id AND tl.request_request_id = er.request_id
    INNER JOIN sys.dm_exec_sessions es (nolock) ON tl.request_session_id = es.session_id
    LEFT JOIN sys.dm_exec_requests block_er (nolock) ON wt.blocking_session_id = block_er.session_id
    LEFT JOIN sys.dm_exec_sessions block_es (nolock) ON wt.blocking_session_id = block_es.session_id
    CROSS APPLY sys.dm_exec_sql_text(er.sql_handle) wait_st
    OUTER APPLY sys.dm_exec_sql_text(block_er.sql_handle) block_st

select *
from sys.dm_tran_locks locks
join sys.sysdatabases d on d.dbid = locks.resource_database_id

select cmd,* from sys.sysprocesses
where blocked > 0

sp_lock

sp_who2


SELECT DISTINCT TOP 20
t.TEXT QueryName,
s.execution_count AS ExecutionCount,
s.max_elapsed_time AS MaxElapsedTime,
ISNULL(s.total_elapsed_time / s.execution_count, 0) AS AvgElapsedTime,
s.creation_time AS LogCreatedOn,
ISNULL(s.execution_count / DATEDIFF(s, s.creation_time, GETDATE()), 0) AS FrequencyPerSec
FROM sys.dm_exec_query_stats s
CROSS APPLY sys.dm_exec_sql_text( s.sql_handle ) t
ORDER BY
s.max_elapsed_time DESC




---------------------------------------------------------
---------------------------------------------------------
-- GUIDE
-- https://www.simple-talk.com/sql/database-administration/investigating-transactions-using-dynamic-management-objects/
---------------------------------------------------------
---------------------------------------------------------
/*
    - request_mode

         type of lock that is being held, or has been requested, such as:
            Shared (S),
            Update (U),
            Exclusive (X),
            Intent Exclusive (IX), and so on. Please see BOL for full details on the various locking modes.


    - request_status

        GRANT   - indicates the lock has been taken
        CONVERT - the request is in the process of being fulfilled
        WAIT    - the resource is not locked, but is trying to lock the resource.


    - request_owner_type - type of owner of the transaction:

        + TRANSACTION
        + CURSOR
        + SESSION
        + SHARED_TRANSACTION_WORKSPACE
        + EXCLUSIVE_TRANSACTION_WORKSPACE

    - request_session_id - the session_id of the requestor.

        Exposing this column allows the DBA to join back to the information provided in any of the sys.dm_exec_* DMVs as well as sys.sysprocesses (via a join to its spid column).


    - request_owner_id -

        this column is only valid when the request_owner_type is TRANSACTION. In that case the value is the transaction_id for the associated transaction.

    - lock_owner_address

        + binary address used internally to track the lock request
        + used to the resource_address column in sys.dm_os_waiting_tasks
            * to relate locking information to tasks that are waiting for a resource to become available, before proceeding (i.e. are blocked)

*/

/* UNCOMMITTED UPDATE STATEMENT */

SELECT  [resource_type] ,
        DB_NAME([resource_database_id]) AS [Database Name] ,
        CASE WHEN DTL.resource_type IN ( 'DATABASE', 'FILE', 'METADATA' )
             THEN DTL.resource_type
             WHEN DTL.resource_type = 'OBJECT'
             THEN OBJECT_NAME(DTL.resource_associated_entity_id,
                              DTL.[resource_database_id])
             WHEN DTL.resource_type IN ( 'KEY', 'PAGE', 'RID' )
             THEN ( SELECT  OBJECT_NAME([object_id])
                    FROM    sys.partitions
                    WHERE   sys.partitions.hobt_id =
                                            DTL.resource_associated_entity_id
                  )
             ELSE 'Unidentified'
        END AS requested_object_name ,
        [request_mode] ,
        [resource_description]
FROM    sys.dm_tran_locks DTL
WHERE   DTL.[resource_type] <> 'DATABASE';


-- More detailed query

SELECT  DTL.[request_session_id] AS [session_id] ,
        DB_NAME(DTL.[resource_database_id]) AS [Database] ,
        DTL.resource_type ,
        CASE WHEN DTL.resource_type IN ( 'DATABASE', 'FILE', 'METADATA' )
             THEN DTL.resource_type
             WHEN DTL.resource_type = 'OBJECT'
             THEN OBJECT_NAME(DTL.resource_associated_entity_id,
                              DTL.[resource_database_id])
             WHEN DTL.resource_type IN ( 'KEY', 'PAGE', 'RID' )
             THEN ( SELECT  OBJECT_NAME([object_id])
                    FROM    sys.partitions
                    WHERE   sys.partitions.hobt_id =
                                            DTL.resource_associated_entity_id
                  )
             ELSE 'Unidentified'
        END AS [Parent Object] ,
        DTL.request_mode AS [Lock Type] ,
        DTL.request_status AS [Request Status] ,
        DER.[blocking_session_id] ,
        DES.[login_name] ,
        CASE DTL.request_lifetime
          WHEN 0 THEN DEST_R.TEXT
          ELSE DEST_C.TEXT
        END AS [Statement]
FROM    sys.dm_tran_locks DTL
        LEFT JOIN sys.[dm_exec_requests] DER
                   ON DTL.[request_session_id] = DER.[session_id]
        INNER JOIN sys.dm_exec_sessions DES
                   ON DTL.request_session_id = DES.[session_id]
        INNER JOIN sys.dm_exec_connections DEC
                   ON DTL.[request_session_id] = DEC.[most_recent_session_id]
        OUTER APPLY sys.dm_exec_sql_text(DEC.[most_recent_sql_handle])
                                                         AS DEST_C
        OUTER APPLY sys.dm_exec_sql_text(DER.sql_handle) AS DEST_R
WHERE   DTL.[resource_database_id] = DB_ID()
        AND DTL.[resource_type] NOT IN ( 'DATABASE', 'METADATA' )
ORDER BY DTL.[request_session_id] ;


--------------------

USE [AdventureWorks] ;
GO
SELECT  DTL.[resource_type] AS [resource type] ,
        CASE WHEN DTL.[resource_type] IN ( 'DATABASE', 'FILE', 'METADATA' )
             THEN DTL.[resource_type]
             WHEN DTL.[resource_type] = 'OBJECT'
             THEN OBJECT_NAME(DTL.resource_associated_entity_id)
             WHEN DTL.[resource_type] IN ( 'KEY', 'PAGE', 'RID' )
             THEN ( SELECT  OBJECT_NAME([object_id])
                    FROM    sys.partitions
                    WHERE   sys.partitions.[hobt_id] =
                                 DTL.[resource_associated_entity_id]
                  )
             ELSE 'Unidentified'
        END AS [Parent Object] ,
        DTL.[request_mode] AS [Lock Type] ,
        DTL.[request_status] AS [Request Status] ,
        DOWT.[wait_duration_ms] AS [wait duration ms] ,
        DOWT.[wait_type] AS [wait type] ,
        DOWT.[session_id] AS [blocked session id] ,
        DES_blocked.[login_name] AS [blocked_user] ,
        SUBSTRING(dest_blocked.text, der.statement_start_offset / 2,
                  ( CASE WHEN der.statement_end_offset = -1
                         THEN DATALENGTH(dest_blocked.text)
                         ELSE der.statement_end_offset
                    END - der.statement_start_offset ) / 2
                                              AS [blocked_command] ,
        DOWT.[blocking_session_id] AS [blocking session id] ,
        DES_blocking.[login_name] AS [blocking user] ,
        DEST_blocking.[text] AS [blocking command] ,
        DOWT.resource_description AS [blocking resource detail]
FROM    sys.dm_tran_locks DTL
        INNER JOIN sys.dm_os_waiting_tasks DOWT
                    ON DTL.lock_owner_address = DOWT.resource_address
        INNER JOIN sys.[dm_exec_requests] DER
                    ON DOWT.[session_id] = DER.[session_id]
        INNER JOIN sys.dm_exec_sessions DES_blocked
                    ON DOWT.[session_id] = DES_Blocked.[session_id]
        INNER JOIN sys.dm_exec_sessions DES_blocking
                    ON DOWT.[blocking_session_id] = DES_Blocking.[session_id]
        INNER JOIN sys.dm_exec_connections DEC
                    ON DTL.[request_session_id] = DEC.[most_recent_session_id]
        CROSS APPLY sys.dm_exec_sql_text(DEC.[most_recent_sql_handle])
                                                         AS DEST_Blocking
        CROSS APPLY sys.dm_exec_sql_text(DER.sql_handle) AS DEST_Blocked
WHERE   DTL.[resource_database_id] = DB_ID()

---------------------

SELECT  DTAT.transaction_id ,
        DTAT.[name] ,
        DTAT.transaction_begin_time ,
        CASE DTAT.transaction_type
          WHEN 1 THEN 'Read/write'
          WHEN 2 THEN 'Read-only'
          WHEN 3 THEN 'System'
          WHEN 4 THEN 'Distributed'
        END AS transaction_type ,
        CASE DTAT.transaction_state
          WHEN 0 THEN 'Not fully initialized'
          WHEN 1 THEN 'Initialized, not started'
          WHEN 2 THEN 'Active'
          WHEN 3 THEN 'Ended' -- only applies to read-only transactions
          WHEN 4 THEN 'Commit initiated'-- distributed transactions only
          WHEN 5 THEN 'Prepared, awaiting resolution'
          WHEN 6 THEN 'Committed'
          WHEN 7 THEN 'Rolling back'
          WHEN 8 THEN 'Rolled back'
        END AS transaction_state ,
        CASE DTAT.dtc_state
          WHEN 1 THEN 'Active'
          WHEN 2 THEN 'Prepared'
          WHEN 3 THEN 'Committed'
          WHEN 4 THEN 'Aborted'
          WHEN 5 THEN 'Recovered'
        END AS dtc_state
FROM    sys.dm_tran_active_transactions DTAT
        INNER JOIN sys.dm_tran_session_transactions DTST
                         ON DTAT.transaction_id = DTST.transaction_id
WHERE   [DTST].[is_user_transaction] = 1
ORDER BY DTAT.transaction_begin_time


----------------------

/* ACCESSING TRANSACTION LOG IMPACT */
/*
    The sys.dm_tran_database_transactions DMV is the only one that provides insight into the effects of user activity on the database transaction logs.
    Using this DMV, and joining across to other transaction-related and execution-related DMVs, as described previously, we can develop a query, shown in
    Listing 14, which will identify all active transactions and their physical effect on the databases' transaction logs.
    This is especially useful when seeking out transactions that may be causing explosive transaction log growth.
*/
SELECT DTST.[session_id],
 DES.[login_name] AS [Login Name],
 DB_NAME (DTDT.database_id) AS [Database],
 DTDT.[database_transaction_begin_time] AS [Begin Time],
 -- DATEDIFF(ms,DTDT.[database_transaction_begin_time], GETDATE()) AS [Duration ms],
 CASE DTAT.transaction_type
   WHEN 1 THEN 'Read/write'
    WHEN 2 THEN 'Read-only'
    WHEN 3 THEN 'System'
    WHEN 4 THEN 'Distributed'
  END AS [Transaction Type],
  CASE DTAT.transaction_state
    WHEN 0 THEN 'Not fully initialized'
    WHEN 1 THEN 'Initialized, not started'
    WHEN 2 THEN 'Active'
    WHEN 3 THEN 'Ended'
    WHEN 4 THEN 'Commit initiated'
    WHEN 5 THEN 'Prepared, awaiting resolution'
    WHEN 6 THEN 'Committed'
    WHEN 7 THEN 'Rolling back'
    WHEN 8 THEN 'Rolled back'
  END AS [Transaction State],
 DTDT.[database_transaction_log_record_count] AS [Log Records],
 DTDT.[database_transaction_log_bytes_used] AS [Log Bytes Used],
 DTDT.[database_transaction_log_bytes_reserved] AS [Log Bytes RSVPd],
 DEST.[text] AS [Last Transaction Text],
 DEQP.[query_plan] AS [Last Query Plan]
FROM sys.dm_tran_database_transactions DTDT
 INNER JOIN sys.dm_tran_session_transactions DTST
   ON DTST.[transaction_id] = DTDT.[transaction_id]
 INNER JOIN sys.[dm_tran_active_transactions] DTAT
   ON DTST.[transaction_id] = DTAT.[transaction_id]
 INNER JOIN sys.[dm_exec_sessions] DES
   ON DES.[session_id] = DTST.[session_id]
 INNER JOIN sys.dm_exec_connections DEC
   ON DEC.[session_id] = DTST.[session_id]
 LEFT JOIN sys.dm_exec_requests DER
   ON DER.[session_id] = DTST.[session_id]
 CROSS APPLY sys.dm_exec_sql_text (DEC.[most_recent_sql_handle]) AS DEST
 OUTER APPLY sys.dm_exec_query_plan (DER.[plan_handle]) AS DEQP
ORDER BY DTDT.[database_transaction_log_bytes_used] DESC;
-- ORDER BY [Duration ms] DESC;


/* SUMMARY */
/*
The sys.dm_tran-prefixed Dynamic Management Objects have a broad scope in SQL Server.
    They not only span the range of DMOs associated with activity at the transactional level of the query engine,
    but also expose locking and blocking between user sessions, as well as exposing the effects and existence of snapshot isolation
    in your SQL Server database and the instance in general.

Via queries against sys.dm_tran_locks, joining to various sys.dm_exec-prefixed DMOs as well as sys.dm_os_waiting_tasks,
    we were able to diagnose locking and blocking occurring within our SQL databases.

Using sys.dm_tran_session_transactions
    we were able to correlate session-based results from
         sys.dm_exec_connections,
         sys.dm_exec_sessions,
         and sys.dm_exec_requests


         with data from the sys.dm_tran-prefixed DMOs.
         Using sys.dm_tran_active_transactions and sys.dm_tran_database_transactions, we collected metrics on the duration and status of our users' transactions,
         and observed the physical effects of those transactions on the database transaction log files on disk.
*/

---------------------------------------------------------
---------------------------------------------------------
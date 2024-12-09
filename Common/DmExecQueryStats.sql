SELECT  SUBSTRING(dest.text, ( deqs.statement_start_offset / 2 ) + 1,
                  ( CASE deqs.statement_end_offset
                      WHEN -1 THEN DATALENGTH(dest.text)
                      ELSE deqs.statement_end_offset
                           - deqs.statement_start_offset
                    END ) / 2 + 1) AS querystatement ,
        deqp.query_plan ,
        deqs.execution_count ,
        deqs.total_worker_time ,
        deqs.total_logical_reads ,
        deqs.total_elapsed_time
FROM    sys.dm_exec_query_stats AS deqs
        CROSS APPLY sys.dm_exec_sql_text(deqs.sql_handle) AS dest
        CROSS APPLY sys.dm_exec_query_plan(deqs.plan_handle) AS deqp;
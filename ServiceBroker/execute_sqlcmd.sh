#!/bin/bash

nohup ./sqlcmd -S localhost -U sa -P "" -d WideWorldImporters -Q "EXEC dbo.LoadData" > sql.nohup 2>&1 & echo $! > pid.txt && tail -f sql.nohup

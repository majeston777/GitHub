SET NOCOUNT ON;
CREATE TABLE #RollingTotalsExample
(
    -- [Date]    DATE PRIMARY KEY
    -- Change data type of [Date] to BIGINT 
    [Date]     BIGINT PRIMARY KEY
    ,[Value]   INT
);

WITH Tally (n) AS
(
    SELECT TOP 1000000 ROW_NUMBER() OVER (ORDER BY (SELECT NULL))
    FROM sys.all_columns a CROSS JOIN sys.all_columns b
)
INSERT INTO #RollingTotalsExample
SELECT n, 1+ABS(CHECKSUM(NEWID()))%1000
FROM Tally;
PRINT 'Number of test rows: ' + CAST(@@ROWCOUNT AS VARCHAR(12));

PRINT 'Solution #1 - Tally Table';
SET STATISTICS TIME ON;
-- Rolling 12 month totals using a Tally table
WITH Tally (n) AS
(
    SELECT 0 UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3
    UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7
    UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10 UNION ALL SELECT 11
)
SELECT GroupingDate
    ,Value=MAX(CASE n WHEN 0 THEN a.Value END)
    ,Rolling12Months=CASE 
                        WHEN ROW_NUMBER() OVER (ORDER BY GroupingDate) < 12 
                        THEN NULL 
                        ELSE SUM(Value) 
                        END
INTO #Results_Soln1
FROM #RollingTotalsExample a
CROSS APPLY Tally b
CROSS APPLY
(
    -- Remove the DATE arithmetic
    SELECT GroupingDate=[Date] + n -- DATEADD(month, n, [Date])
) c
GROUP BY GroupingDate
HAVING GroupingDate <= MAX([Date])
ORDER BY GroupingDate;
SET STATISTICS TIME OFF;

PRINT 'Solution #2 - INNER JOIN' + CHAR(10);
SET STATISTICS TIME ON;
-- Rolling 12 month total by using INNER JOIN
SELECT a.[Date]
    ,Value=MAX(CASE WHEN a.[Date] = b.[Date] THEN a.Value END)
    ,Rolling12Months=CASE 
                        WHEN ROW_NUMBER() OVER (ORDER BY a.[Date]) < 12 
                        THEN NULL 
                        ELSE SUM(b.Value) 
                        END
INTO #Results_Soln2
FROM #RollingTotalsExample a
-- Remove the DATE arithmetic
--JOIN #RollingTotalsExample b ON b.[Date] BETWEEN DATEADD(month, -11, a.[Date]) AND a.[Date]
JOIN #RollingTotalsExample b ON b.[Date] BETWEEN a.[Date]-11 AND a.[Date]
GROUP BY a.[Date];
SET STATISTICS TIME OFF;

PRINT 'Solution #3 - CROSS APPLY TOP' + CHAR(10);
SET STATISTICS TIME ON;
-- Rolling 12 month total by using CROSS APPLY TOP
SELECT a.[Date]
    ,a.Value
    ,Rolling12Months=(a.Value + b.Value) *
        CASE WHEN ROW_NUMBER() OVER (ORDER BY a.[Date]) < 12 THEN NULL ELSE 1 END
INTO #Results_Soln3
FROM #RollingTotalsExample a
CROSS APPLY
( 
    SELECT Value=SUM(Value)
    FROM
    (
        SELECT TOP 11 b.[Date], Value 
        FROM #RollingTotalsExample b
        WHERE b.[Date] < a.[Date]
        ORDER BY b.[Date] DESC
    ) b
) b;
SET STATISTICS TIME OFF;

PRINT 'Solution #4 - Correlated Sub-query' + CHAR(10);
SET STATISTICS TIME ON;
-- Rolling 12 month total by using correlated sub-query
SELECT a.[Date]
    ,a.Value
    ,Rolling12Months=(a.Value + 
        (
            SELECT Value=SUM(Value)
            FROM
            (
                SELECT TOP 11 b.[Date], Value 
                FROM #RollingTotalsExample b
                WHERE b.[Date] < a.[Date]
                ORDER BY b.[Date] DESC
            ) b
        )) * CASE WHEN ROW_NUMBER() OVER (ORDER BY a.[Date]) < 12 THEN NULL ELSE 1 END
INTO #Results_Soln4
FROM #RollingTotalsExample a

-- Performing a Quirky Update to get our running 12 month totals
ALTER TABLE #RollingTotalsExample ADD Rolling12Months INT NULL;
SET STATISTICS TIME OFF;

DECLARE @Lag1   INT = 0
    ,@Lag2      INT = 0
    ,@Lag3      INT = 0
    ,@Lag4      INT = 0
    ,@Lag5      INT = 0
    ,@Lag6      INT = 0
    ,@Lag7      INT = 0
    ,@Lag8      INT = 0
    ,@Lag9      INT = 0
    ,@Lag10     INT = 0
    ,@Lag11     INT = 0
    ,@Lag12     INT = 0
    ,@rt        INT = 0
    ,@rn        INT = NULL;

PRINT 'Solution #5 - Quirky Update' + CHAR(10);
SET STATISTICS TIME ON;
UPDATE #RollingTotalsExample WITH(TABLOCKX)
SET @rt = @rt + Value - @Lag12
    ,@rn = CASE WHEN @rn IS NULL THEN 1 ELSE @rn + 1 END
    ,Rolling12Months = CASE WHEN @rn > 11 THEN @rt END
    ,@Lag12 = @Lag11
    ,@Lag11 = @Lag10
    ,@Lag10 = @Lag9
    ,@Lag9 = @Lag8
    ,@Lag8 = @Lag7
    ,@Lag7 = @Lag6
    ,@Lag6 = @Lag5
    ,@Lag5 = @Lag4
    ,@Lag4 = @Lag3
    ,@Lag3 = @Lag2
    ,@Lag2 = @Lag1
    ,@Lag1 = Value
OPTION (MAXDOP 1);
SET STATISTICS TIME OFF;

--SELECT * FROM #RollingTotalsExample;

PRINT 'Solution #6 - SQL 2012 Window Frame' + CHAR(10);
SET STATISTICS TIME ON;
-- Rolling 12 months totals using SQL 2012 and a window frame
SELECT [Date], Value
    ,Rolling12Months=CASE WHEN ROW_NUMBER() OVER (ORDER BY [Date]) > 11
        THEN SUM(Value) OVER (ORDER BY [Date] ROWS BETWEEN 11 PRECEDING AND CURRENT ROW)
        END
INTO #Results_Soln6
FROM #RollingTotalsExample;
SET STATISTICS TIME OFF;

PRINT 'Solution #7 - SQL 2012 Multiple LAGs' + CHAR(10);
SET STATISTICS TIME ON;
-- Rolling 12 months totals using SQL 2012 and multiple LAGs
SELECT [Date], Value
    ,Rolling12Months=Value +
        LAG(Value, 1) OVER (ORDER BY [Date]) +
        LAG(Value, 2) OVER (ORDER BY [Date]) +
        LAG(Value, 3) OVER (ORDER BY [Date]) +
        LAG(Value, 4) OVER (ORDER BY [Date]) +
        LAG(Value, 5) OVER (ORDER BY [Date]) +
        LAG(Value, 6) OVER (ORDER BY [Date]) +
        LAG(Value, 7) OVER (ORDER BY [Date]) +
        LAG(Value, 8) OVER (ORDER BY [Date]) +
        LAG(Value, 9) OVER (ORDER BY [Date]) +
        LAG(Value, 10) OVER (ORDER BY [Date]) +
        LAG(Value, 11) OVER (ORDER BY [Date])
INTO #Results_Soln7
FROM #RollingTotalsExample;
SET STATISTICS TIME OFF;

GO
DROP TABLE #RollingTotalsExample;
DROP TABLE #Results_Soln1;
DROP TABLE #Results_Soln2;
DROP TABLE #Results_Soln3;
DROP TABLE #Results_Soln4;
DROP TABLE #Results_Soln6;
DROP TABLE #Results_Soln7;

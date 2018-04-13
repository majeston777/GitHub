CREATE TABLE #RollingTotalsExample
(
    [Date]     DATE PRIMARY KEY
    ,[Value]   INT
);

INSERT INTO #RollingTotalsExample
SELECT '2011-01-01',626
UNION ALL SELECT '2011-02-01',231 UNION ALL SELECT '2011-03-01',572
UNION ALL SELECT '2011-04-01',775 UNION ALL SELECT '2011-05-01',660
UNION ALL SELECT '2011-06-01',662 UNION ALL SELECT '2011-07-01',541
UNION ALL SELECT '2011-08-01',849 UNION ALL SELECT '2011-09-01',632
UNION ALL SELECT '2011-10-01',906 UNION ALL SELECT '2011-11-01',961
UNION ALL SELECT '2011-12-01',361 UNION ALL SELECT '2012-01-01',461
UNION ALL SELECT '2012-02-01',928 UNION ALL SELECT '2012-03-01',855
UNION ALL SELECT '2012-04-01',605 UNION ALL SELECT '2012-05-01',83
UNION ALL SELECT '2012-06-01',44 UNION ALL SELECT '2012-07-01',382
UNION ALL SELECT '2012-08-01',862 UNION ALL SELECT '2012-09-01',549
UNION ALL SELECT '2012-10-01',632 UNION ALL SELECT '2012-11-01',2
UNION ALL SELECT '2012-12-01',26;

SELECT * FROM #RollingTotalsExample;

SELECT SUM(Value)
FROM #RollingTotalsExample
WHERE [Date] <= '2011-12-01';

SELECT [Next Results Set]='Rolling 12 month totals using a Tally table';
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
FROM #RollingTotalsExample a
CROSS APPLY Tally b
CROSS APPLY
(
    SELECT GroupingDate=DATEADD(month, n, [Date])
) c
GROUP BY GroupingDate
HAVING GroupingDate <= MAX([Date])
ORDER BY GroupingDate;

SELECT [Next Results Set]='Rolling 12 month total by using INNER JOIN';
-- Rolling 12 month total by using INNER JOIN
SELECT a.[Date]
    ,Value=MAX(CASE WHEN a.[Date] = b.[Date] THEN a.Value END)
    ,Rolling12Months=CASE 
                        WHEN ROW_NUMBER() OVER (ORDER BY a.[Date]) < 12 
                        THEN NULL 
                        ELSE SUM(b.Value) 
                        END
FROM #RollingTotalsExample a
JOIN #RollingTotalsExample b ON b.[Date] BETWEEN DATEADD(month, -11, a.[Date]) AND a.[Date]
GROUP BY a.[Date]
ORDER BY a.[Date];

SELECT [Next Results Set]='Rolling 12 month total by using CROSS APPLY TOP';
-- Rolling 12 month total by using CROSS APPLY TOP
SELECT a.[Date]
    ,a.Value
    ,Rolling12Months=CASE 
                        WHEN ROW_NUMBER() OVER (ORDER BY a.[Date]) < 12 
                        THEN NULL 
                        ELSE a.Value + b.Value 
                        END
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
) b
ORDER BY a.[Date];

SELECT [Next Results Set]='Rolling 12 month total by using a correlated sub-query';
-- Rolling 12 month total by using a correlated sub-query
SELECT a.[Date]
    ,a.Value
    ,Rolling12Months=
        CASE 
        WHEN ROW_NUMBER() OVER (ORDER BY a.[Date]) < 12 
        THEN NULL 
        ELSE a.Value + 
            (
                SELECT Value=SUM(Value)
                FROM
                (
                    SELECT TOP 11 b.[Date], Value 
                    FROM #RollingTotalsExample b
                    WHERE b.[Date] < a.[Date]
                    ORDER BY b.[Date] DESC
                ) b
            )
        END
FROM #RollingTotalsExample a
ORDER BY a.[Date];

SELECT [Next Results Set]='Performing a Quirky Update to get our running 12 month totals';
-- Performing a Quirky Update to get our running 12 month totals
ALTER TABLE #RollingTotalsExample ADD Rolling12Months INT NULL;

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

SELECT * FROM #RollingTotalsExample;

SELECT [Next Results Set]='Rolling 12 months totals using SQL 2012 and a window frame';
-- Rolling 12 months totals using SQL 2012 and a window frame
SELECT [Date], Value
    ,Rolling12Months=CASE WHEN ROW_NUMBER() OVER (ORDER BY [Date]) > 11
        THEN SUM(Value) OVER (ORDER BY [Date] ROWS BETWEEN 11 PRECEDING AND CURRENT ROW)
        END
FROM #RollingTotalsExample;

SELECT [Next Results Set]='Rolling 12 months totals using SQL 2012 and multiple LAGs';
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
FROM #RollingTotalsExample;

GO
DROP TABLE #RollingTotalsExample;

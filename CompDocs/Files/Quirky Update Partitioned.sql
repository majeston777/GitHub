CREATE TABLE #RollingTotalsExample
(
    ID                  INT NOT NULL
    ,[Date]             DATE NOT NULL
    ,[Value]            INT NOT NULL
    ,Rolling12Months    INT NULL
    ,PRIMARY KEY (ID, [Date])
);

INSERT INTO #RollingTotalsExample (ID, [Date], [Value])
SELECT 1, '2011-01-01',626
UNION ALL SELECT 1, '2011-02-01',231 UNION ALL SELECT 1, '2011-03-01',572
UNION ALL SELECT 1, '2011-04-01',775 UNION ALL SELECT 1, '2011-05-01',660
UNION ALL SELECT 1, '2011-06-01',662 UNION ALL SELECT 1, '2011-07-01',541
UNION ALL SELECT 1, '2011-08-01',849 UNION ALL SELECT 1, '2011-09-01',632
UNION ALL SELECT 1, '2011-10-01',906 UNION ALL SELECT 1, '2011-11-01',961
UNION ALL SELECT 1, '2011-12-01',361 UNION ALL SELECT 1, '2012-01-01',461
UNION ALL SELECT 1, '2012-02-01',928 UNION ALL SELECT 1, '2012-03-01',855
UNION ALL SELECT 1, '2012-04-01',605 UNION ALL SELECT 1, '2012-05-01',83
UNION ALL SELECT 1, '2012-06-01',44 UNION ALL SELECT 1, '2012-07-01',382
UNION ALL SELECT 1, '2012-08-01',862 UNION ALL SELECT 1, '2012-09-01',549
UNION ALL SELECT 1, '2012-10-01',632 UNION ALL SELECT 1, '2012-11-01',2
UNION ALL SELECT 1, '2012-12-01',26;


--SELECT * FROM #RollingTotalsExample;

-- Performing a Quirky Update to get our running 12 month totals

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
    -- Setting @rn = NULL only works if there is a single partition
    ,@rn        INT = NULL
    -- We need an additional variable to handle the current ID but
    -- this won't be used when there is a single partition.
    ,@ID        INT = 0;

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

-- Now insert the second ID with some numbers that are easy to add:
-- First rolling 12 months = 1 + 2 + ... + 12 = 13 * 6 = 78
-- Last rolling 12 months = 13 + 14 + ... + 24 = 37 * 6 = 222
INSERT INTO #RollingTotalsExample (ID, [Date], [Value])
SELECT 2, '2011-01-01',1
UNION ALL SELECT 2, '2011-02-01',2 UNION ALL SELECT 2, '2011-03-01',3
UNION ALL SELECT 2, '2011-04-01',4 UNION ALL SELECT 2, '2011-05-01',5
UNION ALL SELECT 2, '2011-06-01',6 UNION ALL SELECT 2, '2011-07-01',7
UNION ALL SELECT 2, '2011-08-01',8 UNION ALL SELECT 2, '2011-09-01',9
UNION ALL SELECT 2, '2011-10-01',10 UNION ALL SELECT 2, '2011-11-01',11
UNION ALL SELECT 2, '2011-12-01',12 UNION ALL SELECT 2, '2012-01-01',13
UNION ALL SELECT 2, '2012-02-01',14 UNION ALL SELECT 2, '2012-03-01',15
UNION ALL SELECT 2, '2012-04-01',16 UNION ALL SELECT 2, '2012-05-01',17
UNION ALL SELECT 2, '2012-06-01',18 UNION ALL SELECT 2, '2012-07-01',19
UNION ALL SELECT 2, '2012-08-01',20 UNION ALL SELECT 2, '2012-09-01',21
UNION ALL SELECT 2, '2012-10-01',22 UNION ALL SELECT 2, '2012-11-01',23
UNION ALL SELECT 2, '2012-12-01',24;

-- Reset the temp variables to initial values
SELECT @Lag1   = 0
    ,@Lag2     = 0
    ,@Lag3     = 0
    ,@Lag4     = 0
    ,@Lag5     = 0
    ,@Lag6     = 0
    ,@Lag7     = 0
    ,@Lag8     = 0
    ,@Lag9     = 0
    ,@Lag10    = 0
    ,@Lag11    = 0
    ,@Lag12    = 0
    ,@rt       = 0
    -- When you have multiple partitions, set @rn = 1
    ,@rn       = 1
    ,@ID       = 0;

UPDATE #RollingTotalsExample WITH(TABLOCKX)
-- All of the local variable assignments must specially handle the case when ID changes
SET @rt = CASE WHEN @ID = ID THEN @rt + Value - @Lag12 ELSE Value END
    -- The next assignment is also slightly different for the partitioned case
    ,@rn = CASE WHEN @ID = ID THEN @rn + 1 ELSE 1 END
    ,Rolling12Months = CASE WHEN @rn > 11 THEN @rt END
    ,@Lag12 = CASE WHEN @ID = ID THEN @Lag11 ELSE 0 END
    ,@Lag11 = CASE WHEN @ID = ID THEN @Lag10 ELSE 0 END
    ,@Lag10 = CASE WHEN @ID = ID THEN @Lag9 ELSE 0 END
    ,@Lag9 = CASE WHEN @ID = ID THEN @Lag8 ELSE 0 END
    ,@Lag8 = CASE WHEN @ID = ID THEN @Lag7 ELSE 0 END
    ,@Lag7 = CASE WHEN @ID = ID THEN @Lag6 ELSE 0 END
    ,@Lag6 = CASE WHEN @ID = ID THEN @Lag5 ELSE 0 END
    ,@Lag5 = CASE WHEN @ID = ID THEN @Lag4 ELSE 0 END
    ,@Lag4 = CASE WHEN @ID = ID THEN @Lag3 ELSE 0 END
    ,@Lag3 = CASE WHEN @ID = ID THEN @Lag2 ELSE 0 END
    ,@Lag2 = CASE WHEN @ID = ID THEN @Lag1 ELSE 0 END
    -- No change here
    ,@Lag1 = Value
    -- Now we keep track of the current (partition) ID
    ,@ID = ID
OPTION (MAXDOP 1);

SELECT * FROM #RollingTotalsExample;


GO
DROP TABLE #RollingTotalsExample;
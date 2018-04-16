select vendorid,
	CASE WHEN EmployeeID = 250 THEN PurchaseOrderID  is NULL END AS Emp250,
	CASE WHEN EmployeeID = 251 THEN PurchaseOrderID is null end AS Emp251,
	CASE WHEN EmployeeID = 252 THEN PurchaseOrderID is NULL END  AS Emp252,
	CASE WHEN EmployeeID = 253 THEN PurchaseOrderID is NULL END AS Emp253,
	CASE WHEN EmployeeID = 254 THEN PurchaseOrderID is NULL END AS Emp254
FROM
  PurchaseOrderHeader p
  WHERE
  p.EmployeeID BETWEEN 250 AND 254
GROUP BY
  VendorID;
  
  
  SELECT
  GROUP_CONCAT(
    CONCAT(
      ' MAX(IF(Property = ''',
      t.Property,
      ''', Value, NULL)) AS ',
      t.Property
    )
  ) INTO @PivotQuery
FROM
  (SELECT
     Property
   FROM
     ProductOld
   GROUP BY
     Property) t;

SET @PivotQuery = CONCAT('SELECT ProductID,', @PivotQuery, ' FROM ProductOld GROUP BY ProductID');


SELECT
  ProductID,
  MAX(IF(Property = 'Color', Value, NULL)) AS Color,
  MAX(IF(Property = 'Name', Value, NULL)) AS Name,
  MAX(IF(Property = 'ProductNumber', Value, NULL)) AS ProductNumber,
  MAX(IF(Property = 'Size', Value, NULL)) AS Size,
  MAX(IF(Property = 'SizeUnitMeasureCode', Value, NULL)) AS SizeUnitMeasureCode
FROM
  ProductOld
GROUP BY
  ProductID
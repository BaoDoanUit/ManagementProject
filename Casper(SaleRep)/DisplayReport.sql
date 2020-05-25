USE [db_aga]
GO
/****** Object:  StoredProcedure [dbo].[ReportMarket.DisplayStock]    Script Date: 4/8/2020 4:56:08 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- [dbo].[ReportMarket.DisplayStock] @fromDate='2020-03-01', @toDate='2020-03-31', @product='AV'
ALTER PROC [dbo].[ReportMarket.DisplayStock]
@fromDate DATE,
@toDate DATE,
@accountId INT = NULL,
@region VARCHAR(32) = NULL,
@product VARCHAR(8),
@userName VARCHAR(32) = NULL
AS
BEGIN
	------ OUTLET -------
	SELECT * 
	INTO #outlet 
	FROM Outlet AS o
	WHERE 
	(@region IS NULL OR o.Region = @region)
	AND (@accountId IS NULL OR o.ObjectId = @accountId)
		AND o.ShopCode NOT like '%demo%'
	AND o.ShopCode NOT like '%test%'
	
	--#################--
	
	-- PRODUCT --
	SELECT * 
	INTO #product
	FROM Product AS p
	WHERE p.Product = @product
	AND p.Brand = 3 
	AND p.[Deleted] = 0 
	----#########----
	
	--StockDisplay--
	SELECT tbl.* INTO #StockDisplay
	FROM(
		SELECT row_number() OVER (PARTITION BY sd.ShopId ORDER BY sd.ReportDate DESC,sd.EmployeeId) rowNum, 
		sd.ShopId, sd.ReportDate, sd.EmployeeId
		FROM StockDisplay sd
		WHERE sd.[Deleted]=0 
		AND sd.ReportDate BETWEEN @fromDate AND @toDate
		AND sd.Product = @product
		AND EXISTS (SELECT 1 FROM #outlet o WHERE o.ShopId = sd.ShopId) 
	)tbl
	WHERE tbl.rowNum = 1

	SELECT sd.* INTO #lastByShop
	FROM StockDisplay AS sd
	WHERE EXISTS (SELECT 1 
	              FROM #StockDisplay AS sd2 
	              WHERE sd2.EmployeeId = sd.EmployeeId
	              AND sd2.ShopId = sd.ShopId
	              AND sd2.ReportDate = sd.ReportDate)
	
	--##-----------
	
	--- TABLE ----
	DECLARE @Table TABLE (ShopId INT, pivotCol VARCHAR(20), [valueCol] INT)
	--------------
	
	------COLUMN PIVOT------
	DECLARE @colPivot NVARCHAR(MAX)
	
	
	SELECT CONCAT(p.Model,'_','STOCK') col , p.Model, 1 [index]
	INTO #tbpivotCol  
	FROM #product p
	
	UNION ALL 
	SELECT CONCAT(p.Model,'_','DISPLAY') col, p.Model, 0 [index]
	FROM #product p
	
	
	SELECT @colPivot = STUFF(
	(SELECT N', ' + QUOTENAME(p.col)
	 FROM #tbpivotCol AS p
	 ORDER BY  p.Model, [index]
	 FOR XML PATH(''),TYPE)
	.value('text()[1]','nvarchar(max)'),1,2,N'')
	
	PRINT @colPivot
	--####################--
	
	
	--------STOCK DISPLAY----------
	INSERT INTO @Table
	SELECT sd.ShopId, CONCAT(sd.Model,'_','DISPLAY') pivotColumn,
	 ISNULL(sd.Display,0) Qty 
	FROM #lastByShop AS sd
	
	UNION ALL
	SELECT sd.ShopId, CONCAT(sd.Model,'_','STOCK') pivotColumn,
	ISNULL(sd.Stock,0) Qty 
	FROM #lastByShop AS sd

	--#####################---	
	


	SELECT 
	o.*, t.*
	INTO #pivot
	FROM @Table t 
	OUTER APPLY (SELECT od.ObjectName Account, o2.ShopCode,
						 o2.ShopName, o2.[Address], o2.District,
						 o2.City Province, o2.Region, 'MT' [Channel], 
						 '' [State]
					FROM #outlet AS o2
					LEFT JOIN ObjectData AS od ON od.ObjectId = o2.ObjectId 
					WHERE o2.ShopId = t.ShopId
					) o
					
	           

	--#####################--
	----PIVOT-----
	DECLARE @sql NVARCHAR(MAX) 
	SET @sql =' SELECT
		[Account],[Region],[Channel],[Province],[ShopCode],[ShopName],'+@colPivot+'
		FROM 
		(
			Select * 
			from #pivot
		) as src
		PIVOT
		( 
		MAX([valueCol]) FOR pivotCol IN ('+@colPivot+ ') 
		) as pv
	'
	exec sp_executesql @sql
	
	--##########--
	
	--------DROP TABLE--------
	DROP TABLE #pivot
	DROP TABLE #outlet
	DROP TABLE #product
	DROP TABLE #tbpivotCol
	DROP TABLE #StockDisplay
	DROP TABLE #lastByShop
	-----#####################---
	
END


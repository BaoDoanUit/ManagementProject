USE [db_aga]
GO
/****** Object:  StoredProcedure [dbo].[ReportMarket.DisplayShare]    Script Date: 3/30/2020 11:39:09 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- [dbo].[ReportMarket.DisplayShare] @fromDate='2020-03-01', @toDate='2020-03-31', @product='AV'
ALTER PROC [dbo].[ReportMarket.DisplayShare]
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
	--#################--
	
	-- PRODUCT --
	SELECT * 
	INTO #product
	FROM Product AS p
	WHERE p.Product = @product
	----#########----
	
	--- TABLE ----
	DECLARE @Table TABLE (ShopId INT, pivotCol VARCHAR(20), [valueCol] INT)
	--------------
	
	------COLUMN PIVOT------
	DECLARE @colPivot NVARCHAR(MAX)
	
	SELECT DISTINCT od.ObjectName Competior, od.ObjectIndex
	INTO #proComp
	FROM #product p
	JOIN ObjectData AS od ON od.ObjectId = p.Brand
	UNION ALL
	SELECT 'OTHER', 10000
	

	
	
	SELECT @colPivot = STUFF(
	(SELECT N', ' + QUOTENAME(CONCAT(CONVERT(varchar(2), c.[Month]),'|',pc.Competior))
	FROM Calendars AS c
	OUTER APPLY(
   	SELECT Competior , ObjectIndex
   		FROM #proComp
	) pc
	WHERE c.[Date] BETWEEN @fromDate  AND @toDate
	GROUP BY c.[Month], Competior, pc.ObjectIndex
	ORDER BY c.[Month] ASC, pc.ObjectIndex ASC
		FOR XML PATH(''),TYPE)
	.value('text()[1]','nvarchar(max)'),1,2,N'')
	
	PRINT @colPivot
	--####################--
	
	--------STOCK DISPLAY----------
	INSERT INTO @Table
	SELECT sd.ShopId, CONCAT(CONVERT(varchar(2), c.[Month]),'|','Casper') pivotColumn,
	 SUM(IIF(sd.Display = -1, 0, sd.Display)) Qty 
	FROM StockDisplay AS sd
	JOIN Calendars AS c ON c.[Date] = sd.ReportDate
	WHERE 
	sd.ReportDate BETWEEN @fromDate AND @toDate
	AND sd.Product = @product
	AND EXISTS (SELECT 1 FROM #outlet o WHERE o.ShopId = sd.ShopId) 
	GROUP BY  sd.ShopId, c.[Month]
	UNION ALL
	SELECT c.ShopId, 
	CONCAT(CONVERT(VARCHAR(2), ca.[Month]),'|',ISNULL(od.ObjectName,'OTHER')) pivotColumn, 
	SUM(IIF(c.Quantity = -1, 0, c.Quantity)) Qty
	FROM Compertitor AS c
	LEFT JOIN ObjectData AS od ON od.ObjectId = c.Brand
	JOIN Calendars AS ca ON ca.[Date] = c.ReportDate
	WHERE c.Product = @product
	GROUP BY c.ShopId, od.ObjectName, ca.[Month]

	
	--#####################---	
	
	--- PC PER SHOP ---
	
	SELECT tbl.ShopId, COUNT(tbl.EmployeeId) [QtyPC] INTO #pcQty
	FROM
	(
	SELECT o.ShopId, a.EmployeeId 
	FROM #outlet AS o
	JOIN Attendance AS a ON a.ShopId = o.ShopId
	JOIN Employee AS e ON a.EmployeeId = e.EmployeeId
	WHERE a.AttendantDate BETWEEN @fromDate AND @toDate
	AND e.Position = 'PC'
	GROUP BY o.ShopId, a.EmployeeId
	)tbl
	GROUP BY tbl.ShopId
	--- ########## -----

	SELECT 
	o.*, t.*, pc.[QtyPC]
	INTO #pivot
	FROM @Table t
	LEFT JOIN #pcQty pc ON pc.ShopId = t.ShopId  
	OUTER APPLY (SELECT od.ObjectName Account, o2.ShopCode,
						 o2.ShopName, o2.[Address], o2.District,
						 o2.City Province, o2.Region, 'MT' [Channel]
					FROM #outlet AS o2
					LEFT JOIN ObjectData AS od ON od.ObjectId = o2.ObjectId 
					WHERE o2.ShopId = t.ShopId
					) o
					
	           
		
				 
	--#####################--
	----PIVOT-----
	DECLARE @sql NVARCHAR(MAX) 
	SET @sql ='
	SELECT ROW_NUMBER() OVER (ORDER BY ShopCode ) rowNum
 	 ,[Region], [Channel],[Province],[District], [ShopCode],[ShopName],[QtyPC],
	'+@colPivot+'
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
	DROP TABLE #proComp
	DROP TABLE #pcQty
	--#####################---
	
END


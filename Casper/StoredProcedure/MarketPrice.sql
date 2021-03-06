USE [db_aga]
GO
/****** Object:  StoredProcedure [dbo].[ReportMarket.DisplayShare]    Script Date: 4/4/2020 11:23:55 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- [dbo].[ReportMarket.MarketPrice] @fromDate='2020-03-01', @toDate='2020-03-31', @product='AV'
ALTER PROC [dbo].[ReportMarket.MarketPrice]
@fromDate DATE,
@toDate DATE,
@accountId INT = NULL,
@region VARCHAR(32) = NULL,
@product VARCHAR(8),
@userName VARCHAR(32) = NULL
AS
BEGIN
	-- PRODUCT--
	SELECT p.*
	INTO #product
	FROM Product AS p 
	WHERE @Product IS NULL OR p.Product = @Product
	
		
	------ OUTLET -------
	SELECT * 
	INTO #outlet 
	FROM Outlet AS o
	WHERE 
	(@region IS NULL OR o.Region = @region)
	AND (@accountId IS NULL OR o.ObjectId = @accountId)
	AND  ISNULL(o.ObjectId,0) <> 0
	--#################--
	
	--- TABLE ---
		DECLARE @Table TABLE (Brand NVARCHAR(32), ProductId INT, pivotCol VARCHAR(64), [valueCol] NVARCHAR(64))
		DECLARE @tablepivotCol TABLE([col] NVARCHAR(128),[colName] VARCHAR(128), [index] INT)
		
	-----------
	------COLUMN PIVOT------
	INSERT INTO @tablepivotCol 
	SELECT CONCAT(ISNULL(od.ObjectName,'Other'),'_','NetPrice') col,od.ObjectIndex, 0 [index]
	FROM #outlet AS o
	CROSS APPLY(SELECT od.ObjectName, od.ObjectIndex
	              FROM ObjectData AS od WHERE od.ObjectId = o.ObjectId AND od.ObjectType = 'account') od
	GROUP BY od.ObjectIndex, od.ObjectName
	ORDER BY od.ObjectIndex
	
	INSERT INTO @tablepivotCol 
	SELECT CONCAT(ISNULL(od.ObjectName,'Other'),'_','PromotionName') col,od.ObjectIndex, 1 [index]
	FROM #outlet AS o
	CROSS APPLY(SELECT od.ObjectName, od.ObjectIndex
	              FROM ObjectData AS od WHERE od.ObjectId = o.ObjectId AND od.ObjectType = 'account') od
	GROUP BY od.ObjectIndex, od.ObjectName
	ORDER BY od.ObjectIndex
	
	INSERT INTO @tablepivotCol 
	SELECT CONCAT(ISNULL(od.ObjectName,'Other'),'_','PromotionPrice') col,od.ObjectIndex, 2 [index]
	FROM #outlet AS o
	CROSS APPLY(SELECT od.ObjectName, od.ObjectIndex
	              FROM ObjectData AS od WHERE od.ObjectId = o.ObjectId AND od.ObjectType = 'account') od
	GROUP BY od.ObjectIndex, od.ObjectName
	ORDER BY od.ObjectIndex
	
	INSERT INTO @tablepivotCol 
	SELECT CONCAT(ISNULL(od.ObjectName,'Other'),'_','End') col,od.ObjectIndex, 3 [index]
	FROM #outlet AS o
	CROSS APPLY(SELECT od.ObjectName, od.ObjectIndex
	              FROM ObjectData AS od WHERE od.ObjectId = o.ObjectId AND od.ObjectType = 'account') od
	GROUP BY od.ObjectIndex, od.ObjectName
	ORDER BY od.ObjectIndex
	

	

	DECLARE @colPivot NVARCHAR(MAX)
	
	SELECT @colPivot = STUFF(
	(SELECT N', ' + QUOTENAME([col])
	 FROM @tablepivotCol 
	 ORDER BY [colName], [index]
	 FOR XML PATH(''),TYPE)
	.value('text()[1]','nvarchar(max)'),1,2,N'')
	
	PRINT @colPivot
	--####################--
	
	----MASTER DATA----
	SELECT pr.Id, pr.EmployeeId, pr.ShopId, pr.ReportDate, pr.ProductId, pr.NetPrice, od.ObjectName Account, od2.ObjectName Brand
	INTO #masterPriceReport
	FROM PriceReports AS pr
	JOIN #product AS p ON pr.ProductId = p.ProductId
	JOIN #outlet AS o ON pr.ShopId = o.ShopId
	JOIN ObjectData AS od ON od.ObjectId = o.ObjectId
	JOIN ObjectData AS od2 ON od2.ObjectId = p.Brand
	WHERE pr.ReportDate BETWEEN @fromDate AND @toDate
	---##-------------
	-- LAST UPDATE BY SHOP ---
	SELECT tbl.* 
	INTO #lastByShop
    FROM(
    	SELECT *,   ROW_NUMBER() OVER 
    	(PARTITION BY  ShopId, ProductId  ORDER BY ReportDate DESC, ProductId) rowNum
    	FROM #masterPriceReport
    ) AS tbl
	WHERE tbl.rowNum=1 
	AND ISNULL(tbl.NetPrice,0) <> 0 
	--###--------------
	-- COUNT
	SELECT tbl.ProductId ,tbl.ObjectName, NetPrice
	INTO #count
	FROM(
		SELECT lst.ProductId, od.ObjectName, NetPrice
		FROM #lastByShop lst
		JOIN #outlet AS o ON lst.ShopId = o.ShopId
		JOIN ObjectData AS od ON od.ObjectId = o.ObjectId 
		GROUP BY lst.ProductId, od.ObjectName, lst.NetPrice
	)tbl
	
	SELECT p.ProductId ,p.ObjectName, NetPrice,
	ROW_NUMBER() OVER (PARTITION BY  
		 ProductId, NetPrice  ORDER BY ProductId  DESC) dem INTO #count1
	from #count p
	GROUP BY  p.ProductId ,p.ObjectName, p.NetPrice
	
	SELECT  p.ProductId ,p.ObjectName, MAX(dem) dem INTO #count2
	FROM #count1 p	
	GROUP BY  p.ProductId ,p.ObjectName
	
	SELECT tbl.*, tb.NetPrice 
	INTO #count3 
	FROM #count2 tbl
	OUTER APPLY (SELECT TOP 1 pp.NetPrice 
	             FROM #count1 pp 
	             WHERE pp.dem = tbl.dem 
	             AND pp.ProductId = tbl.ProductId 
	             AND pp.ObjectName = tbl.ObjectName
	             ORDER BY pp.dem 
	)tb
	
	
	SELECT ProductId, ObjectName, MIN(NetPrice) NetPrice
	INTO #count4
	FROM #count3
	GROUP BY ProductId, ObjectName
	---END COUNT---
	
	--NET PRICE--
	SELECT isnull(od.ObjectName,'Other') Brand, pr.ObjectName Account, pr.ProductId, pr.NetPrice INTO #netprice
	FROM #count4 AS pr
	JOIN #product AS p ON pr.ProductId = p.ProductId
	JOIN ObjectData AS od ON od.ObjectId = p.Brand
	---#####--
	
	
	
	--- PROMOTION ----
	SELECT p.Brand,p.Account, p.ProductId, p.ReportDate, prg.GiftName, prg.GiftPrice INTO #promotionReport
	FROM PriceReportGifts AS prg
	CROSS APPLY (SELECT pr.ProductId,pr.Account, pr.Brand,pr.ReportDate 
	             FROM #masterPriceReport AS pr WHERE prg.PriceId =  pr.Id) p
	
	SELECT Brand, Account, ProductId, GiftName, GiftPrice INTO #promotion
    FROM(
    	SELECT *,   ROW_NUMBER() OVER 
    	(PARTITION BY Brand, Account, ProductId  ORDER BY ReportDate DESC, ProductId) rowNum
    	FROM #promotionReport
    ) AS tbl
	WHERE tbl.rowNum=1 
	AND ISNULL(tbl.GiftPrice,0) <> 0 
	
	---- ############## -----
	
	--TABLE BEFORE PIVOT---
	INSERT INTO @Table
	SELECT Brand, productId, CONCAT(Account,'_','NetPrice') pivotCol, FORMAT(NetPrice, N'#.##')
	FROM #netPrice
	
	INSERT INTO @Table
	SELECT Brand, productId, CONCAT(Account,'_','PromotionName') pivotCol, GiftName
	FROM #promotion
	
	INSERT INTO @Table
	SELECT Brand, productId, CONCAT(Account,'_','PromotionPrice') pivotCol,FORMAT(GiftPrice, N'#.##')
	FROM #promotion
	
	--------#######------
	
	SELECT t.*,p.Product [Cat], p.[Type],p.[Range] [SubCat],p.Capacity, p.Model, lp.Price ListedPrice, '' MinPrice
	INTO #pivot
	FROM @Table t
	JOIN #product AS p ON p.ProductId = t.ProductId
	OUTER APPLY(SELECT lp.Price
	              FROM ListedPrice AS lp WHERE lp.ProductId = t.ProductId) lp
	
		
	
	DECLARE @sql NVARCHAR(MAX) 
	SET @sql ='
	SELECT [Cat], [Type], [SubCat] , [Capacity], [Brand], [Model], [ListedPrice],[MinPrice],
	'+@colPivot+'
	FROM 
	(
		Select * 
		from #pivot
	) as src
	PIVOT
	( 
		MIN([valueCol]) FOR pivotCol IN ('+@colPivot+ ') 
	) as pv
	'
	exec sp_executesql @sql
	
	---DROP TABLE--
	DROP TABLE #product
	DROP TABLE #outlet
	DROP TABLE #netPrice
	DROP TABLE #promotionReport
	DROP TABLE #pivot
	DROP TABLE #promotion
	DROP TABLE #count
	DROP TABLE #count1
	DROP TABLE #count2
	DROP TABLE #count3
	DROP TABLE #count4
	-----######----
END




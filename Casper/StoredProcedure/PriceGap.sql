USE [db_aga]
GO
/****** Object:  StoredProcedure [dbo].[ReportMarket.DisplayStock]    Script Date: 4/3/2020 3:14:29 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- [dbo].[ReportMarket.PriceGap] @fromDate='2020-03-01', @toDate='2020-03-31', @product='RAC'
ALTER PROC [dbo].[ReportMarket.PriceGap]
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
	
	--- PriceReports ---
	SELECT pr.*, o.ShopName INTO #priceReport
	FROM PriceReports AS pr
	JOIN #outlet AS o ON o.ShopId = pr.ShopId
	JOIN Product AS p ON p.ProductId = pr.ProductId
	WHERE pr.ReportDate BETWEEN @fromDate AND @toDate
	--#####----------------
	
	--- TABLE ----
	DECLARE @Table TABLE (ProductId INT, pivotCol VARCHAR(128), [valueCol] INT)
	
	DECLARE @tablepivotCol TABLE([col] NVARCHAR(128),[colName] VARCHAR(128), [index] INT)
	--------------
	
	------COLUMN PIVOT------

	
	INSERT INTO @tablepivotCol 
	SELECT CONCAT(o.ShopName,'_','SellingPrice') col, o.ShopName, 0 [index]
	FROM #outlet o
	
	INSERT INTO @tablepivotCol 
	SELECT CONCAT(o.ShopName,'_','PromotionValue') col,  o.ShopName, 1 [index]
	FROM #outlet o
	
	INSERT INTO @tablepivotCol 
	SELECT CONCAT(o.ShopName,'_','NetPrice') col, o.ShopName, 2 [index]
	FROM #outlet o
	
	INSERT INTO @tablepivotCol 
	SELECT CONCAT(o.ShopName,'_','Gap') col, o.ShopName, 3 [index]
	FROM #outlet o
	
	DECLARE @colPivot NVARCHAR(MAX)
	
	SELECT @colPivot = STUFF(
	(SELECT N', ' + QUOTENAME([col])
	 FROM @tablepivotCol 
	 ORDER BY [colName], [index]
	 FOR XML PATH(''),TYPE)
	.value('text()[1]','nvarchar(max)'),1,2,N'')
	
	PRINT @colPivot
	--####################--

	
	--------Selling Price----------
	INSERT INTO @Table
	SELECT pr.ProductId, CONCAT(pr.ShopName,'_','SellingPrice') pivotColumn, pr.MarketPrice 
	FROM #priceReport AS pr
	---##################----
	
	-------- Promotion Value -------
	INSERT INTO @Table
	SELECT pr.ProductId, CONCAT(pr.ShopName,'_','PromotionValue') pivotColumn,  ISNULL(prg.GiftPrice,0)
	FROM #priceReport AS pr
	OUTER APPLY(SELECT prg.GiftPrice
	              FROM PriceReportGifts AS prg where prg.PriceId = pr.Id) prg
	--#####################---	
	
	----- Net Price -------
	INSERT INTO @Table
	SELECT pr.ProductId, CONCAT(pr.ShopName,'_','NetPrice') pivotColumn, pr.NetPrice 
	FROM #priceReport AS pr
	-----############-----
	
	


	SELECT 
	p.Product, p.Model,lp.Price, t.*
	INTO #pivot
	FROM @Table t
	JOIN #product AS p ON p.ProductId = t.ProductId 
	OUTER APPLY ( SELECT lp.Price
	                FROM ListedPrice AS lp WHERE lp.ProductId = t.ProductId) lp
	
					
	           

	--#####################--
	----PIVOT-----
	DECLARE @sql NVARCHAR(MAX) 
	SET @sql =' SELECT 
		ROW_NUMBER() OVER (ORDER BY  [productId] ) No,
		[Product],[Model],[Price],'+@colPivot+'
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
	DROP TABLE #priceReport
	-----#####################---
	
END


USE [db_aga]
GO
/****** Object:  StoredProcedure [dbo].[Report_TrackingPC]    Script Date: 4/6/2020 11:04:45 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- [dbo].[ReportMarket.RawData] '2020-03-01', '2020-03-31', @product='AV'
ALTER PROC [dbo].[ReportMarket.RawData]
@fromDate DATE,
@toDate DATE,
@accountId INT = NULL,
@region VARCHAR(32) = NULL,
@product VARCHAR(8) = NULL,
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
	
	------ PRODUCT ------
	SELECT * 
	INTO #product
	FROM Product AS p
	WHERE (@product IS NULL OR p.Product = @product) AND p.Brand=3
	
	--#################--

	
	 
	--------SELL OUT----------
	
	SELECT so.EmployeeId, so.ShopId,so.ProductId, so.SaleDate, so.CusName,so.CusPhone, so.CussAdd,
	IIF(so.Quantity = -1, 0,so.Quantity) Qty, so.Price SellingPrice
	INTO #SaleOut
	FROM SaleOut AS so  
	JOIN #outlet AS o ON o.ShopId = so.ShopId
	JOIN #product AS p ON p.ProductId = so.ProductId
	WHERE so.SaleDate BETWEEN @fromDate AND @toDate	
	--#####################---	

	
	SELECT ROW_NUMBER() OVER (ORDER BY o.Region) rowNum,
	o.Region, [Account] ,o.ShopCode, o.ShopName,
	o.[Address],o.District, o.Province, [Brand], [Type], [SubCat], [Model], [Capacity],
	so.Qty [Quantity], [ListedPrice], [SellingPrice] , so.CusName,so.CusPhone, so.CussAdd,
	[PC Name], 1 [PC User], [PC SUPERVISOR], so.SaleDate, [Week]
	FROM #SaleOut so
	OUTER APPLY (
		SELECT od.ObjectName Account, o2.ShopCode, o2.ShopName, o2.[Address], o2.District ,o2.City Province, o2.Region
	    FROM #outlet AS o2
		JOIN ObjectData AS od ON od.ObjectId = o2.ObjectId 
	    WHERE o2.ShopId = so.ShopId
	) o
	OUTER APPLY(SELECT p.[Type], p.[Range] [SubCat], od.ObjectName Brand, p.Model, p.Capacity
	              FROM #product AS p 
	              JOIN ObjectData AS od ON od.ObjectId = p.Brand
	            WHERE p.ProductId = so.ProductId
	) p
	 OUTER APPLY(SELECT TOP 1 lp.Price [ListedPrice]
	               FROM ListedPrice AS lp 
	             WHERE lp.ProductId = so.ProductId
	             ORDER BY lp.ActiveDate DESC
	 ) lp
	 OUTER APPLY ( SELECT e.EmployeeName [PC Name], e2.EmployeeName [PC SUPERVISOR]
	               FROM Employee AS e 
	               JOIN Employee AS e2 ON e2.EmployeeId =e.ParentId
	               WHERE so.EmployeeId = e.EmployeeId
	 ) e
	OUTER APPLY(SELECT c.WeekByYear [Week]
	              FROM Calendars AS c WHERE c.[Date] = so.SaleDate)	c
				 
	--#####################--
	
	
	
	
	--------DROP TABLE--------
	DROP TABLE #SaleOut
	DROP TABLE #outlet
	DROP TABLE #product
	--#####################---
	
END



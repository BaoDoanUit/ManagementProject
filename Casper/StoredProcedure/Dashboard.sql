USE [db_aga]
GO
/****** Object:  StoredProcedure [dbo].[Report_TrackingPC]    Script Date: 4/6/2020 11:04:45 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

--  [dbo].[ReportMarket.Dashboard] @fromDate='2020-03-01', @toDate='2020-03-31', @userName='admin',@product ='AV'
ALTER PROC [dbo].[ReportMarket.Dashboard]
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
	
	--- EMPLOYEE ---
	DECLARE @empId INT
	SELECT @empId = e.EmployeeId  FROM Employee AS e
	WHERE e.UserName = @userName

	
	SELECT * INTO #employee
	FROM Employee AS e
	WHERE EXISTS (SELECT 1 FROM dbo.fnGetChild(@empId) AS fgc WHERE fgc.EmployeeId = e.EmployeeId)
	--- ######### ----
	--PRODUCT----------
	SELECT * INTO #product
	FROM Product AS p
	WHERE p.Product = @product 
	--##---------------
	
	--PRODUCT  CASP----
	SELECT * INTO #productCasp
	FROM Product AS p
	WHERE p.Product = @product AND p.Brand =3
	--##-----------
	
	---TABLE[0] Display Stock by Model
	SELECT pc.Model, d.Display, '' perD, s.Stock,'' perS, o.ShopQty
	FROM #productCasp AS pc
	OUTER APPLY ( SELECT COUNT(DISTINCT sd.ShopId) Display
	                FROM StockDisplay AS sd 
	              WHERE sd.Model = pc.Model
	              AND sd.ReportDate BETWEEN @fromDate AND @toDate
	              AND sd.Display > 0
	) d
	OUTER APPLY ( SELECT COUNT(DISTINCT sd.ShopId) Stock
	                FROM StockDisplay AS sd 
	              WHERE sd.Model = pc.Model
	              AND sd.ReportDate BETWEEN @fromDate AND @toDate
	              AND sd.Stock > 0
	) s
	OUTER APPLY (SELECT COUNT(o.ShopId) ShopQty FROM #outlet AS o) o
		
	--##-------------------------------
	
	---TABLE[0] Display Stock by Chanel
	
	--COLUM PIVOT--
	DECLARE @colPivot NVARCHAR(MAX)
	
	SELECT @colPivot = STUFF(
	(SELECT N', ' + QUOTENAME(c.[Date])
	FROM Calendars AS c
	WHERE 
	c.[Date] BETWEEN @fromDate AND @toDate
	 ORDER BY c.[Date]
	 FOR XML PATH(''),TYPE)
	.value('text()[1]','nvarchar(max)'),1,2,N'')
	
	PRINT @colPivot
	
	----###--------

	
	
	--PIVOT---
	
	DECLARE @sql NVARCHAR(MAX) 
	SET @sql ='
	SELECT [ShopName],[EmployeeName],
	'+@colPivot+'
	FROM 
	(
		Select * 
		from #pivot
	) as src
	PIVOT
	( 
		MAX([ShiftType]) FOR [WorkingDate] IN ('+@colPivot+ ') 
	) as pv
	'
	--exec sp_executesql @sql
	--##------------
	
	--------DROP TABLE--------
--	DROP TABLE #pivot
	DROP TABLE #outlet
	DROP TABLE #employee
	DROP TABLE #product
	DROP TABLE #productCasp
	--#####################---
	
END



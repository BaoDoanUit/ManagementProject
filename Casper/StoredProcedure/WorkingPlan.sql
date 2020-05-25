USE [db_aga]
GO
/****** Object:  StoredProcedure [dbo].[Report_TrackingPC]    Script Date: 4/6/2020 11:04:45 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- [dbo].[ReportMarket.WorkingPlan] @fromDate='2020-03-01', @toDate='2020-03-31', @userName='admin'
ALTER PROC [dbo].[ReportMarket.WorkingPlan]
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

	--WORKING PLAN-
	
	SELECT e.EmployeeName, o.ShopName, wp.WorkingDate , ISNULL(wp.[ShiftType],ts.ShiftName) [ShiftType] INTO #pivot
	FROM WorkingPlan AS wp
	JOIN #outlet AS o ON o.ShopId = wp.ShopId
	JOIN #employee AS e ON e.EmployeeId = wp.EmployeeId
	JOIN TimeShift AS ts ON ts.Id = wp.ShiftId
	WHERE wp.WorkingDate BETWEEN @fromDate AND @toDate
	--#####################--
	

	
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
	exec sp_executesql @sql
	--##------------
	
	--------DROP TABLE--------
	DROP TABLE #pivot
	DROP TABLE #outlet
	DROP TABLE #employee
	--#####################---
	
END



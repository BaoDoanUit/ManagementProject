
INSERT INTO Audit
(
	-- Id -- this column value is auto-generated
	OutletId,
	EmployeeId,
	AuditStatus,
	WorkingDate,
	Note,
	Create_at,
	Update_at,
	Isdelete
)
SELECT a.ShopId, a.EmployeeId,1,a.WorkingDate,'',GETDATE(),GETDATE(),0
FROM Attendances AS a
WHERE a.WorkingDate > '2020-04-10' AND
NOT EXISTS (SELECT 1 FROM Audit AS a2 WHERE a2.EmployeeId = a.EmployeeId 
						AND a2.OutletId = a.ShopId
					AND a.WorkingDate = a2.WorkingDate)



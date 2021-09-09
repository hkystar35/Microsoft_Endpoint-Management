SELECT
one.Computer1Name AS [Computer 1 Name], 
one.Computer1Display AS [Display Name], 
one.ProductVersion0, two.Computer2Name AS [Computer 2 Name],
two.Computer2Display AS [Display Name],
two.ProductVersion0 
FROM 
(SELECT IS1.ProductName0 AS Computer1Display, 
v_R_System.Netbios_Name0 AS Computer1Name,
 IS1.ProductVersion0, IS1.InstallDate0 
 FROM v_GS_INSTALLED_SOFTWARE IS1 
 INNER JOIN v_R_System ON IS1.ResourceID = v_R_System.ResourceID 
 WHERE (v_R_System.Netbios_Name0 = 'AILEENREYES') AND (IS1.ProductName0 IS NOT NULL)) 
 AS one 
 FULL OUTER JOIN 
 
 (SELECT IS2.ProductName0 AS Computer2Display, 
 v_R_System_1.Netbios_Name0 AS Computer2Name,  
 IS2.ProductVersion0, 
 IS2.InstallDate0  
 FROM v_GS_INSTALLED_SOFTWARE IS2 INNER JOIN  v_R_System AS v_R_System_1 
 ON IS2.ResourceID = v_R_System_1.ResourceID 
 WHERE (v_R_System_1.Netbios_Name0 = 'TaylorLaRochell') AND (IS2.ProductName0 IS NOT NULL)) 
 AS two 
 
 ON one.Computer1Display = two.Computer2Display 
 
 WHERE '[Computer 1 Name]' IS NOT NULL
 or '[Computer 2 Name]' IS NOT NULL

 ORDER BY [Computer 1 Name], [Computer 2 Name]
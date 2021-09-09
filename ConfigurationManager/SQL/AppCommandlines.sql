SELECT Program.PackageID,
Package.Name 'Package Name',
Program.ProgramName 'Program Name',
Program.CommandLine,
Program.Comment,
Program.Description,
Package.PkgSourcePath
FROM [v_Program] as Program
LEFT JOIN v_Package as Package on Package.PackageID = Program.PackageID
Order by Program.PackageID
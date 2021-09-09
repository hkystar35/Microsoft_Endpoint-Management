#Styles
<#
[Enum]::GetNames([Microsoft.Office.Interop.Word.WdBuiltinStyle]) | ForEach {
    [pscustomobject]@{Style=$_}
} | Format-Wide -Property Style -Column 4
#>

$User = $env:USERNAME
$CreatedBy = Get-aduser -Filter {SamAccountName -eq $User} -Properties Name | Select Name

<# Provide Creds
Function Invoke-SQL ( $DataSource, $Database , $sqlCommand) {
        $UserID="<user>"
        $pwd = "<password>"
        $connectionString = "Data Source=$dataSource; " + "Initial Catalog=$database; " + "User ID=$userID; " + "Password=$pwd"
        $connection = new-object system.data.SqlClient.SQLConnection($connectionString)
        $command = new-object system.data.sqlclient.sqlcommand($sqlCommand,$connection)
        $connection.Open()
      
        $adapter = New-Object System.Data.sqlclient.sqlDataAdapter $command
        $dataset = New-Object System.Data.DataSet
        $adapter.Fill($dataSet) | Out-Null

        $connection.Close()
        $dataSet.Tables
                    }
#>

# Uses current PowerShell user creds
Function Invoke-SQL {
        param (
                [string] $dataSource = "ah-sccm-01.paylocity.com",
                [string] $database = "CM_PAY",
                [string] $sqlCommand = $(throw "Please specify a query.")
              )

       $connectionString = "Data Source=$dataSource; " +
            "Integrated Security=SSPI; " +
            "Initial Catalog=$database"

       $connection = new-object system.data.SqlClient.SQLConnection($connectionString)
        $command = new-object system.data.sqlclient.sqlcommand($sqlCommand,$connection)
        $connection.Open()

       $adapter = New-Object System.Data.sqlclient.sqlDataAdapter $command
        $dataset = New-Object System.Data.DataSet
        $adapter.Fill($dataSet) | Out-Null

       $connection.Close()
        $dataSet.Tables
                    }
#>

$Deployments = (Invoke-SQL "ah-sccm-01.paylocity.com" "CM_PAY" "
Select
Case
When FeatureType = 1 Then 'Application'
When FeatureType = 2 Then 'Package'
End [DeploymentType],
SoftwareName, CollectionName from v_deploymentsummary
Where FeatureType in ('1','2')
Order by SoftwareName
") | Out-Gridview -OutputMode Single


$SoftQuery = (Invoke-SQL "ah-sccm-01.paylocity.com" "CM_PAY" "
Create Table #FNAPP
(
Assign int,
Policy int,
AppCI int,
DTCI int,
DTModelID int,
AppName varchar(200),
Collection varchar(200)
)
Insert Into #FNApp (Assign, Policy, AppCI, DTCI, DTModelID, AppName, Collection)
Select Distinct Assignmentid, PolicyModelID, APPCI, DTCI, DTModelID, AppName, CollectionName from fn_AppDeploymentAssetDetails(1033)

;WITH XMLNAMESPACES (DEFAULT 'http://schemas.microsoft.com/SystemCenterConfigurationManager/2009/AppMgmtDigest')

Select
Case
When FeatureType = 1 Then 'Application'
When FeatureType = 2 Then 'Package'
End [Type],
SoftwareName, VDS.CollectionName, VDS.PackageID,

Case
When FeatureType = '1' Then CAST(VDS.AssignmentID as varchar)
When FeatureType = '2' Then CAST(OfferID as varchar)
End [DeploymentID],
Case
When FeatureType = 1 Then 'N/A'
When FeatureType = 2 Then VDS.ProgramName
End [ProgramName],
DeploymentTime,
Case
When FeatureType = 1 Then ContentSource
When FeatureType = 2 Then PkgSourcePath
End [SourceFiles],
Case
When FeatureType = 1 Then Right(AppUniqueID, Charindex('/', Reverse(AppUniqueID)) -1)
When FeatureType = 2 Then SourceVersion
End [Version],
Case
When SDMPackageDigest.value('(/AppMgmtDigest/DeploymentType/Installer/InstallAction/Args/Arg/@Name) [1]', 'nvarchar(MAX)') = 'InstallCommandLine' Then SDMPackageDigest.value('(/AppMgmtDigest/DeploymentType/Installer/InstallAction/Args/Arg) [1]', 'nvarchar(MAX)')
When FeatureType = 2 Then CommandLine
End [CommandLine]

from v_DeploymentSummary VDS
Left Join v_Package VP on VDS.PackageID = VP.PackageID
Left Join v_content VC on VDS.packageid = VC.PkgID and VC.contentsource is not null
Left Join vAppstatsummary VAS on VAS.DisplayName = VDS.SoftwareName
Left Join v_program VPro on VPRO.packageid = VDS.PackageID and VPro.programname <> '*'
Left Join vCIAllContents VCIA on VCIA.Content_ID = VC.Content_ID
Left Join v_ConfigurationItems VCI on VCI.ci_id = VCIA.ci_id
Where Softwarename = '$($Deployments.SoftwareName)' and CollectionName = '$($Deployments.CollectionName)'

Drop Table #FNApp
")

$Source = $($SoftQuery.SourceFiles)
$Files = get-childitem -Path "$($Softquery.sourceFiles)"

Foreach ($File in $Files | ? {$_.name -like '*.ps1'}){
    If ($Softquery.commandline -match "$($File.name)"){
    $ScriptContents = Get-content -Path "$($SoftQuery.sourcefiles)\$($File.name)"
    }
}

#Add-Type -AssemblyName Microsoft.Office.Interop.Word
$Word = New-Object -ComObject Word.Application
$Word.Visible = $False
$Document = $Word.Documents.Add()
$Selection = $Word.Selection

$Selection.Style = 'Title'
$Selection.Font.Bold = 1
$Selection.font.Size = 24
$Selection.TypeText("$($SoftQuery.SoftwareName)")
$Selection.ParagraphFormat.Alignment = 1
$Selection.TypeParagraph()

$Selection.Style = 'SubTitle'
$Selection.Font.Bold = 1
$Selection.font.Size = 18
$Selection.TypeText("$($SoftQuery.Type) Deployment")
$Selection.ParagraphFormat.Alignment = 1
$Selection.TypeParagraph()

$Selection.Style = 'SubTitle'
$Selection.Font.Bold = 1
$Selection.font.Size = 10
$Selection.TypeText("Document created on: $(get-date)")
$Selection.ParagraphFormat.Alignment = 1
$Selection.TypeParagraph()

$Selection.Style = 'SubTitle'
$Selection.Font.Bold = 1
$Selection.font.Size = 10
$Selection.TypeText("Document created by: $($CreatedBy.name)")
$Selection.ParagraphFormat.Alignment = 1
$Selection.TypeParagraph()

If ($SoftQuery.programname -ne 'N/A'){
$Selection.Style = 'Normal'
$Selection.Font.Bold = 0
$Selection.font.Size = 12
$Selection.TypeText("Program Name: $($SoftQuery.ProgramName)")
$Selection.ParagraphFormat.Alignment = 0
$Selection.TypeParagraph()
}

$Selection.Style = 'Normal'
$Selection.Font.Bold = 0
$Selection.font.Size = 12
$Selection.TypeText("Package ID: $($SoftQuery.PackageID)")
$Selection.ParagraphFormat.Alignment = 0
$Selection.TypeParagraph()

$Selection.Style = 'Normal'
$Selection.Font.Bold = 0
$Selection.font.Size = 12
$Selection.TypeText("Version: $($SoftQuery.Version)")
$Selection.ParagraphFormat.Alignment = 0
$Selection.TypeParagraph()

$Selection.Style = 'Normal'
$Selection.Font.Bold = 0
$Selection.font.Size = 12
$Selection.TypeText("Deployed to Collection: $($SoftQuery.CollectionName)")
$Selection.ParagraphFormat.Alignment = 0
$Selection.TypeParagraph()

$Selection.Style = 'Normal'
$Selection.Font.Bold = 0
$Selection.font.Size = 12
$Selection.TypeText("Deployment ID: $($SoftQuery.DeploymentID)")
$Selection.ParagraphFormat.Alignment = 0
$Selection.TypeParagraph()

$Selection.Style = 'Normal'
$Selection.Font.Bold = 0
$Selection.font.Size = 12
$Selection.TypeText("Deployment Start Time: $($SoftQuery.DeploymentTime)")
$Selection.ParagraphFormat.Alignment = 0
$Selection.TypeParagraph()

$Selection.Style = 'Normal'
$Selection.Font.Bold = 0
$Selection.font.Size = 12
$Selection.TypeText("Source File Location: $Source")
$Selection.ParagraphFormat.Alignment = 0
$Selection.TypeParagraph()

$Selection.Style = 'Normal'
$Selection.Font.Bold = 0
$Selection.font.Size = 12
$Selection.TypeText("Command Line: $($SoftQuery.CommandLine)")
$Selection.ParagraphFormat.Alignment = 0
$Selection.TypeParagraph()

If ($ScriptContents){
$Selection.Style = 'Normal'
$Selection.Font.Bold = 0
$Selection.font.Size = 12
$Selection.TypeText("Script Details: ")
$Selection.ParagraphFormat.Alignment = 0
$Selection.TypeParagraph()

$Selection.Style = 'Normal'
$Selection.Font.Bold = 0
$Selection.font.Size = 12
$Selection.TypeText("$ScriptContents")
$Selection.ParagraphFormat.Alignment = 1
$Selection.TypeParagraph()
}


$Report = 'C:\Users\_nwendlowsky\Desktop\Application Deployment Documentation.doc'
$Document.SaveAs([ref]$Report,[ref]$SaveFormat::wdFormatDocument)
$word.Quit()
#Remove-variable * -ErrorAction SilentlyContinue

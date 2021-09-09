$NameManuf = "TortoiseGit 2.2.0.0 (64 bit);TortoiseGit",
"Todoist;Doist",
"RescueTime Lite;RescueTime",
"RavenDB;Hibernating Rhinos",
"Python Tools 2.1 for Visual Studio 2013;Microsoft Corporation",
"PureText Test;Steve P. Miller",
"Puretext PaceTest;Steve P. Miller",
"PureText;Steve P. Miller",
"MS SSO 6.5;Microsoft Corporation",
"mRemoteNG;mRemoteNG",
"MongoDB 3.2.11;MongoDB Inc",
"LINQPad 5;Joseph Albahari",
"LINQPad;Joseph Albahari",
"KDiff3;Joachim Eibl",
"1Password 4.6.0.604;AgileBits Inc",
"Git Extensions;GitHub",
"FocusBooster;focus booster",
"CouchDB2.0.0;Apache Software Foundation",
"CouchDB;Apache Software Foundation",
"CCH IntelliForms 2016;CCH Group",
"CCH IntelliForms 2015;CCH Group",
"Bitlocker key backup;Custom",
"Barco Clickshare 1.9.0.02;Barco",
"Barco Clickshare;Barco",
"ASAP activation;Bastien Mensink",
"ASAP;Bastien Mensink",
"Adapt - Interaction Desktop - Agent Automated Status Changer;Adapt Telephony Services LLC",
"WinMerge;WinMerge",
"XML Notepad 2007;Microsoft Corporation"
#>

$NameManuf | foreach{
    $Var1 = $_ -split (";")
#    Get-CMApplication -Name "$($Var1[0])" | select localizeddisplayname,manufacturer
    Get-CMApplication -Name "$($Var1[0])" | Set-CMApplication -Publisher "$($Var1[1])"
}

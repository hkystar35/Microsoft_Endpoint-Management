$cmSiteCode = ''
$cmAdminServiceHost = ''
$cmAdminService_CMG =''

$AppRequestID = 'blah'
$AppRequestAction = 'Approve' # or 'Deny'

$RequestURI = "https://$cmAdminServiceHost/AdminService/wmi/SMS_UserApplicationRequest('$AppRequestID')/AdminService.$AppRequestAction"
Invoke-WebRequest -Uri $RequestURI
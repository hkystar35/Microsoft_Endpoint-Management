# Get Boundary Groups with referenced Site systems

# Get Site Roles with test URLs
$SiteRoles = Get-CMSiteRole -AllSite

FUNCTION Get-CMSiteRoleURL {
  #[CmdletBinding()]
  PARAM
  (
    [Parameter(ValueFromPipelineByPropertyName = $true)][ValidateNotNullOrEmpty()]$RoleName,
    [Parameter(ValueFromPipelineByPropertyName = $true)][ValidateNotNullOrEmpty()]$NALPath,
    [Parameter(ValueFromPipelineByPropertyName = $true)][ValidateNotNullOrEmpty()]$SSLstate
  )
	
  $ServerName = ($NALPath).split('\\', [system.stringsplitoptions]::RemoveEmptyEntries)[-1]
  
  $URL = SWITCH ($RoleName) {
    'SMS Management Point' {
      'https://{0}/sms_mp/.sms_aut?mplist' -f $ServerName
    }
    'SMS Distribution Point' {
      'https://{0}/SMS_DP_SMSPKG$/DataLib' -f $ServerName
    }
    'SMS Software Update Point' {
      SWITCH (Get-CMSiteSSLstate -SSLstate $SSLstate) {
        {
          $_ -eq 'HTTPS' -or $_ -eq 'Always HTTPS'
        } {
          'https://{0}:8531/selfupdate/wuident.cab' -f $ServerName
        }
        {
          $_ -eq 'HTTP' -or $_ -eq 'Always HTTP'
        } {
          'https://{0}:8531/selfupdate/wuident.cab' -f $ServerName
        }
        default {
          $null
        }
      }
    }
    default {
      $null
    }
  }
  
  $Output = New-Object -TypeName pscustomobject -Property @{
    ServerName = $ServerName
    RoleName = $RoleName
    URL = $URL
    SSLState = Get-CMSiteSSLstate -SSLstate $SSLstate
  }
  $Output
}

FUNCTION Get-CMSiteSSLstate {
  [CmdletBinding()]
  PARAM
  (
    [Parameter(ValueFromPipelineByPropertyName = $true)][ValidateNotNullOrEmpty()]$SSLstate
  )
	
  SWITCH ($SslState) {
    0	{
      'HTTP'
    }
    1	{
      'HTTPS'
    }
    2	{
      'n/a'
    }
    3	{
      'Always HTTPS'
    }
    4	{
      'Always HTTP'
    }
  }
}

$SiteRoles | %{$_ | Get-CMSiteRoleURL} | sort SSLState,ServerName,RoleName
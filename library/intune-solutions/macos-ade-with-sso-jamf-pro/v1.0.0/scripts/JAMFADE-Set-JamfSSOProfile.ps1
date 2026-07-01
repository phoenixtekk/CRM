<#
.SYNOPSIS
    JAMFADE-Set-JamfSSOProfile.ps1 — create & scope the macOS Platform SSO profile in Jamf Pro.

.DESCRIPTION
    PURPOSE
        Uploads a macOS Single Sign-On Extensions (Platform SSO) configuration profile to Jamf Pro
        with the correct Microsoft Enterprise SSO identifiers, login URLs, and the Secure Enclave
        authentication method — the same profile described in the Implementation Guide §Phase 3 /
        Step 10 — and scopes it to a target Smart Computer Group. Jamf is the MDM, so the SSO profile
        is delivered by Jamf (not Intune).

    HOW TO RUN
        $cred = Get-Credential                              # Jamf account with config-profile write
        # Preview only (no change):
        .\JAMFADE-Set-JamfSSOProfile.ps1 -JamfUrl https://yourorg.jamfcloud.com -Credential $cred -TargetGroup "macOS SSO - Pilot" -WhatIf
        # Create & scope:
        .\JAMFADE-Set-JamfSSOProfile.ps1 -JamfUrl https://yourorg.jamfcloud.com -Credential $cred -TargetGroup "macOS SSO - Pilot"
        # Choose a different method:
        .\JAMFADE-Set-JamfSSOProfile.ps1 -JamfUrl ... -Credential $cred -TargetGroup ... -AuthMethod passwordSync

    EXPECTED RESULTS
        A new macOS configuration profile named "macOS Platform SSO - <method>" is created and scoped
        to the Smart Group. Verify it in Jamf Pro → Computers → Configuration Profiles.

.NOTES
    Phoenixtekk Workplace Marketplace — Intune Solutions. Creates a configuration profile via the Jamf
    Pro Classic API; supports -WhatIf. The profile embeds an Apple com.apple.extensiblesso payload.
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)] [string]$JamfUrl,
    [Parameter(Mandatory)] [pscredential]$Credential,
    [Parameter(Mandatory)] [string]$TargetGroup,
    [ValidateSet('secureEnclaveKey','passwordSync')]
    [string]$AuthMethod = 'secureEnclaveKey',
    [string]$Name = 'macOS Platform SSO'
)

$ErrorActionPreference = 'Stop'
$JamfUrl = $JamfUrl.TrimEnd('/')

$extensionId = 'com.microsoft.CompanyPortalMac.ssoextension'
$teamId      = 'UBF8T346G9'
$urls = @(
    'https://login.microsoftonline.com','https://login.microsoft.com','https://sts.windows.net',
    'https://login.partner.microsoftonline.cn','https://login.chinacloudapi.cn',
    'https://login.microsoftonline.us','https://login-us.microsoftonline.com'
)
$applePsoMethod = if ($AuthMethod -eq 'passwordSync') { 'Password' } else { 'UserSecureEnclaveKey' }
$profileName = "$Name - $AuthMethod"

# --- build the .mobileconfig (Apple SSO extension + Platform SSO) ---
$profileUuid = (New-Guid).Guid.ToUpper()
$payloadUuid = (New-Guid).Guid.ToUpper()
$urlXml = ($urls | ForEach-Object { "            <string>$_</string>" }) -join "`n"

$mobileconfig = @"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>PayloadContent</key>
  <array>
    <dict>
      <key>PayloadType</key><string>com.apple.extensiblesso</string>
      <key>PayloadVersion</key><integer>1</integer>
      <key>PayloadIdentifier</key><string>com.phoenixtekk.platformsso.$payloadUuid</string>
      <key>PayloadUUID</key><string>$payloadUuid</string>
      <key>PayloadDisplayName</key><string>Microsoft Enterprise SSO (Platform SSO)</string>
      <key>ExtensionIdentifier</key><string>$extensionId</string>
      <key>TeamIdentifier</key><string>$teamId</string>
      <key>Type</key><string>Redirect</string>
      <key>URLs</key>
      <array>
$urlXml
      </array>
      <key>PlatformSSO</key>
      <dict>
        <key>AuthenticationMethod</key><string>$applePsoMethod</string>
        <key>UseSharedDeviceKeys</key><true/>
      </dict>
    </dict>
  </array>
  <key>PayloadDisplayName</key><string>$profileName</string>
  <key>PayloadIdentifier</key><string>com.phoenixtekk.platformsso.$profileUuid</string>
  <key>PayloadType</key><string>Configuration</string>
  <key>PayloadUUID</key><string>$profileUuid</string>
  <key>PayloadVersion</key><integer>1</integer>
  <key>PayloadScope</key><string>System</string>
</dict>
</plist>
"@

# --- wrap into the Classic API osxconfigurationprofile XML (payloads is CDATA) ---
$body = @"
<os_x_configuration_profile>
  <general>
    <name>$profileName</name>
    <description>Microsoft Enterprise SSO / Platform SSO for macOS. Created by Phoenixtekk JAMFADE-Set-JamfSSOProfile.ps1.</description>
    <distribution_method>Install Automatically</distribution_method>
    <user_removable>false</user_removable>
    <level>computer</level>
    <payloads><![CDATA[$mobileconfig]]></payloads>
  </general>
  <scope>
    <computer_groups>
      <computer_group><name>$TargetGroup</name></computer_group>
    </computer_groups>
  </scope>
</os_x_configuration_profile>
"@

if (-not $PSCmdlet.ShouldProcess($profileName, "Create macOS Platform SSO profile in Jamf and scope to '$TargetGroup'")) {
    Write-Host "WhatIf: would create '$profileName' (method=$applePsoMethod) scoped to group '$TargetGroup'." -ForegroundColor Yellow
    return
}

# bearer token
$pair  = "$($Credential.UserName):$($Credential.GetNetworkCredential().Password)"
$basic = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($pair))
$tok   = Invoke-RestMethod -Method POST -Uri "$JamfUrl/api/v1/auth/token" -Headers @{ Authorization = "Basic $basic" }
$bearer = $tok.token

$resp = Invoke-RestMethod -Method POST -Uri "$JamfUrl/JSSResource/osxconfigurationprofiles/id/0" `
    -Headers @{ Authorization = "Bearer $bearer" } -ContentType 'application/xml' -Body $body

$newId = $resp.os_x_configuration_profile.id
Write-Host "Created profile '$profileName' (id $newId), scoped to '$TargetGroup'." -ForegroundColor Green
Write-Host 'Verify in Jamf Pro -> Computers -> Configuration Profiles, then pilot-enroll a Mac.' -ForegroundColor Green

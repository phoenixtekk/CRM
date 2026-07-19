<#
.SYNOPSIS
    PFXMOB-Import-Pfx.ps1 — import a third-party PFX into Intune via Microsoft Graph for a target user
    (the userPfxCertificate / imported-PFX flow). Encrypts the PFX to the Intune Certificate
    Connector's public key.
.DESCRIPTION
    PURPOSE
        Path A helper. Uploads an EXISTING third-party .pfx/.p12 to Intune as a user PFX certificate
        object so a "PKCS imported certificate" profile can later deliver it to iOS devices.
        It does NOT issue a new certificate (that is SCEP/PKCS, the WRONG path for a static PFX).

        IMPORTANT — the Intune Certificate Connector is REQUIRED:
          * On import, the PFX private key is encrypted to the Certificate Connector's PUBLIC key.
          * At delivery time, the Connector DECRYPTS the imported PFX onto the device.
          * If no healthy Connector exists, the imported object will never deploy — use the custom
            PKCS12 profile path (Path B) instead.

        This script reads the PFX PATH and PASSWORD from PARAMETERS / SECURE INPUT and NEVER hardcodes
        them. It sets the certificate THUMBPRINT (read from the PFX) and the INTENDED PURPOSE (note:
        the imported-PFX intended-purpose options are S/MIME-oriented — for a non-S/MIME app cert set
        what the app expects, or use Path B).

        NOTE ON ENCRYPTION: the official Microsoft "Intune-PFXImport-PowerShell" module
        (Export-IntunePublicKey / New-IntuneUserPfxCertificate / Add-IntuneUserPfxCertificate) performs
        the connector-public-key encryption and is the supported helper. This script uses it when
        available and otherwise stops with guidance rather than uploading an unencrypted blob.
    HOW TO RUN
        Install once:  Install-Module Microsoft.Graph -Scope CurrentUser
                       Install-Module IntunePfxImport -Scope CurrentUser   # Microsoft PFXImport helper
        Then (you will be prompted for the PFX password securely):
          powershell -ExecutionPolicy Bypass -File .\PFXMOB-Import-Pfx.ps1 `
              -PfxPath 'C:\secure\app-cert.pfx' `
              -UserUpn 'Intune.Cert.<service>@<your-domain>' `
              -IntendedPurpose smimeEncryption
        Or pass the password non-interactively as a SecureString via -PfxPassword (still never plain text).
    EXPECTED RESULTS
        The third-party PFX imported into Intune as a userPfxCertificate object for the target user.
        Confirm with PFXMOB-Discovery.ps1, then assign a "PKCS imported certificate" profile
        (PFX Imported - iOS App Cert - Pilot) to the user/group — the object alone does NOT deploy.
.NOTES
    Intune Solutions. Requires write scope. Privacy: use the neutral
    placeholder Intune.Cert.<service>@<your-domain> — never a real tenant UPN.
#>
[CmdletBinding(SupportsShouldProcess)] param(
    [Parameter(Mandatory)] [ValidateScript({ Test-Path $_ })] [string] $PfxPath,
    [Parameter(Mandatory)] [string] $UserUpn,
    # S/MIME-oriented options per the imported-PFX model. Choose what the app expects.
    [ValidateSet('unassigned','smimeEncryption','smimeSigning')] [string] $IntendedPurpose = 'smimeEncryption',
    [System.Security.SecureString] $PfxPassword
)

# Never accept or store the password in plain text — prompt securely if not supplied.
if (-not $PfxPassword) { $PfxPassword = Read-Host -AsSecureString -Prompt 'Enter the PFX password' }

Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
if (-not (Get-Module -ListAvailable IntunePfxImport)) {
    Write-Host "The Microsoft 'IntunePfxImport' helper module is not installed." -ForegroundColor Yellow
    Write-Host "Install it (it performs the connector-public-key encryption):  Install-Module IntunePfxImport -Scope CurrentUser" -ForegroundColor Yellow
    Write-Host "Without it, do NOT upload an unencrypted PFX. Use Path B (custom PKCS12 profile) if you cannot install it." -ForegroundColor Yellow
    return
}
Import-Module IntunePfxImport -ErrorAction Stop

# Write scope is required to upload the imported PFX object.
Connect-MgGraph -Scopes 'DeviceManagementConfiguration.ReadWrite.All' -NoWelcome

# Read the thumbprint from the PFX (needed on the imported object).
try {
    $cert = [System.Security.Cryptography.X509Certificates.X509Certificate2]::new($PfxPath, $PfxPassword,
        [System.Security.Cryptography.X509Certificates.X509KeyStorageFlags]::Exportable)
    $thumbprint = $cert.Thumbprint
    Write-Host ("PFX loaded. Subject: {0} | Thumbprint: {1}" -f $cert.Subject, $thumbprint) -ForegroundColor Cyan
} catch {
    Write-Host ("Could not open the PFX with the supplied password: {0}" -f $_.Exception.Message) -ForegroundColor Red
    return
}

# 1. Retrieve the Intune Certificate Connector PUBLIC KEY (required to encrypt the PFX).
#    Export-IntunePublicKey is provided by the IntunePfxImport module.
Write-Host "Retrieving the Certificate Connector public key..." -ForegroundColor Cyan
try { $publicKey = Export-IntunePublicKey -ProviderName 'Microsoft Software Key Storage Provider' -KeyName 'PFXEncryptionKey' }
catch {
    Write-Host ("Could not obtain the connector public key: {0}" -f $_.Exception.Message) -ForegroundColor Red
    Write-Host "A healthy Intune Certificate Connector is REQUIRED for this path. Verify it (Tenant administration > Connectors and tokens > Certificate connectors), or use Path B." -ForegroundColor Yellow
    return
}

# 2. Build the encrypted userPfxCertificate object (PFX encrypted to the connector public key).
$plainPwd = [System.Net.NetworkCredential]::new('', $PfxPassword).Password
$userPfx  = New-IntuneUserPfxCertificate -PathToPfxFile $PfxPath -PfxPassword $plainPwd `
                -EncryptionCertificate $publicKey -UserPrincipalName $UserUpn `
                -IntendedPurpose $IntendedPurpose
$plainPwd = $null   # drop the plaintext password reference immediately

# 3. Upload (import) the object to Intune via Graph.
if ($PSCmdlet.ShouldProcess($UserUpn, "Import third-party PFX (thumbprint $thumbprint, purpose $IntendedPurpose)")) {
    Add-IntuneUserPfxCertificate -CertificateList $userPfx
    Write-Host ("Imported PFX for {0} (thumbprint {1}, intended purpose {2})." -f $UserUpn, $thumbprint, $IntendedPurpose) -ForegroundColor Green
    Write-Host "NEXT: assign a 'PKCS imported certificate' profile (PFX Imported - iOS App Cert - Pilot) to this user/group — the imported object alone does NOT reach a device." -ForegroundColor Cyan
} else {
    Write-Host "[WhatIf] Would import the PFX object; no upload performed." -ForegroundColor Yellow
}

Disconnect-MgGraph | Out-Null

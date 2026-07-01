# 6. Troubleshooting Guide — Configuration Manager Cloud Management Gateway (CMG)

Use `CMG-Discovery.ps1` for environment readiness and `CMG-Validation.ps1` for endpoint/client state,
`CMG-Report.ps1` for internet-client health, and `CMG-Remediation.ps1` for safe client fixes.

## A. CMG service won't reach Ready
| Symptom | Cause | Remediation |
|---|---|---|
| Cloud Management Gateway stuck Provisioning / Error | Wrong certificate, bad PFX password, or Azure rights | Re-check the `CMG – Internet Clients – Server Auth` PFX and password; confirm Contributor on the resource group; recreate the service |
| Certificate name mismatch | CMG service name (from cert subject) ≠ planned DNS name | Reissue the cert with the correct subject/SAN, or align the DNS CNAME to the cert name |

## B. Connection point unhealthy
| Symptom | Cause | Remediation |
|---|---|---|
| Connection Analyzer fails to reach the CMG | Outbound 443 to Azure blocked from the connection point host | Allow outbound HTTPS to Azure / the CMG endpoints; re-run the analyzer |
| MP/SUP not reachable through the channel | MP/SUP not enabled for CMG traffic | Enable "Allow Configuration Manager cloud management gateway traffic" on the MP and SUP roles (Implementation Step 7) |

## C. Client won't use the CMG
| Symptom | Cause | Remediation |
|---|---|---|
| Client shows no internet management point | Cloud-management client settings not applied | Confirm `CMG – Internet Clients – Client Settings` is deployed to the client's collection; run a Machine Policy cycle or `CMG-Remediation.ps1` |
| Client reaches CMG but is rejected | Authentication failing (token or PKI) | For token: confirm Entra join/registration and Cloud Management onboarding; for PKI: confirm a valid client auth cert and CRL reachability |

## D. Authentication / Enhanced HTTP issues
- Token authentication requires Enhanced HTTP (or PKI) on the site systems; if the MP isn't accepting
  token traffic, verify Enhanced HTTP is enabled (Communication Security) and the Cloud Management
  onboarding (server/client app registrations) is complete and consented.

## E. Content / deployments stall over the internet
- Internet clients with no content path cannot install deployments. Enable the CMG to serve content
  (or provide another internet content source) and confirm the deployment targets the internet client
  collection.

## F. Certificate expiry (silent outage)
- An expired `CMG – Internet Clients – Server Auth` certificate breaks all internet management with no
  warning. Track expiry; renew and re-upload the PFX to the CMG ahead of time with your CA/PKI team.

## G. Diagnostics quick reference
```powershell
# Site / role readiness (run on the site server with the ConfigMgr console installed)
Import-Module "$env:SMS_ADMIN_UI_PATH\..\ConfigurationManager.psd1"
Get-CMCloudManagementGateway | Select Name, State, ServiceStatus
Get-CMCloudManagementGatewayConnectionPoint | Select SiteCode, NetworkOSPath

# Public endpoint reachability (run from an internet host)
Test-NetConnection -ComputerName 'CMG.contoso.com' -Port 443

# On a client: ConfigMgr client log locations
# CcmExec.log, ClientLocation.log, CMGHttpHandler.log under C:\Windows\CCM\Logs
```

## H. When to escalate
If the CMG is Ready, the connection point passes the analyzer, the MP/SUP are enabled for CMG, the
client has the cloud-management settings and a valid auth method, and clients still cannot be managed,
collect the client logs above plus the CMG service logs and open a Microsoft support case.

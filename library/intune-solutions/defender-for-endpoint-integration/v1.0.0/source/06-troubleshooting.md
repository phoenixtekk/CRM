# 6. Troubleshooting Guide — Microsoft Defender for Endpoint Integration

Use **`MDE-Validation.ps1`** / **`MDE-Discovery.ps1`** for local onboarding state and
**`MDE-ConnectorCheck.ps1`** for the connector, **`MDE-Remediation.ps1`** for safe fixes.

## A. Connector problems
| Symptom | Cause | Remediation |
|---|---|---|
| Connector "Unavailable" in Intune | Intune connection not turned on in Defender portal | Defender portal → **Settings → Endpoints → Advanced features → Microsoft Intune connection = On** |
| Connector active but no onboarding | No onboarding policy / wrong package type | Create the EDR onboarding policy with **Auto from connector** |

## B. Device not onboarding
| Symptom | Cause | Remediation |
|---|---|---|
| Policy "Succeeded" but device absent in Defender | Sensor not reporting yet, or network blocked | Run `MDE-Validation.ps1`; allow MDE URLs; reboot; wait for first check-in |
| `OnboardingState = 0` | Onboarding not applied | Sync policy (`MDE-Remediation.ps1`); confirm device in `MDE-Pilot` group |
| Sense service stopped | Service disabled/crashed | `MDE-Remediation.ps1` restarts Sense; check Event Viewer (SENSE) |

## C. Risk score not affecting compliance
- Compliance unchanged by risk → the compliance policy's Defender risk requirement isn't set, or the connector isn't active. Set **Require risk at or under <level>** in the compliance policy.
- Device risk "Unknown" → not yet onboarded/reporting; wait for first telemetry.

## D. Network / connectivity
- Sensor unhealthy → run the MDE connectivity analyzer; ensure MDE service URLs are allowed and **not SSL-inspected**.
- Proxy issues → configure the sensor proxy (static or WinHTTP) per Microsoft guidance.

## E. Diagnostics quick reference
```powershell
Get-Service Sense                                  # Defender for Endpoint sensor service
Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows Advanced Threat Protection\Status'  # OnboardingState
Get-MpComputerStatus                               # Defender AV health
```
Sensor logs/connectivity: the **MDEClientAnalyzer** tool from Microsoft.

## F. When to escalate
If the device shows `OnboardingState = 1`, Sense is Running, and connectivity passes but the
device never appears in the Defender portal, capture the device ID and open a Microsoft Defender support case.

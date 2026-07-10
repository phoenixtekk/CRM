# 6. Troubleshooting Guide — Microsoft 365 Copilot Adoption & Change-Management Program

Use `CPLTADOPT-Discovery.ps1` for the license/usage baseline, `CPLTADOPT-Report.ps1` for adoption
metrics, `CPLTADOPT-Validate.ps1` for program readiness, `CPLTADOPT-ChampionsRoster.ps1` for champion
coverage, and `CPLTADOPT-LicenseOptimization.ps1` for idle seats.

## A. Usage reports are empty, missing, or show no names
| Symptom | Cause | Remediation |
|---|---|---|
| `Reports -> Usage -> Microsoft 365 Copilot` shows no data | Reporting not yet populated, or Copilot usage report unavailable in the tenant | Allow for report latency; confirm the Copilot usage report is available for your tenant/licensing (*usage-report availability varies — verify current availability in your tenant*) |
| User names appear as anonymized IDs | `Reports -> Settings -> Display concealed user names` is off (privacy default) | An admin can toggle it on if policy allows — this is a governance decision for the customer; otherwise report at the aggregate/cohort level |
| `CPLTADOPT-Report.ps1` / `-Discovery.ps1` returns no rows | Graph usage-report endpoint/scope unavailable or not consented | Confirm `Reports.Read.All` is consented; *verify the current Copilot usage-report Graph endpoint name in your tenant*; fall back to the admin-center report or Viva Copilot Dashboard |

## B. Licenses assigned but usage is flat
| Symptom | Cause | Remediation |
|---|---|---|
| High assigned count, low active count | Enablement without adoption — the core problem this program solves | Work the levers: confirm sponsor visibility, add champion attention to the cohort, sharpen the role use cases, and increase training/comms frequency; re-measure |
| Usage concentrated in one app (e.g. Teams) only | Users haven't discovered value in the other surfaces | Run a focused prompt clinic and publish the role use cases for the under-used apps (Word/Excel/Outlook/PowerPoint) |
| A whole department is not adopting | No champion or no relevant use cases for that team | `CPLTADOPT-ChampionsRoster.ps1` will flag the gap — recruit a champion there and tailor the use-case catalog to their work |

## C. Champions network is not working
- If champions are inactive, check they have time allocated and a clear ask (model use cases, answer
  peers, submit wins/friction). A champion with no cadence and no recognition disengages. Reinforce the
  recurring sync, the shared channel, and public recognition of their wins.

## D. Data readiness is blocking good results
- If Copilot results are poor or users worry about seeing content they shouldn't, adoption stalls
  regardless of the program. This is a data-readiness problem, not an adoption one — pause broad
  expansion and complete oversharing remediation and the sensitivity-label baseline (global
  requirements G4/G5; see the Copilot data-readiness / Purview solutions) first.

## E. Sponsor engagement fading
- If usage plateaus after launch, sponsorship has usually gone quiet. Bring the sponsor the monthly
  adoption narrative (baseline-to-current from `CPLTADOPT-Report.ps1`) and a champion win story, and ask
  for one visible message — renewed sponsorship restarts momentum.

## F. Script/connection issues
| Symptom | Cause | Remediation |
|---|---|---|
| `Connect-MgGraph` fails or scopes missing | SDK not installed, or read scopes not consented | `Install-Module Microsoft.Graph -Scope CurrentUser`; re-run and accept `Reports.Read.All`, `User.Read.All`, `Group.Read.All`, `Organization.Read.All` |
| Group-scoped scripts return nothing | Wrong group name/ID | Confirm `Copilot Adoption Pilot - Pilot - Pilot` / `Copilot Champions Network - Tenant - Steady` exist and pass the correct `-GroupId`/name |

## G. Diagnostics quick reference
```powershell
Connect-MgGraph -Scopes 'Reports.Read.All','User.Read.All','Group.Read.All','Organization.Read.All' -NoWelcome
# Copilot usage (user detail) — *verify current endpoint/period support in your tenant*
Invoke-MgGraphRequest -Method GET -Uri "/v1.0/reports/getMicrosoft365CopilotUsageUserDetail(period='D30')"
# assigned Copilot licenses (match the Copilot service plan/SKU in your tenant)
Get-MgUser -All -Property displayName,assignedLicenses,userPrincipalName
```

## H. When to pause the program
If broad data readiness is not actually in place (oversharing unaddressed, no label baseline), stop
expanding adoption and remediate readiness first — driving more usage over an ungoverned data estate
increases AI data-exposure risk. Adoption resumes once the gate is met.

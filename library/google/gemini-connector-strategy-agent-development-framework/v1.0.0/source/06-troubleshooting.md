# 6. Troubleshooting Guide — Gemini Connector Strategy & Agent Development Framework

Use `GEMCONN-Set-ScopeTargeting.ps1` / `GEMCONN-Discovery.ps1` for scope and inventory,
`GEMCONN-Validation.ps1` for boundary/guardrail conformance, `GEMCONN-Report.ps1` for coverage-and-risk
and drift, and `GEMCONN-Remediation.ps1` (defaults to `-WhatIf`) for safe fixes. Objects are referenced
by their `<Purpose> – <Scope> – <Stage>` names.

> **Preview note.** Gemini Enterprise / Agentspace and the Agent Platform are rolling out. If a script
> returns empty or errors on an API version, that often means the surface differs in your tenant — treat
> it as **verify-in-tenant** and confirm in the console before concluding a control is absent.

## A. Discovery / scripts return nothing (or an API error)
| Symptom | Cause | Remediation |
|---|---|---|
| `GEMCONN-Discovery.ps1` lists no connectors/agents | Discovery Engine API not enabled, wrong location, or preview API version | Enable the Discovery Engine API; try `-Location 'global'` (or your region) and `-ApiVersion v1alpha`; confirm in the console — **verify-in-tenant** before concluding "none" |
| `Could not obtain a gcloud access token` | Not authenticated | Run `gcloud auth login` and `gcloud config set project your-project-id`, then re-run |
| 403 / permission denied | Operating account lacks `discoveryengine.viewer` (or higher) | Grant the least-privilege `discoveryengine.*` role at the project scope; re-run `GEMCONN-Set-ScopeTargeting.ps1` |

## B. A user sees data they should not (ACL not respected)
- This is the highest-priority failure. Gemini **respects source permissions**, so if an unentitled user
  sees a result, either the **source ACL is wrong** or **identity mapping is misconfigured**.
- Verify the source system's ACL for that document; verify the identity provider and identity mapping
  ([identity/access control](https://cloud.google.com/agentspace/agentspace-enterprise/docs/identity)).
- For **custom** sources, confirm each document carries correct `acl_info` metadata.
- Until fixed, **disable the connector** (`GEMCONN-Remediation.ps1 -Action DisableConnector`) so it stops
  exposing the source. Re-run Testing Guide Test 3 before reconnecting.

## C. Connector present but not approved
- `GEMCONN-Validation.ps1` flags a data store not on the allow-list. Either add it to the approval record
  `Connector Approval – Pilot Project – Prod` after it meets the criteria, or disable it
  (`GEMCONN-Remediation.ps1 -Action DisableConnector`, default `-WhatIf` first).

## D. Boundary / VPC Service Controls not detected
| Symptom | Cause | Remediation |
|---|---|---|
| Validation reports no perimeter | No perimeter, or the account can't read Access Context Manager | Confirm/define a perimeter covering the project; grant read on the access policy; **verify-in-tenant** whether an org-level perimeter already applies |
| Connector egress blocked unexpectedly | VPC firewall / perimeter is doing its job (or too tight) | Confirm the source FQDN is allowed; adjust the egress rule under change control — do not remove the perimeter |

## E. Agent-development framework gaps
| Symptom | Cause | Remediation |
|---|---|---|
| No Agent Registry / Identity / Gateway visible | Component not yet available in your tenant (preview) | Enforce the equivalent by process (register agents in a tracked list, restrict tools manually) and flag **verify-in-tenant**; enable the component when it reaches your tenant |
| Agent surfaces unentitled data | Agent reaching an unapproved connector, or ACL issue (see B) | Restrict the agent's tools to the approved allow-list (Agent Gateway / tool governance); fix the underlying ACL |
| Evaluation gate skipped | Agent deployed without Gen AI Evaluation | Roll back the deploy; run evaluation + boundary tests; only redeploy after the review gate passes |

## F. Agent shared too broadly
- `GEMCONN-Validation.ps1` prompts a console audience check (audience read is preview). If an agent is
  public or shared beyond its group, narrow the audience in the console, or
  `GEMCONN-Remediation.ps1 -Action UnpublishAgent` (default `-WhatIf`). Automated unpublish is best-effort
  on the preview surface — the script tells you the console step if the API path is unavailable.

## G. Diagnostics quick reference
```powershell
gcloud auth print-access-token                                   # confirm auth
gcloud config get-value project                                  # confirm target project
gcloud projects get-iam-policy your-project-id --format=json      # Gemini Enterprise IAM bindings
gcloud access-context-manager perimeters list --format=json      # VPC Service Controls perimeters
.\GEMCONN-Discovery.ps1 -ProjectId 'your-project-id' -ApiVersion v1alpha   # try preview API version
```

## H. When to escalate
If the Discovery Engine API is enabled, the account holds the right `discoveryengine.*` role, the API
version matches your tenant, and connectors/agents still do not appear or ACLs still misbehave after
verifying identity mapping and source permissions, collect `GEMCONN-Report.ps1` output and the
project/location details and open a Google Cloud support case. Cross-check the
[Gemini Enterprise release notes](https://docs.cloud.google.com/gemini/enterprise/docs/release-notes)
for a preview-status or API change affecting the surface.

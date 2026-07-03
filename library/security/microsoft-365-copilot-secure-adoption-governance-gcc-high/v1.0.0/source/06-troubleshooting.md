# Troubleshooting Guide — Microsoft 365 Copilot Secure Adoption & Governance (GCC High)

The failures below are the ones that specifically bite on **GCC High** — most stem from following a
Commercial click-path or connecting to the wrong cloud. Each entry: **Symptom · Cause · Fix.**

---

## T1. Scripts return empty results (or "tenant not found") but no obvious error

**Symptom:** Discovery/Validation run "successfully" but show no sites, no licenses, or a tenant
mismatch.
**Cause:** Connected to the **default (Global/Commercial) Graph environment**, not US Gov. A GCC High
tenant does not exist in Commercial Graph.
**Fix:** Ensure every connection uses **`-Environment USGov`**. Verify:
```
Connect-MgGraph -Environment USGov -Scopes "Sites.Read.All"
(Get-MgContext).Environment           # must show USGov
(Get-MgEnvironment -Name USGov).GraphEndpoint   # https://graph.microsoft.us
```
Disconnect (`Disconnect-MgGraph`) and reconnect if a prior Global session is cached.

## T2. A portal shows the wrong tenant, or won't load your tenant

**Symptom:** `entra.microsoft.com` / `admin.microsoft.com` opens a different (or empty) tenant.
**Cause:** You used a **Commercial** portal URL against a GCC High tenant.
**Fix:** Use the **`*.us`** portal for every task: `portal.office365.us`, `entra.microsoft.us`,
`compliance.microsoft.us`, `security.microsoft.us`, `endpoint.microsoft.us`, `portal.azure.us`,
`high.powerva.microsoft.us`. Sign in at `login.microsoftonline.us`.

## T3. `Connect-MgGraph -Environment USGov` fails to authenticate

**Symptom:** Auth error or endpoint unreachable when connecting to US Gov Graph.
**Cause:** Network filtering allows only Commercial endpoints, or the Graph module is outdated.
**Fix:** Allow the **US Gov endpoint set** through proxy/firewall — `*.microsoft.us`, `*.azure.us`,
`*.usgovcloudapi.net`, `*.windows.net`, and the `AzureCloud.usgovvirginia` / `AzureCloud.usgovtexas`
IP ranges. Update the SDK: `Update-Module Microsoft.Graph`. Confirm reach to
`https://login.microsoftonline.us` and `https://graph.microsoft.us`.

## T4. Restricted SharePoint Search option is missing

**Symptom:** RSS is not visible in the SharePoint (GCC High) admin center.
**Cause:** Feature availability in GCC High can **lag Commercial** — or you lack the SharePoint
Administrator role.
**Fix:** First confirm the **SharePoint Administrator** role (`entra.microsoft.us` → Roles). If the
role is correct and RSS is still absent, **verify RSS availability for GCC High** (it may not have
landed for your tenant). Until it does, use the fallback: **tighten site permissions directly** and
keep unremediated sites out of Copilot's reach. (See parity notes; do not assume the Commercial
behavior.)

## T5. Copilot doesn't activate for a licensed pilot user

**Symptom:** A user in `SG-COPILOTG-Pilot` has the Copilot add-on but sees no Copilot in the apps.
**Cause:** Missing **eligible base plan**, or license just assigned (propagation), or an app/channel
requirement.
**Fix:** Confirm the user holds an eligible GCC High base plan (G3/G5 Gov, or eligible Office 365
G-plan) **in addition to** the Copilot add-on. Allow propagation time. Use the **Copilot License
Details** diagnostic. Verify the user is on a supported Microsoft 365 Apps channel/build.

## T6. Copilot won't return live/web information

**Symptom:** Copilot answers seem dated or refuses current-events questions.
**Cause:** **Web grounding is OFF by default in GCC High** — by design, to keep data in-boundary.
**Fix:** This is expected. Copilot answers from **tenant content** (and its trained model, subject to
a knowledge cutoff). Only enable web grounding if your organization explicitly accepts the
data-boundary tradeoff — document that decision. Do not treat the absence of web results as a bug.

## T7. Teams meeting Copilot is missing for pilot users

**Symptom:** Copilot appears in Word/Outlook but not in Teams meetings/chat.
**Cause:** **Teams-meeting Copilot / Copilot in Teams chat/channels** have historically been
**limited or unavailable** in GCC High.
**Fix:** **Verify current status for your tenant** before promising it. If unavailable, set pilot
expectations to the surfaces that work today (Word/Excel/PowerPoint/Outlook, Copilot Chat) — do not
fail the pilot over a not-yet-shipped capability. (See parity notes.)

## T8. A Copilot Studio / agent capability isn't available

**Symptom:** Teams app publishing, an M365-extending agent, Prompt Action, transfer-to-agent, or
triggers/autonomous agents are missing in GCC High.
**Cause:** These Copilot Studio surfaces are **restricted or unavailable** in GCC High by design.
**Fix:** Design only around surfaces confirmed available in GCC High. Use `high.powerva.microsoft.us`
for Copilot Studio; expect the **web-user client**, not the Teams app. Consult the parity notes'
feature-limitations table and **verify for GCC High**.

## T9. DLP policy "isn't doing anything"

**Symptom:** CUI content isn't being protected despite a DLP policy.
**Cause:** Policy left in **test/simulation** mode, or scoped to the wrong locations.
**Fix:** In `compliance.microsoft.us` → **DLP → Policies**, move `DLP-COPILOTG-CUI` from simulation
to **enforce**, and confirm it targets SharePoint, OneDrive, and Teams. Confirm your SKU includes
Purview DLP (G3 may need the Purview Suite GCCH add-on).

## T10. Sensitivity label not appearing for users

**Symptom:** The mandated CUI label isn't selectable in apps.
**Cause:** Label not **published** to the user (or only to a different group), or Purview
Information Protection not licensed for the SKU.
**Fix:** In `compliance.microsoft.us` → **Information protection → Label policies**, confirm the
label is published to `SG-COPILOTG-Pilot` (or the user's group). Confirm Purview Information
Protection is included/added for the SKU. Allow propagation time.

## T11. Remediation script made a change you didn't expect

**Symptom:** A site was modified when you only wanted a preview.
**Cause:** The apply switch was passed instead of the default **-WhatIf**.
**Fix:** Run Remediation/Set-ScopeTargeting **without** the apply switch first to preview. Only apply
after review against the change ticket (R11). Roll back per your documented rollback step; re-run
Validation to confirm state.

---

## Escalation checklist

Before opening a Microsoft support case, confirm: (1) `-Environment USGov` on every connection; (2)
`*.us` portals throughout; (3) eligible base + Copilot add-on licensing; (4) roles correct; (5) the
capability in question is actually **available in GCC High** per the parity notes — a "missing"
feature may simply not have shipped to GCC High yet. **Verify for GCC High** before treating it as a
defect.

# 3. Implementation Guide — Onboarding Accelerator: Microsoft Defender for Cloud Apps

Follow these steps **in order**. Most configuration is in the **unified Defender portal** (`https://security.microsoft.com` → **Cloud apps**); Conditional Access App Control is wired in the **Entra admin center** (`https://entra.microsoft.com`). Objects are named `<Purpose> – <Scope> – <Stage>` and reused verbatim in every later step, script, and test.

> **Model:** Connect the apps and discovery, scope every policy **monitor / report-only** to a **pilot user group** first, validate that signal and control work, and only then enforce and expand. Keep enforcing actions (block, revoke OAuth app, suspend session) approval-gated throughout. Never block production access to "test."

## Naming (set once, reuse verbatim)
- Pilot user group (Entra): `MDCA Pilot Users – Pilot Ring – Pilot`
- App connectors effort: `MDCA App Connectors – Priority SaaS – Prod`
- OAuth app policy: `MDCA OAuth App Risk – Tenant – Report`
- Session policy (via CA App Control): `MDCA Session Control – Pilot Users – Report`
- Access policy: `MDCA Access Control – Pilot Users – Report`
- Conditional Access policy (Entra): `MDCA Session Control – Pilot Users – Report`
- Advanced-hunting saved query: `MDCA Signal Validation – Tenant – Validate`

## Step 1 — Assess readiness
1. Sign in to `security.microsoft.com` as a **Security Administrator**.
2. Run `MCAONB-Discovery.ps1` to capture the current state: MDCA activation, plan hints, admin roles, existing app connectors, Cloud Discovery source, and app-governance status.
3. In **Entra** → **Groups**, create the pilot user group `MDCA Pilot Users – Pilot Ring – Pilot`.

## Step 2 — Connect the priority apps (API connectors)
1. `security.microsoft.com` → **Cloud apps → Connected apps → App connectors → Connect an app**.
2. Connect **Microsoft 365** first, then the priority third-party apps as `MDCA App Connectors – Priority SaaS – Prod`; complete each app's admin consent / API-credential flow.
3. Confirm each connector shows **Connected** and begins pulling activity (connectors work out of band — no user impact).
4. Run `MCAONB-Validate.ps1 -Check Connectors` to confirm the connectors are connected and streaming.

## Step 3 — Turn on Cloud Discovery
1. `security.microsoft.com` → **Cloud apps → Cloud discovery → Settings**.
2. Enable the **Microsoft Defender for Endpoint integration** so MDE-onboarded devices feed discovery automatically (preferred). Where MDE is not the source, configure a **log collector** for the secure web gateway.
3. Confirm discovery data appears under **Cloud apps → Cloud discovery → Dashboard**.
4. Run `MCAONB-Validate.ps1 -Check Discovery` to confirm discovery data is flowing.

## Step 4 — Enable app governance and OAuth app policy (report-only)
1. `security.microsoft.com` → **Cloud apps → App governance** — enable it and let it inventory the tenant's OAuth apps. *App governance may require a specific plan — verify current availability.*
2. Create the OAuth app policy `MDCA OAuth App Risk – Tenant – Report` in **report-only** to flag over-privileged scopes, unverified publishers, and unusual consent patterns — **no auto-revoke** yet.
3. Run `MCAONB-Report.ps1 -Section OAuth` to list the current risky OAuth apps.
4. *Revoking an app consent is disruptive and stays approval-gated — the decision is the security team's.*

## Step 5 — Create session/access policies via Conditional Access App Control (pilot, report-only)
1. In **Entra** → **Protection → Conditional Access → New policy**, create `MDCA Session Control – Pilot Users – Report`: assign **Users = `MDCA Pilot Users – Pilot Ring – Pilot`**, target cloud apps, and under **Session** choose **Use Conditional Access App Control → Use custom policy** (routes sessions to MDCA). *Verify current App Control licensing and supported apps.*
2. In `security.microsoft.com` → **Cloud apps → Policies → Policy management**, create the session policy `MDCA Session Control – Pilot Users – Report` (e.g. monitor downloads on unmanaged devices) in **monitor** mode, and the access policy `MDCA Access Control – Pilot Users – Report` in **monitor** mode — both scoped to the pilot users.
3. Run `MCAONB-Validate.ps1 -Check Policy` to confirm the policies exist, are report-only, and are scoped to the pilot group.

## Step 6 — Add anomaly-detection and activity policies (monitor-first)
1. `security.microsoft.com` → **Cloud apps → Policies** — confirm the built-in **anomaly detection** policies are on (impossible travel, mass download, risky OAuth), tuned to the pilot scope where possible.
2. Add any needed **activity** or **file** policies in **report-only** first.
3. Run `MCAONB-Report.ps1 -Section Policies` to capture the current policy inventory and posture.

## Step 7 — Validate signal and control on the pilot
1. Run `MCAONB-Hunt.ps1` to execute `MDCA Signal Validation – Tenant – Validate` — it confirms `CloudAppEvents` (and OAuth app data) stream from the connectors and discovery.
2. As a pilot user, perform a benign action the monitor policy watches (e.g. a download from a connected app on an unmanaged device) and confirm the expected **alert** appears in **Incidents & alerts** — without enforcement blocking anything.
3. Complete the **Testing Guide** before enforcing or expanding.

## Step 8 — Enforce and expand tenant-wide
1. **Policies:** after validation, move the pilot session/access policies from **monitor** to **enforce** for the pilot group, confirm no false positives, then broaden the CA policy `MDCA Session Control – Pilot Users – Report` scope in waves toward the full tenant.
2. **Connectors:** add connectors for the remaining SaaS apps.
3. **OAuth governance:** review flagged apps with the security team; only then consider approval-gated revocation for the riskiest.
4. **Discovery:** expand the discovery source coverage (more MDE devices / log-collector sources).
5. Re-baseline with `MCAONB-Report.ps1 -SaveBaseline` and track coverage/OAuth-risk drift each cycle.

---
### Order of operations
`Assess → connect apps (M365 first) → turn on Cloud Discovery → enable app governance + OAuth report policy → create session/access policies via CA App Control (pilot, report-only) → add anomaly/activity policies → validate signal + control → enforce + expand`

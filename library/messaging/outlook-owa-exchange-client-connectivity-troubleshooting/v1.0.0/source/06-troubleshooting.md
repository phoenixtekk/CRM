# Troubleshooting

Common failure modes when running the toolkit and its scripts, and the resolutions. These are
the *meta* problems — issues with the diagnostic process itself. For the client-connectivity
faults you are diagnosing, the symptom→root-cause tree is `03-implementation.md`.

---

## Connecting / tooling

**`Connect-ExchangeOnline` fails or prompts endlessly.**
Ensure the **ExchangeOnlineManagement (EXO V3)** module is installed and current
(`Update-Module ExchangeOnlineManagement`). Basic Auth is retired — you must complete
modern-auth / MFA sign-in. Behind a proxy, the auth pop-up may be blocked; test from an
unproxied path. For Government clouds, pass the correct environment
(`Connect-ExchangeOnline -ExchangeEnvironmentName O365USGovGCCHigh` / `O365USGovDoD`) —
**verify the value for your cloud**.

**`Test-OutlookConnectivity` or `Test-OutlookWebServices` is "not recognized."**
These cmdlets' availability and parameters are **version-dependent** (and differ between EXO and
on-prem EMS). The assessment script degrades gracefully and reports `N/A - cmdlet unavailable`.
Fall back to the **Remote Connectivity Analyzer** (Outlook Connectivity / EWS tests) for the
same signal. Do not assume a cmdlet exists — verify in your tenant/build.

**Graph checks in `Test-ModernAuthConditionalAccess.ps1` return nothing.**
`Connect-MgGraph` needs the read scopes `Policy.Read.All`, `AuditLog.Read.All`,
`Directory.Read.All`. **Sign-in log** queries require **Entra ID P1 or above**; without it the
sign-in section is empty — read the sign-in logs manually in the Entra portal instead. If
consent is missing, an admin must grant the scopes once.

**Scripts throw "mailbox not found" for a valid user.**
Directory replication/lag or a proxy-address vs UPN mismatch. Try the **primary SMTP address**
and confirm with `Get-Mailbox <user>`. In hybrid, a mailbox may be **on-prem** — run the on-prem
equivalent in Exchange Management Shell.

---

## Discovery-layer diagnosis pitfalls

**RCA Autodiscover passes but the domain-joined client still misbehaves.**
Outlook on a domain-joined machine prefers the **SCP** over DNS. RCA tests the *external* path,
not the SCP. Check `Get-ClientAccessService | Select AutoDiscoverServiceInternalUri` and the
client's `Test E-mail AutoConfiguration` output; a stale SCP or a decommissioned server URI beats
a correct public record.

**`Test-AutodiscoverEndpoints.ps1` shows CNAME "REVIEW".**
Cloud-only Commercial expects `autodiscover.outlook.com`. A hybrid tenant may **intentionally**
point Autodiscover at the on-prem endpoint — "REVIEW" is not automatically a fault; confirm
against the org's coexistence design. For **GCC High / DoD**, the expected host differs — pass
`-ExpectedCname` with the correct sovereign value.

**The v2 JSON endpoint returns a redirect/401.**
A redirect can be normal (to the sovereign or on-prem endpoint); follow it. A 401 from an
*internal* run but 200 from RCA (external) implicates an **SSL-inspecting proxy / CASB** breaking
the request — test off-network.

---

## Auth-layer diagnosis pitfalls

**"Auth loop" but Conditional Access shows Success/Not applied.**
The token is fine server-side; the loop is **local** — a stale entry in **Windows Credential
Manager** (`MicrosoftOffice*`) or a cached broker token. Clear the credential and re-auth
(playbook D4.2). Don't keep re-reading CA when it already says Success.

**Sign-in log shows the failure but names a policy you didn't expect.**
CA policies stack; a *report-only* policy can look like a block in some views. Read the
**per-policy Result** column (Success / Failure / Not applied / Report-only) — only **Failure**
on a **required grant** blocks. Fix the device/app condition; **never disable a CA policy** as a
quick fix.

**New Outlook / Outlook mobile behaves differently from classic Outlook.**
They authenticate as **different client apps** (and use Graph, not EAS). Filter the sign-in log
by the correct **client app** — a grant that blocks one client may not apply to another, which is
exactly why "new Outlook works, classic doesn't" (or vice-versa) happens.

---

## Protocol / free-busy / mobile pitfalls

**`Get-CASMailbox` shows a protocol True but the client still can't use it.**
Enablement ≠ reachability. A `True` protocol can still fail on **transport (proxy/firewall)** or
**auth**. Run `Test-OutlookConnectivity` / RCA (D2.2), then check auth (D3). Also check for an
**EWS application access policy** that scopes EWS per app even when `EwsEnabled` is `True`.

**Free/busy still shows hash marks after the org relationship tests pass.**
Free/busy inherits the **target org's** Autodiscover + EWS health and the **individual user's**
`EwsEnabled`. Confirm the *other* org's D1/D2 and the specific user's EWS before concluding the
relationship is at fault (playbook D5).

**Mobile device is "quarantined" and enabling ActiveSync doesn't help.**
Quarantine/block is a **device-access / mobile-device-policy** or **Conditional Access
app-protection** decision, not a protocol switch. Resolve it at the policy layer (approve the
device / enroll in Intune / use the approved app) — re-enabling EAS alone won't release a
quarantined device.

---

## Remediation-safety pitfalls

**`Set-MailboxProtocolAccess.ps1` "did nothing."**
That is the **safe default** — it is a **dry-run** until you pass `-Commit`. Confirm the printed
CURRENT vs INTENDED, get change approval, then re-run with `-Commit`. Keep the printed prior value
as your rollback.

**A change fixed one user but you're unsure it's safe fleet-wide.**
Never bulk-`-Commit` from a single-user diagnosis. Validate against the **Testing & Validation**
gate for that change on `ConnTest` + the affected user first, confirm no other gate regressed,
then expand under change control. DNS / Autodiscover / SCP / relationship changes are high-impact
to production mail — treat them accordingly.

**You changed a Conditional Access policy to unblock a user.**
Revert it. Weakening CA is a security regression and rarely the real fix; the correct resolution
is to satisfy the device/app condition. If the policy is genuinely misscoped, the CA owner
corrects scope under change control — not the triage technician mid-ticket.

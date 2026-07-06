# 3. Implementation Guide — Google Workspace Security Baseline, DLP & Context-Aware Access (CAA)

This guide applies the **named security posture** in the category-standard order
**Assess → Configure → Pilot → Validate → Expand**, scoped to a **pilot OU first**, with a documented
rollback at every gate. All paths are in the **Google Admin console** (`https://admin.google.com`).

> **Vendor boundary.** Console paths follow Google's current public documentation. **CAA** and the
> **DLP for Drive/Gmail rule engine** are **edition-gated** (Enterprise / Education tiers). Where a
> page or toggle is evolving, it is flagged **"verify in your tenant."** Never enforce (session,
> DLP block, CAA enforce) org-wide before the pilot gate passes.

## Named objects this solution creates and reuses
| Object | Name (reuse verbatim) | Purpose |
|---|---|---|
| Pilot OU | `Security Baseline - Pilot` | Curated scope validated before fleet rollout |
| CAA access level | `Access - Corp Network` | Require a known corporate IP range |
| CAA access level | `Access - Managed Device` | Require encrypted + screen-locked (+ company-owned) device |
| DLP rule (Drive) | `DLP - Drive - Sensitive - External` | Scan Drive files for sensitive data on external sharing |
| DLP rule (Gmail) | `DLP - Gmail - Sensitive - Outbound` | Scan outbound Gmail for sensitive data |

---

## Step 0 — Assess current posture (read-only)
Before changing anything, capture the baseline you are improving from.
- Run **`GWSEC-Discovery.ps1`** — reports 2SV method availability, session-control posture, Drive
  external-sharing settings, and whether any DLP rules / CAA access levels already exist.
- Cross-check in the Admin console: **Security → Security dashboard** and **Reporting → Audit and
  investigation** for current sharing / login patterns.
- Record the pre-change values (they are your **rollback targets**).

**Gate:** you have a written snapshot of the starting posture and the risky defaults to fix.

---

## Step 1 — Create the pilot OU and move representative users
- Admin console → **Directory → Organizational units → Create organizational unit** → name it
  **`Security Baseline - Pilot`** (or run **`GWSEC-Set-ScopeTargeting.ps1 -Apply`**).
- Move 3–10 representative users (a super-admin's own test account, one power user, one field/mobile
  user) into the pilot OU so every scenario is covered.

**Gate:** the pilot OU exists and contains representative users.

---

## Step 2 — Apply the hardening baseline (Layer 1) to the pilot OU
Apply each setting **scoped to `Security Baseline - Pilot`** (select the OU in the left pane of each
settings page), not the root OU.

**2a. 2-Step Verification (2SV).** Admin console → **Security → Authentication → 2-step
verification**.
- First confirm every super-admin has enrolled and holds **backup codes** (Security → Authentication
  → generate backup codes) — this is break-glass.
- Set **Allow users to turn on 2-Step Verification = On**, **Enforcement = On** for the pilot OU,
  choose the method (**Any**, or **Only security key** including passkeys for privileged users), and
  set a **New user enrollment period** so onboarding is not broken.

**2b. Google session control.** Admin console → **Security → Access and data control → Google session
control**. Set the **web session duration** to the agreed window (e.g. **8 hours** to **14 hours**)
so a stolen cookie cannot bypass 2SV indefinitely; require reauthentication (password / security
key) on expiry.

**2c. Drive & Docs sharing.** Admin console → **Apps → Google Workspace → Drive and Docs → Sharing
settings** (scoped to the pilot OU).
- Constrain **external sharing** (e.g. allowlisted domains only, or off), disable/limit **"anyone
  with the link"**, enable **warn when sharing outside the organization**, and set the default link
  scope to **restricted**.

**2d. Close less-secure surfaces.** Admin console → **Security → Access and data control → Less
secure apps / API controls → App access control** — restrict/allow-list third-party OAuth apps;
confirm legacy/basic-auth access is off. Keep the **super-admin count minimal**.

Use **`GWSEC-Remediation.ps1`** (default **`-WhatIf`**) to preview any scriptable baseline fixes
(e.g. tightening a broadly-shared file surfaced in Step 0) before applying with `-Apply`.

**Gate:** the pilot OU shows 2SV enforced, a bounded session, restricted sharing, and closed legacy
surfaces — and no pilot user's legitimate work is broken.

---

## Step 3 — Create CAA access levels (Layer 3, monitor mode) — *edition-gated*
Admin console → **Security → Access and data control → Context-Aware Access**. Turn CAA **On** for
the org if not already, then **Access levels → Create access level** (Basic mode).

**3a. `Access - Corp Network`.** Attribute → **IP subnet** → enter your corporate egress ranges in
**CIDR** (IPv4/IPv6). Condition = **Meet attributes**. Save.

**3b. `Access - Managed Device`.** Attributes → **Device policy**: **Encrypted = Encrypted**,
**Screen lock = required**, optionally **Company-owned = required**, and a **minimum OS version**.
Combine with AND logic. Save. *(Device attributes require endpoint verification / device management
signals — verify in your tenant.)*

Access levels do nothing until assigned. Create them now; assign in Step 6.

**Gate:** both access levels exist with correct signals; nothing is assigned/enforced yet.

---

## Step 4 — Author DLP rules (Layer 2, audit mode) — *edition-gated*
Admin console → **Security → Access and data control → Data protection**. If needed, build custom
detectors first via **Manage detectors → Add detector → Word list / Regular expression**.

**4a. `DLP - Drive - Sensitive - External`.** **Create rule → Drive**.
- **Scope:** the pilot OU (`Security Baseline - Pilot`).
- **Trigger:** *File shared outside the organization* (and *"anyone with the link"*).
- **Conditions:** predefined detectors (credit-card number, national ID, financial/health) and/or
  your custom detector, with a threshold (e.g. likelihood = *Possible* and count ≥ 1).
- **Action (start at audit):** **Audit only / log the event** (no block yet). Save + activate.

**4b. `DLP - Gmail - Sensitive - Outbound`.** **Create rule → Gmail**.
- **Scope:** the pilot OU. **Trigger:** *Message sent* (outbound / external recipients).
- **Conditions:** the same detector set applied to subject/body/attachments.
- **Action (start at audit):** **Audit only** (later: *Warn* / *Quarantine* / *Block delivery*).
  Save + activate.

**Gate:** both rules are active in **audit** mode and generating incidents you can review — no user
is blocked yet.

---

## Step 5 — Pilot: exercise the controls on the pilot OU
- **Baseline:** confirm pilot users are prompted for 2SV, sessions expire and reauthenticate,
  external-sharing warnings appear, and legacy clients are refused.
- **DLP:** from a pilot account, attempt to externally share a Drive test file containing a
  synthetic credit-card / national-ID string, and send an outbound test email with the same →
  confirm **audit incidents** appear in **Data protection** / the security investigation tool.
- **CAA (still monitor):** review Step 6 assignment behavior below.

Run **`GWSEC-Validation.ps1 -OrgUnitPath '/Security Baseline - Pilot'`** to check the pilot OU against
the intended baseline / DLP / CAA state, and **`GWSEC-Report.ps1`** for a coverage / exceptions view.

**Gate:** baseline applied, DLP fires on test content (audit), CAA levels ready — with **no
false-positive breakage** of legitimate pilot work.

---

## Step 6 — Assign CAA (monitor → enforce) and graduate DLP (audit → block)
**6a. Assign CAA in monitor mode.** Context-Aware Access → **Assign access levels** → select apps
(**Drive**, **Gmail**, and the **Admin console** for privileged OUs) → assign `Access - Corp Network`
and/or `Access - Managed Device` to the **pilot OU**. New assignments default to **monitor mode** —
this **simulates** enforcement (logs what *would* be blocked) without blocking users. Review the
would-block signals for false positives.
**6b. Enforce CAA.** Once monitor logs are clean, switch the assignment from **monitor** to
**enforce** for the pilot OU.
**6c. Graduate DLP.** Once audit incidents confirm the rules match the right content without noise,
raise the action ladder: **`DLP - Gmail - Sensitive - Outbound`** → **Warn** then **Block delivery**;
**`DLP - Drive - Sensitive - External`** → **Block external sharing**.

**Gate:** CAA enforced and DLP at block on the pilot OU, still with no legitimate-work breakage.
Re-run `GWSEC-Validation.ps1` — it should pass.

---

## Step 7 — Expand to the fleet, OU by OU
With the pilot validated:
- Apply the **hardening baseline** (Step 2) OU-by-OU, then **assign CAA** (monitor → enforce) and
  **scope DLP** rules to each OU, promoting audit→block per OU as each clears.
- After each wave, run **`GWSEC-Validation.ps1`** for the OU and **`GWSEC-Report.ps1`** for
  fleet-wide coverage and exceptions.
- Keep the **rollback** documented and tested at every wave.

**Gate:** every in-scope OU passes validation; the coverage report shows the baseline, DLP, and CAA
applied with exceptions explicitly tracked.

---

## Rollback (keep ready at every gate)
- **Session/2SV:** relax the session window / lift 2SV enforcement for the affected OU.
- **Sharing:** re-widen the sharing setting to the previous value recorded in Step 0.
- **DLP:** set the rule action back to **Audit only** (or deactivate the rule).
- **CAA:** set the assignment back to **monitor mode** (or unassign the access level).
Each is a single scoped change in the Admin console; record the pre-change value in Step 0 so
rollback is exact.

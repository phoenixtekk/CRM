# 2. Requirements Guide — Google Workspace Security Baseline, DLP & Context-Aware Access (CAA)

Verify **every** requirement before configuring. Each entry: **Description · Why · Verify ·
Implement-if-missing.** Category-wide prerequisites are in `global-requirements-google.md`.

> **Vendor boundary.** Admin console paths are authored from Google's current public documentation.
> **DLP for Drive/Gmail rule authoring and Context-Aware Access are edition-gated** (Enterprise /
> Education tiers) — confirm the exact editions and toggles that apply to *your* licensing. Anything
> not confirmed GA in your tenant is flagged **"verify in your tenant."**

## 2.1 A Workspace edition that supports the controls you will enforce
**Description:** A Google Workspace (or Cloud Identity) edition whose feature set covers the layers
you intend to enforce. The **hardening baseline** (2SV, session control, sharing) works on **all**
editions. **Context-Aware Access** and the **DLP for Drive/Gmail rule engine** require higher tiers
— typically **Enterprise Standard/Plus**, **Education Standard/Plus**, **Enterprise Essentials
Plus**, or **Cloud Identity Premium** (for CAA).
**Why:** Authoring DLP rules and CAA access levels on an edition that lacks them will fail at the
console — you must know before you plan the pilot which layers your license supports.
**Verify:** Admin console (`https://admin.google.com`) → **Billing → Subscriptions**; confirm the
edition and license counts. Then confirm the surfaces exist: **Security → Access and data control →
Data protection** (DLP) and **Security → Access and data control → Context-Aware Access**. *(Feature
availability is edition-gated — verify in your tenant.)*
**Implement:** Acquire the required edition through Google or an authorized reseller. If CAA/DLP are
out of scope for now, deploy **Layer 1 (hardening baseline)** alone and document the deferred layers.

## 2.2 Super-admin (and least-privilege operator roles)
**Description:** A **super-admin** account to set org-wide security toggles, plus scoped admin roles
so day-to-day work is least-privilege: **Security Settings** / **Services** (2SV, session, CAA),
**Data protection (DLP)** admin, and **Drive and Docs** settings.
**Why:** 2SV enforcement, session control, CAA, and DLP publishing require elevated rights; reserve
super-admin for tenant-wide toggles and delegate the rest.
**Verify:** Admin console → **Account → Admin roles**; confirm the operator holds Security, Data
protection, and Drive/Docs privileges, and that super-admins are few and 2SV-enrolled.
**Implement:** Assign least-privilege admin roles per surface; enroll every super-admin in 2SV
(ideally security key / passkey) **before** enforcing 2SV org-wide (see 2.3).

## 2.3 2SV readiness (enrollment path + break-glass)
**Description:** A path for users to enroll a second factor, a decided **enforcement method**
(any 2SV, or **security-key/passkey-only** for privileged accounts), a **new-user enrollment grace
period**, and **backup / break-glass** codes so enforcement does not lock anyone out.
**Why:** Enforcing 2SV before users have enrolled — or without break-glass — causes lockouts; the
grace period and backup codes are the safety net.
**Verify:** Admin console → **Security → Authentication → 2-step verification**; confirm allowed
methods, and that a super-admin has generated **backup codes** and holds a break-glass account.
**Implement:** Publish enrollment instructions, generate backup codes for admins, set the new-user
enrollment period, then enforce on the pilot OU first (Implementation Step 2).

## 2.4 Identity & session signals
**Description:** A defined **session policy** target (reauthentication window, e.g. 8–12h web) and
awareness of which sessions the setting governs (Google web session; native/mobile apps behave
differently).
**Why:** Indefinite sessions let a stolen cookie bypass 2SV; the session-control setting is a core
baseline lever, but it must be set at a value that does not cripple legitimate long-running work.
**Verify:** Admin console → **Security → Access and data control → Google session control**; confirm
the current web-session length and reauthentication policy.
**Implement:** Decide the target window with the security stakeholder; apply to the pilot OU first.

## 2.5 Context signals for CAA (network + device)
**Description:** The **context signals** CAA will gate on: known **corporate IP ranges** (CIDR),
**device** posture (encrypted, screen-lock, company-owned, minimum OS) via **endpoint verification /
device management** where required, and allowed **regions**.
**Why:** A CAA access level is only as good as its signals — you must know your egress IP ranges and
have device signals flowing before an access level can meaningfully require them. Device-attribute
levels depend on managed/endpoint-verified devices.
**Verify:** Confirm your corporate egress CIDR blocks; Admin console → **Devices** shows enrolled /
endpoint-verified devices for the pilot users. *(Device-signal availability depends on management
posture — verify in your tenant.)*
**Implement:** Catalog corporate IP ranges; roll out endpoint verification / device management to the
pilot users so device attributes are available before you require them in an access level.

## 2.6 DLP scope & detectors (what "sensitive" means here)
**Description:** A decided **DLP scope**: which content types are sensitive (predefined detectors —
credit-card, SSN/national ID, financial/health — or **custom word-list / regex detectors**), which
surfaces (**Drive**, **Gmail**, and which triggers: external sharing, message send), and the graded
**action** ladder (audit → warn → block).
**Why:** DLP rules are only meaningful against defined sensitive-data classes and a decided
enforcement posture; starting at **block** without an audit phase breaks legitimate workflows.
**Verify:** The data-governance owner has confirmed the sensitive-data classes and the surfaces in
scope; Admin console → **Security → Access and data control → Data protection** loads.
**Implement:** Document the detector list and the audit→warn→block plan (Implementation Steps 4–5);
build any custom detectors before authoring rules.

## 2.7 Pilot scope (OU) and named baseline objects
**Description:** A **pilot organizational unit** (e.g. `Security Baseline - Pilot`) to validate on
before fleet rollout, and the **named** baseline objects this solution reuses: the pilot OU, the
CAA access levels (`Access - Corp Network`, `Access - Managed Device`), and the DLP rules
(`DLP - Drive - Sensitive - External`, `DLP - Gmail - Sensitive - Outbound`).
**Why:** Every solution follows **Assess → Configure → Pilot → Validate → Expand**; a curated pilot
OU proves the design, and consistent object names make validation, reporting, and rollback repeatable.
**Verify:** Admin console → **Directory → Organizational units** shows the pilot OU (or run
`GWSEC-Set-ScopeTargeting.ps1`).
**Implement:** Create the pilot OU with `GWSEC-Set-ScopeTargeting.ps1` (or **Directory →
Organizational units → Create**) and move a few representative users into it.

## 2.8 Security stakeholders + change control / rollback
**Description:** Engagement with **security (CISO)** and **data-governance / legal** stakeholders
whose policies the baseline, DLP, and CAA must satisfy, and a documented **change-control** process
with a **rollback** for every production change (session enforcement, sharing tightening, DLP block,
CAA enforce).
**Why:** Tightening sessions/sharing, enforcing DLP block, or enforcing CAA can block legitimate work
or lock users out; a pilot gate, change window, and rollback are mandatory (global requirement 6).
**Verify:** Applicable policies and named approvers are confirmed; a change ticket exists with an
approver, a maintenance window, and a rollback step.
**Implement:** Identify security/governance owners, obtain the policy requirements, and record the
rollback (re-widen sharing, relax session, set DLP back to audit, set CAA back to monitor) before
production.

---
## Checklist
- [ ] Edition supports the layers in scope (baseline = all; DLP rules + CAA = Enterprise/Education tiers — verify in your tenant)
- [ ] Super-admin available; least-privilege operator roles (Security, Data protection, Drive/Docs) assigned
- [ ] 2SV enrollment path, method decided, new-user grace period, and admin backup/break-glass codes ready
- [ ] Session policy target decided (e.g. 8–12h web reauthentication)
- [ ] CAA context signals ready — corporate CIDR ranges cataloged; device signals flowing for pilot users
- [ ] DLP scope decided — detectors, surfaces (Drive/Gmail), audit→warn→block ladder
- [ ] `Security Baseline - Pilot` OU created; named baseline/DLP/CAA objects agreed
- [ ] Security & data-governance engaged; change control / rollback documented

# 7. Best Practices — Google Workspace Security Baseline, DLP & Context-Aware Access (CAA)

Field-tested practices for a **staged, low-breakage** rollout of the Workspace security posture. The
theme throughout is **staged enforcement**: observe before you block, pilot before you fleet, and
keep a tested rollback at every step.

## Staged enforcement (the core discipline)
- **Audit → Warn → Block for DLP.** Never publish a DLP rule straight to *block*. Run in **audit**
  long enough to see real incident volume, tune detectors/thresholds against false positives, add
  **warn** so users self-correct, then **block** only the classes that must never leave.
- **Monitor → Enforce for CAA.** New CAA assignments default to **monitor mode** — keep them there
  until the would-block logs are clean, then flip to **enforce**. Monitor mode is your simulation;
  use it.
- **Pilot OU → fleet, OU by OU.** Prove every control on `Security Baseline - Pilot` before touching
  a production OU, then expand in waves, validating each. Never apply a new enforcement to the root
  OU first.

## Identity & session hygiene
- **Enroll admins before enforcing.** Every super-admin enrolls 2SV (prefer **security key /
  passkey**) and holds **backup codes** before org-wide enforcement — and keep a **break-glass**
  super-admin account documented and secured.
- **Use security-key/passkey-only for privileged accounts.** Phishing-resistant factors for the
  accounts that matter most; a **new-user enrollment grace period** keeps onboarding smooth.
- **Bound the session, don't cripple it.** Set the web-session window tight enough to matter
  (8–14h) but not so tight it disrupts legitimate long tasks; decide the value with security.
- **Minimize super-admins** and review admin-role assignments regularly.

## Data protection (DLP)
- **Start from templates, then customize.** Use Google's built-in rule templates (financial, health,
  PII) as a baseline; add **custom word-list / regex detectors** only for your organization-specific
  data.
- **Tune thresholds to cut noise.** Combine detector *likelihood* and *minimum count* so a single
  incidental match doesn't fire; the negative test (benign content passes) is as important as the
  positive.
- **Cover both surfaces.** Author matched rules for **Drive** (external sharing / anyone-with-link)
  and **Gmail** (outbound send) — leaking is equally possible through either.
- **Review incidents, don't just collect them.** Assign an owner to triage DLP incidents in the
  security investigation tool; incidents are signal, not noise-to-ignore.

## Context-Aware Access (CAA)
- **Signals before requirements.** Catalog corporate egress CIDR ranges and get device/endpoint
  signals flowing **before** an access level requires them — an access level with no signal blocks
  everyone.
- **Compose small, named levels.** Keep `Access - Corp Network` and `Access - Managed Device` as
  separate, reusable levels and combine per app, rather than one monolithic level.
- **Gate the Admin console.** Assign a strict access level to the **Admin console** for privileged
  OUs so admin actions require a trusted context — a high-value, low-friction win.
- **Mind non-web clients.** CAA behavior differs for native/mobile apps; test those paths explicitly
  before enforcing.

## Change control & rollback
- **Record pre-change values (Step 0) as rollback targets** for every control before you change it.
- **One scoped change at a time** per OU, under a change window with an approver, so a regression is
  easy to isolate and reverse.
- **Rehearse rollback on the pilot** at least once (relax session, re-widen sharing, DLP→audit,
  CAA→monitor) so you know it works under pressure.

## Operate & sustain
- **Re-validate on a schedule.** Run `GWSEC-Validation.ps1` and `GWSEC-Report.ps1` periodically —
  posture drifts as OUs, users, and sharing change.
- **Track exceptions explicitly.** Any OU or user deliberately outside the baseline gets a named,
  owned exception with a review date — not a silent gap.
- **Verify edition-gated features in your tenant.** CAA and DLP-rule availability and exact toggles
  evolve; confirm against your license and Google's current documentation before relying on them.

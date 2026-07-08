# 1. Solution Overview — Microsoft Purview Optimization & Tune-Up

## What this solution is
This solution is a structured **tune-up** of an existing **Microsoft Purview** deployment whose signal
has decayed into noise. Over time, DLP rules match too broadly, sensitivity/auto-labeling flags the
wrong content, insider-risk indicators fire on ordinary behaviour, and alert policies page on volumes
that no one acts on. The result is **alert fatigue** — analysts stop trusting the console, real
violations hide in the noise, and the compliance program looks busy but is not defensible. This
solution **reduces false positives and alert noise** across **DLP, sensitivity/auto-labeling,
insider-risk indicators, and alert policies**, using each capability's own **simulation / test** mode
so nothing is changed blind, then validates the reduction against pass/fail gates before re-enforcing.

It is written for an administrator who already **has** Purview running and now needs to make it
**accurate**. It does not stand up a greenfield deployment — it measures what your existing policies do,
finds the noisy rules, tunes them in simulation, proves the false-positive rate dropped without letting
real detections through, and re-enforces under change control.

It is **precision work, not policy authorship.** This solution does **not** decide what your DLP should
protect, what a sensitivity label *means*, or whether a given insider-risk signal is a real HR concern.
Those are **determinations** owned by compliance, records, privacy, security, HR, and legal. Here you
make the *existing* policy set fire **on the right things** — fewer false positives, less noise, higher
trust — while every determination stays with its owner.

## The four noise sources this tunes
- **DLP false positives** — rules that match on **too-low a confidence level**, **too-low an instance
  count**, or **without the exceptions** real business workflows need (e.g. a finance mailbox that
  legitimately handles card-like numbers). Tuned by raising the **confidence level**, adjusting the
  **min/max instance count** on the sensitive-information-type condition, and adding **`ExceptIf`**
  conditions — all measured first in **simulation** (`TestWithoutNotifications`).
- **Sensitivity / auto-labeling over-reach** — **auto-labeling policies** applying (or recommending) a
  label to content that should not carry it, driven by over-broad SIT matching. Auto-labeling has a
  first-class **simulation mode** (`TestWithoutNotifications`) that shows exactly what *would* be
  labeled before anything is; tuning uses that view to tighten the conditions before enforcing.
- **Insider-risk indicator noise** — policies firing on **too many low-value indicators** or **too
  short a triggering window**, producing alerts HR/analysts dismiss. Insider Risk is **HR- and
  privacy-sensitive**: this solution tunes it **in the portal**, under strict **role separation** and
  **privacy-by-design** (pseudonymization on where available), and the *outcome* of any case is
  **deferred to HR/legal** — you tune the noise, not the verdict.
- **Alert-policy noise** — **alert policies** (`Get-ProtectionAlert`) with **thresholds too low** or
  **no aggregation**, paging on every single event. Tuned by raising the **threshold**, switching to
  **aggregated** alerting, and scoping notification recipients — so an alert means something again.

## How the signal is measured
- **DLP match and false-positive detail** comes from **`Get-DlpDetailReport`** (Security & Compliance
  PowerShell), which returns per-match records including whether a user **overrode** the policy or
  reported a **false positive**, and the matching rule — the raw material for finding the noisiest
  rules. *(Availability/retention window is tenant-dependent — verify.)*
- **Activity and alert volume** comes from **`Search-UnifiedAuditLog`** filtered to the DLP and
  alert record types, and from the **alert policies** themselves (`Get-ProtectionAlert`).
- **Auto-labeling impact** is read from the policy's **simulation** results before any label is applied.
- Everything the scripts read is **read-only**; everything they change is **`-WhatIf` / `-Commit`
  gated** and lands the policy in **simulation first**.

## What is authored exactly vs deferred / flagged
- **Exact cmdlets and portal navigation** are given for the **Microsoft Purview portal**
  (`purview.microsoft.com`), **Security & Compliance PowerShell** (`Connect-IPPSSession`), and
  **Exchange Online PowerShell** (`Search-UnifiedAuditLog`). Where a surface still lives in the classic
  compliance portal, both locations are named.
- **Licensing is plan-gated and flagged.** Advanced DLP, auto-labeling, and Insider Risk Management
  generally require **Microsoft 365 E5 / E5 Compliance** — availability is **"verify your
  licensing/tenant"**, never assumed.
- **The portal is evolving.** Menu and card names shift and surfaces move between the classic and new
  portals — where a path is version-dependent, this solution flags **"verify against your current
  portal."**
- **Insider-risk cmdlet coverage is limited by design.** Insider Risk Management policy tuning is
  **portal-driven** (with narrow, privacy-preserving PowerShell/Graph read surfaces) — this solution
  does **not** invent IRM configuration cmdlets; it gives the exact **portal** tuning steps under role
  separation.
- **Determinations are deferred.** What DLP must protect, what a label means, whether an insider-risk
  case is real, and what retention a record needs are owned by **compliance, records, privacy,
  security, HR, and legal**. This solution reduces noise and evidences the reduction; it does not rule.

## The standard deployment model
> **Assess** the current policy set and its false-positive/noise signal → **Design** the target
> thresholds, exceptions, and aggregation → **Configure** the tuning **into simulation/test mode**
> (never straight to enforce) → **Pilot** on a named scope → **Validate** false positives dropped and
> no real detections were lost, against pass/fail gates → **Expand (enforce)** the tuned policies and
> schedule recurring health checks. Pattern: **Assess → Design → Configure → Pilot (simulate) →
> Validate → Expand (enforce)**, with explicit pass/fail gates and a documented rollback. DLP, label,
> insider-risk, and alert changes are high-impact — **always piloted in simulation/test first**.

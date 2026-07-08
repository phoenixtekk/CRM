# Executive Summary

**Outcome.** Intune's Android Enterprise management moved from the **legacy Google Play EMM API**
to the **Android Management API (AMAPI)** deliberately and with low disruption — the estate
assessed, the migration waved, the end-user and **re-enrollment** impact **verified rather than
assumed**, and each cohort validated to confirm devices manage under AMAPI, Google accounts add,
and managed Google Play apps still deliver.

**The problem it solves.** Microsoft is transitioning Intune's Android Enterprise capabilities onto
AMAPI. Teams need three things they usually lack: a clear **migration approach**, an honest read on
the **end-user impact**, and certainty about **whether devices re-enroll**. The rollout is staged
and **actively evolving**, so the biggest risk is acting on stale assumptions — communicating the
wrong outcome, resetting a kiosk unexpectedly, or breaking app delivery — because someone asserted
a behavior from memory instead of verifying it.

**Approach.** A pilot-first playbook built around a single discipline: **verify every
version-specific behavior against current Microsoft guidance and your own tenant.** It assesses the
Android estate and enrollment models, plans a migration wave, decides the enrollment path per model
(including a readiness check for the newer **web / account-driven enrollment**), then **pilots each
enrollment model to observe the real re-enrollment / user impact before expanding** — turning the
impact statement from a guess into documented fact. Five Microsoft Graph PowerShell tools inventory
the estate, plan waves, check web-enrollment readiness, and produce a post-migration validation
report — all read-only or `-WhatIf` by default, least-privilege, no stored secrets.

**Why it is low-risk.** Everything is **pilot-first** with explicit pass/fail gates — *manage under
AMAPI → accounts add → apps deliver → compliant* — and a **halt-and-hold** rollback that keeps
un-migrated devices on the current path and never disturbs already-validated ones. Critically, the
solution **refuses to publish a timeline or re-enrollment outcome it cannot verify**: every such
behavior is flagged for confirmation against Microsoft's live guidance and proven in the pilot. The
result is a repeatable, evidence-backed migration that stays current as AMAPI evolves — the estate
migrated with eyes open, not on assumptions.

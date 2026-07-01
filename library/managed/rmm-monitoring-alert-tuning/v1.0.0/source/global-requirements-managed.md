# Global Requirements (Managed) — RMM Monitoring & Alert Tuning — Noise Reduction & Actionable Alerting

These are the category-wide prerequisites shared by every **Managed** solution. They are the operating foundation a managed-services practice must have in place before any individual Managed runbook (including this one) is executed. Solution-specific requirements are in `02-requirements.md`. For each item: **Description / Why / Verify / Implement-if-missing** — never assume any of these is already true.

---

## GR1 — Established MSP practice and tooling administration
**Description.** A functioning managed-services practice with administrative ownership of the core operational tooling (RMM, PSA, documentation, and remote access).
**Why.** Tuning and operating monitoring requires an accountable team with the rights to change policies and the mandate to own the outcome.
**Verify.** Confirm named owners exist for the RMM and PSA and that they hold administrative roles.
**Implement-if-missing.** Assign tooling owners and grant the administrative roles before starting; do not run the loop from a technician account.

## GR2 — MFA and least-privilege access
**Description.** Multi-factor authentication enforced on all administrative tooling, with role-based, least-privilege access.
**Why.** RMM and PSA hold the keys to every managed endpoint; a compromised admin account is a fleet-wide incident. Tuning work uses elevated rights and must be protected.
**Verify.** Confirm MFA is enforced on RMM/PSA admin logins and that roles grant only the access each function needs.
**Implement-if-missing.** Enable MFA, define least-privilege roles, and remove standing access that is not required.

## GR3 — A maintained CMDB / asset inventory
**Description.** A current configuration management database recording clients, sites, devices, business hours, and criticality.
**Why.** Per-endpoint metrics, business-hours routing, and severity decisions all depend on an accurate inventory; stale data corrupts both the baseline and the routing.
**Verify.** Spot-check the CMDB against the RMM device list and confirm business hours and criticality are recorded.
**Implement-if-missing.** Reconcile the CMDB with the RMM, fill in business hours/criticality, and establish a refresh cadence.

## GR4 — Change control / change management
**Description.** A documented change-management process covering approval, recording, and rollback for changes to managed environments.
**Why.** Monitoring changes affect live production for clients; every threshold, routing, or automation change must be reviewed, logged, and reversible.
**Verify.** Confirm a change record can be raised and that prior state is captured before changes.
**Implement-if-missing.** Adopt a lightweight change-control workflow (request → approve → implement → verify → record) before editing live policy.

## GR5 — Secrets management
**Description.** A secrets manager / password vault for API keys, service-account credentials, and integration tokens — never stored in scripts or documents.
**Why.** Tuning may use RMM/PSA API keys for export and ticket creation; leaked credentials expose every managed client.
**Verify.** Confirm API keys and service accounts live in the vault and are not hardcoded in scripts or configs.
**Implement-if-missing.** Move any embedded credentials into the vault; reference them at runtime only.

## GR6 — A designated pilot client
**Description.** A representative client or device group nominated for first rollout of changes.
**Why.** Changes must be proven on a contained population before fleet-wide application, limiting blast radius.
**Verify.** Confirm a pilot client is named and its stakeholders accept piloting.
**Implement-if-missing.** Select a lower-risk, representative client and confirm acceptance before broad rollout.

## GR7 — A documentation home
**Description.** A durable, access-controlled documentation location (e.g. an IT documentation platform, SharePoint, or wiki) for runbooks, baselines, and reports.
**Why.** The tuning baseline, severity matrix, and routing matrix must persist and be discoverable; knowledge that lives only in one technician's head is not operable.
**Verify.** Confirm a documentation home exists with appropriate access controls.
**Implement-if-missing.** Stand up or designate the documentation home and record all named objects there as they are produced.

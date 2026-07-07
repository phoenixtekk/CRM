# Deliverables Summary

This solution delivers a complete, self-guided OAuth & third-party app-access governance package for
Google Workspace: the documentation set plus five authentic Python automation tools.

## Documentation

- **Solution Overview** — the OAuth risk model (scopes, connected apps, the trusted/limited/blocked
  API access control model, Marketplace allowlisting, unverified-app blocking) and the reference
  design with named artifacts.
- **Requirements Guide** — the solution-specific prerequisites (super-admin/API-controls privilege,
  Admin SDK + delegated automation identity, scope-sensitivity reference, vetting authority,
  representative pilot, change window), each with verify/implement steps, building on the shared
  Google-category global requirements.
- **Implementation Guide** — exact ordered steps: inventory apps + scopes, classify by risk, configure
  API access control + Marketplace allowlist + unverified-app block, pilot, validate against the
  gates, revoke risky grants, and expand org-wide — with pass/fail gates and rollback at each stage.
- **Testing & Validation** — seven procedures with expected pass/fail, covering the three governance
  gates plus no-false-breakage and revocation checks.
- **Troubleshooting** — common failure modes (auth/scope errors, reporting lag, broken legitimate
  apps, revocation side-effects) and resolutions.
- **Best Practices** — durable app-access hygiene: vet-before-trust, default-deny the unknown,
  scheduled re-inventory and token review, and safe automation.
- **Executive Summary** — the outcome, approach, and why the change is safe and governed.

## Python tools (`scripts/`)

All tools are **read-only or dry-run by default**; writes/revocations require `--apply`. They
authenticate via **Application Default Credentials** or a delegated service account — **no hardcoded
credentials, no exported keys, no secrets in code**. Python 3.10+; `pip install
google-api-python-client google-auth`.

1. **`oauth-app-inventory.py`** — *Assessment / discovery (read-only).* Enumerates connected
   third-party apps, their OAuth scopes, and per-app grant counts from the Admin SDK Reports API
   (OAuth-token activity) and Directory API (domain tokens); risk-scores each app (HIGH/MEDIUM/LOW/
   UNKNOWN) using the scope-sensitivity reference. Produces `App Inventory – Org-Wide – v1`.

2. **`api-access-control-helper.py`** — *Configuration helper (dry-run default).* Takes a
   classification plan (Trusted/Limited/Blocked per app) and shows current-vs-intended access level,
   flagging changes that could break a legitimate app. Applies only with `--apply`; supports pilot
   scoping. Drives `Trusted/Limited/Blocked Apps – Org-Wide – v1`.

3. **`app-access-validation.py`** — *Validation / report generator (read-only).* Checks the three
   governance gates — (A) high-risk scopes only held by Trusted apps, (B) unverified apps blocked,
   (C) Marketplace allowlist-only — and emits a pass/fail report and the approver review packet.

4. **`risky-grant-revoker.py`** — *Policy/guardrail — token revocation (`--apply` gated).* From the
   inventory, targets HIGH-risk (or vetted-Blocked) standing grants and revokes them via the Directory
   API `tokens.delete`, writing an evidence log. Dry-run by default; executes `Token Revocation –
   Risky-Grants – Runbook`.

5. **`scope-config-helper.py`** — *Scope/config helper (read-only).* Loads and validates the
   scope-sensitivity reference (restricted/sensitive/basic tiers), reports scopes seen in the
   inventory that are UNKNOWN to the reference (for manual triage), and emits a reviewable
   scope-classification file the other tools consume.

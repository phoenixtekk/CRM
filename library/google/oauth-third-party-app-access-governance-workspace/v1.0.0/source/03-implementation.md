# Implementation

Follow these steps in order. They implement the **Assess → Design → Configure → Pilot → Validate →
Expand** model, pilot-first, with explicit pass/fail gates and a documented rollback for every
org-wide change. Every artifact created is **named** with the convention `<Purpose> – <Scope> –
<Stage>` and that exact name is reused in later steps, testing, troubleshooting, and the Python tools.

Console navigation is current as of authoring; **verify paths in your tenant** where Google may have
moved a menu. All automation is the included Python tooling, run with ADC or a delegated
service account — **no keys in code**.

---

## Stage 0 — Prepare the automation environment

1. On the workstation that will run the tools, install Python 3.10+ and the client library:
   ```
   pip install google-api-python-client google-auth
   ```
2. Authenticate with Application Default Credentials as an admin (or configure the delegated
   service account per Requirement 2):
   ```
   gcloud auth application-default login
   ```
3. Confirm the automation identity and scopes:
   ```
   python oauth-app-inventory.py --check-auth
   ```
   **Pass gate:** the tool prints the authenticated principal and confirms the read-only Reports and
   Directory scopes are present. If not, fix auth before proceeding (see Requirement 2).

---

## Stage 1 — Assess: inventory connected apps + scopes

Produce `App Inventory – Org-Wide – v1`.

1. Run the read-only discovery tool to enumerate connected third-party apps, their OAuth scopes, and
   the number of users who granted each — risk-scored by scope sensitivity:
   ```
   python oauth-app-inventory.py --days 180 --out app-inventory.json
   ```
   It reads OAuth-token activity from the **Reports API** and domain tokens from the **Directory API**,
   joins them, and applies the scope-sensitivity reference to score each app
   (**HIGH / MEDIUM / LOW / UNKNOWN**).
2. Review `app-inventory.json`. Confirm every **HIGH**-risk app (holding restricted/sensitive scopes:
   full Gmail, full Drive, admin/directory, etc.) is understood, and every **UNKNOWN**-scope app is
   triaged against the scope reference.

   **Pass gate:** the inventory is complete (row count matches the Admin console **API controls →
   App access control → connected apps** count, allowing for reporting lag) and no HIGH/UNKNOWN app is
   unexplained.

## Stage 2 — Design: classify apps and define policy

Produce `Trusted Apps – Org-Wide – v1`, `Limited Apps – Org-Wide – v1`, `Blocked Apps – Org-Wide –
v1`, and the vetting workflow.

1. Using the inventory + Requirement 4 risk criteria, classify each app into:
   - **Trusted** — vetted, may access all (incl. restricted/sensitive) scopes → `Trusted Apps –
     Org-Wide – v1`.
   - **Limited** — allowed basic/non-sensitive scopes only → `Limited Apps – Org-Wide – v1`.
   - **Blocked** — denied all Google access → `Blocked Apps – Org-Wide – v1`.
2. Record each decision (app name, OAuth client ID, scopes, risk, decision, approver, date) — the
   report generator produces this review packet for the approver.
3. Define `App-Vetting Workflow – Org-Wide – v1`: the intake form, risk criteria, reviewer, decision
   record, and where the decision is applied (which list). This is the durable process for all new
   apps going forward.

   **Pass gate:** every HIGH-risk app has an explicit Trusted/Limited/Blocked decision with a named
   approver; the vetting workflow is documented and agreed.

## Stage 3 — Configure (preview first): API access control, Marketplace, unverified apps

All configuration lives in **Admin console → Security → Access and data control → API controls**.
Configure with a dry-run/preview mindset — stage the desired state, apply to the pilot first.

1. **App access control (per-app trusted/limited/blocked).** In **API controls → App access
   control → Manage third-party app access**, set each app from your Stage 2 lists to **Trusted**,
   **Limited**, or **Blocked**. You can scope some settings to an OU/group for the pilot.
   - Preview the intended state first with the config helper (dry-run default):
     ```
     python api-access-control-helper.py --plan classification.json --dry-run
     ```
     It prints, per app, the current vs. intended access level and flags any change that would break a
     legitimate app — **no change is applied without `--apply`.**
2. **Marketplace allowlist.** In **API controls → App access control → Settings → Google Workspace
   Marketplace settings**, set the install policy to **"Allow users to install only allowlisted
   apps"** and populate the allowlist from `Trusted Apps – Org-Wide – v1`. Name this
   `Marketplace Allowlist – Org-Wide – v1`.
3. **Unverified / unconfigured third-party apps.** In **API controls → Settings → Unconfigured third-
   party apps** (naming varies by tenant/rollout — *verify in your tenant*), set unconfigured apps to
   be **blocked** from accessing Google services, or at minimum blocked from **sensitive and
   restricted scopes**. Name this `Unverified-App Block – Org-Wide – Pilot` (pilot-scoped first).

   > **Rollback for every setting above:** the previous access level / install policy / unconfigured-
   > app setting, recorded before the change. Reverting the specific setting restores prior behavior;
   > tokens already granted are unaffected by policy alone (revoke separately in Stage 5b).

   **Pass gate:** the config helper's dry-run shows the intended state matches the Stage 2 design with
   no unexplained breakage before you pass `--apply`.

## Stage 4 — Pilot: apply to the pilot OU/group

1. Scope the settings above to `App-Access Pilot – Pilot-OU – v1` (the representative pilot from
   Requirement 5). Apply the classification with the helper:
   ```
   python api-access-control-helper.py --plan classification.json --scope pilot-ou --apply
   ```
2. Have pilot users exercise their normal third-party apps for the agreed soak period.

   **Pass gate:** no legitimate pilot app is broken; any Trusted app still works; blocked/unverified
   apps are correctly denied (verified in Stage/Validation testing).

## Stage 5 — Validate against the gates

1. Run the validation/report tool against the pilot scope:
   ```
   python app-access-validation.py --scope pilot-ou --report validation.json
   ```
   It checks the three gates: **(a)** high-risk (restricted/sensitive) scopes are only held by Trusted
   apps; **(b)** unverified/unconfigured apps are blocked (or blocked from sensitive scopes);
   **(c)** the Marketplace install policy is allowlist-only and matches `Trusted Apps – Org-Wide – v1`.

   **Pass gate:** all three gates PASS for the pilot. Any FAIL is remediated (reclassify, adjust
   setting, or revoke) and re-validated before expansion.

### Stage 5b — Revoke risky standing grants (`--apply` gated)

Standing tokens granted before the policy remain until revoked. Use the revocation helper to act on
the HIGH-risk grants identified in the inventory, following `Token Revocation – Risky-Grants –
Runbook`:

1. Preview which grants would be revoked (safe default — no writes):
   ```
   python risky-grant-revoker.py --inventory app-inventory.json --risk HIGH --dry-run
   ```
2. After approver sign-off, revoke:
   ```
   python risky-grant-revoker.py --inventory app-inventory.json --risk HIGH --apply
   ```
   It calls the **Directory API `tokens.delete`** for each targeted (user, app) grant and writes an
   evidence log.

   > **Rollback:** revocation forces users to re-consent to legitimately needed apps; there is no
   > "un-revoke." Therefore revoke only vetted-Blocked or clearly abusive grants, communicate to
   > affected users, and keep the evidence log. This is why `--apply` is gated and approver-signed.

## Stage 6 — Expand org-wide under change control

1. Within the approved change window (Requirement 6), promote each pilot setting from pilot scope to
   **org-wide**: the per-app Trusted/Limited/Blocked classification, `Marketplace Allowlist –
   Org-Wide – v1`, and `Unverified-App Block – Org-Wide – Pilot` → org-wide (rename to
   `Unverified-App Block – Org-Wide – v1`).
2. Re-run validation org-wide:
   ```
   python app-access-validation.py --scope org --report validation-org.json
   ```
   **Pass gate:** all three gates PASS org-wide.
3. Operationalize: schedule periodic re-inventory + token review (see Best Practices), and route all
   new third-party apps through `App-Vetting Workflow – Org-Wide – v1` before they are Trusted.

   > **Org-wide rollback:** revert the specific org-wide setting to its recorded prior value; the
   > pilot scope remains governed while you investigate.

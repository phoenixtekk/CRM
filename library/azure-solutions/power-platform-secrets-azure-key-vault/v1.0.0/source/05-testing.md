# 5. Testing Guide — Standardize Power Platform Secrets in Azure Key Vault

Run after the pilot configuration applies (Implementation Step 9) and again after each expansion and
after each rotation. The goal of the last four tests is to prove the secret value appears **nowhere**
in Power Platform.

## Test 1 — Vault permission model is RBAC
**Do:** Azure portal → vault → **Access configuration**, or run `PPKV-Validation.ps1`.
**Expected:** Permission model is **Azure role-based access control**.

## Test 2 — Power Platform service principal has read access
**Do:** Vault → **Access control (IAM) → Role assignments**, or run `PPKV-Validation.ps1`.
**Expected:** `Key Vault Secrets User` is assigned to the Power Platform / Dataverse service principal (`Secrets Reader – Power Platform SP – <Vault>`).

## Test 3 — The Secret environment variable resolves
**Do:** Run the pilot flow/app that references `Secret EnvVar – <Integration> – <Environment>`; run `PPKV-Validation.ps1`.
**Expected:** The flow/app runs successfully using the vault-backed value — the reference resolves to the current secret version.

## Test 4 — Secret value NOT in flow run history
**Do:** Open the flow's **run history** → the run → inspect each action's inputs and outputs.
**Expected:** The secret value is masked / not shown; actions that touch the secret show **Secure Inputs/Outputs** in effect. No literal secret anywhere in the run.

## Test 5 — Secret value NOT in app formulas / flow definition
**Do:** Inspect the app formulas and the flow actions where the secret was previously hardcoded.
**Expected:** Only a reference to the environment variable remains — no literal secret value.

## Test 6 — Secret value NOT in connector definitions or exports
**Do:** Export the solution (and any custom connector). Open the exported JSON; run `PPKV-Discovery.ps1` against the export.
**Expected:** No hardcoded-secret pattern is flagged; the exported definition contains only references, not values.

## Test 7 — Rotation flows through without a rebuild
**Do:** Add a new version of the secret in the vault (or run `PPKV-Set-RotationOwnership.ps1` to update expiry), then run the flow/app again **without editing it**.
**Expected:** The flow/app uses the **new** value automatically (versionless reference resolves current) — no edit or re-publish was needed.

## Test 8 — Inventory / access / expiry report
**Do:** Run `PPKV-Report.ps1`.
**Expected:** A clear list of secrets with owner/purpose tags, expiry/rotation status, and who holds read/manage roles — no secret values printed.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| **Pilot pass** | Tests 1–6 pass on the pilot flow/app — the vault-backed value works and appears in no run history, formula, connector, or export |
| **Rotation pass** | Test 7 passes — a rotated secret is picked up with no rebuild |
| **Expand pass** | Tests 3–6 pass for every additional flow/app, and Test 8 shows a clean, governed inventory |

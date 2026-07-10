# 3. Implementation — AWS IAM Identity Center + Microsoft Entra SSO Federation

Follow these steps in order. You work across two consoles — the **AWS Management Console** (as an assumed least-privilege role in the management or delegated Identity account, never root) and the **Microsoft Entra admin center** (`entra.microsoft.com`). Every object uses the `<Purpose> – <Scope> – <Stage>` convention from the Overview and is reused verbatim in Testing, Troubleshooting, and the scripts. **Do the pilot against the sandbox account and one pilot group before touching any production account or IAM user.**

> Portal navigation paths and blade names change. Where a path has moved, use the console search bar for the service/feature name. Confirm IAM Identity Center feature and Region availability for your partition before you begin.

---

## Stage A — Assess

### Step A1. Confirm the organization and identity
1. Sign in to the AWS Management Console as your assumed deployment role.
2. Open **AWS Organizations**. Confirm the banner shows **All features** enabled and note the **management account ID** and the **sandbox account ID** (from R5).
3. Run the discovery script `AWSSSO-Discovery.sh` (read-only). It reports whether an IAM Identity Center instance exists, lists existing IAM users and access keys, and lists any existing permission sets. Save the output — it is your baseline.

### Step A2. Confirm Entra rights and licensing
1. Sign in to the **Entra admin center** (`entra.microsoft.com`) as Application Administrator or higher.
2. Confirm you can reach **Entra ID -> Enterprise applications** and that **New application** is available.
3. Confirm the tenant licensing covers the features you plan to use (R7). *Verify current licensing.*

---

## Stage B — Configure

### Step B1. Enable IAM Identity Center
1. In the management account, open **IAM Identity Center**.
2. Choose your home Region (R2) in the Region selector, then choose **Enable**.
3. When prompted for the deployment, choose **Enable with AWS Organizations**. Wait for the instance to be created.
4. On the dashboard, note the **AWS access portal URL** (e.g. `https://d-xxxxxxxxxx.awsapps.com/start`). You will need it for the Entra SAML config and for user testing.

### Step B2. Register the delegated administrator (Identity account)
1. Still in the management account, open **IAM Identity Center -> Settings -> Management**.
2. Under **Delegated administrator**, choose **Register account** and select your designated **Identity account** (a member account, not the management account).
3. From now on, perform day-to-day SSO administration signed into the **Identity account** where possible. (Changing the identity source in B4 must still be done from the management account.)

### Step B3. Create the Entra enterprise application
1. In the Entra admin center, go to **Entra ID -> Enterprise applications -> New application**.
2. In the gallery, search for the **AWS IAM Identity Center** application and choose it. On the create pane set the name to **`AWS IAM Identity Center – Federation – SSO`** and choose **Create**.
3. This single gallery app supports both SAML SSO and SCIM provisioning, which you configure next.

### Step B4. Establish SAML trust (both directions)
1. **AWS side (management account):** In **IAM Identity Center -> Settings -> Identity source**, choose **Actions -> Change identity source -> External identity provider**.
2. On that page, **download the AWS SAML metadata** file (the service-provider metadata). Leave this page open.
3. **Entra side:** open the `AWS IAM Identity Center – Federation – SSO` app -> **Single sign-on -> SAML**.
   - In **Basic SAML Configuration**, upload the AWS metadata file (choose **Upload metadata file**) so the Identifier (Entity ID) and Reply URL populate from AWS. Save.
   - In the **SAML Certificates** section, download the **Federation Metadata XML** (the Entra IdP metadata).
4. **Back on the AWS side:** upload the Entra **Federation Metadata XML** as the IdP SAML metadata, then choose **Next / Change identity source** to confirm. AWS now trusts Entra for authentication.
5. In Entra, on the app **-> Users and groups**, add yourself (a test admin) so you can sign in during the pilot.

### Step B5. Enable SCIM provisioning (both directions)
1. **AWS side:** In **IAM Identity Center -> Settings -> Identity source**, find **Automatic provisioning** and choose **Enable**. AWS displays a **SCIM endpoint (Tenant URL)** and generates an **Access token (Secret Token)**. Copy both now — the token is shown once.
2. **Entra side:** on the `AWS IAM Identity Center – Federation – SSO` app -> **Provisioning -> Get started**, set **Provisioning Mode = Automatic**.
   - Under **Admin Credentials**, paste the AWS **Tenant URL** and **Secret Token**, then choose **Test Connection**. It must succeed before saving.
   - Save. Leave **Provisioning Status = Off** for now; you will turn it on in the pilot after scoping.

### Step B6. Create the Entra security groups
1. In **Entra ID -> Groups -> New group**, create these security groups (assigned membership):
   - `AWS-SSO-Admin-Sandbox-Pilot`
   - `AWS-SSO-ReadOnly-AllAccounts`
   - `AWS-SSO-PowerUser-Workloads`
   - `AWS-SSO-Billing-Management`
   - `AWS-SSO-BreakGlass-Emergency`
2. Add your pilot users only to `AWS-SSO-Admin-Sandbox-Pilot` and `AWS-SSO-ReadOnly-AllAccounts` for now. Populate the others during Expand.
3. On the app **-> Users and groups**, **Add** each of the five groups so they are in provisioning scope. (In **Provisioning -> Settings**, set **Scope = Sync only assigned users and groups**.)

### Step B7. Create the permission sets (Terraform, plan-first)
1. Use the provided Terraform configuration `AWSSSO-permission-sets.tf` (AWS provider, `aws_ssoadmin_permission_set` + `aws_ssoadmin_managed_policy_attachment` + `aws_ssoadmin_account_assignment`). Set the input variables for your instance ARN, sandbox account ID, and Entra-provisioned group display names.
2. Run **plan-first** through your pipeline/remote state (Global Requirements G4/G5): `terraform plan`. Review that it will create exactly these permission sets:
   - `SSO-Admin – Sandbox – Pilot` (AdministratorAccess managed policy; short session duration, e.g. PT1H).
   - `SSO-ReadOnly – AllAccounts – Prod` (ReadOnlyAccess).
   - `SSO-PowerUser – Workloads – Prod` (PowerUserAccess).
   - `SSO-Billing – Management – Prod` (Billing + read-only, scoped to management account).
   - `SSO-BreakGlass – Management – Emergency` (AdministratorAccess; assigned only to `AWS-SSO-BreakGlass-Emergency`).
3. **Apply only the sandbox-scoped resources first** (target the pilot assignment) after approval. Production account assignments are applied in Expand.

> If you prefer the console for the pilot: **IAM Identity Center -> Permission sets -> Create permission set** creates the same objects; name them exactly as above. Terraform remains the source of truth for repeatability.

---

## Stage C — Pilot (sandbox + pilot group)

### Step C1. Turn on provisioning and confirm the sync
1. In Entra, on the app **-> Provisioning**, set **Provisioning Status = On** and save.
2. Wait for the initial cycle (it can take time). In **Provisioning -> View provisioning logs**, confirm your pilot users and the five groups provisioned successfully.
3. In AWS **IAM Identity Center -> Users** and **-> Groups**, confirm the same users/groups now appear (pushed by SCIM — you did not create them by hand).

### Step C2. Assign pilot access (sandbox only)
1. Confirm the Terraform-applied (or console-created) assignments for the **sandbox account**:
   - `AWS-SSO-Admin-Sandbox-Pilot` -> `SSO-Admin – Sandbox – Pilot` on the **sandbox account** only.
   - `AWS-SSO-ReadOnly-AllAccounts` -> `SSO-ReadOnly – AllAccounts – Prod` on the **sandbox account** only for now.
2. Do **not** assign any production account yet.

### Step C3. First federated sign-in
1. Open the **AWS access portal URL** (from B1) in a clean browser session.
2. Sign in — you are redirected to Entra, authenticate with MFA, and return to the portal.
3. Confirm you see tiles only for the sandbox account with the roles your group membership grants (Admin and ReadOnly). Click a tile and confirm you get a console session.

Proceed to the Testing Guide and pass every gate before Expand.

---

## Stage D — Validate

Run the Testing Guide (`05-testing.md`) end to end: SAML sign-in, SCIM provisioning and **de**provisioning, the least-privilege boundary (ReadOnly cannot change anything), session duration, and the break-glass path. Record pass/fail. Do not expand until all gates pass.

---

## Stage E — Expand and decommission

### Step E1. Configure break-glass before production expansion
1. Keep **one** emergency IAM user in the **management account** named `breakglass-emergency` with a strong password, hardware MFA, and **no access keys**, stored offline (this is your recovery path if federation breaks — see Best Practices). Do not delete it during decommissioning.
2. Assign `AWS-SSO-BreakGlass-Emergency` -> `SSO-BreakGlass – Management – Emergency` to the management account, membership limited to one or two trusted admins, and enable CloudTrail alerting on its use.

### Step E2. Assign production accounts (group by group)
1. Populate the Entra groups with their real members (per the R6 entitlement matrix).
2. Using `AWSSSO-permission-sets.tf`, add and **plan-first** the production account assignments:
   - `AWS-SSO-ReadOnly-AllAccounts` -> `SSO-ReadOnly – AllAccounts – Prod` across the accounts they should read.
   - `AWS-SSO-PowerUser-Workloads` -> `SSO-PowerUser – Workloads – Prod` on workload accounts.
   - `AWS-SSO-Billing-Management` -> `SSO-Billing – Management – Prod` on the management account.
3. Apply after approval, one wave of accounts at a time. Re-run `AWSSSO-Report.sh` after each wave to confirm the assignment matrix matches the intended mapping.

### Step E3. Decommission legacy IAM users (staged, with rollback)
1. From the R8 inventory, confirm which IAM users are **human logins** now replaced by SSO (retire) versus **workload identities** (migrate to roles/OIDC separately — out of scope).
2. For each human user, in this order: **deactivate access keys -> disable console access (remove login profile) -> wait an agreed soak period -> delete the user**. Deactivating first is reversible; deletion is last.
3. Keep the `breakglass-emergency` user. Re-run `AWSSSO-Discovery.sh` after each wave to confirm the shrinking IAM-user footprint and that no unexpected key is still in use.

> Production change approval for disabling/removing IAM users is the customer's operational decision — schedule each wave through your change process with a rollback (re-enable the login profile) ready.

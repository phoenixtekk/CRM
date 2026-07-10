# 7. Best Practices — AWS IAM Identity Center + Microsoft Entra SSO Federation

## Keep it clean

- **One identity source, one truth.** Once Entra ID is the identity source, create and manage all human access through Entra groups — never hand-create users inside IAM Identity Center. Group membership in Entra is the single control point.
- **Least privilege by default.** Start from `SSO-ReadOnly – AllAccounts – Prod` and grant up only where a role genuinely needs it. Reserve `AdministratorAccess` (the Admin and BreakGlass sets) for the smallest possible groups and the shortest session durations.
- **Sandbox before production, always.** The pilot uses `SSO-Admin – Sandbox – Pilot` on a non-production account precisely so admin testing never risks production. Keep that separation permanently — do not repurpose the sandbox set for prod.
- **Terraform is the source of truth.** Make permission sets and account assignments through `AWSSSO-permission-sets.tf`, plan-first, reviewed in a pull request. Console clicks drift; version-controlled assignments are auditable and reproducible.
- **Never delete break-glass.** Keep exactly one `breakglass-emergency` IAM user in the management account with hardware MFA, no access keys, credentials stored offline, and CloudTrail alerting on its use. It is your only way back in if federation breaks. Test it on a schedule (Gate 6).
- **Scope SCIM to assigned only.** Keep provisioning scope = "Sync only assigned users and groups" so you never accidentally push the whole directory into AWS.
- **Watch the SCIM sync window.** Deprovisioning is not instant — it follows the provisioning cycle. For immediate offboarding of a high-risk departure, disable the user in Entra (blocks sign-in immediately) as well as removing group membership.
- **Session duration is a control.** Short durations for privileged sets reduce the blast radius of a stolen session. Tune per tier, not globally.
- **Decommission legacy IAM users in the safe order.** Deactivate keys -> remove login profile -> soak -> delete. Deactivation is reversible; deletion is last. Keep re-runs of `AWSSSO-Discovery.sh` as evidence the footprint is shrinking.
- **Separate humans from workloads.** SSO is for people. Programmatic identities (CI, apps, service accounts) belong on IAM roles / OIDC federation, not IAM Identity Center — migrate them on a separate track.
- **Re-verify feature and licensing facts.** IAM Identity Center Region/feature support and Entra plan gating change. Before relying on Conditional Access, identity protection, or a specific provisioning behavior, *verify current availability in your tenant and organization.*

## Defer the decisions that aren't yours

Who belongs in which access tier, how long privileged sessions may last under your policy, and when a legacy IAM user may be deleted are governance and change-control decisions for the customer's security, identity, and operations owners. This solution provides the technical controls and a safe rollout method — not the entitlement policy or the production change approval.

## Where to go next (adjacent catalog areas)

- **AWS landing zone / Organizations baseline** — build or harden the OU structure, SCPs, and account factory that this SSO layer assigns access across.
- **AWS Security Hub & GuardDuty enablement** — turn on org-wide threat detection and posture scoring so the newly federated access is monitored.
- **Entra ID governance (PIM & access reviews)** — add just-in-time elevation and periodic recertification on top of the Entra groups that now drive AWS access.
- **Passwordless / phishing-resistant MFA (Entra)** — strengthen the authentication that AWS now trusts by federation.
- **Enterprise app & service principal governance (Entra)** — govern the `AWS IAM Identity Center – Federation – SSO` app itself alongside your other enterprise applications.

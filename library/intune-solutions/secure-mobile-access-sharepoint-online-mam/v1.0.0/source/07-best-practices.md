# 7. Best Practices — Secure Mobile Access to SharePoint Online under MAM

- **Align all three layers, always.** App Protection, Conditional Access, and the access path must
  agree. Change one and re-validate the other two — a mismatch is the single most common cause of
  "can't reach the intranet on mobile."
- **Target Office 365, not just the SharePoint resource, in CA.** Scoping the CA policy to
  **Office 365** is the supported, recommended pattern and avoids gaps where a related sign-in
  slips past the grant.
- **Prefer `Require app protection policy`, paired with `Require approved client app`.** The
  app-protection grant is the stronger control; pairing the two (require one of the selected) keeps
  older approved apps covered while enforcing MAM where it exists.
- **Always start CA in Report-only.** Review the impact in Sign-in logs before you enforce, so a
  scoping mistake never blocks real users.
- **Steer, don't weaken.** When users are blocked in Safari/Chrome, move them to the SharePoint app
  or protected Edge — never relax the CA grant to let unmanaged browsers in.
- **Make the routing decision explicitly.** SharePoint Online is cloud-reachable and needs no
  Microsoft Tunnel. Only a truly private/on-prem resource needs Tunnel for MAM — confirm which one
  you have before building anything.
- **Never lock yourself out.** Keep two break-glass Global Administrators excluded from every CA
  policy and test them.
- **Pilot before you expand.** Prove the supported paths and the grant on `SPO Mobile – Users – Pilot`
  before adding `SPO Mobile – Users – Prod`.
- **Reuse the exact object names.** `SPO Mobile – App Protection – iOS/Android`,
  `CA – SPO Mobile – Require APP`, and the group names keep the deployment auditable and repeatable.
- **Communicate the supported path to users.** A one-line message ("use the SharePoint app or Edge
  with your work account") prevents most tickets.
- **Re-validate each wave.** Run `SPMAM-Validation.ps1` and `SPMAM-Report.ps1` before and after each
  expansion so coverage never drifts.

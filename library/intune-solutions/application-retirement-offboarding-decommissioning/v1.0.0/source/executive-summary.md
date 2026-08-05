# Executive Summary

## The problem

Organisations are good at deploying applications and bad at retiring them. Apps that reached
end-of-life, failed a security assessment, were made redundant by a merger, or sit installed on
hundreds of devices that nobody uses — they linger, because removal feels risky and nobody owns the
decision. The result is paid-for licences on unused software, unpatchable security exposure, and a
tenant cluttered with orphaned groups, scripts, and app-control rules. When someone finally tries to
remove an app, they either destroy user data they should have kept, or cancel the licence while the
software is still 60% installed — often both.

## The solution

This is a **repeatable retirement process plus tooling** for the end of the application lifecycle on
an Intune-managed Windows fleet. It turns "delete the app and hope" into a governed campaign: a
signed decision record, an impact analysis of what depends on the app, a communication plan and grace
period, a hard **data-preservation checkpoint** before the irreversible step, a **staged uninstall
campaign** (pilot → waves → broad) that respects how Intune's Uninstall intent actually behaves,
disciplined straggler handling, cleanup of **every artefact** the app leaves behind, licence
reclamation, and a **decommission evidence pack** that proves the app is genuinely gone. Five
PowerShell scripts read the campaign state directly from Microsoft Graph and stay read-only by
default.

## What you get

- A **retirement pipeline** — trigger → decision → impact → comms → data → uninstall waves →
  stragglers → artefact cleanup → licence reclamation → evidence → monitoring — with an owner and an
  exit gate at every stage.
- The **truth about Intune uninstall**: how the Uninstall intent runs the app's stored uninstall
  command, why **Required beats Uninstall**, why deleting the app object removes nothing, and why the
  fleet's check-in rate bounds your completion rate.
- **Five PowerShell scripts** — install-base discovery, dependency/supersedence impact analysis,
  wave status/planning/straggler classification, leftover-artefact finder, and decommission evidence
  export.
- **Testing gates** that make an irreversible action safe, and **Best Practices** that prevent the
  classic data-loss and "nothing happened" failures.

## Business impact

- **Real cost recovery:** licences reclaimed and reported, so the saving lands in a budget line.
- **Reduced risk exposure:** EOL and vulnerable apps are removed on a deadline, with proof.
- **No surprise data loss:** the data checkpoint stops the one-way door from destroying anything you
  must keep.
- **A clean tenant:** groups, scripts, app-control rules, and Conditional Access references go too —
  not just the app.
- **Audit-ready:** the evidence pack answers "is it gone?" with data, for security, compliance, and
  finance.

## Bottom line

Every retired application is removed the way it should be — decided, communicated, data-protected,
staged, cleaned up, licence-reclaimed, and proven gone — with a repeatable method and scripts your
team keeps and reuses for the next app, at a fraction of the cost of ad-hoc removal or outside
consulting.

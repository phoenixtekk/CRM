# Executive Summary — Attack Surface Reduction (ASR) Rules (Microsoft Intune)

**Phoenixtekk Workplace Marketplace · Intune Solutions**

Most malware uses the same handful of tricks: a macro spawning PowerShell, an email attachment
launching an executable, credential theft from LSASS. **Attack Surface Reduction (ASR) rules**
block those behaviors at the source — and managed through Microsoft Intune, you can roll them out
safely in **Audit mode first**, review what *would* have been blocked, then enforce.

This is a complete, **deploy-it-today** package for implementing ASR rules with Microsoft Intune,
written for an administrator with no prior ASR experience — including the audit-first method that
prevents business-app breakage.

## What you get
- A plain-language **Solution Overview** of what ASR rules block and how modes work.
- A **Requirements Guide** with verify / implement-if-missing for every prerequisite.
- An **Implementation Guide** of precise, click-by-click Intune steps in the required order.
- Five **PowerShell scripts** for posture discovery, rule validation, audit-event reporting, remediation, and a rule reference.
- **Testing** and **Troubleshooting** guides for confident rollout.

## What this delivers
An Intune **Attack Surface Reduction policy** with the high-value rules (block Office child
processes, block credential theft from LSASS, block executable content from email, block obfuscated
scripts, and more) — deployed **Audit-first**, reviewed, then moved to **Block**, with exclusions.

## The Phoenixtekk deployment model
**Assess → Configure → Pilot → Validate → Expand.**

## Outcome
Behavior-based malware prevention across the fleet — rolled out without breaking line-of-business
apps — deployable by a single administrator and validated before enforcement.

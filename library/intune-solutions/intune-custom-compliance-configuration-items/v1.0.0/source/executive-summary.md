# Executive Summary — Intune Custom Compliance & Configuration Items (Scripted)

**Phoenixtekk Workplace Marketplace · Intune Solutions**

Intune's built-in compliance settings cover the basics — encryption, OS version, password — but
real security standards go further: a specific registry value, a minimum app version, a control the
GUI simply can't reach. **Custom compliance** closes that gap. It pairs a **PowerShell detection
script** with a **JSON rule** that Intune evaluates on the device, then folds the result into device
compliance — and, through Conditional Access, into access decisions. For the settings templates can't
express, **scripted configuration items** (settings-catalog custom settings) push exactly the value
you need.

This is a complete, deploy-it-today package for authoring, deploying, and managing scripted custom
compliance and configuration items with Microsoft Intune, written for an administrator with no prior
custom-compliance experience.

## What you get
- A plain-language Solution Overview of how custom compliance works (detection script + JSON rule +
  settings mapping), scripted configuration items, and how compliance feeds Conditional Access.
- A Requirements Guide with verify / implement-if-missing for every prerequisite.
- An Implementation Guide of precise, ordered Intune steps — including a worked detection-script and
  JSON-rule example you can adapt.
- Five PowerShell scripts for discovery, rule/JSON validation, fleet custom-compliance reporting,
  safe remediation, and building the compliance-scope group.
- Testing and Troubleshooting guides for a confident rollout.

## What this delivers
A repeatable authoring model: write the detection script, author the JSON discovery/rule file and
settings mapping, upload it as a custom compliance policy, add any scripted configuration items,
assign to a pilot, validate evaluation and the Conditional Access effect, then expand — so device
state is measured and enforced exactly the way your standards require.

## The Phoenixtekk deployment model
**Assess → Configure → Pilot → Validate → Expand.**

## Outcome
Device state measured and enforced to your standards — custom detection scripts and scripted
configuration items covering what the built-in settings can't, wired into Conditional Access, and
proven on a pilot before you scale.

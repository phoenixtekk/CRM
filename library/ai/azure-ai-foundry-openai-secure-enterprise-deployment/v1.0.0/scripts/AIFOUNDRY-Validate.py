#!/usr/bin/env python3
"""
.SYNOPSIS
    AIFOUNDRY-Validate.py -- keyless, read-only posture validation of the deployed Azure OpenAI resource.
.DESCRIPTION
    PURPOSE
        Confirms the platform matches the Testing guide's pass/fail gates:
          - public network access DISABLED
          - local auth (account keys) DISABLED  -> keyless-only
          - a custom subdomain is set (required for keyless + private endpoints)
          - at least one private endpoint connection is present
          - a least-privilege data-plane role (Cognitive Services OpenAI User) is assigned
          - at least one model deployment exists WITH a bounded TPM capacity
          - a diagnostic setting is configured
        Authenticates via DefaultAzureCredential (your az login / a managed identity) with NO KEY.
        Read-only: it inspects resource management state; it makes no changes.
    HOW TO RUN
        pip install azure-identity azure-mgmt-cognitiveservices azure-mgmt-authorization azure-mgmt-monitor
        python AIFOUNDRY-Validate.py --subscription <sub id> --resource-group rg-aiplatform-nonprod \
               --account aoai-ent-nonprod
        (az login first, or run as a managed identity with Reader on the resource.)
        *Verify current Azure SDK versions -- the AI SDKs move fast.*
    EXPECTED RESULTS
        A PASS/FAIL line per gate and a non-zero exit code if any gate fails. No changes are made.
.NOTES
    White-label. Read-only. Keyless (DefaultAzureCredential). Makes no changes.
"""
import argparse
import sys

OPENAI_USER_ROLE = "Cognitive Services OpenAI User"  # least-privilege data-plane role

_passed = 0
_failed = 0


def gate(name: str, ok: bool, detail: str = "") -> None:
    global _passed, _failed
    if ok:
        print(f"PASS  {name}")
        _passed += 1
    else:
        print(f"FAIL  {name}" + (f" -- {detail}" if detail else ""))
        _failed += 1


def main() -> int:
    ap = argparse.ArgumentParser(description="Keyless posture validation for a secure Azure OpenAI resource.")
    ap.add_argument("--subscription", required=True)
    ap.add_argument("--resource-group", required=True)
    ap.add_argument("--account", required=True, help="Azure OpenAI account name (e.g. aoai-ent-nonprod)")
    args = ap.parse_args()

    try:
        from azure.identity import DefaultAzureCredential
        from azure.mgmt.cognitiveservices import CognitiveServicesManagementClient
        from azure.mgmt.authorization import AuthorizationManagementClient
        from azure.mgmt.monitor import MonitorManagementClient
    except ImportError as e:
        print("Missing SDK. Run: pip install azure-identity azure-mgmt-cognitiveservices "
              "azure-mgmt-authorization azure-mgmt-monitor", file=sys.stderr)
        print(f"  ({e})", file=sys.stderr)
        return 2

    cred = DefaultAzureCredential()  # NO KEY -- token-based
    cog = CognitiveServicesManagementClient(cred, args.subscription)

    print(f"Validating '{args.account}' in RG '{args.resource_group}' (keyless, read-only)\n")

    try:
        acct = cog.accounts.get(args.resource_group, args.account)
    except Exception as e:  # noqa: BLE001
        print(f"FAIL  could not read account: {e}", file=sys.stderr)
        return 2

    props = acct.properties

    # Gate 1 -- public access disabled
    pub = getattr(props, "public_network_access", None)
    gate("Public network access disabled", str(pub).lower() == "disabled", f"found '{pub}'")

    # Gate 2 -- local auth (keys) disabled -> keyless only
    disable_local = getattr(props, "disable_local_auth", None)
    gate("Local auth (keys) disabled -- keyless only", disable_local is True, f"disable_local_auth='{disable_local}'")

    # Gate 3 -- custom subdomain set (required for keyless + private endpoints)
    subdomain = getattr(props, "custom_sub_domain_name", None)
    gate("Custom subdomain set", bool(subdomain), "no customSubDomainName -- resource must be recreated")

    # Gate 4 -- at least one private endpoint connection
    pecs = getattr(props, "private_endpoint_connections", None) or []
    gate("Private endpoint present", len(pecs) > 0, "no private endpoint connections")

    # Gate 5 -- model deployment(s) with a bounded TPM capacity
    try:
        deployments = list(cog.deployments.list(args.resource_group, args.account))
    except Exception as e:  # noqa: BLE001
        deployments = []
        print(f"      (could not list deployments: {e})")
    bounded = [d for d in deployments if getattr(getattr(d, "sku", None), "capacity", 0)]
    gate("Model deployment with bounded TPM capacity", len(bounded) > 0,
         f"{len(deployments)} deployment(s), {len(bounded)} with a TPM ceiling")
    for d in deployments:
        cap = getattr(getattr(d, "sku", None), "capacity", None)
        model = getattr(getattr(d.properties, "model", None), "name", "?") if getattr(d, "properties", None) else "?"
        print(f"        - {d.name}: model={model} TPM(k)={cap}")

    # Gate 6 -- least-privilege data-plane role assigned on the resource
    try:
        auth = AuthorizationManagementClient(cred, args.subscription)
        scope = acct.id
        role_defs = {rd.id: rd.role_name for rd in auth.role_definitions.list(scope)}
        assignments = list(auth.role_assignments.list_for_scope(scope, filter="atScope()"))
        assigned_roles = {role_defs.get(a.role_definition_id, "") for a in assignments}
        gate(f"Least-privilege '{OPENAI_USER_ROLE}' assigned", OPENAI_USER_ROLE in assigned_roles,
             f"roles at scope: {sorted(r for r in assigned_roles if r)}")
        over = {r for r in assigned_roles if r in ("Owner", "Contributor")}
        if over:
            print(f"      NOTE: broad role(s) at resource scope: {sorted(over)} -- prefer OpenAI User for apps.")
    except Exception as e:  # noqa: BLE001
        gate(f"Least-privilege '{OPENAI_USER_ROLE}' assigned", False, f"role check error: {e}")

    # Gate 7 -- diagnostic setting configured
    try:
        mon = MonitorManagementClient(cred, args.subscription)
        diags = list(mon.diagnostic_settings.list(acct.id))
        gate("Diagnostic setting configured", len(diags) > 0, "no diagnostic settings -> platform is unobserved")
    except Exception as e:  # noqa: BLE001
        gate("Diagnostic setting configured", False, f"diagnostics check error: {e}")

    print(f"\nResult: {_passed} passed, {_failed} failed.")
    return 1 if _failed else 0


if __name__ == "__main__":
    sys.exit(main())

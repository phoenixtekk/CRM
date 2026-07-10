#!/usr/bin/env bash
###############################################################################
# AWSLZ-Deploy.sh — plan-first, approval-gated Terraform wrapper for the landing zone.
#
# PURPOSE
#   The ONLY sanctioned way to apply the landing-zone Terraform (main.tf).
#   `plan` never changes anything. `apply` re-plans, shows the plan, and requires
#   an explicit typed confirmation ("apply") before it applies — it will NEVER
#   apply unattended. Non-prod-first: SCPs attach to pilot OUs only until
#   validated (see 03-implementation.md / 05-testing.md).
#
# HOW TO RUN
#   ./AWSLZ-Deploy.sh plan          # safe: init + validate + plan, no changes
#   ./AWSLZ-Deploy.sh apply         # re-plans, prompts for typed confirmation
#   ./AWSLZ-Deploy.sh destroy       # DELIBERATE teardown: plan-first + double confirm
#
#   Prereqs: Terraform (pinned) + AWS CLI v2, authenticated as an ASSUMED ROLE
#   (never root), with remote state configured (R6). GovCloud: matching partition.
#
# EXPECTED RESULTS
#   plan    -> a readable plan; exit 0; nothing changed.
#   apply   -> applies ONLY after you type "apply" at the prompt.
#   destroy -> tears down ONLY after you type the exact confirmation phrase.
#
# NOTES
#   White-label. Plan-first + approval-gated. No credentials in script. Do NOT
#   wire `apply`/`destroy` to run unattended in CI without a human approval gate.
###############################################################################
set -euo pipefail

ACTION="${1:-plan}"
TF_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "${TF_DIR}"

echo "== AWS Landing Zone deploy wrapper =="
echo "Identity check (must be an assumed role, not root):"
aws sts get-caller-identity --query 'Arn' --output text

if aws sts get-caller-identity --query 'Arn' --output text | grep -q ':root'; then
  echo "REFUSING: you are the ROOT user. Assume a scoped deployment role (G2)."; exit 1
fi

echo "-- terraform init --"
terraform init -input=false

echo "-- terraform validate --"
terraform validate

case "${ACTION}" in
  plan)
    echo "-- terraform plan (no changes will be made) --"
    terraform plan -input=false
    echo "PLAN ONLY. Review the plan; nothing was changed. Commit it for approval (G4/G8)."
    ;;

  apply)
    echo "-- terraform plan (saved) --"
    terraform plan -input=false -out=tfplan
    echo ""
    echo "Review the plan above. This will create/modify REAL, billable AWS resources."
    echo "Applying to PILOT scope first is expected (SCPs attach to NonProd/Sandbox only)."
    read -r -p 'Type "apply" to proceed, anything else to abort: ' CONFIRM
    if [[ "${CONFIRM}" == "apply" ]]; then
      terraform apply -input=false tfplan
      echo "Apply complete. Now validate: ./AWSLZ-Validate.sh"
    else
      echo "Aborted. Nothing applied."; rm -f tfplan
    fi
    ;;

  destroy)
    echo "-- terraform plan -destroy (review what would be removed) --"
    terraform plan -destroy -input=false
    echo ""
    echo "WARNING: destroy removes foundation resources (OUs, SCPs, logging)."
    echo "Do NOT casually destroy central logging or accounts."
    read -r -p 'Type "destroy the landing zone" EXACTLY to proceed: ' CONFIRM
    if [[ "${CONFIRM}" == "destroy the landing zone" ]]; then
      terraform destroy -input=false
      echo "Destroy complete."
    else
      echo "Aborted. Nothing destroyed."
    fi
    ;;

  *)
    echo "Usage: $0 {plan|apply|destroy}"; exit 2
    ;;
esac

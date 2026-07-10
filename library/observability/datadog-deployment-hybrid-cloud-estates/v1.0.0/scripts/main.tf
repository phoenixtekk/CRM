###############################################################################
# main.tf — Datadog for hybrid & cloud estates (white-label reference IaC)
#
# PURPOSE
#   Manages the Datadog observability stack AS CODE via the Datadog provider:
#     - Cloud integrations:  Azure (datadog_integration_azure), AWS (datadog_integration_aws)
#     - Estate dashboard:    OBSDDOG-Dashboard-EstateOverview
#     - SLO:                 OBSDDOG-SLO-APIAvailability
#     - Monitors (PILOT):    OBSDDOG-Monitor-HostUnreachable-Pilot / -CPUHigh-Pilot / -K8sPodCrashloop-Pilot
#     - Log pipeline:        OBSDDOG-Pipeline-AppLogs
#   Agent rollout is handled by the installer scripts (install-datadog-agent.sh / Install-DatadogAgent.ps1)
#   and, on Kubernetes, the official Helm chart — NOT baked in here.
#
# HOW TO RUN  (plan/what-if FIRST — never apply blind)
#   export DD_API_KEY="$(read-from-secret-store)"        # NEVER hard-code — from a secret store
#   export DD_APP_KEY="$(read-from-secret-store)"
#   terraform init
#   terraform plan  -out tfplan          # review the what-if in a pull request
#   terraform apply tfplan               # pilot scope first (env:pilot), then expand in waves
#
# EXPECTED RESULTS
#   plan creates the integrations, dashboard, SLO, the three PILOT monitors, and the log pipeline —
#   and NOTHING unexpected. Thresholds/targets/handles are variables — set them to YOUR SLOs.
#
# NOTES
#   White-label. *** NO SECRETS IN CODE ***: DD_API_KEY / DD_APP_KEY come from the environment /
#   secret store; the Azure client secret and AWS role are passed via variables sourced from the secret
#   store — never inline, never committed. Store Terraform STATE in a secured backend, not the repo.
#   Provider version is PINNED and FLAGGED "verify" — confirm the current supported DataDog/datadog
#   provider version against the registry/Datadog docs before you apply.
###############################################################################

terraform {
  required_version = ">= 1.6.0, < 2.0.0" # verify supported range

  required_providers {
    datadog = {
      source  = "DataDog/datadog"
      version = "~> 3.47" # verify: pin to a current supported provider release
    }
  }

  # Store state in a SECURED remote backend (example: azurerm). NEVER commit state to the repo.
  # backend "azurerm" { ... }   # configure per your environment; no secrets inline.
}

# Provider reads DD_API_KEY / DD_APP_KEY from the ENVIRONMENT (secret store) — not from code.
# Set `api_url` to your org's site (e.g. https://api.datadoghq.com or https://api.datadoghq.eu). verify.
provider "datadog" {
  api_url = var.datadog_api_url
}

# --- Variables (values from tfvars / CI, secrets from the secret store) -------
variable "datadog_api_url" { type = string, default = "https://api.datadoghq.com" } # verify site
variable "env"             { type = string, default = "pilot" }
variable "service"         { type = string, default = "demo" }
variable "team"            { type = string, default = "platform" }
variable "notify_handle"   { type = string, default = "@slack-ops @pagerduty-ops" } # your routing
variable "cpu_threshold"   { type = number, default = 85 }   # set to your SLO
variable "slo_target"      { type = number, default = 99.9 } # set to your SLO

# Azure integration inputs — client_secret comes from the SECRET STORE via a secure variable.
variable "azure_tenant_id"     { type = string, default = "" }
variable "azure_client_id"     { type = string, default = "" }
variable "azure_client_secret" { type = string, default = "", sensitive = true }

# AWS integration inputs — from the secret store / CI.
variable "aws_account_id"  { type = string, default = "" }
variable "aws_role_name"   { type = string, default = "DatadogIntegrationRole" }

# --- Cloud integrations -------------------------------------------------------
resource "datadog_integration_azure" "sub" {
  count         = var.azure_tenant_id == "" ? 0 : 1
  tenant_name   = var.azure_tenant_id
  client_id     = var.azure_client_id
  client_secret = var.azure_client_secret # sensitive; sourced from secret store — never committed
  host_filters  = "env:${var.env}"        # scope collection; widen in Expand
}

resource "datadog_integration_aws" "acct" {
  count      = var.aws_account_id == "" ? 0 : 1
  account_id = var.aws_account_id
  role_name  = var.aws_role_name          # cross-account IAM role Datadog assumes
  # filter_tags / host_tags as needed — verify current resource schema in the provider docs.
}

# --- Monitors (PILOT scope via env tag) --------------------------------------
resource "datadog_monitor" "host_unreachable" {
  name    = "OBSDDOG-Monitor-HostUnreachable-Pilot"
  type    = "service check"
  query   = "\"datadog.agent.up\".by(\"host\").last(2).count_by_status()"
  message = "Host unreachable (no agent heartbeat). ${var.notify_handle}"
  tags    = ["env:${var.env}", "service:${var.service}", "team:${var.team}"]
  monitor_thresholds { critical = 1, warning = 1 }
}

resource "datadog_monitor" "cpu_high" {
  name    = "OBSDDOG-Monitor-CPUHigh-Pilot"
  type    = "metric alert"
  query   = "avg(last_15m):avg:system.cpu.user{env:${var.env}} by {host} > ${var.cpu_threshold}"
  message = "High CPU on {{host.name}} (env:${var.env}). ${var.notify_handle}"
  tags    = ["env:${var.env}", "service:${var.service}", "team:${var.team}"]
  monitor_thresholds { critical = var.cpu_threshold }
}

resource "datadog_monitor" "k8s_crashloop" {
  name    = "OBSDDOG-Monitor-K8sPodCrashloop-Pilot"
  type    = "metric alert"
  query   = "max(last_10m):max:kubernetes.containers.restarts{env:${var.env}} by {kube_namespace,pod_name} > 3"
  message = "Pod crashloop in {{kube_namespace.name}} (env:${var.env}). ${var.notify_handle}"
  tags    = ["env:${var.env}", "service:${var.service}", "team:${var.team}"]
  monitor_thresholds { critical = 3 }
}

# --- SLO ----------------------------------------------------------------------
resource "datadog_service_level_objective" "api_availability" {
  name        = "OBSDDOG-SLO-APIAvailability"
  type        = "monitor"
  description = "API availability target (env:${var.env}). Set target/monitors to your SLO."
  monitor_ids = [datadog_monitor.host_unreachable.id]
  thresholds {
    timeframe = "30d"
    target    = var.slo_target
  }
  tags = ["env:${var.env}", "service:${var.service}", "team:${var.team}"]
}

# --- Estate-overview dashboard ------------------------------------------------
resource "datadog_dashboard" "estate_overview" {
  title       = "OBSDDOG-Dashboard-EstateOverview"
  layout_type = "ordered"
  description = "Single pane over Azure + AWS + on-prem (scoped by tags). Managed as code."

  widget {
    timeseries_definition {
      title = "CPU by host (env:${var.env})"
      request { q = "avg:system.cpu.user{env:${var.env}} by {host}" }
    }
  }
  widget {
    query_value_definition {
      title = "Hosts reporting"
      request { q = "count_not_null(avg:system.cpu.user{env:${var.env}} by {host})" }
    }
  }
}

# --- Log pipeline -------------------------------------------------------------
resource "datadog_logs_custom_pipeline" "app_logs" {
  name       = "OBSDDOG-Pipeline-AppLogs"
  is_enabled = true
  filter { query = "env:${var.env}" }
  processor {
    grok_parser {
      name       = "parse-app-log"
      is_enabled = true
      source     = "message"
      grok {
        support_rules = ""
        match_rules   = "app_rule %%{date(\"yyyy-MM-dd HH:mm:ss\"):timestamp}\\s+%%{word:level}\\s+%%{data:msg}"
      }
    }
  }
  # Index/retention is set on the log index (cost lever) — index only what you will query. verify pricing.
}

output "dashboard_url" { value = datadog_dashboard.estate_overview.url }
output "slo_id"        { value = datadog_service_level_objective.api_availability.id }

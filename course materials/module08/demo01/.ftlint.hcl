# TFLint Configuration - Komplett eksempel

plugin "azurerm" {
  enabled = true
  version = "0.29.0"
  source  = "github.com/terraform-linters/tflint-ruleset-azurerm"
}

# ============================================================
# TERRAFORM CORE RULES
# ============================================================

# Naming conventions
rule "terraform_naming_convention" {
  enabled = true
  
  resource {
    format = "snake_case"
  }
  
  variable {
    format = "snake_case"
  }
  
  output {
    format = "snake_case"
  }
  
  module {
    format = "snake_case"
  }
}

# Documentation
rule "terraform_documented_outputs" {
  enabled = true
}

rule "terraform_documented_variables" {
  enabled = true
}

# Type safety
rule "terraform_typed_variables" {
  enabled = true
}

# Unused code
rule "terraform_unused_declarations" {
  enabled = true
}

rule "terraform_unused_required_providers" {
  enabled = true
}

# Module best practices
rule "terraform_module_pinned_source" {
  enabled = true
  style   = "semver"
}

rule "terraform_standard_module_structure" {
  enabled = true
}

# Version constraints
rule "terraform_required_version" {
  enabled = true
}

rule "terraform_required_providers" {
  enabled = true
}

# Deprecated syntax
rule "terraform_deprecated_interpolation" {
  enabled = true
}

rule "terraform_deprecated_index" {
  enabled = true
}

rule "terraform_comment_syntax" {
  enabled = true
}

# Remote state
rule "terraform_workspace_remote" {
  enabled = true
}

# ============================================================
# AZURE-SPECIFIC RULES (Eksempler)
# ============================================================

# Virtual Machines
rule "azurerm_linux_virtual_machine_invalid_vm_size" {
  enabled = true
}

rule "azurerm_windows_virtual_machine_invalid_vm_size" {
  enabled = true
}

# Storage
rule "azurerm_storage_account_invalid_name" {
  enabled = true
}

# Resource Groups
rule "azurerm_resource_group_invalid_name" {
  enabled = true
}

# App Service
rule "azurerm_app_service_plan_invalid_sku" {
  enabled = true
}

# Location validation
rule "azurerm_resource_invalid_location" {
  enabled = true
}
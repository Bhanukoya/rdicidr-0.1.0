# In this file put all the logic to crete the proper infraestructure
terraform {
  required_providers {
    # Add the provideres according to the challenges
  }
}



# Add the resources relatedo to the provider
resource "azurerm_resource_group" "fsl_rg" {
  name     = "${var.environment}-fsl-rg"
  location = "Canada Central"
}

resource "azurerm_storage_account" "fsl_sa" {
  name                     = "${var.environment}fslstorage"
  resource_group_name      = azurerm_resource_group.fsl_rg.name
  location                 = azurerm_resource_group.fsl_rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_container" "fsl_container" {
  name                  = "webapp"
  storage_account_id    = azurerm_storage_account.fsl_sa.id
  container_access_type = "blob"
}

resource "azurerm_cdn_profile" "fsl_cdn" {
  name                = "${var.environment}-fsl-cdn"
  location            = azurerm_resource_group.fsl_rg.location
  resource_group_name = azurerm_resource_group.fsl_rg.name
  sku                 = "Standard_Microsoft"
}

resource "azurerm_cdn_endpoint" "fsl_endpoint" {
  name                = "${var.environment}-fsl-endpoint"
  profile_name        = azurerm_cdn_profile.fsl_cdn.name
  location            = azurerm_resource_group.fsl_rg.location
  resource_group_name = azurerm_resource_group.fsl_rg.name

  origin {
    name       = "bloborigin"
    host_name  = replace(azurerm_storage_account.fsl_sa.primary_blob_endpoint, "https://", "")
    http_port  = 80
    https_port = 443
  }
}

resource "azurerm_log_analytics_workspace" "fsl_law" {
  name                = "${var.environment}-fsl-law"
  location            = azurerm_resource_group.fsl_rg.location
  resource_group_name = azurerm_resource_group.fsl_rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_monitor_diagnostic_setting" "fsl_mds" {
  name                       = "${var.environment}-fsl-cdn-logs"
  target_resource_id         = azurerm_cdn_endpoint.fsl_endpoint.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.fsl_law.id

  enabled_log {
    category = "CdnAccessLogs"
  }

}

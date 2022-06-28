terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=2.75.0"
    }
  }
}

provider "azurerm" {
  features {}
}

locals {
  package_path = "api.zip"
  package_hash = filemd5(local.package_path)
}

## resource group
resource "azurerm_resource_group" "rg" {
  name     = "${var.resource_group_prefix}-${var.product}-${var.environment}"
  location = var.location
}

## application insights
resource "azurerm_application_insights" "ai" {
  name                = "${var.app_insights_prefix}-${var.product}-${var.environment}"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  application_type    = "Node.JS"
}

## app service plan
resource "azurerm_app_service_plan" "asp" {
  name                = "${var.app_service_plan_prefix}-${var.product}-${var.environment}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  kind                = "FunctionApp"
  reserved            = false
  sku {
    tier = "Dynamic"
    size = "Y1"
  }
}

## storage account
resource "azurerm_storage_account" "sa" {
  resource_group_name      = azurerm_resource_group.rg.name
  account_replication_type = "LRS"
  account_tier             = "Standard"
  location                 = var.location
  name                     = "${var.storage_account_prefix}${var.product}${var.environment}"
}

resource "azurerm_storage_container" "deployment_packages" {
  name                  = "${var.container_prefix}-${var.product}-pkg-${var.environment}-${var.location}"
  storage_account_name  = azurerm_storage_account.sa.name
  container_access_type = "private"
}

data "azurerm_storage_account_sas" "sas" {
  connection_string = azurerm_storage_account.sa.primary_connection_string
  https_only        = true
  start             = "2022-06-23"
  expiry            = "2023-12-31"
  resource_types {
    object    = true
    container = false
    service   = false
  }
  services {
    blob  = true
    queue = true
    table = false
    file  = false
  }
  permissions {
    read    = true
    write   = false
    delete  = false
    list    = false
    add     = false
    create  = false
    update  = false
    process = false
  }
}

# function package
resource "azurerm_storage_blob" "code" {
  name                   = "functions-${local.package_hash}.zip"
  storage_account_name   = azurerm_storage_account.sa.name
  storage_container_name = azurerm_storage_container.deployment_packages.name
  type                   = "Block"
  source                 = local.package_path
}

## function app
resource "azurerm_function_app" "fa" {
  name                       = "${var.function_app_prefix}-${var.product}-${var.environment}"
  location                   = azurerm_resource_group.rg.location
  resource_group_name        = azurerm_resource_group.rg.name
  app_service_plan_id        = azurerm_app_service_plan.asp.id
  storage_account_name       = azurerm_storage_account.sa.name
  storage_account_access_key = azurerm_storage_account.sa.primary_access_key

  app_settings = {
    https_only                     = true
    FUNCTIONS_WORKER_RUNTIME       = "node",
    FUNCTION_APP_EDIT_MODE         = "readonly"
    WEBSITE_RUN_FROM_PACKAGE       = format("%s%s", azurerm_storage_blob.code.url, data.azurerm_storage_account_sas.sas.sas)
    APPINSIGHTS_INSTRUMENTATIONKEY = azurerm_application_insights.ai.instrumentation_key,
    WEBSITE_NODE_DEFAULT_VERSION : "~14"
  }

  site_config {
    use_32_bit_worker_process = false
  }
}

## api management
## remove to save money!
/*
resource "azurerm_api_management" "apim" {
  location            = azurerm_resource_group.rg.location
  name                = "${var.api_management_prefix}-${var.product}-${var.environment}"
  publisher_email     = "jphilipwade@gmail.com"
  publisher_name      = "vmoney"
  resource_group_name = azurerm_resource_group.rg.name
  sku_name            = "Developer_1"
}

resource "azurerm_api_management_api" "api" {
  api_management_name = azurerm_api_management.apim.name
  name                = "${var.api_management_api_prefix}-${var.product}-${var.environment}"
  resource_group_name = azurerm_resource_group.rg.name
  revision            = "1"
  display_name        = "Event API"
  protocols           = ["https"]

  import {
    content_format = "openapi-link"
    content_value  = format("%s%s", azurerm_storage_blob.openapi.url, data.azurerm_storage_account_sas.sas.sas)
  }
}
*/

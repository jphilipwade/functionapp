resource "azurerm_servicebus_namespace" "sbns" {
  name                = "${var.product}-${var.service_bus_namespace_prefix}-${var.environment}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "Standard"

  tags = {
    source = "terraform"
  }
}

resource "azurerm_servicebus_topic" "sbtopic" {
  name         = "${var.product}-${var.service_bus_namespace_prefix}-topic-${var.environment}"
  namespace_id = azurerm_servicebus_namespace.sbns.id

  enable_partitioning = true
}

resource "azurerm_servicebus_subscription" "example" {
  name               = "${var.product}-${var.service_bus_namespace_prefix}-sub-${var.environment}"
  topic_id           = azurerm_servicebus_topic.sbtopic.id
  max_delivery_count = 1
}

###########################################################
###
### This Terraform Script will install an architecture that includes:
###
### A) IoT Architecture which includes:
###    1) IoT Hub with two routes
###    2) Stream Analytics that has IoT Hub as an input and Blob Storage as an output
###    3) Event Hub to route the info from IoT Hub
###
### B) ML Service which includes:
###    1) A blob storage
###    2) Its own key value
###    3) Its own log analytics
###
###########################################################


provider "azurerm" {
  version = "~> 2.01.0"

  features {

  }
}

###########################################################
###
### Definition of Resource Group
###
###########################################################
resource "azurerm_resource_group" "iotDeployment" {
  name     = format("%sRG%s01" ,var.prefix, var.env) 
  location = var.location
  tags = {
    cc = var.cctag
    expiration_date = var.expiration_date
    environment = var.environment
  }
}

###########################################################
### VNET and Subnets configuration:
###     Subnet 1: For IoT Private Endpoint
###     Subnet 2: For Virtual Machine with IoT Edge
###     Subnet 3: For AKS
##########################################################

resource "azurerm_virtual_network" "iotDeployment" {
  name                = var.vnet_name
  address_space       = [var.vnet_address_space]
  location            = azurerm_resource_group.iotDeployment.location
  resource_group_name = azurerm_resource_group.iotDeployment.name
}

# Subnet definition for IoT Private Endpoint
resource "azurerm_subnet" "iotDeployment1" {
  name                 = var.subnet_name_1
  resource_group_name  = azurerm_resource_group.iotDeployment.name
  virtual_network_name = azurerm_virtual_network.iotDeployment.name
  address_prefix       = var.subnet_address_prefix_1

  enforce_private_link_endpoint_network_policies = true
}

# Subnet definition for Virtual Machine with IoT Edge
resource "azurerm_subnet" "iotDeployment2" {
  name                 = var.subnet_name_2
  resource_group_name  = azurerm_resource_group.iotDeployment.name
  virtual_network_name = azurerm_virtual_network.iotDeployment.name
  address_prefix       = var.subnet_address_prefix_2
}

# Subnet definition for AKS
resource "azurerm_subnet" "iotDeployment3" {
  name                 = var.subnet_name_3
  resource_group_name  = azurerm_resource_group.iotDeployment.name
  virtual_network_name = azurerm_virtual_network.iotDeployment.name
  address_prefix       = var.subnet_address_prefix_3
}


###########################################################
###
### IoT Section:
###     1) Storage Account for IoT Route Endpoint and for Stream Analytics output
###     2) Storage Account for Data Lake of IoT Information
###     3) Event Hub Namespace, Event Hub and Authorization Rule
###     4) IoT Hub with two routes configured 1) Storage Account, 2) Event Hub
###     5) Stream Analytics for NRT analytics
###
###########################################################


resource "azurerm_storage_account" "iotDeployment1" {
  name                     = lower(format("%sSA%s01" ,var.prefix, var.env))
  resource_group_name      = azurerm_resource_group.iotDeployment.name
  location                 = azurerm_resource_group.iotDeployment.location
  account_tier             = "Standard"
  account_replication_type = "GRS"
  account_kind             = "StorageV2"
  is_hns_enabled           = "true"
  tags = {
    cc = var.cctag
    expiration_date = var.expiration_date
  }
}

resource "azurerm_storage_account" "iotDeployment2" {
  name                     = lower(format("%sSA%s02" ,var.prefix, var.env))
  resource_group_name      = azurerm_resource_group.iotDeployment.name
  location                 = azurerm_resource_group.iotDeployment.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  tags = {
    cc = var.cctag
    expiration_date = var.expiration_date
  }
}

resource "azurerm_storage_container" "iotDeployment" {
  name                  = lower(format("%sCTR%s01" ,var.prefix, var.env))
  storage_account_name  = azurerm_storage_account.iotDeployment1.name
  container_access_type = "private"
}

resource "azurerm_eventhub_namespace" "iotDeployment" {
  name                = format("%sEHN%s01" ,var.prefix, var.env) 
  resource_group_name = azurerm_resource_group.iotDeployment.name
  location            = azurerm_resource_group.iotDeployment.location
  sku                 = "Basic"

  tags = {
    cc = var.cctag
    expiration_date = var.expiration_date
  }
}

resource "azurerm_eventhub" "iotDeployment" {
  name                = format("%sEH%s01" ,var.prefix, var.env) 
  resource_group_name = azurerm_resource_group.iotDeployment.name
  namespace_name      = azurerm_eventhub_namespace.iotDeployment.name
  partition_count     = 2
  message_retention   = 1
}

resource "azurerm_eventhub_authorization_rule" "iotDeployment" {
  resource_group_name = azurerm_resource_group.iotDeployment.name
  namespace_name      = azurerm_eventhub_namespace.iotDeployment.name
  eventhub_name       = azurerm_eventhub.iotDeployment.name
  name                = "acctest"
  send                = true
}

resource "azurerm_iothub" "iotDeployment" {
  name                = format("%sHUBS%s01" ,var.prefix, var.env) 
  resource_group_name = azurerm_resource_group.iotDeployment.name
  location            = azurerm_resource_group.iotDeployment.location

  sku {
    name     = "S1"
    capacity = "1"
  }

  endpoint {
    type                       = "AzureIotHub.StorageContainer"
    connection_string          = azurerm_storage_account.iotDeployment1.primary_blob_connection_string
    name                       = "export"
    batch_frequency_in_seconds = 60
    max_chunk_size_in_bytes    = 10485760
    container_name             = azurerm_storage_container.iotDeployment.name
    encoding                   = "Avro"
    file_name_format           = "{iothub}/{partition}_{YYYY}_{MM}_{DD}_{HH}_{mm}"
  }

  endpoint {
    type              = "AzureIotHub.EventHub"
    connection_string = azurerm_eventhub_authorization_rule.iotDeployment.primary_connection_string
    name              = "export2"
  }

  route {
    name           = "export"
    source         = "DeviceMessages"
    condition      = "true"
    endpoint_names = ["export"]
    enabled        = true
  }

  route {
    name           = "export2"
    source         = "DeviceMessages"
    condition      = "true"
    endpoint_names = ["export2"]
    enabled        = true
  }

  tags = {
    cc = var.cctag
    expiration_date = var.expiration_date
  }
}

resource "azurerm_stream_analytics_job" "iotDeployment" {
  name                                     = format("%sSTRA%s01" ,var.prefix, var.env) 
  resource_group_name                      = azurerm_resource_group.iotDeployment.name
  location                                 = azurerm_resource_group.iotDeployment.location
  compatibility_level                      = "1.1"
  data_locale                              = "en-GB"
  events_late_arrival_max_delay_in_seconds = 60
  events_out_of_order_max_delay_in_seconds = 50
  events_out_of_order_policy               = "Adjust"
  output_error_policy                      = "Drop"
  streaming_units                          = 3

  tags = {
    CC = var.cctag
    expiration_date = var.expiration_date
  }

  transformation_query = <<QUERY
        SELECT *
    INTO output-to-blob-storage
    FROM iothub-input
QUERY
}


resource "azurerm_stream_analytics_stream_input_iothub" "iotDeployment" {
  name                         = "iothub-input"
  stream_analytics_job_name    = azurerm_stream_analytics_job.iotDeployment.name
  resource_group_name          = azurerm_stream_analytics_job.iotDeployment.resource_group_name
  endpoint                     = "messages/events"
  eventhub_consumer_group_name = "$Default"
  iothub_namespace             = azurerm_iothub.iotDeployment.name
  shared_access_policy_key     = azurerm_iothub.iotDeployment.shared_access_policy[0].primary_key
  shared_access_policy_name    = "iothubowner"

  serialization {
    type     = "Json"
    encoding = "UTF8"
  }
}

resource "azurerm_stream_analytics_output_blob" "iotDeployment" {
  name                      = "output-to-blob-storage"
  stream_analytics_job_name = azurerm_stream_analytics_job.iotDeployment.name
  resource_group_name       = azurerm_stream_analytics_job.iotDeployment.resource_group_name
  storage_account_name      = azurerm_storage_account.iotDeployment1.name
  storage_account_key       = azurerm_storage_account.iotDeployment1.primary_access_key
  storage_container_name    = azurerm_storage_container.iotDeployment.name
  path_pattern              = ""
  date_format               = "yyyy-MM-dd"
  time_format               = "HH"

  serialization {
    type            = "Csv"
    encoding        = "UTF8"
    field_delimiter = ","
  }
}

###########################################################
###
### App Service Function Section:
###     1) App Service Plan
###     2) Function App
###
###########################################################



resource "azurerm_app_service_plan" "iotDeployment" {
  name                = format("%sFNP%s01" ,var.prefix, var.env) 
  location            = azurerm_resource_group.iotDeployment.location
  resource_group_name = azurerm_resource_group.iotDeployment.name
  kind                = "FunctionApp"

  sku {
    tier = "Dynamic"
    size = "Y1"
  }

  tags = {
    cc = var.cctag
    expiration_date = var.expiration_date
  }
}

resource "azurerm_function_app" "iotDeployment" {
  name                      = format("%sFUN%s01" ,var.prefix, var.env) 
  location                  = azurerm_resource_group.iotDeployment.location
  resource_group_name       = azurerm_resource_group.iotDeployment.name
  app_service_plan_id       = azurerm_app_service_plan.iotDeployment.id
  storage_connection_string = azurerm_storage_account.iotDeployment1.primary_connection_string

  tags = {
    cc = var.cctag
    expiration_date = var.expiration_date
  }
}


###########################################################
###
### Private Endpoint for IoT Hub
###     1) Uncomment this section to create and assign
###
###########################################################


resource "azurerm_private_endpoint" "iotDeployment" {
  name                = var.private_endpoint_name
  location            = azurerm_resource_group.iotDeployment.location
  resource_group_name = azurerm_resource_group.iotDeployment.name
  subnet_id           = azurerm_subnet.iotDeployment1.id

  private_service_connection {
    name                           = "privateserviceconnection"
    private_connection_resource_id = azurerm_iothub.iotDeployment.id
    subresource_names              = [ "iotHub" ]
    is_manual_connection           = false
  }
}



###########################################################
###
### Container Registry
###
###########################################################

resource "azurerm_container_registry" "iotDeployment" {
  name                     = var.container_registry_name
  resource_group_name      = azurerm_resource_group.iotDeployment.name
  location                 = azurerm_resource_group.iotDeployment.location
  sku                      = "Standard"
}


###########################################################
###
### Deployment of the Virtual Machine
###     1) NIC Definition
###     2) VM Deployment with
###         a) Storage Image Reference: Linux
###         b) Storage OS Disk
###########################################################

resource "azurerm_network_interface" "iotDeployment" {
  name                = var.nic_name
  location            = azurerm_resource_group.iotDeployment.location
  resource_group_name = azurerm_resource_group.iotDeployment.name

  ip_configuration {
    name                          = "ipConfiguration1"
    subnet_id                     = azurerm_subnet.iotDeployment2.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_virtual_machine" "iotDeployment" {
  name                  = var.virtual_machine_name
  location              = azurerm_resource_group.iotDeployment.location
  resource_group_name   = azurerm_resource_group.iotDeployment.name
  network_interface_ids = [azurerm_network_interface.iotDeployment.id]
  vm_size               = var.vm_size

  # Uncomment this line to delete the OS disk automatically when deleting the VM
  delete_os_disk_on_termination = true

  # Uncomment this line to delete the data disks automatically when deleting the VM
  delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }
  storage_os_disk {
    name              = "myosdisk1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name  = "hostname"
    admin_username = var.vm_username
    admin_password = var.vm_username_password
  }
  os_profile_linux_config {
    disable_password_authentication = false
  }
  tags = {
    environment = "staging"
  }
}


###########################################################
###
### Deployment of the AKS service
###########################################################

resource "azurerm_kubernetes_cluster" "amlDeployment" {
  name                = "${var.prefix}-aks"
  location            = azurerm_resource_group.iotDeployment.location
  resource_group_name = azurerm_resource_group.iotDeployment.name
  dns_prefix          = "${var.prefix}-aks"

  default_node_pool {
    name                = "default"
    node_count          = 2
    vm_size             = "Standard_D2_v2"
    type                = "VirtualMachineScaleSets"
    availability_zones  = ["1", "2"]
    enable_auto_scaling = true
    min_count           = 2
    max_count           = 4

    # Required for advanced networking
    vnet_subnet_id = azurerm_subnet.iotDeployment3.id
  }

service_principal {
    client_id     = var.client_app_id
    client_secret = var.server_app_secret
  }
  identity {
    type = "SystemAssigned"
  }

  role_based_access_control {
    azure_active_directory {
      client_app_id     = var.client_app_id
      server_app_id     = var.server_app_id
      server_app_secret = var.server_app_secret
      tenant_id         = var.tenant_id
    }
    enabled = true
  }

  network_profile {
    network_plugin    = "azure"
    load_balancer_sku = "standard"
    network_policy    = "calico"
  }

  tags = {
    Environment = "Development"
  }
}

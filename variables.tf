variable "prefix"{
  type = string
  description = "This will be the prefix all resources will have"
  default = "PODMTY"
}

variable "env"{
  type = string
  description = "Environment: Dev, QA, Prod, Sbx, etc..."
  default = "SBX"
}

variable "location" {
  type        = string
  description = "Resource Location"
  default = "East US 2"
}

variable "cctag" {
  type        = string
  description = "Cost Center"
  default = "Microsoft ACOs"
}

variable "expiration_date" {
  type        = string
  description = "Cost Center"
  default = "20201120"
}

variable "environment" {
  type        = string
  description = "Select your environment from: Demo, PoC, Hackathon, Dev, QA, Performance, Pre-Prod, Prod"
  default = "PoC"
}

variable "vnet_name" {
  type        = string
  description = "Name of the Vnet"
  default = "PODMTYVNETD01"
}

variable "vnet_address_space" {
  type        = string
  description = "Address space for  the Vnet"
  default = "12.5.0.0/16"
}

variable "subnet_name_1" {
  type        = string
  description = "Name of the Vnet"
  default = "PODMTYSUBNETD01"
}

variable "subnet_name_2" {
  type        = string
  description = "Name of the Vnet"
  default = "PODMTYSUBNETD02"
}


variable "subnet_name_3" {
  type        = string
  description = "Name of the Vnet"
  default = "PODMTYSUBNETD02"
}

variable "subnet_address_prefix_1" {
  type        = string
  description = "address prefix of the SubNet"
  default = "12.5.1.0/24"
}

variable "subnet_address_prefix_2" {
  type        = string
  description = "address prefix of the SubNet"
  default = "12.5.2.0/24"
}

variable "subnet_address_prefix_3" {
  type        = string
  description = "address prefix of the SubNet"
  default = "12.5.3.0/24"
}

variable "private_endpoint_name" {
  type        = string
  description = "Private Endpoint Name"
  default = "IoTPrivateEndpointName"
}

variable "nic_name" {
  type        = string
  description = "NIC Name"
  default = "IoTVMNicName"
}

variable "virtual_machine_name" {
  type        = string
  description = "Virtual Machine Name"
  default = "PODMTYVMD01"
}

variable "vm_size" {
  type        = string
  description = "Virtual Machine Size"
  default = "Standard_D4d_v4"
}

variable "vm_username" {
  type        = string
  description = "Virtual Machine User Name"
  default = "adminadmin"
}

variable "vm_username_password" {
  type        = string
  description = "Virtual Machine User Name Password"
  default = "P.4ssw0rd!"
}


variable "container_registry_name" {
  type        = string
  description = "Container Registry Name"
  default = "PODMTYCRD01"
}


variable "client_app_id" {
  type        = string
  description = "Registered application in AD for AKS management"
  default = "244fe285-01aa-4db9-aa9c-d9b85c163098"
}

variable "server_app_id" {
  type        = string
  description = "Name of the server registered in AD - this is a UUID"
  default = "4a4147d2-f0d7-49bc-95bd-1168cb34990a"
}

variable "server_app_secret" {
  type        = string
  description = "Client Secret"
  default = "-SK5b_b9mLVc30-iU56k_-vS2WM~2XvKs-"
}

variable "tenant_id" {
  type        = string
  description = "Container Registry Name"
  default = "72f988bf-86f1-41af-91ab-2d7cd011db47"
}


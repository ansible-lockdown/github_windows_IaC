# Configure the Azure provider
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.18.0"
    }
    local = {
      source = "hashicorp/local"
      version = "~> 2.5"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.6.3"
    }
    tls = {
      source = "hashicorp/tls"
      version = "4.0.6"
    }
  }
  required_version = ">= 1.1.0"
}

locals {
  name_prefix = "${var.prefix}-${var.OS_version}-${var.benchmark_type}-${var.run_job_id}"
  # Read Username and password from file
  win_credentials = jsondecode(file("sensitive_info.json"))
  tags = {
    Environment = var.tagname
    Name        = "${var.OS_version}-${var.benchmark_type}"
    Repository  = var.repository
  }
}

provider "azurerm" {
  features {}
}

#Read Username and password from file
data "external" "win_account" {
  program = ["cat", "./sensitive_info.json"]
}

resource "azurerm_resource_group" "main" {
  name     = "${local.name_prefix}-RG"
  location = var.location
  tags = local.tags
}

resource "azurerm_virtual_network" "main" {
  name                = "${local.name_prefix}-network"
  address_space       = ["172.16.0.0/16"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags = local.tags
}

resource "azurerm_subnet" "internal" {
  name                 = "${local.name_prefix}-intip"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["172.16.101.0/24"]
}

resource "azurerm_public_ip" "main" {
  name                = "${local.name_prefix}-pubip"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  tags = local.tags
}

resource "azurerm_network_interface" "main" {
  name                = "${local.name_prefix}-nic"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.internal.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.main.id
  }

  tags = local.tags
}

resource "azurerm_network_security_group" "secgroup" {
  name                = "${local.name_prefix}-secgroup"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  security_rule {
    name                       = "default-allow-3389"
    priority                   = 1000
    access                     = "Allow"
    direction                  = "Inbound"
    destination_port_range     = 3389
    protocol                   = "*" # rdp uses both
    source_port_range          = "*"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "default-allow-winrm"
    priority                   = 1001
    access                     = "Allow"
    direction                  = "Inbound"
    destination_port_range     = "5985-5986"
    protocol                   = "*" # rdp uses both
    source_port_range          = "*"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }
  tags = local.tags
}

# Associate subnet and network security group
resource "azurerm_subnet_network_security_group_association" "secgroup-assoc" {
  subnet_id                 = azurerm_subnet.internal.id
  network_security_group_id = azurerm_network_security_group.secgroup.id
}

resource "azurerm_windows_virtual_machine" "main" {
  name                = local.name_prefix
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  size                = var.system_size
  admin_username      = local.win_credentials["username"]
  admin_password      = local.win_credentials["password"]
  network_interface_ids = [
    azurerm_network_interface.main.id,
  ]

  source_image_reference {
    publisher = var.OS_publisher
    offer     = var.product_id
    sku       = "${var.OS_version}-${var.system_release}"
    version   = "latest"
  }

  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }

  tags = local.tags
}

## Install the custom script VM extension to each VM. When the VM comes up,
## the extension will download the ConfigureRemotingForAnsible.ps1 script from GitHub
## and execute it to open up WinRM for Ansible to connect to it from Azure Cloud Shell.
## exit code has to be 0
resource "azurerm_virtual_machine_extension" "enablewinrm" {
  name                       = "enablewinrm"
  virtual_machine_id         = azurerm_windows_virtual_machine.main.id
  publisher                  = "Microsoft.Compute"     ## az vm extension image list --location eastus Do not use Microsoft.Azure.Extensions here
  type                       = "CustomScriptExtension" ## az vm extension image list --location eastus Only use CustomScriptExtension here
  type_handler_version       = "1.10"                  ## az vm extension image list --location eastus
  auto_upgrade_minor_version = true
  settings                   = jsonencode(
    {
      fileUris = [
        "https://raw.githubusercontent.com/ansible-lockdown/github_windows_IaC/devel/scripts/ConfigureRemotingForAnsible.ps1"
      ]
      commandToExecute = "powershell -ExecutionPolicy Unrestricted -File ConfigureRemotingForAnsible.ps1"
    }
  )
}


// generate inventory file
resource "local_file" "inventory" {
  filename             = "./hosts.yml"
  directory_permission = "0755"
  file_permission      = "0644"
  content              = yamlencode(
    {
      # benchmark host
      all = {
        hosts = {
          (var.hostname) = {
            ansible_host = azurerm_public_ip.main.ip_address
          }
        }
        vars = {
          ansible_user                         = local.win_credentials["username"]
          ansible_password                     = local.win_credentials["password"]
          setup_audit                          = true
          run_audit                            = true
          system_is_ec2                        = true
          audit_git_version                    = "devel"
          win_skip_for_test                    = true
          ansible_connection                   = "winrm"
          ansible_winrm_server_cert_validation = "ignore"
          ansible_winrm_operation_timeout_sec  = 120
          ansible_winrm_read_timeout_sec       = 180
        }
      }
    }
  )
}

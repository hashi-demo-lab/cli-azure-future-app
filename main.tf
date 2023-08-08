provider "azurerm" {
  tenant_id       = var.tenant_id
  subscription_id = var.subscription_id
  features {}

}

provider "hcp" {
  project_id = var.hcp_project_id
}

resource "azurerm_resource_group" "myresourcegroup" {
  name     = "${var.prefix}-workshop"
  location = var.location

  tags = {
    environment = "Test"
  }
}

resource "azurerm_virtual_network" "vnet" {
  name                = "${var.prefix}-vnet"
  location            = azurerm_resource_group.myresourcegroup.location
  address_space       = [var.address_space]
  resource_group_name = azurerm_resource_group.myresourcegroup.name
}

resource "azurerm_subnet" "subnet" {
  name                 = "${var.prefix}-subnet"
  virtual_network_name = azurerm_virtual_network.vnet.name
  resource_group_name  = azurerm_resource_group.myresourcegroup.name
  address_prefixes     = [var.subnet_prefix]
}

resource "azurerm_network_security_group" "futureApp-sg" {
  name                = "${var.prefix}-sg"
  location            = var.location
  resource_group_name = azurerm_resource_group.myresourcegroup.name

  security_rule {
    name                       = "HTTP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "HTTPS"
    priority                   = 102
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "SSH"
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface" "futureApp-nic" {
  name                = "${var.prefix}-futureApp-nic"
  location            = var.location
  resource_group_name = azurerm_resource_group.myresourcegroup.name

  ip_configuration {
    name                          = "${var.prefix}ipconfig"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.futureApp-pip.id
  }
}

resource "azurerm_network_interface_security_group_association" "futureApp-nic-sg-ass" {
  network_interface_id      = azurerm_network_interface.futureApp-nic.id
  network_security_group_id = azurerm_network_security_group.futureApp-sg.id
}

resource "azurerm_public_ip" "futureApp-pip" {
  name                = "${var.prefix}-ip"
  location            = var.location
  resource_group_name = azurerm_resource_group.myresourcegroup.name
  allocation_method   = "Dynamic"
  domain_name_label   = "${var.prefix}-future"
}

data "hcp_packer_iteration" "ubuntu" {
  bucket_name = "azure-ubuntu-apache"
  channel     = "latest"
}

data "hcp_packer_image" "azure-ubuntu-apache" {
  bucket_name    = "azure-ubuntu-apache"
  cloud_provider = "azure"
  iteration_id   = data.hcp_packer_iteration.ubuntu.ulid
  region         = "Australia East"
}

resource "azurerm_linux_virtual_machine" "futureApp" {
  name                            = "${var.prefix}-future"
  resource_group_name             = azurerm_resource_group.myresourcegroup.name
  location                        = var.location
  size                            = var.vm_size
  admin_username                  = var.admin_username
  admin_password                  = var.admin_password
  network_interface_ids           = [azurerm_network_interface.futureApp-nic.id]
  disable_password_authentication = false
  source_image_id                 = data.hcp_packer_image.azure-ubuntu-apache.cloud_image_id
  computer_name                   = var.prefix
  os_disk {
    name                 = "${var.prefix}-osdisk"
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }
  # Added to allow destroy to work correctly.
  depends_on = [azurerm_network_interface_security_group_association.futureApp-nic-sg-ass]
}

locals {
  dnsregion = lower(replace(var.location, "/\\s+/", ""))
}

resource "azurerm_virtual_machine_extension" "vmext" {

  name                 = "${var.prefix}-${var.extension_name}"
  virtual_machine_id   = azurerm_linux_virtual_machine.futureApp.id
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.0"
  settings             = <<SETTINGS
  {
  "commandToExecute": "sudo chown -R ${var.admin_username}:${var.admin_username} /var/www/html;cd /tmp;git clone https://github.com/CloudbrokerAz/theFutureHasLanded.git; cd /var/www/html ; sudo cp -r /tmp/theFutureHasLanded/. . ; sudo certbot --agree-tos --apache --renew-by-default --register-unsafely-without-email -d ${var.prefix}-future.${local.dnsregion}.cloudapp.azure.com"
  }
SETTINGS

  lifecycle {
    create_before_destroy = false
  }

}



# We're using a little trick here so we can run the provisioner without
# destroying the VM. Do not do this in production.

# If you need ongoing management (Day N) of your virtual machines a tool such
# as Chef or Puppet is a better choice. These tools track the state of
# individual files and can keep them in the correct configuration.

# Here we do the following steps:
# Sync everything in files/ to the remote VM.
# Set up some environment variables for our script.
# Add execute permissions to our scripts.
# Run the deploy_app.sh script.
/* resource "null_resource" "configure-future-app" {
  depends_on = [
    azurerm_linux_virtual_machine.futureApp
  ]

  provisioner "file" {
    source      = "${path.module}/files/"
    destination = "/home/${var.admin_username}/"

    connection {
      type     = "ssh"
      user     = var.admin_username
      password = var.admin_password
      host     = azurerm_public_ip.futureApp-pip.fqdn
    }
  }

  provisioner "remote-exec" {
    inline = [
      "sudo chown -R ${var.admin_username}:${var.admin_username} /var/www/html",
      "chmod +x *.sh",
      "cd /var/www/html",
      "rm index.html",
      "git clone https://github.com/CloudbrokerAz/theFutureHasLanded.git .",
      "LOCATION=${var.location} PREFIX=${var.prefix} /home/${var.admin_username}/deploy_app.sh",
      "sudo certbot --agree-tos --apache --renew-by-default --register-unsafely-without-email -d ${var.prefix}-future.australiaeast.cloudapp.azure.com",
    ]

    connection {
      type     = "ssh"
      user     = var.admin_username
      password = var.admin_password
      host     = azurerm_public_ip.futureApp-pip.fqdn
    }
  }


} */
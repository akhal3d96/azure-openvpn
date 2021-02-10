provider "azurerm" {
  features {}
}

# Create a resource group
resource "azurerm_resource_group" "vpn_resource_group" {
  name     = var.resource_group_name
  location = var.resource_group_location
}

resource "azurerm_virtual_network" "vpn_network" {
  name                = var.vpn_network_name
  resource_group_name = azurerm_resource_group.vpn_resource_group.name
  location            = azurerm_resource_group.vpn_resource_group.location

  # 192.168.X.X
  address_space = ["192.168.0.0/16"]
}

resource "azurerm_network_security_group" "vpn_security_group" {
  name                = "vpn_security_group"
  location            = azurerm_resource_group.vpn_resource_group.location
  resource_group_name = azurerm_resource_group.vpn_resource_group.name
}

resource "azurerm_network_security_rule" "vpn_server_openvpn" {
  name                        = "openvpn"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "443"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.vpn_resource_group.name
  network_security_group_name = azurerm_network_security_group.vpn_security_group.name

}

resource "azurerm_network_security_rule" "vpn_server_ssh" {
  name                        = "ssh"
  priority                    = 101
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.vpn_resource_group.name
  network_security_group_name = azurerm_network_security_group.vpn_security_group.name

}


resource "azurerm_network_interface_security_group_association" "example" {
  network_interface_id      = azurerm_network_interface.vpn_nic.id
  network_security_group_id = azurerm_network_security_group.vpn_security_group.id
}


resource "azurerm_subnet" "vpn_subnet" {
  name                 = var.vpn_subnet_name
  resource_group_name  = azurerm_resource_group.vpn_resource_group.name
  virtual_network_name = azurerm_virtual_network.vpn_network.name

  # 192.168.1.0 - 192.168.1.7
  # 5 Azure reserved + 3 Available
  address_prefixes = ["192.168.1.0/29"]
}


resource "azurerm_network_interface" "vpn_nic" {
  name                = var.vpn_nic_name
  location            = azurerm_resource_group.vpn_resource_group.location
  resource_group_name = azurerm_resource_group.vpn_resource_group.name

  ip_configuration {
    name                          = "vpn_internal"
    subnet_id                     = azurerm_subnet.vpn_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.vpn_public_ip.id
  }
}

resource "azurerm_public_ip" "vpn_public_ip" {
  name                = var.vpn_public_ip_name
  resource_group_name = azurerm_resource_group.vpn_resource_group.name
  location            = azurerm_resource_group.vpn_resource_group.location
  allocation_method   = "Static"
}


resource "azurerm_linux_virtual_machine" "vpn_server" {
  name                = var.vpn_server_name
  resource_group_name = azurerm_resource_group.vpn_resource_group.name
  location            = azurerm_resource_group.vpn_resource_group.location
  size                = var.vpn_server_size
  admin_username      = var.vpn_server_username
  # priority            = var.vpn_server_priority
  # eviction_policy     = "Deallocate"
  network_interface_ids = [
    azurerm_network_interface.vpn_nic.id,
  ]

  admin_ssh_key {
    username = var.vpn_server_username
    # public_key = var.vpn_server_public_key
    public_key = file("${path.module}/vpn_ssh.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  connection {
    type        = "ssh"
    user        = var.vpn_server_username
    host        = self.public_ip_address
    private_key = file("${path.module}/vpn_ssh")
  }

  # Install OpenVPN
  provisioner "remote-exec" {
    inline = [
      "curl -O https://raw.githubusercontent.com/angristan/openvpn-install/master/openvpn-install.sh",
      "chmod +x openvpn-install.sh",
      "sudo CLIENT=${var.vpn_server_username} PORT_CHOICE=2 PORT=443 PROTOCOL_CHOICE=2 AUTO_INSTALL=y ./openvpn-install.sh"
    ]
  }

  # Copy OpenVPN profile
  provisioner "local-exec" {
    command = "scp -i vpn_ssh -o StrictHostKeyChecking=no -o IdentitiesOnly=yes ${var.vpn_server_username}@${self.public_ip_address}:~/${var.vpn_server_username}.ovpn ./"
  }

  depends_on = [azurerm_network_interface.vpn_nic]
}

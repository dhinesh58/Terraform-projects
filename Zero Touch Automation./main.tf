terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "3.92.0"
    }
  }
}
provider "azurerm" {
 features {}
}
#Create a resource group if it doesn't exist

resource "azurerm_resource_group" "name" {
    name = var.resource_group_name_value
    location = var.resource_group_location_value
}
# Create virtual network

resource "azurerm_virtual_network" "name" {
    name = var.virtual_network_name_value
    location = var.resource_group_location_value
    resource_group_name =azurerm_resource_group.name.name
    address_space = var.address_space_value
}

# Create subnet
resource "azurerm_subnet" "name" {
    name = var.subnet_name_value
    resource_group_name = azurerm_resource_group.name.name
    virtual_network_name = azurerm_virtual_network.name.name
    address_prefixes = var.address_prefixes_value 
}

# Create public IPs
resource "azurerm_public_ip" "name" {
  name = var.public_ip_name
  resource_group_name = azurerm_resource_group.name.name
  location = azurerm_resource_group.name.location
  allocation_method = "Dynamic" 
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "name" {
  name = var.network_security_group_value
  resource_group_name = azurerm_resource_group.name.name
  location = azurerm_resource_group.name.location 
  security_rule {
       name                        = "SSH"
        priority                   = 1001
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "22"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
        
  }
  security_rule {
    name = "Http"
    priority = "100"
    direction = "Inbound"
    access = "Allow"
    protocol = "Tcp"
    source_port_range           = "*"
  destination_port_range      = "80"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  }
}

#Create Network Interface 
resource "azurerm_network_interface" "name" {
    name = var.network_interface_name_value
    location = var.resource_group_location_value
    resource_group_name = azurerm_resource_group.name.name
    ip_configuration {
      name = "Internal"
      subnet_id = azurerm_subnet.name.id
      private_ip_address_allocation = "Dynamic"
      public_ip_address_id =azurerm_public_ip.name.id
    } 
}

#Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "name" {
  network_interface_id = azurerm_network_interface.name.id
  network_security_group_id = azurerm_network_security_group.name.id  
}

#Create storage account for boot diagnostics
resource "azurerm_storage_account" "mystorageaccount" {
  name = var.storage_account_mystorageaccount
  resource_group_name = azurerm_resource_group.name.name
  location = var.resource_group_location_value
  account_replication_type = "LRS"
  account_tier = "Standard"  
}
#Create and display an SSH key
resource "tls_private_key" "linuxkey" {
  algorithm = "RSA"
  rsa_bits = "4096" 
}
output "tls_private_key" {
  value = tls_private_key.linuxkey.private_key_pem
  sensitive = true 
}
output "azurerm_linux_virtual_machine" {
  value = azurerm_linux_virtual_machine.name.public_ip_address
}
resource "local_file" "linuxkey" {
  filename = "linuxkey.pem"
  content = tls_private_key.linuxkey.private_key_pem

}
#Create Virtual machine
resource "azurerm_linux_virtual_machine" "name" {
  name = var.virtual_machine_name_Value
  location =var.resource_group_location_value
  resource_group_name = azurerm_resource_group.name.name
  admin_username = var.admin_username_value
  size = "Standard_F2"
  network_interface_ids = [azurerm_network_interface.name.id]
  os_disk {
    caching = "ReadWrite"
    storage_account_type = "Standard_LRS"
    }
    source_image_reference {
      publisher = "Canonical"
      offer = "0001-com-ubuntu-server-jammy"
      sku = "22_04-lts"
      version = "latest" 
    }  
    admin_ssh_key {
      username = var.admin_username_value
      public_key = tls_private_key.linuxkey.public_key_openssh
      
    }
    boot_diagnostics {
      storage_account_uri = azurerm_storage_account.mystorageaccount.primary_blob_endpoint
    } 
    depends_on = [ 
      tls_private_key.linuxkey
     ]
    connection {
      host = self.public_ip_address
      type = "ssh"
      user = var.admin_username_value
      private_key = tls_private_key.linuxkey.public_key_openssh
    } #File provisioner to copy a file from local to the VM
    provisioner "file" {
      source = "app.py"
      destination = "/home/ubuntu/app.py"
    }
    
    

     provisioner "remote-exec" {
    inline = [
      "echo 'Hello from the remote instance'",
      "sudo apt update -y",  # Update package lists (for ubuntu)
      "sudo apt-get install -y python3-pip",  # Example package installation
      "cd /home/ubuntu",
      "sudo pip3 install flask",
      "sudo python3 app.py &",
    ]
  }


}






  

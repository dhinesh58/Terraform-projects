# Terraform projects using provioner concepts

File Provisioners
The file provisioner is used to copy files or directories from the local machine to a remote machine. This is useful for deploying configuration files, scripts, or other assets to a provisioned instance.

```json
provisioner"file" {
      source = "app.py"
      destination = "/home/ubuntu/app.py"
    }
    connection { 
    host = self.public_ip_address 
    type = "ssh"
    user = var.admin_username_value
    private_key = tls_private_key.linuxkey.public_key_openssh
     }

  In this example, the file provisioner copies the localfile.txt from the local machine to the /path/on/remote/instance/file.txt location on the Azure virtual machines using an SSH connection.

 **#  Remote-exec Provisioner**
 The remote-exec provisioner is used to run scripts or commands on a remote machine over SSH or WinRM connections. It's often used to configure or install software on provisioned instances.

 ```json
 provisioner"remote-exec"{
    inline = [
      "echo 'Hello from the remote instance'",
      "sudo apt update -y",  # Update package lists (for ubuntu)
      "sudo apt-get install -y python3-pip",  # Example package installation
      "cd /home/ubuntu",
      "sudo pip3 install flask",
      "sudo python3 app.py &",
    ]
  }

 In this example, the remote-exec provisioner connects to the Azure VM using SSH and runs a series of commands to update the package repositories, install Apache HTTP Server, and start the HTTP server.

variable "headless" {
  type = bool
  default = false
}

variable "cpus" {
  type = number
  default = 2
}

variable "memory" {
  type = number
  default = "1024"
}

source "qemu" "arch-ansible" {
  vm_name = "test-arch-ansible.qcow2"
  format = "qcow2"
  output_directory = "target/test-arch-ansible/"
  disk_image = true
  use_backing_file = true
  iso_url = "target/test-arch-setup/test-arch-setup.qcow2"
  iso_checksum = "none"
  efi_firmware_code = "/usr/share/edk2/x64/OVMF_CODE.4m.fd"
  efi_firmware_vars = "/usr/share/edk2/x64/OVMF_VARS.4m.fd"
  headless = var.headless
  cpus = var.cpus
  memory = var.memory
  disk_size = "10G"
  disk_additional_size = [ "10G" ]
  boot_wait = "15s"

  ssh_username = "user"
  ssh_password = "user"
  ssh_timeout = "30m"

  shutdown_command = "echo 'user' | sudo -S shutdown -P now"
}

build {
  sources = ["source.qemu.arch-ansible"]

  provisioner "shell" {
    inline = ["echo 'user' | sudo -S pacman -S ansible --noconfirm"]
  }

  provisioner "ansible-local" {
    extra_arguments = [
      "--limit", "local",
      "--extra-vars", "\"ansible_become_pass=user\""
    ]
    inventory_file = "../ansible/inventory"
    playbook_dir = "../ansible"
    playbook_file = "../ansible/local.yml"
  }
}

packer {
  required_plugins {
    qemu = {
      source  = "github.com/hashicorp/qemu"
      version = "~> 1"
    }
    ansible = {
      source = "github.com/hashicorp/ansible"
      version = "~> 1"
    }
  }
}

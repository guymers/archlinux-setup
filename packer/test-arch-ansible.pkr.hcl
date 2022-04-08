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
  headless = var.headless
  cpus = var.cpus
  memory = var.memory
  disk_size = 10240
  qemuargs = [
    ["-bios", "/usr/share/edk2-ovmf/x64/OVMF_CODE.fd"]
  ]
  boot_wait = "15s"

  ssh_username = "user"
  ssh_password = "user"
  ssh_timeout = "30m"

  shutdown_command = "echo 'user' | sudo -S shutdown -P now"
}

build {
  sources = ["source.qemu.arch-ansible"]

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

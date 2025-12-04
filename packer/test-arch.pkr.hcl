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

source "qemu" "arch-setup" {
  vm_name = "test-arch.qcow2"
  format = "qcow2"
  output_directory = "target/test-arch/"
  iso_url = "https://geo.mirror.pkgbuild.com/iso/2025.12.01/archlinux-2025.12.01-x86_64.iso"
  iso_checksum = "sha256:c2b1f13a68482db3aad008f14bb75cb15a44cd38fa8a1aa15e6675a50d4c4374"
  efi_firmware_code = "/usr/share/edk2/x64/OVMF_CODE.4m.fd"
  efi_firmware_vars = "/usr/share/edk2/x64/OVMF_VARS.4m.fd"
  headless = var.headless
  cpus = var.cpus
  memory = var.memory
  disk_size = "10G"
  disk_additional_size = [ "10G" ]
  boot_wait = "9s"
  boot_command = [
    "<enter><wait10><wait10><wait10>",
    "curl -O http://{{ .HTTPIP }}:{{ .HTTPPort }}/init.sh<enter><wait2>",
    "bash init.sh<enter>"
  ]
  http_directory = "http"

  ssh_username = "user"
  ssh_password = "user"
  ssh_timeout = "30m"
  ssh_handshake_attempts = 100

  shutdown_command = "echo 'user' | sudo -S shutdown -P now"
}

build {
  sources = ["source.qemu.arch-setup"]
}

packer {
  required_plugins {
    qemu = {
      source  = "github.com/hashicorp/qemu"
      version = "~> 1"
    }
  }
}

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
  iso_url = "https://geo.mirror.pkgbuild.com/iso/2024.08.01/archlinux-2024.08.01-x86_64.iso"
  iso_checksum = "sha256:55284a14f71df3e1e45a1e732097f2ca0034c0fc0d912e58812c2eededa0828f"
  headless = var.headless
  cpus = var.cpus
  memory = var.memory
  disk_size = "10G"
  disk_additional_size = [ "10G" ]
  qemuargs = [
    ["-bios", "/usr/share/edk2-ovmf/x64/OVMF_CODE.fd"]
  ]
  boot_wait = "10s"
  boot_command = [
    "<enter><wait10><wait10><wait10><wait10>",
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

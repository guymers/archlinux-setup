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
  vm_name = "test-arch-setup.qcow2"
  format = "qcow2"
  output_directory = "target/test-arch-setup/"
  iso_url = "http://mirror.rackspace.com/archlinux/iso/2021.07.01/archlinux-2021.07.01-x86_64.iso"
  iso_checksum = "sha1:5804cefb2e5e7498cb15f38180cb3ebc094f6955"
  headless = var.headless
  cpus = var.cpus
  memory = var.memory
  disk_size = 10240
  qemuargs = [
    ["-bios", "/usr/share/edk2-ovmf/x64/OVMF_CODE.fd"]
  ]
  boot_wait = "10s"
  boot_command = [
    "<enter><wait10><wait10><wait10><wait10>",
    "curl -s http://{{ .HTTPIP }}:{{ .HTTPPort }}/setup.tar | tar -x<enter><wait2>",
    "curl -s http://{{ .HTTPIP }}:{{ .HTTPPort }}/run_setup.sh > run_setup.sh<enter><wait2>",
    "bash run_setup.sh<enter>"
  ]
  http_directory = "http"

  ssh_username = "user"
  ssh_password = "user"
  ssh_timeout = "15m"
  ssh_handshake_attempts = 100

  shutdown_command = "echo 'user' | sudo -S shutdown -P now"
}

build {
  sources = ["source.qemu.arch-setup"]
}

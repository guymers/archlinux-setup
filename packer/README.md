To test the current version run:

    packer build test-arch.json

To not run headless use the command flag `-var 'headless=false'`

To test against a machine using UEFI use the command flag `-var 'firmware=efi'`

During development run:

    (cd .. && tar cf packer/http/setup.tar ansible/ setup.sh)
    packer build -force test-arch-setup.json
    packer build -force test-arch-ansible.json

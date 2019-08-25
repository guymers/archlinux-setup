To test the current version run:

    packer build test-arch.json

To run headless use the command flag `-var 'headless=true'`

During development run:

    (cd .. && tar cf packer/http/setup.tar ansible/ setup.sh)
    packer build -force test-arch-setup.json
    packer build -force test-arch-ansible.json

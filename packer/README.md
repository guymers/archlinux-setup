To test the current version run:

    packer build test-arch.pkr.hcl

To run headless use the command flag `-var 'headless=true'`

During development run:

    (cd .. && tar cf packer/http/setup.tar ansible/ config/ setup.sh)
    packer build -force test-arch-setup.pkr.hcl
    packer build -force test-arch-ansible.pkr.hcl

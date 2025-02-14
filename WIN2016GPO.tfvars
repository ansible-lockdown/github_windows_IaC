OS_publisher   = "MicrosoftWindowsServer"
OS_version     = "2016"
system_release = "datacenter-gensecond"
hostname       = "ALGPO"
product_id     = "WindowsServer"

additional_inventory_settings = <<EOT
        win16cis_ansible_remediation: "false"
        win16cis_create_gpos: "true"
        win16cis_create_domain: true
EOT

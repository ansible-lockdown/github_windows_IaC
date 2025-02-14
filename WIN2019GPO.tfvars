OS_publisher   = "MicrosoftWindowsServer"
OS_version     = "2019"
system_release = "datacenter-gensecond"
hostname       = "ALGPO"
product_id     = "WindowsServer"
resource_group_style = "GPO"

additional_inventory_settings = <<EOT
        win19cis_ansible_remediation: false
        win19cis_create_gpos: true
        win19cis_create_domain: true
EOT

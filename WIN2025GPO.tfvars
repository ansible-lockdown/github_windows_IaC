OS_publisher   = "MicrosoftWindowsServer"
OS_version     = "2025"
system_release = "datacenter-g2"
hostname       = "ALGPO"
product_id     = "WindowsServer"
resource_group_style = "GPO"

additional_inventory_settings = <<EOT
        win25cis_ansible_remediation: false
        win25cis_create_gpos: true
        win25cis_create_domain: true
EOT

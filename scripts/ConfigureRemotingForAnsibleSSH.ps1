# Import the required module
Import-Module -Name 'NetSecurity'

# Store the original startup type of Windows Update service
$wuauserv = Get-WmiObject Win32_Service -Filter "Name = 'wuauserv'"
$wuauserv_starttype = $wuauserv.StartMode

# Set Windows Update service to manual startup type
Set-Service wuauserv -StartupType Manual

# Set SSH service to automatic startup type and start it
Set-Service sshd -StartupType Automatic
Start-Service sshd

# Restore the original startup type of Windows Update service
Set-Service wuauserv -StartupType $wuauserv_starttype

# Configure PowerShell as the default shell for SSH
New-ItemProperty -Path "HKLM:\SOFTWARE\OpenSSH" -Name DefaultShell -Value "$Env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe" -PropertyType String -Force

# Restart the SSH service
Restart-Service sshd

# SSH public key content (Enter Your Public Key Here)
######################################################
##                                                  ##
##  REMOVE THE PUBLIC KEY BELOW AND ENTER YOUR OWN  ##
##                                                  ##
######################################################
$content = @"
ssh-rsa BAAAB3NzaC1yc2FAAAADAQABAAABgQDbWnk4if1hQiX8dCiDEYKxkyVcpYBUayQt9p/a6PeVUl41WFmwbtgELjUR4P62BW9kQmRfzCBUya1YNKAXMjDu+KJxF/zN8kPU2BXm3eEOIKMbjSrusBQfKXZEy7DYFUChKRpYG262Hur9I7gxCxYm4CzF7e8t/oRhiA/OXkGvEvWA7WALMRP0Et1KEQSsMoPvuHs5BYQMElOcsV4feRhEu4qcgxH74+x569DVsD7l+5Zgt+qnZ26Mx0JFPrBq8TjeiIR5aqxgnz+xTl5XHfJ3D4ncsgPkQOqodFeJ4kR3eVGsWmtGZrYz/4VkfRDWGSPcowsqCwlkUtxpR28tGtDslv7jcg21Bzqn6RD/UmSd9PosuQHG41OS3aiSMfISXVcRziiDRrsB0sSFaVT/mdbyD7xHYTtsPdrn3spc0VpvD6Z2Iq+Q/4VMZJ73NWA+4OISBWMj0bIBp8NboeQHyN47kKeFHpOnh7DETGl44Nmwe6ybcV1R0NBGQHsKqOk5+x8= stephenw@MPGLT-C02GKAT0MD6M
"@

# Write public key to file
$content | Set-Content -Path "$Env:ProgramData\ssh\administrators_authorized_keys"

# Set ACL on administrators_authorized_keys
$admins = ([System.Security.Principal.SecurityIdentifier]'S-1-5-32-544').Translate([System.Security.Principal.NTAccount]).Value
$acl = Get-Acl "$Env:ProgramData\ssh\administrators_authorized_keys"
$acl.SetAccessRuleProtection($true, $false)
$administratorsRule = New-Object System.Security.AccessControl.FileSystemAccessRule($admins, "FullControl", "Allow")
$systemRule = New-Object System.Security.AccessControl.FileSystemAccessRule("SYSTEM", "FullControl", "Allow")
$acl.SetAccessRule($administratorsRule)
$acl.SetAccessRule($systemRule)
$acl | Set-Acl

# Open firewall port 22 for SSH
$FirewallParams = @{
    "DisplayName"       = 'OpenSSH SSH Server (sshd)'
    "Direction"         = 'Inbound'
    "Action"            = 'Allow'
    "Protocol"          = 'TCP'
    "LocalPort"         = '22'
    "Program"           = '%SystemRoot%\system32\OpenSSH\sshd.exe'
}
New-NetFirewallRule @FirewallParams

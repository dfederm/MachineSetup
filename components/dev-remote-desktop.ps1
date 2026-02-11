@{
    Name        = "Remote Desktop"
    Description = "Enable Remote Desktop and firewall rules"
    Category    = "Dev"
    Scope       = "work"
    Detect      = {
        Test-RegistryValue -Path "HKLM:\System\CurrentControlSet\Control\Terminal Server" -Name "fDenyTSConnections" -Data 0
    }
    Install     = {
        Set-RegistryValue -Path "HKLM:\System\CurrentControlSet\Control\Terminal Server" -Name "fDenyTSConnections" -Data 0 -Type DWord -Elevate > $null
        Enable-FirewallRuleGroup -DisplayGroup "Remote Desktop"
    }
}

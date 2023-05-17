Import-Module "$PSScriptRoot\Console.psm1"
Import-Module "$PSScriptRoot\Elevation.psm1"

function Enable-FirewallRuleGroup()
{
    [CmdletBinding()]
    param (
        [Parameter(Position = 0, Mandatory)]
        [String] $DisplayGroup
    )

    $rules = Get-NetFirewallRule -DisplayGroup $DisplayGroup
    $rulesEnabled = $true
    foreach ($rule in $rules)
    {
        if ($rule.Enabled)
        {
            Write-Debug "$DisplayGroup Firewall rule already enabled: $($rule.DisplayName)"
        }
        else
        {
            Write-Debug "$DisplayGroup Firewall rule not enabled: $($rdpFirewallRule.DisplayName)"
            $rulesEnabled = $false
        }
    }

    if ($rulesEnabled)
    {
        Write-Debug "All $DisplayGroup Firewall rules already enabled"
    }
    else
    {
        Write-Debug "Enabling $DisplayGroup Firewall rules"
        $EnableFirewallRulesBlock = {
            Enable-NetFirewallRule -DisplayGroup $DisplayGroup
        }
        Invoke-Elevated ($ExecutionContext.InvokeCommand.ExpandString($EnableFirewallRulesBlock))
    }
}

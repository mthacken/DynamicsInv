# Requires the Microsoft.Xrm.Data.PowerShell module.
# Install the module if not already installed:
#   Install-Module -Name Microsoft.Xrm.Data.PowerShell

Import-Module Microsoft.Xrm.Data.PowerShell

# Connect to the Dynamics 365 instance interactively.
$crmConn = Get-CrmConnection

<#
This script creates an overview of all plugins and workflows from a Dynamics 365 repository.
It uses the following requests from the CRM SDK:
  - RetrieveAllPluginsRequest
  - RetrieveWorkflowRequest
  - RetrievePluginAssembliesRequest

NOTE: The standard Microsoft.Xrm.Data.PowerShell module may not expose these requests directly.
This script uses Get-CrmRecords as an approximation to retrieve plugin assemblies and workflows.
Adjust the retrieval logic according to your environment and SDK extensions.
#>

function Get-DynamicsOverview {
    # Retrieve plugin assemblies (simulate RetrievePluginAssembliesRequest)
    $pluginAssemblies = Get-CrmRecords -EntityLogicalName pluginassembly -AllRecords

    # Retrieve workflows (simulate RetrieveWorkflowRequest)
    $workflows = Get-CrmRecords -EntityLogicalName workflow -AllRecords

    # Build an overview table
    $overview = @()

    # Process plugin assemblies as plugins (simulate RetrieveAllPluginsRequest details)
    foreach ($assembly in $pluginAssemblies.CrmRecords) {
        $overview += [PSCustomObject]@{
            Type                    = "Plugin"
            Naam                    = $assembly.friendlyname
            "Class Name"            = $assembly.primaryclassname
            "Geregistreerde Entiteit" = $assembly.sourcetype
            Event                   = ""
            Assembly                = $assembly.name
            Solution                = $assembly.solutionid
        }
    }

    # Process workflows
    foreach ($workflow in $workflows.CrmRecords) {
        $overview += [PSCustomObject]@{
            Type                    = "Workflow"
            Naam                    = $workflow.name
            "Class Name"            = $workflow.workflowactivityname
            "Geregistreerde Entiteit" = $workflow.primaryentity
            Event                   = $workflow.message
            Assembly                = ""
            Solution                = $workflow.solutionid
        }
    }

    return $overview
}

# Retrieve overview data and display in table format
$overviewData = Get-DynamicsOverview
$overviewData | Format-Table -AutoSize

# Optionally, export the overview to a CSV file.
# $overviewData | Export-Csv -Path "DynamicsOverview.csv" -NoTypeInformation

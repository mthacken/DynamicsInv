# Zet het pad naar de root van je repo
$repoRoot = "c:\beheer\Vibe\toezicht2"

# Vind alle csproj files
$csprojFiles = Get-ChildItem -Path $repoRoot -Recurse -Filter *.csproj

$results = @()

foreach ($csproj in $csprojFiles) {
    $projPath = $csproj.FullName
    $projName = $csproj.BaseName

    # Lees de csproj als XML
    [xml]$projXml = Get-Content $projPath

    # Zoek alle Compile Include (C# files)
    $csharpFiles = $projXml.Project.ItemGroup.Compile | Where-Object { $_.Include } | ForEach-Object { $_.Include }

    # Plugins: zoek naar bestanden met 'Plugin' of 'ActionPlugin' in de naam
    $plugins = $csharpFiles | Where-Object { $_ -match 'Plugin\.cs$' -or $_ -match 'ActionPlugin\.cs$' }

    # Workflows: zoek naar bestanden met 'Workflow' in de naam
    $workflows = $csharpFiles | Where-Object { $_ -match 'Workflow\.cs$' }

    # Webresources: zoek naar js, html, css files (Content Include)
    $webresources = @()
    $contentNodes = $projXml.Project.ItemGroup.Content
    if ($contentNodes) {
        $webresources = $contentNodes | Where-Object { $_.Include -match '\.(js|html|css)$' } | ForEach-Object { $_.Include }
    }

    $results += [PSCustomObject]@{
        Project = $projName
        Path = $projPath
        TotalCount = $plugins.Count + $workflows.Count + $webresources.Count
        PluginCount = $plugins.Count
        Plugins = $plugins -join ", "
        WorkflowCount = $workflows.Count
        Workflows = $workflows -join ", "
        WebresourceCount = $webresources.Count  
        Webresources = $webresources -join ", "
    }
}

# Toon het resultaat als tabel
$results | Where-Object { $_.TotalCount -gt 0 } | Format-Table Project,Path,TotalCount,PluginCount,WorkflowCount,WebresourceCount -AutoSize

# Optioneel: exporteer naar CSV
$results | Export-Csv -Path "$repoRoot\csproj_overview.csv" -NoTypeInformation -Delimiter ";"

Write-Host "Overzicht opgeslagen in csproj_overview.csv"
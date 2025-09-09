# Zet het pad naar de root van je repo
$repoRoot = "c:\beheer\Vibe\toezicht2"

function Get-ProjectOverview {
    # Vind alle csproj en sln files
    $csprojFiles = Get-ChildItem -Path $repoRoot -Recurse -Filter *.csproj
    $slnFiles = Get-ChildItem -Path $repoRoot -Recurse -Filter *.sln

    # Maak een mapping: projectpad (relatief) -> solutions
    $projectToSolutions = @{}

    foreach ($sln in $slnFiles) {
        $slnPath = $sln.FullName
        $slnName = $sln.Name

        # Zoek alle projectregels in de solution file
        $projectLines = Select-String -Path $slnPath -Pattern '^Project\(".*"\) = "([^"]+)", "([^"]+)", "([^"]+)"'

        foreach ($line in $projectLines) {
            $matches = [regex]::Match($line.Line, '^Project\(".*"\) = "([^"]+)", "([^"]+)", "([^"]+)"')
            if ($matches.Success) {
                $projRelPath = $matches.Groups[2].Value -replace '\\', [IO.Path]::DirectorySeparatorChar
                $projFullPath = Join-Path -Path (Split-Path $slnPath -Parent) -ChildPath $projRelPath
                $projFullPath = [IO.Path]::GetFullPath($projFullPath)
                if (-not $projectToSolutions.ContainsKey($projFullPath)) {
                    $projectToSolutions[$projFullPath] = @()
                }
                $projectToSolutions[$projFullPath] += $slnName
            }
        }
    }

    $results = @()

    foreach ($csproj in $csprojFiles) {
        $projPath = $csproj.FullName
        $projName = $csproj.BaseName

        # Zoek solutions waarin dit project voorkomt
        $solutions = @()
        if ($projectToSolutions.ContainsKey($projPath)) {
            $solutions = $projectToSolutions[$projPath]
        }

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
            Project          = $projName
            Path             = $projPath
            Solutions        = ($solutions -join ", ")
            CsharpFileCount  = $csharpFiles.Count
            TotalCount       = $plugins.Count + $workflows.Count + $webresources.Count
            PluginCount      = $plugins.Count
            Plugins          = $plugins -join ", "
            WorkflowCount    = $workflows.Count
            Workflows        = $workflows -join ", "
            WebresourceCount = $webresources.Count  
            Webresources     = $webresources -join ", "
        }
    }
    return $results
}


# Toon het resultaat als tabel
$results | Where-Object { $_.TotalCount -gt 0 } | Format-Table Project, Solutions, TotalCount, PluginCount, WorkflowCount, WebresourceCount -AutoSize

# Optioneel: exporteer naar CSV
$results | Export-Csv -Path "$repoRoot\csproj_solution_overview.csv" -NoTypeInformation -Delimiter ";"

Write-Host "Overzicht opgeslagen in csproj_solution_overview.csv"

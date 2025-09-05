# Zoek alle .sln files in de repo
$repoRoot = "c:\beheer\Vibe\toezicht2"
$slnFiles = Get-ChildItem -Path $repoRoot -Recurse -Filter *.sln

$results = @()

foreach ($sln in $slnFiles) {
    $slnPath = $sln.FullName
    $slnName = $sln.Name

    # Zoek alle projectregels in de solution file
    $projectLines = Select-String -Path $slnPath -Pattern '^Project\(".*"\) = "([^"]+)", "([^"]+)", "([^"]+)"'

    $projects = $projectLines | ForEach-Object {
        $matches = [regex]::Match($_.Line, '^Project\(".*"\) = "([^"]+)", "([^"]+)", "([^"]+)"')
        [PSCustomObject]@{
            Solution = $slnName
            ProjectName = $matches.Groups[1].Value
            ProjectPath = $matches.Groups[2].Value
        }
    }

    $results += $projects
}

# Toon het resultaat als tabel
$results | Format-Table -AutoSize

# Optioneel: exporteer naar CSV
$results | Export-Csv -Path "$repoRoot\solution_projects_overview.csv" -NoTypeInformation -Delimiter ";"

Write-Host
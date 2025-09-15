#requires -Version 7.5

Import-Module "$PSScriptRoot\DynamicsInv.psm1" -force

############################################################################################################################################################
# main script
############################################################################################################################################################

# algemene variabelen
if (Test-Path "P:\") {
    $repoRoot = 'P:\Repos\toezicht'
    $outputPath = 'L:\OntwikkelShare\Projecten\Toezicht\Architectuur'
    #    $analyserepo = 'P:\Repos\analyse'
}
else {
    $repoRoot = 'C:\beheer\vibe\toezicht2'
    $outputPath = 'output'
    #    $analyserepo = 'C:\beheer\vibe\dynamicsinv'
}
$servicerepo = "$repoRoot"
$entityrepo = "$repoRoot\crmfiles\components\entities"
$pluginrepo = "$repoRoot\rechtspraak.toezicht.processing\"

$pluginResults = @()
$entityResults = @()
$serviceResults = @()
$serviceRows = @()
$relationResultTotals = @()
$entityNotFound = @()
$script:namespaces = @()
$NameSpaceRelations = @()

# zoek alle C# files de services (alle classes) en service rows (alle constructors, methods, namespaces en usings)
Write-Progress -Activity "Opstarten C# file scan ......"
$i = 1
$csFiles = Get-ChildItem -Path "$servicerepo" -Filter *.cs -Recurse
foreach ($file in $csFiles) {
    # Lees alle regels uit het bestand.
    $serviceResult = Get-CSharpClassOverview -file $File
    if ($serviceResult) {
        $serviceResults += $serviceResult
        $serviceRows += $serviceResult.rows
    }
    Write-Progress -Activity "zoeken door de C# files" -Status "($i / $($csFiles.Count)) $($file.Name)" -PercentComplete ((($i++) / $csFiles.Count) * 100)
}

# zoek dan alle plugins
Write-Progress -Activity "Opstarten Plugins....."
$csFiles = Get-ChildItem -Path $pluginrepo -Filter *.cs -Recurse
$i = 1 
foreach ($file in $csFiles) {
    $pluginResult = Get-PluginOverview -File $file 
    if ($null -ne $pluginResult) {
        $pluginResults += $pluginResult
    }
    Write-Progress -Activity "zoeken door de plugins" -Status "($i / $($csFiles.Count)) $($file.Name)" -PercentComplete ((($i++) / $csFiles.Count) * 100)
}

# uit de namespaces die in de C# files gevonden zijn, maak een overzicht van alle usings per namespace
$i = 1
foreach ($serviceResult in $serviceResults) {
    Update-NamespaceRelations -serviceResult $serviceResult -namespaces ([ref]$namespaces)
    Write-Progress -Activity "update namespace relations" -Status "($i / $($serviceResults.Count))" -PercentComplete ((($i++) / $serviceResults.Count) * 100)
}

# stop de namespace relaties in een array van objecten
$i = 1
foreach ($namespace in $namespaces) {
    foreach ($using in $namespace.usings) {        
        $targetnamespace = $namespaces | where-Object { $_.name -eq $using.name }
        $rows = [PSCustomObject]@{
            Namespace       = $namespace.Name
            Soort           = $namespace.Soort
            Using           = $using.name
            FileNamen       = $using.FileNamen -join '; '
            TargetSoort     = if ($targetnamespace) { $targetnamespace.Soort } else { "Niet gevonden" }
            TargetNamespace = if ($targetnamespace) { $targetnamespace.Name } else { "Niet gevonden" }
            Soortmatch      = if ($namespace.Soort -eq $targetnamespace.Soort) { $true } else { $false }
        }
        $NameSpaceRelations += $rows
    }
    Write-Progress -Activity "save namespace relaties" -Status "($i / $($namespaces.Count))" -PercentComplete ((($i++) / $namespaces.Count) * 100)
}

# Selecteer alleen de objecten waar 'soort plugin' gelijk is aan 'entity'. Deze worden gebruikt om plugins en entities aan elkaar te koppelen.
# $entityPlugins = $pluginResults | Where-Object { $_.'soort plugin' -eq 'entity' }

# zoek alle entities
$csFiles = Get-ChildItem -Path $entityrepo -Filter entity.xml -Recurse
$i = 1
foreach ($file in $csFiles) {
    $entityResult = get-EntityOverview -file $file
    if ($entityResult) {
        $entityResults += $entityResult
        $relationResultTotals += $entityResult.Relations
    }
    Write-Progress -Activity "zoeken naar entities" -Status "($i / $($csFiles.Count)) $($file.Name)" -PercentComplete ((($i++) / $csFiles.Count) * 100)
}

# vul de secondaryEntities aan in de relaties
$i = 1
foreach ($relation in $relationResultTotals) {
    $result = set-SecondaryEntity -Relation $relation
    if (!$result.success) {
        if ($relation.SecondaryId -notin ($entityNotFound | Select-Object -ExpandProperty SecondaryId)) {
            $entityNotFound += , $Relation
        }
    }
    Write-Progress -Activity "completeer relations" -Status "($i / $($relationResultTotals.Count))" -PercentComplete ((($i++) / $relationResultTotals.Count) * 100)
}

# maak een overzicht van projects en solutions
$solutionResults = Get-ProjectOverview -repoRoot $repoRoot

# exporteer de verzamelde object arrays in 7 csv files
if (!(Test-Path -Path "output")) { New-Item -ItemType Directory -Path "output" | Out-Null }

$pluginFile = Resolve-fileName -fileName "plugins" -date $false -outputPath $outputPath
$serviceFile = Resolve-fileName  -fileName "services" -date $false -outputPath $outputPath
$serviceRowsFile = Resolve-fileName -fileName "services_methods" -date $false -outputPath $outputPath
$entityFile = Resolve-fileName -fileName "entities" -date $false -outputPath $outputPath
$relationsFile = Resolve-fileName -fileName "entityrelations" -date $false -outputPath $outputPath
$EntityNotFoundFile = Resolve-fileName -fileName "entity_not_found" -date $false -outputPath $outputPath
$NameSpaceFile = Resolve-filename -FileName "Namespacerelations" -date $false -outputPath $outputPath
$solutionsFile = Resolve-fileName -fileName "solutions" -date $false -outputPath $outputPath

# Exporteer de verzamelde plugin-data naar een CSV-bestand.
$pluginResults | Export-Csv -Path $pluginFile -NoTypeInformation -Encoding UTF8
Write-Output "Export completed to $pluginFile"

# Exporteer de verzamelde services-data naar een CSV-bestand.
$serviceResults | Export-Csv -Path $serviceFile -NoTypeInformation -Encoding UTF8
$serviceRows | Export-Csv -Path $serviceRowsFile -NoTypeInformation -Encoding UTF8
Write-Output "Export completed to $serviceFile and $serviceRowsFile"

# Exporteer de verzamelde entity-data naar een CSV-bestand.
$entityResults | Export-Csv -Path $entityFile -NoTypeInformation -Encoding UTF8
$relationResultTotals | Export-Csv -Path $relationsFile -NoTypeInformation -Encoding UTF8
$entityNotFound | Export-Csv -Path $EntityNotFoundFile -NoTypeInformation -Encoding UTF8
$NameSpaceRelations | Export-Csv -Path $NameSpaceFile -NoTypeInformation -Encoding UTF8
$solutionResults | Export-Csv -Path $solutionsFile -NoTypeInformation -Encoding UTF8

Write-Output "Export completed to $entityFile, $relationsFile, $EntityNotFoundFile and $NameSpaceFile"
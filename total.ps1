#requires -Version 7.5

Import-Module "$PSScriptRoot\DynamicsInv.psm1" -force

############################################################################################################################################################
# main script
############################################################################################################################################################

# algemene variabelen
if (Test-Path "P:\") {
    $repo = 'P:\Repos\toezicht'
    #    $analyserepo = 'P:\Repos\analyse'
}
else {
    $repo = 'C:\beheer\vibe\toezicht2'
    #    $analyserepo = 'C:\beheer\vibe\dynamicsinv'
}
$servicerepo = "$repo\rechtspraak.toezicht\"
$entityrepo = "$repo\crmfiles\components\entities"
$pluginrepo = "$repo\rechtspraak.toezicht.processing\"

$pluginResults = @()
$entityResults = @()
$serviceResults = @()
$serviceRows = @()
$relationResultTotals = @()
$entityNotFound = @()

# zoek eerst alle plugins
Write-Progress -Activity "Opstarten......"
$csFiles = Get-ChildItem -Path $pluginrepo -Filter *.cs -Recurse
$i = 1 
foreach ($file in $csFiles) {
    $pluginResult = Get-PluginOverview -File $file 
    if ($null -ne $pluginResult) {
        $pluginResults += $pluginResult
    }
    Write-Progress -Activity "zoeken naar plugins" -Status "($i / $($csFiles.Count)) $($file.Name)" -PercentComplete ((($i++) / $csFiles.Count) * 100)
}


# vervolgens alle services en service rows (alle methods)
$i = 1
$csFiles = Get-ChildItem -Path "$servicerepo" -Filter *.cs -Recurse
foreach ($file in $csFiles) {
    # Lees alle regels uit het bestand.
    $serviceResult = Get-CSharpClassOverview -file $File
    if ($serviceResult) {
        $serviceResults += $serviceResult
        $serviceRows += $serviceResult.rows
    }
    Write-Progress -Activity "zoeken naar services" -Status "($i / $($csFiles.Count)) $($file.Name)" -PercentComplete ((($i++) / $csFiles.Count) * 100)
}

# Selecteer alleen de objecten waar 'soort plugin' gelijk is aan 'entity'. Deze worden gebruikt om plugins en entities aan elkaar te koppelen.
$entityPlugins = $pluginResults | Where-Object { $_.'soort plugin' -eq 'entity' }

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

# exporteer de 5 csv files

if (!(Test-Path -Path "output")) { New-Item -ItemType Directory -Path "output" | Out-Null }
$pluginFile = Resolve-fileName -fileName "plugins"
$serviceFile = Resolve-fileName  -fileName "services"
$serviceRowsFile = Resolve-fileName -fileName "services_methods"
$entityFile = Resolve-fileName -fileName "entities"
$relationsFile = Resolve-fileName -fileName "entityrelations"
$EntityNotFoundFile = Resolve-fileName -fileName "entity_not_found"

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
Write-Output "Export completed to $entityFile en $relationsFile"
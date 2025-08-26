#requires -Version 7.5

function Resolve-fileName {
    param(
        [string]$fileName,
        [bool]$overwrite = $true
    )
    $OldOutputFile = $null
    for ($i = 1; $i -lt 100; $i++) {
        $NewOutputFile = "output/{0}_{1}_{2}.csv" -f $fileName, (Get-Date -Format "yyyyMMdd"), $i
        if (!(Test-Path $NewOutputFile)) {
            if ($overwrite -and ($null -ne $OldOutputFile)) {
                Remove-Item $OldOutputFile -Force
                return $OldOutputFile
            }
            return $NewOutputFile
        }
        $OldOutputFile = $NewOutputFile
    }
}
function Get-CSharpClassOverview {
    param(
        [object]$File
    )
    $content = Get-Content $File.PSPath -Raw
    $rows = @()
    # Zoek de classdefinitie
    $classMatch = [regex]::Match($content, '(public|internal|private|protected)?\s*class\s+(\w*Service\w*)')
    $className = $classMatch.Groups[2].Value
    $serviceResult = $null

    #alleen als de class gevonden is, ga verder
    if ($classMatch.Success) {
        
        # Zoek de constructor(en)
        $constructorPattern = "(public|internal|private|protected)?\s*$className\s*\([^\)]*\)"
        $constructors = [regex]::Matches($content, $constructorPattern) | ForEach-Object { $_.Value.Trim() }

        # Zoek methoden (exclusief constructoren)
        $methodPattern = "(public|internal|private|protected)\s+[\w\<\>\[\]]+\s+\w+\s*\([^\)]*\)"
        $methods = [regex]::Matches($content, $methodPattern) | ForEach-Object {
            $method = $_.Value.Trim()
            if ($constructors -notcontains $method) { $method }
        }

        if ($file.FullName -match "[Cc][Bb][Mm]") {
            $onderdeel = "CBM"
        }
        elseif ($file.FullName -match "Insolventie") {
            $onderdeel = "Insolventie"
        }
        elseif ($file.FullName -match "[Ll][Kk][Bb]") {   
            $onderdeel = "LKB"
        }
        else {
            $onderdeel = "Common"
        }

        # Bouw array van objecten  
        if ($classMatch.Success) {
            $rows += [PSCustomObject]@{ Service = $classname; Type = "Class"; Signature = $classMatch.Value.Trim() -replace "(\r\n|\n|\r)", "" }
        }
        foreach ($ctor in $constructors) {
            $rows += [PSCustomObject]@{ Service = $classname; Type = "Constructor"; Signature = $ctor -replace "(\r\n|\n|\r)", "" }
        }
        foreach ($method in $methods) {
            $rows += [PSCustomObject]@{ Service = $classname; Type = "Method"; Signature = $method -replace "(\r\n|\n|\r)", "" }
        }
        $serviceResult = [PSCustomObject]@{
            "onderdeel" = $onderdeel
            "naam"      = $file.Name.split('.')[0]
            "service"   = $className
            "filenaam"  = $file.FullName
            "rows"      = $rows
        }
        
    }
    return $serviceResult
}

function Get-PluginOverview {
    param(
        [object]$File
    )
    # Lees alle regels uit het bestand.
    $content = Get-Content $File.PSPath

    # Zoek naar de eerste regel die een class-definitie bevat.
    # Dit matcht optioneel de toegangsspecificatie (public/private/etc.) en de keyword 'class' gevolgd door de class-naam.
    $classDefPattern = '^\s*(public|internal|private|protected)?\sclass\s+(\w+)\s:\s*[^\{]*\bIPlugin\b'
    $classDefLine = $null
    $classfound = $false
    $resolvePattern = 'Resolve<'
    $excludePattern = 'ICrmContext'
    $resolveLine = $null
    $resolvefound = $false
    $servicenaam = $null
    $entitynaam = $null
    $actionplugin = $false

    foreach ($line in $content) {
        if (!$classfound) { 
            if ($line -match $classDefPattern) {
                $classDefLine = $line.TrimStart()
                $classfound = $true
                if ($line -match '<(.*?)>') {
                    $entitynaam = $matches[1]
                }
                if ($line -match 'ActionPluginEventHandler') {
                    $actionplugin = $true
                }
            }
        }
        else {
            if (!$resolvefound) {
                if ($line -match $resolvePattern) {
                    if (!($line -match $excludepattern)) {
                        $resolveLine = $line.TrimStart()
                        if ($line -match '<(.*?)>') {
                            $servicenaam = $matches[1]
                        }
                        $resolveFound = $true
                    }
                }
            }
        }
    }
    if ($file.FullName -match "[Cc][Bb][Mm]") {
        $onderdeel = "CBM"
    }
    elseif ($file.FullName -match "Insolventie") {
        $onderdeel = "Insolventie"
    }
    elseif ($file.FullName -match "[Ll][Kk][Bb]") {   
        $onderdeel = "LKB"
    }
    else {
        $onderdeel = "Common"
    }
    if ($classDefLine) {
        if ($actionplugin) {
            $soortplugin = "action"
            $entitynaam = $entitynaam.Split(',')[0]
        } 
        else {
            $soortplugin = "entity"
        }
        $pluginResult = [PSCustomObject]@{
            "onderdeel"              = $onderdeel
            "soort plugin"           = $soortPlugin
            "entityrequest"          = $entitynaam
            "naam"                   = $file.Name.split('.')[0]
            "service"                = $servicenaam
            "classdefinitie"         = $classDefLine
            "serviceaanroep"         = $resolveline
            "filenaam"               = $file.FullName
            "ConnectedLocalizedName" = $null
            "ConnectedEntityName"    = $null
            "ConnectedOn"            = $null
        }
        return $pluginResult
    }
    return $null
}
function get-EntityOverview {
    param(
        [object]$File
    )
    $entityName = $null
    $originalName = $null
    $LocalizedName = $null
    $LocalizedCollectionName = $null
    $description = $null
    $primaryId = $null

    # Laad het XML-bestand in
    [xml]$xml = Get-Content $file.PSPath

    # haal de entity gegevens uit de xml
    $entityName = $xml.Entity.Name.'#text'
    $originalName = $xml.Entity.Name.OriginalName
    $LocalizedName = $xml.Entity.Name.LocalizedName
    $description = $xml.Entity.EntityInfo.entity.Descriptions.Description.description
    $LocalizedCollectionName = $xml.Entity.EntityInfo.entity.LocalizedCollectionNames.LocalizedCollectionName.description

    # Haal de namen van primarykey op uit de <attributes> sectie
    $lookupAttributeNames = @()
    foreach ($attribute in $xml.Entity.EntityInfo.entity.attributes.attribute) {
        if ($attribute.Type -eq "primarykey") {
            $primaryid = $attribute.Name
        }
    }

    # $entityName = $entityName -replace '^(spi_|_spir_)', ''
    $entityplugin = @()
    $entityplugin = $entityPlugins | Where-Object { $_.'entityrequest' -eq ($entityName -replace '^(spi_|_spir_)', '') }
    if ($entityPlugin) {
        foreach ($plugin in $entityplugin) {
            $plugin.ConnectedEntityName = $entityName
            $plugin.ConnectedLocalizedName = $LocalizedName
            $plugin.ConnectedOn = "EntityName"
        }
    }
    else {
        $entityplugin = $entityPlugins | Where-Object { $_.'entityrequest' -eq ($LocalizedName -replace ' ', '') }
        if ($entityplugin) {
            foreach ($plugin in $entityplugin) {
                $plugin.ConnectedEntityName = $entityName
                $plugin.ConnectedLocalizedName = $LocalizedName
                $plugin.ConnectedOn = "LocalizedName"
            }
        }
    }

    # soms staat het entity onderdeel in de naam van de entity, soms door de plugin, zijn  er 2 plugins dan wordt het common.
    $EntityOnderdeel = if ($entityName -match "cbm") { "CBM" } elseif ($entityName -match "lkb") { "LKB" } elseif ($entityName -match "ins") { "Insolventie" } else { $null }
    if ($null -ne $entityplugin) {
        if ($entityplugin.count -eq 2) {
            $entityOnderdeel = "Common"   # Do something specific for entities with 2 plugins
        }
        else {
            $entityOnderdeel = $entityplugin[0].onderdeel
        }
    }

    # Haal de namen van lookup-attributen op uit de <attributes> sectie
    $relationResults = @()
    foreach ($attribute in $xml.Entity.EntityInfo.entity.attributes.attribute) {
        if ($attribute.Type -eq "lookup") {
            if (($attribute.Name.EndsWith("id")) -and ($primaryId)) {
                $lookupAttributeNames += $attribute.Name
                $relationResults += [PSCustomObject]@{
                    PrimaryId                = $primaryid
                    PrimaryEntity            = $entityName
                    PrimaryEntityOnderdeel   = $EntityOnderdeel
                    SecondaryId              = $attribute.Name
                    SecondaryIdLogical       = $attribute.LogicalName
                    SecondaryRequired        = $attribute.RequiredLevel
                    SecondaryStyle           = $attribute.LookupStyle
                    SecondaryDisplayName     = $attribute.displaynames.displayname.description
                    SecondaryDescription     = $attribute.descriptions.description.description
                    SecondaryEntity          = $null
                    SecondaryEntityOnderdeel = $null
                }
            }
        }
    }

    if (($null -ne $primaryId) -or ($null -ne $entityplugin)) {
        $entityResult = [PSCustomObject]@{
            EntityName              = $entityName
            OriginalName            = $originalName
            LocalizedName           = $LocalizedName
            EntityOnderdeel         = $EntityOnderdeel
            PrimaryId               = $primaryid
            LocalizedCollectionName = $LocalizedCollectionName 
            aantalPlugins           = $Entityplugin.Count
            plugin                  = if ($entityplugin -and $entityplugin.Count -gt 0) { $entityplugin[0].naam } else { $null }
            service                 = if ($entityplugin -and $entityplugin.Count -gt 0) { $entityplugin[0].service } else { $null }
            pluginonderdeel         = if ($entityplugin -and $entityplugin.Count -gt 0) { $entityplugin[0].onderdeel } else { $null }
            plugin2                 = if ($entityplugin -and $entityplugin.Count -gt 1) { $entityplugin[1].naam } else { $null }
            service2                = if ($entityplugin -and $entityplugin.Count -gt 1) { $entityplugin[1].service } else { $null }
            pluginonderdeel2        = if ($entityplugin -and $entityplugin.Count -gt 1) { $entityplugin[1].onderdeel } else { $null }
            Description             = $description 
            Relations               = $relationResults
            LookupAttributes        = $lookupAttributeNames -join ', '
        }
        return $entityResult
    } 
    return $null
}
function set-SecondaryEntity { 
    param(
        [object]$Relation
    )
    
    $Entity = $entityResults | Where-Object { $_.PrimaryId -eq $relation.SecondaryId } | Select-Object -First 1 
    if ($Entity) {
        $Relation.SecondaryEntity = $Entity.EntityName
        $Relation.SecondaryEntityOnderdeel = $Entity.EntityOnderdeel
        return [PSCustomObject]@{ Success = $true; Result = $Relation }
    }
    else {
        return [PSCustomObject]@{ Success = $false; Error = "EntityId Not Found!" }
    }
}

# main script

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

$pluginResults = @()
$entityResults = @()
$serviceResults = @()
$serviceRows = @()
$relationResultTotals = @()
$entityNotFound = @()

# zoek eerst alle plugins
Write-Progress -Activity "Opstarten......"
$csFiles = Get-ChildItem -Path $repo -Filter *.cs -Recurse
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
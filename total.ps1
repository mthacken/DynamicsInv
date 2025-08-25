#requires -Version 7.5

function Resolve-fileName {
    param(
        [string]$fileName
    )
    for ($i = 1; $i -lt 100; $i++) {
        $outputFile = "output/{0}_{1}_{2}.csv" -f $fileName, (Get-Date -Format "yyyyMMdd"), $i
        if (!(Test-Path $outputFile)) {
            break
        }
    }
    return $outputFile
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
            "onderdeel"       = $onderdeel
            "soort plugin"    = $soortPlugin
            "entityrequest"   = $entitynaam
            "naam"            = $file.Name.split('.')[0]
            "service"         = $servicenaam
            "classdefinitie"  = $classDefLine
            "serviceaanroep"  = $resolveline
            "filenaam"        = $file.FullName
            "ConnectedEntity" = $null
            "ConnectedOn"     = $null
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

    # Haal de namen van primarykey en lookup-attributen op uit de <attributes> sectie
    $lookupAttributeNames = @()
    foreach ($attribute in $xml.Entity.EntityInfo.entity.attributes.attribute) {
        if ($attribute.Type -eq "primarykey") {
            $primaryid = $attribute.Name
        }
    }
    foreach ($attribute in $xml.Entity.EntityInfo.entity.attributes.attribute) {
        if ($attribute.Type -eq "lookup") {
            if (($attribute.Name.EndsWith("id")) -and ($primaryId)) {
                $lookupAttributeNames += $attribute.Name
                $relationResult = [PSCustomObject]@{
                    PrimaryId       = $primaryid
                    PrimaryEntity   = $entityName
                    SecundaryId     = $attribute.Name
                    SecundaryEntity = $null
                }
                $relationResults += $relationResult
            }
        }
    }
    $entityName = $entityName -replace '^(spi_|_spir_)', ''
    $entityplugin = $entityPlugins | Where-Object { $_.'entityrequest' -eq $entityName }
    if ($entityPlugin) {
        $entityplugin.ConnectedEntity = $entityName
        $entityplugin.ConnectedOn = "EntityName"
    }
    else {
        $entityplugin = $entityPlugins | Where-Object { $_.'entityrequest' -eq $LocalizedName }
        if ($entityplugin) {
            $entityplugin.ConnectedEntity = $LocalizedName
            $entityplugin.ConnectedOn = "LocalizedName"
        }
    }

    # Toon de geëxtraheerde variabelen
    if ($primaryId) {
        $entityResult = [PSCustomObject]@{
            EntityName              = $entityName
            OriginalName            = $originalName
            LocalizedName           = $LocalizedName
            PrimaryId               = $primaryid
            LocalizedCollectionName = $LocalizedCollectionName      
            plugin                  = $entityPlugin.naam
            service                 = $entityplugin.service
            pluginonderdeel         = $entityplugin.onderdeel
            Description             = $description   
            LookupAttributes        = $lookupAttributeNames -join ', '
        }
        return $entityResult
    } 
    return $null
}
function set-SecondaryEntity { 
    
    foreach ($relation in $relationResults) {
        $Entity = $entityResults | Where-Object { $_.EntityName -eq $relation.SecundaryId } | first 1 
        $relation.SecundaryEntity = $Entity.EntityName
    }
}

# main script

# algemene variabelen
if (Test-Path "P:\") {
    $repo = 'P:\Repos\toezicht'
    $analyserepo = 'P:\Repos\analyse'
}
else {
    $repo = 'C:\beheer\vibe\toezicht2'
    $analyserepo = 'C:\beheer\vibe\dynamicsinv'
}
$servicerepo = "$repo\rechtspraak.toezicht\"
$entityrepo = "$repo\crmfiles\components\entities"


$pluginResults = @()
$entityResults = @()
$serviceResults = @()
$serviceRows = @()
$relationResults = @()

# zoek eerst alle plugins
$csFiles = Get-ChildItem -Path $repo -Filter *.cs -Recurse
$i = 1 
foreach ($file in $csFiles) {
    $pluginResult = Get-PluginOverview -File $file 
    if ($null -ne $pluginResult) {
        $pluginResults += $pluginResult
    }
    Write-Progress -Activity "zoeken naar plugins" -Status "($i / $($csFiles.Count)) $($file.Name)" -PercentComplete (($i++) / $csFiles.Count * 100)
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
    Write-Progress -Activity "zoeken naar services" -Status "($i / $($csFiles.Count)) $($file.Name)" -PercentComplete (($i++) / $csFiles.Count * 100)
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
    }
    Write-Progress -Activity "zoeken naar entities" -Status "($i / $($csFiles.Count)) $($file.Name)" -PercentComplete (($i++) / $csFiles.Count * 100)
}

# vul de secondaryEntities aan in de relaties
set-SecondaryEntity

# exporteer de 5 csv files

if (!(Test-Path -Path "output")) { New-Item -ItemType Directory -Path "output" | Out-Null }
$pluginFile = Resolve-fileName -fileName "plugins"
$serviceFile = Resolve-fileName  -fileName "services"
$serviceRowsFile = Resolve-fileName -fileName "services_methods"
$entityFile = Resolve-fileName -fileName "entities"
$relationsFile = Resolve-fileName -fileName "entityrelations"

# Exporteer de verzamelde plugin-data naar een CSV-bestand.
$pluginResults | Export-Csv -Path $pluginFile -NoTypeInformation -Encoding UTF8
Write-Output "Export completed to $pluginFile"

# Exporteer de verzamelde services-data naar een CSV-bestand.
$serviceResults | Export-Csv -Path $serviceFile -NoTypeInformation -Encoding UTF8
$serviceRows | Export-Csv -Path $serviceRowsFile -NoTypeInformation -Encoding UTF8
Write-Output "Export completed to $serviceFile and $serviceRowsFile"

# Exporteer de verzamelde entity-data naar een CSV-bestand.
$entityResults | Export-Csv -Path $entityFile -NoTypeInformation -Encoding UTF8
$relationResults | Export-Csv -Path $relationsFile -NoTypeInformation -Encoding UTF8
Write-Output "Export completed to $entityFile en $relationsFile"
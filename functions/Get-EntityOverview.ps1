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
            $entityFunctie = $entityplugin[0].functie
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
                    PrimaryEntityFunctie     = $entityFunctie
                    SecondaryId              = $attribute.Name
                    SecondaryIdLogical       = $attribute.LogicalName
                    SecondaryRequired        = $attribute.RequiredLevel
                    SecondaryStyle           = $attribute.LookupStyle
                    SecondaryDisplayName     = $attribute.displaynames.displayname.description
                    SecondaryDescription     = $attribute.descriptions.description.description
                    SecondaryEntity          = $null
                    SecondaryEntityOnderdeel = $null
                    SecondaryEntityFunctie   = $null
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
            PrimaryEntityFunctie    = $entityFunctie
            PrimaryId               = $primaryid
            LocalizedCollectionName = $LocalizedCollectionName 
            aantalPlugins           = $Entityplugin.Count
            plugin                  = if ($entityplugin -and $entityplugin.Count -gt 0) { $entityplugin[0].naam } else { $null }
            service                 = if ($entityplugin -and $entityplugin.Count -gt 0) { $entityplugin[0].service } else { $null }
            pluginonderdeel         = if ($entityplugin -and $entityplugin.Count -gt 0) { $entityplugin[0].onderdeel } else { $null }
            pluginFunctie           = if ($entityplugin -and $entityplugin.Count -gt 0) { $entityplugin[0].functie } else { $null }
            plugin2                 = if ($entityplugin -and $entityplugin.Count -gt 1) { $entityplugin[1].naam } else { $null }
            service2                = if ($entityplugin -and $entityplugin.Count -gt 1) { $entityplugin[1].service } else { $null }
            pluginonderdeel2        = if ($entityplugin -and $entityplugin.Count -gt 1) { $entityplugin[1].onderdeel } else { $null }
            pluginFunctie2          = if ($entityplugin -and $entityplugin.Count -gt 1) { $entityplugin[1].functie } else { $null }
            Description             = $description 
            Relations               = $relationResults
            LookupAttributes        = $lookupAttributeNames -join ', '
        }
        return $entityResult
    } 
    return $null
}
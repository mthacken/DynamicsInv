$csFiles = Get-ChildItem -Path 'C:\beheer\vibe\toezicht2\crmfiles\components\entities' -Filter entity.xml -Recurse #| Select-Object -First 100


$EntityResults = @()

foreach ($file in $csFiles) {
    $entityName = $null
    $originalName = $null
    $LocalizedName = $null
    $LocalizedCollectionName = $null
    $description = $null
    $primaryId = $null

    # Laad het XML-bestand in
    [xml]$xml = Get-Content $file

    $entityName = $xml.Entity.Name.'#text'
    $originalName = $xml.Entity.Name.OriginalName
    $LocalizedName = $xml.Entity.Name.LocalizedName
    $description = $xml.Entity.EntityInfo.entity.Descriptions.Description.description
    
    # Extract LocalizedCollectionName uit het element <LocalizedCollectionName> binnen <LocalizedCollectionNames>
    $LocalizedCollectionName = $xml.Entity.EntityInfo.entity.LocalizedCollectionNames.LocalizedCollectionName.description


    # Haal de namen van lookup-attributen op uit de <attributes> sectie; filter op Type gelijk aan "lookup"
    $lookupAttributeNames = @()
    foreach ($attribute in $xml.Entity.EntityInfo.entity.attributes.attribute) {
        if ($attribute.Type -eq "lookup") {
            $lookupAttributeNames += $attribute.Name
        }
        if ($attribute.Type -eq "primarykey") {
            $primaryid = $attribute.Name
        }
    }

    # Toon de geëxtraheerde variabelen
    if ($primaryId) {
        Write-Host "EntityName: $EntityName"
        Write-Host "OriginalName: $OriginalName"
        Write-Host "LocalizedName: $localizedName"
        Write-Host "PrimaryId: $primaryid"
        Write-Host "LocalizedCollectionName: $localizedCollectionName"
        Write-Host "Description: $description"
        Write-Host "Lookup Attributes: $($lookupAttributeNames -join ', ')"
    } 
}


$outputFile = "output/entities_{0}.csv" -f (Get-Date -Format "yyyyMMdd_HHmmss")
$relationsFile = "output/entityrelations_{0}.csv" -f (Get-Date -Format "yyyyMMdd_HHmmss")

$csFiles = Get-ChildItem -Path 'C:\beheer\vibe\toezicht2\crmfiles\components\entities' -Filter entity.xml -Recurse #| Select-Object -First 100


$entityResults = @()
$relationResults = @()

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
        if ($attribute.Type -eq "primarykey") {
            $primaryid = $attribute.Name
        }
    }
    foreach ($attribute in $xml.Entity.EntityInfo.entity.attributes.attribute) {
        if ($attribute.Type -eq "lookup") {
            $lookupAttributeNames += $attribute.Name
            if (($attribute.Name.EndsWith("id")) -and ($primaryId)) {
                $relationResults += [PSCustomObject]@{
                    PrimaryId   = $primaryid
                    SecundaryId = $attribute.Name
                }
            }
        }
    }

    # Toon de geëxtraheerde variabelen
    if ($primaryId) {
        $entityResults += [PSCustomObject]@{
            EntityName              = $entityName
            OriginalName            = $originalName
            LocalizedName           = $LocalizedName
            PrimaryId               = $primaryid
            LocalizedCollectionName = $LocalizedCollectionName
            Description             = $description
            LookupAttributes        = $lookupAttributeNames -join ', '
        }

    } 
}

# Exporteer de verzamelde entity-data naar een CSV-bestand.
$entityResults | Export-Csv -Path $outputFile -NoTypeInformation -Encoding UTF8
$relationResults | Export-Csv -Path $relationsFile -NoTypeInformation -Encoding UTF8

Write-Output "Export completed to $outputFile en $relationsFile"
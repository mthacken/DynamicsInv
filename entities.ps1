# Laad het XML-bestand in
[xml]$xml = Get-Content "Entity.xml"

# Extract LocalizedName uit de <Name> element attribuut "LocalizedName"
$localizedName = $xml.Entity.Name.LocalizedName


# Extract LocalizedCollectionName uit het element <LocalizedCollectionName> binnen <LocalizedCollectionNames>
$localizedCollectionElement = $xml.Entity.EntityInfo.entity.LocalizedCollectionNames.LocalizedCollectionName
if ($localizedCollectionElement -and $localizedCollectionElement.'@description') {
    $localizedCollectionName = [string]$localizedCollectionElement.'@description'
} else {
    $localizedCollectionName = $localizedCollectionElement.InnerText
}

# Extract Description.
# Indien het <Description> element een attribuut "description" heeft, gebruik dit; anders gebruik de elementtekst
if ($xml.Entity.EntityInfo.entity.Descriptions.Description -and $xml.Entity.EntityInfo.entity.Descriptions.Description.description) {
    $description = $xml.Entity.EntityInfo.entity.Descriptions.Description.description
}
else {
    $description = $xml.Entity.EntityInfo.entity.Descriptions.Description
}

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
Write-Host "LocalizedName: $localizedName"
Write-Host "PrimaryId: $primaryid"
Write-Host "LocalizedCollectionName: $localizedCollectionName"
Write-Host "Description: $description"
Write-Host "Lookup Attributes: $($lookupAttributeNames -join ', ')"

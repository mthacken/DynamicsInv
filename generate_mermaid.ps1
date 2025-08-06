# Dit script leest de plugins_output.csv, filtert de rijen zodat alleen entity plugins overblijven met een "onderdeel" dat niet overeenkomt met CBM (ongeacht hoofdlettergebruik),
# en genereert vervolgens een Mermaid-tekening in Markdown waarin wordt weergegeven welke entity (entity request) welk service aanroept.
#
# De gegenereerde diagram toont voor elke gefilterde rij een pijl van de entity naar de service.
#
# Voer dit script uit in de huidige map (c:/beheer/Vibe/DynamicsInv). Het resultaat wordt opgeslagen in "plugins_mermaid.md".

# Pad naar de CSV met plugin-data
$csvPath = "plugins_output.csv"
# Pad naar het te genereren Markdown-bestand
$mdPath = "plugins_mermaid.md"

# Lees de CSV
$data = Import-Csv -Path $csvPath

# Filter: gebruik alleen rijen met "entity plugin" en waarbij de kolom "onderdeel" niet 'cbm' bevat (case-insensitive)
$filtered = $data | Where-Object { 
    $_."soort plugin" -eq "entity" -and ($_."onderdeel" -match "CBM")
}

# Bouw de Mermaid content
$lines = @()
$lines += '```mermaid'
$lines += 'graph LR'

# Voor elke gefilterde plugin, maak een relatie: entity --> service
foreach ($row in $filtered) {
    $entity = $row.entityrequest
    $service = $row.service
    # Voeg de relatie toe, bv. "LkbOnderneming --> LkbOndernemingService"
    $lines += "$entity --> $service"
}

$lines += '```'

# Sla de gegenereerde Markdown op
$lines | Out-File -FilePath $mdPath -Encoding UTF8

Write-Output "Mermaid markdown gegenereerd in $mdPath"

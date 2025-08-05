# Dit script zoekt in de codebase (recursief in het huidige pad) naar plugins en workflows
# via attributen in C#-bestanden, en toont een overzicht in een tabel.
#
# Het script gaat uit van het gebruik van attributen:
#   - [CrmPluginRegistration(...)] voor plugins
#   - [CrmWorkflowRegistration(...)] voor workflows
#
# Verwachte attribuutparameters (in volgorde):
#   Naam, Class Name, Geregistreerde Entiteit, Event, Assembly, Solution
#
# Indien sommige waarden niet aanwezig zijn in het attribuut, worden lege waarden ingevuld.

# Zoek alle C#-bestanden in de codebase
$csFiles = Get-ChildItem -Path 'C:\beheer\vibe\toezicht2' -Filter *.cs -Recurse

$overview = @()

foreach ($file in $csFiles) {
    # Lees de inhoud van het bestand als een enkele string
    $content = Get-Content $file.FullName -Raw

    # Variabele om vast te stellen of een item is toegevoegd
    $itemAdded = $false

    # Controleer op het CrmPluginRegistration attribuut
    if ($content -match "\[CrmPluginRegistration\s*\(([^)]*)\)\]") {
        $attrParamsText = $matches[1]
        # Haal de parameters in dubbele aanhalingstekens op
        $params = [regex]::Matches($attrParamsText, '"([^"]*)"') | ForEach-Object { $_.Groups[1].Value }
        
        # Probeer de class naam te achterhalen via de class definitie
        if ($content -match "public\s+class\s+(\w+)\s*:\s*IPlugin") {
            $detectedClass = $matches[1]
        }
        else {
            $detectedClass = ""
        }

        $naam      = if ($params.Count -gt 0) { $params[0] } else { "" }
        $className = if ($params.Count -gt 1) { $params[1] } else { $detectedClass }
        $entity    = if ($params.Count -gt 2) { $params[2] } else { "" }
        $event     = if ($params.Count -gt 3) { $params[3] } else { "" }
        $assembly  = if ($params.Count -gt 4) { $params[4] } else { "" }
        $solution  = if ($params.Count -gt 5) { $params[5] } else { "" }
    
        $overview += [PSCustomObject]@{
            Type                    = "Plugin"
            Naam                    = $naam
            "Class Name"            = $className
            "Geregistreerde Entiteit" = $entity
            Event                   = $event
            Assembly                = $assembly
            Solution                = $solution
        }
        $itemAdded = $true
    }
    
    # Controleer op het CrmWorkflowRegistration attribuut
    if ($content -match "\[CrmWorkflowRegistration\s*\(([^)]*)\)\]") {
        $attrParamsText = $matches[1]
        # Haal de parameters in dubbele aanhalingstekens op
        $params = [regex]::Matches($attrParamsText, '"([^"]*)"') | ForEach-Object { $_.Groups[1].Value }
        
        # Probeer de class naam te achterhalen via de class definitie
        if ($content -match "public\s+class\s+(\w+)\s*:\s*CodeActivity") {
            $detectedClass = $matches[1]
        }
        else {
            $detectedClass = ""
        }

        $naam      = if ($params.Count -gt 0) { $params[0] } else { "" }
        $className = if ($params.Count -gt 1) { $params[1] } else { $detectedClass }
        $entity    = if ($params.Count -gt 2) { $params[2] } else { "" }
        $event     = if ($params.Count -gt 3) { $params[3] } else { "" }
        $assembly  = if ($params.Count -gt 4) { $params[4] } else { "" }
        $solution  = if ($params.Count -gt 5) { $params[5] } else { "" }
    
        $overview += [PSCustomObject]@{
            Type                    = "Workflow"
            Naam                    = $naam
            "Class Name"            = $className
            "Geregistreerde Entiteit" = $entity
            Event                   = $event
            Assembly                = $assembly
            Solution                = $solution
        }
        $itemAdded = $true
    }
    
    # Optioneel: als er geen attributen gevonden werden maar er staat een IPlugin implementatie,
    # kan er eventueel alsnog informatie worden afgeleid.
    # Dit gedeelte kan uitgebreid worden indien gewenst.
}

# Toon het overzicht in een tabel
$overview | Format-Table -AutoSize

# Optioneel: Exporteer het overzicht naar een CSV-bestand
$overview | Export-Csv -Path "DynamicsOverviewFromCode.csv" -NoTypeInformation

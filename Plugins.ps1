$csFiles = Get-ChildItem -Path 'C:\beheer\vibe\toezicht2' -Filter *.cs -Recurse

$pluginResults = @()

foreach ($file in $csFiles) {

    # Lees alle regels uit het bestand.
    $content = Get-Content $File

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

        $pluginResults += [PSCustomObject]@{
            "onderdeel"    = $onderdeel
            "soort plugin" = $soortPlugin
             "entityrequest" = $entitynaam
            "naam"         = $file.Name.split('.')[0]
            "service" = $servicenaam
            "classdefinitie" = $classDefLine
            "serviceaanroep" = $resolveline
            "filenaam" = $file.FullName
        }
    }
}

# Exporteer de verzamelde plugin-data naar een CSV-bestand.
$exportPath = "plugins_output.csv"
$pluginResults | Export-Csv -Path $exportPath -NoTypeInformation -Encoding UTF8

Write-Output "Export completed to $exportPath"

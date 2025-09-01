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


    if ($classDefLine) {
        if ($actionplugin) {
            $soortplugin = "action"
            $entitynaam = $entitynaam.Split(',')[0]
        } 
        else {
            $soortplugin = "entity"
        }

        # plugins zijn ingedeeld in folders met de structuur: <onderdeel>\<functie>
        $filerelative = $file.FullName -replace [regex]::Escape($pluginrepo), ''
        $parts = $filerelative -split '\\'
        if ($parts.count -ge 2) {
            $onderdeelPlugin = $parts[0]
            if ($parts.count -eq 3) {
                $functiePlugin = $parts[1]
            }
        }
        else {
            throw "Invalid file structure $filerelative"
        }

        $pluginResult = [PSCustomObject]@{
            "onderdeel"              = $onderdeelPlugin
            "functie"                = $functiePlugin
            "soort plugin"           = $soortPlugin
            "entityrequest"          = $entitynaam
            "naam"                   = $file.Name.split('.')[0]
            "service"                = $servicenaam
            "classdefinitie"         = $classDefLine
            "serviceaanroep"         = $resolveline
            "filenaam"               = $filerelative
            "ConnectedLocalizedName" = $null
            "ConnectedEntityName"    = $null
            "ConnectedOn"            = $null
        }
        return $pluginResult
    }
    return $null
}

$csFiles = Get-ChildItem -Path 'C:\beheer\vibe\toezicht2' -Filter *.cs -Recurse

$overview = @()

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
                $classDefLine = $line
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
                        $resolveLine = $line
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
        Write-output $file.FullName
        Write-Output "Class definitie:$classDefLine"
        if ($actionplugin) {
            Write-Output "action plugin - req,res = $entitynaam"
        } 
        else {
            Write-Output "entity plugin - entity = $entitynaam"
        }
        if ($resolveLine) {
            if ($servicenaam) {
                Write-Output "Sevice: $servicenaam"
            }
            else {
                Write-Output "Service aanroep: $resolveLine `n"
            }
        }
    }
}

$csFiles = Get-ChildItem -Path 'C:\beheer\vibe\toezicht2\rechtspraak.toezicht\' -Filter *.cs -Recurse

$pluginResults = @()

foreach ($file in $csFiles) {

    # Lees alle regels uit het bestand.
    $content = Get-Content $File

    # Zoek naar de eerste regel die een class-definitie bevat.
    # Dit matcht optioneel de toegangsspecificatie (public/private/etc.) en de keyword 'class' gevolgd door de class-naam.
    $classDefPattern = 'public\s+class\s+\w*Service\w*\b'

    $classDefLine = $null
    $classfound = $false

    foreach ($line in $content) {
        if (!$classfound) { 
            if ($line -match $classDefPattern) {
                write-host "ja $line"
                $classDefLine = $line.TrimStart()
                $classfound = $true
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
        $pluginResults += [PSCustomObject]@{
            "onderdeel"      = $onderdeel
            "naam"           = $file.Name.split('.')[0]
            "service"        = $servicenaam
            "classdefinitie" = $classDefLine
            "serviceaanroep" = $resolveline
            "filenaam"       = $file.FullName
        }
    }
}

# Exporteer de verzamelde plugin-data naar een CSV-bestand.
$exportPath = "output\services_output.csv"
$pluginResults | Export-Csv -Path $exportPath -NoTypeInformation -Encoding UTF8

Write-Output "Export completed to $exportPath"

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
    $resolvePattern = 'resolve\s*\(\s*(\w+)'
    $resolveLine = $null
    $resolvefound = $false

    foreach ($line in $content) {
        if (!$classfound) { 
            if ($line -match $classDefPattern) {
                $classDefLine = $line
                $classfound = $true
                break
            }
        }
        else {
            if (!$resolvefound) {
                if ($line -match $resolvePattern) {
                    if (-not $resolveFound) {
                        $resolveLine = $line
                        $resolveFound = $true
                    }
                }
            }
        }
    }

    if ($classDefLine) {
        Write-Output "Class definitie:"
        Write-Output $classDefLine
        if ($resolveLine) {
            Write-Output "`nService aanroep:"
            Write-Output $resolveLine
            Write-Output "`n"
        }
    }
}

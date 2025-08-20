
function Resolve-fileName {
    param(
        [string]$fileName
    )
    for ($i = 1; $i -lt 100; $i++) {
        $outputFile = "output/$fileName_{0}_{1}.csv" -f (Get-Date -Format "yyyyMMdd"), $i
        if (!(Test-Path $outputFile)) {
            break
        }
    }
    return $outputFile
}

function Get-CSharpClassOverview {
    param(
        [object]$File
    )
    $content = Get-Content $File -Raw
    $rows = @()
    # Zoek de classdefinitie
    $classMatch = [regex]::Match($content, '(public|internal|private|protected)?\s*class\s+(\w*Service\w*)')
    $className = $classMatch.Groups[2].Value

    #alleen als de class gevonden is, ga verder
    if ($classMatch.Success) {
        
        # Zoek de constructor(en)
        $constructorPattern = "(public|internal|private|protected)?\s*$className\s*\([^\)]*\)"
        $constructors = [regex]::Matches($content, $constructorPattern) | ForEach-Object { $_.Value.Trim() }

        # Zoek methoden (exclusief constructoren)
        $methodPattern = "(public|internal|private|protected)\s+[\w\<\>\[\]]+\s+\w+\s*\([^\)]*\)"
        $methods = [regex]::Matches($content, $methodPattern) | ForEach-Object {
            $method = $_.Value.Trim()
            if ($constructors -notcontains $method) { $method }
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

        # Bouw array van objecten  
        if ($classMatch.Success) {
            $rows += [PSCustomObject]@{ Type = "Class"; Signature = $classMatch.Value.Trim() }
        }
        foreach ($ctor in $constructors) {
            $rows += [PSCustomObject]@{ Type = "Constructor"; Signature = $ctor }
        }
        foreach ($method in $methods) {
            $rows += [PSCustomObject]@{ Type = "Method"; Signature = $method }
        }
        $serviceResults = [PSCustomObject]@{
            "onderdeel" = $onderdeel
            "naam"      = $file.Name.split('.')[0]
            "service"   = $className
            "filenaam"  = $file.FullName
            "rows"      = $rows
        }
        
    }
    return $serviceResults
}

# main script

$outputFile = Resolve-fileName ("services")
$csFiles = Get-ChildItem -Path 'C:\beheer\vibe\toezicht2\rechtspraak.toezicht\' -Filter *.cs -Recurse

$serviceResults = @()

foreach ($file in $csFiles) {

    # Lees alle regels uit het bestand.
    $rows = Get-CSharpClassOverview -file $File


    # Zoek naar de eerste regel die een class-definitie bevat.
    # Dit matcht optioneel de toegangsspecificatie (public/private/etc.) en de keyword 'class' gevolgd door de class-naam.
    $classDefPattern = 'public\s+class\s+\w*Service\w*\b'

    $classDefLine = $null
    $classfound = $false

    foreach ($line in $content) {
        if (!$classfound) { 
            if ($line -match $classDefPattern) {
                # write-host "ja $line"
                $classDefLine = $line.TrimStart()
                $classfound = $true
            }
        }
    }

    if ($classDefLine) {
        $serviceResults += [PSCustomObject]@{
            "onderdeel"      = $onderdeel
            "naam"           = $file.Name.split('.')[0]
            "service"        = $servicenaam
            "classdefinitie" = $classDefLine
            "serviceaanroep" = $resolveline
            "filenaam"       = $file.FullName
        }
    }
}

# Exporteer de verzamelde services-data naar een CSV-bestand.
$serviceResults | Export-Csv -Path $outputFile -NoTypeInformation -Encoding UTF8
Write-Output "Export completed to $outputFile"
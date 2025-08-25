
function Resolve-fileName {
    param(
        [string]$fileName
    )
    for ($i = 1; $i -lt 100; $i++) {
        $outputFile = "output/{0}_{1}_{2}.csv" -f $fileName, (Get-Date -Format "yyyyMMdd"), $i
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
    $serviceResult = $null

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
            $rows += [PSCustomObject]@{ Service = $classname; Type = "Class"; Signature = $classMatch.Value.Trim() -replace "(\r\n|\n|\r)", ""}
        }
        foreach ($ctor in $constructors) {
            $rows += [PSCustomObject]@{ Service = $classname; Type = "Constructor"; Signature = $ctor -replace "(\r\n|\n|\r)", "" }
        }
        foreach ($method in $methods) {
            $rows += [PSCustomObject]@{ Service = $classname; Type = "Method"; Signature = $method -replace "(\r\n|\n|\r)", "" }
        }
        $serviceResult = [PSCustomObject]@{
            "onderdeel" = $onderdeel
            "naam"      = $file.Name.split('.')[0]
            "service"   = $className
            "filenaam"  = $file.FullName
            "rows"      = $rows
        }
        
    }
    return $serviceResult
}

# main script

$outputFile = Resolve-fileName ("services")
$outputRowsFile = Resolve-fileName ("services_rows")
$csFiles = Get-ChildItem -Path 'C:\beheer\vibe\toezicht2\rechtspraak.toezicht\' -Filter *.cs -Recurse

$serviceResults = @()
$serviceRows = @()

foreach ($file in $csFiles) 
{
    # Lees alle regels uit het bestand.
    $serviceResult = Get-CSharpClassOverview -file $File
    if ($serviceResult) {
        $serviceResults += $serviceResult
        $serviceRows += $serviceResult.rows
    }
}

# Exporteer de verzamelde services-data naar een CSV-bestand.
$serviceResults | Export-Csv -Path $outputFile -NoTypeInformation -Encoding UTF8
$serviceRows | Export-Csv -Path $outputRowsFile -NoTypeInformation -Encoding UTF8
Write-Output "Export completed to $outputFile"

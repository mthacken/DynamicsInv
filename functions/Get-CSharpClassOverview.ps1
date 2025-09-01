function Get-CSharpClassOverview {
    param(
        [object]$File
    )
    $content = Get-Content $File.PSPath -Raw
    $rows = @()
    # Zoek de classdefinitie
    $classMatch = [regex]::Match($content, '(public|internal|private|protected)?\s*class\s+(\w*Service\w*)')
    $className = $classMatch.Groups[2].Value
    $serviceResult = $null

    # Zoek alle using statements
    $usings = [regex]::Matches($content, 'using\s+[\w\.]+;') | ForEach-Object {
         $usingValue = ($_.Value -replace 'using','' -replace ';','').Trim() 
         if ($usingValue -like 'rechtspraak.toezicht*') { $usingValue }
    }

    # Zoek de namespace
    $namespaceMatch = [regex]::Match($content, 'namespace\s+([\w\.]+)')
    $namespace = $namespaceMatch.Groups[1].Value

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

        # services zijn ingedeeld in folders met de structuur: <onderdeel>\<functie>
        $filerelative = $file.FullName -replace [regex]::Escape($servicerepo), ''
        $parts = $filerelative -split '\\'
        if ($parts.count -ge 2) {
            $onderdeelService = $parts[0]
            if ($parts.count -eq 3) {
                $functieService = $parts[1]
            }
        }
        else {
            throw "Invalid file structure $filerelative"
        }      

        # Bouw array van objecten  
        if ($classMatch.Success) {
            $rows += [PSCustomObject]@{ Service = $classname; Type = "Class"; Signature = $classMatch.Value.Trim() -replace "(\r\n|\n|\r)", "" }
        }
        foreach ($ctor in $constructors) {
            $rows += [PSCustomObject]@{ Service = $classname; Type = "Constructor"; Signature = $ctor -replace "(\r\n|\n|\r)", "" }
        }
        foreach ($method in $methods) {
            $rows += [PSCustomObject]@{ Service = $classname; Type = "Method"; Signature = $method -replace "(\r\n|\n|\r)", "" }
        }
        foreach ($using in $usings) {
            $rows += [PSCustomObject]@{ Service = $classname; Type = "Using"; Signature = $using -replace "(\r\n|\n|\r)", "" }
        }
        $serviceResult = [PSCustomObject]@{
            "onderdeel" = $onderdeelService
            "functie"   = $functieService
            "naam"      = $file.Name.split('.')[0]
            "service"   = $className
            "filenaam"  = $filerelative
            "namespace" = $namespace
            "usings"    = $usings
            "rows"      = $rows
        }
    }
    return $serviceResult
}

function Update-NamespaceRelations {
    param(
        [object]$serviceResult,
        [ref]$namespaces
    )
    # zoek in de bestaande $namespaces.Value of de namespace al bestaat
    $namespace = $namespaces.Value | where-Object { $_.name -eq $serviceResult.namespace }
    # als de namespace al bestaat voeg dan de usings toe die nog niet bestaan voor die namespace en de filenaam van de CS file
    if ($namespace) {
        foreach ($using in $serviceResult.usings) {
            $usingfound = @()
            $usingfound = $namespace.usings | where-Object { $_.Name -eq $using } 
            if ($usingfound.Count -eq 0) {  
                $namespace.usings += [PSCustomObject]@{ Name = $using; Filenamen = @($serviceResult.filenaam) }
            }
            else {
                $namesArray = $namespaces.Value | ForEach-Object { $_.name }
                $index = $namesArray.IndexOf($serviceResult.namespace)
                if ($index -ge 0) {
                    $namespaces.Value[$index].filenamen += $serviceResult.filenaam
                    $usingArray = $namespaces.Value[$index].usings | ForEach-Object { $_.name }
                    $index2 = $usingArray.IndexOf($using)
                    if ($index2 -ge 0) {
                        try {
                            $namespaces.Value[$index].usings[$index2].Filenamen += $serviceResult.filenaam
                        }
                        catch {
                            Write-Host "Error updating Filenamen for $using in $($namespaces.Value[$index].name): $_"
                        }
                    }
                }
            }
        }
        $namesArray = $namespaces.Value | ForEach-Object { $_.name }
        $index = $namesArray.IndexOf($serviceResult.namespace)
        if ($index -ge 0) {
            $namespaces.Value[$index].Filenamen += $serviceResult.filenaam
        }
    }
    # als de namespace nog niet bestaat, maak een nieuwe aan met alle usings en de filenaam van de CS file
    else {
        switch -Regex ($serviceResult.namespace) {
            'Tests' { $soort = 'Tests'; break }
            'CBM' { $soort = 'CBM'; break }
            'Insolventie' { $soort = 'Insolventie'; break }
            'LKB' { $soort = 'LKB'; break }
            'Common' { $soort = 'Common'; break }

            default { $soort = 'Andere' }
        }
        $filenamen = @()
        $filenamen += $serviceResult.filenaam
        $namespace = [PSCustomObject]@{
            Name      = $serviceResult.namespace
            Filenamen = $Filenamen
            Soort     = $soort
            usings    = @()
        }
        foreach ($using in $serviceResult.usings) {
            $namespace.usings += [PSCustomObject]@{ Name = $using; Filenamen = @($serviceResult.filenaam) }
        }
        
        $namespaces.Value += $namespace
    }
}

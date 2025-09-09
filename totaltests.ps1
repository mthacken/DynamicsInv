#requires -Version 7.5

Import-Module "$PSScriptRoot\DynamicsInv.psm1" -force

function Get-RelativePath {
    param(
        [string]$FullPath,
        [string]$RepoRoot
    )
    # Zorg dat beide paden eindigen met een backslash
    $root = [System.IO.Path]::GetFullPath($RepoRoot).ToLower()
    if (!$root.EndsWith('\')) { $root += '\' }
    $full = [System.IO.Path]::GetFullPath($FullPath).ToLower()
    if ($full.StartsWith($root)) {
        return $full.Substring($root.Length)
    }
    else {
        return $FullPath
    }
}

function Get-KeywordsFromPath {
    param(
        [string]$FilePath,
        [string[]]$Keywords = @(
            'cypress', 'e2e', 'lkb', 'portaal', 'formulier', 'functional', 'verzoek', 'load', 'cbm',
            'curatoren', 'bewind', 'particulier', 'wsnp', 'robot', 'insolventie', 'faillissement',
            'zittingen', 'verslagen', 'mentorschap', 'integratie', 's2s', ''
        )
    )
    $found = @()
    foreach ($keyword in $Keywords) {
        if ($FilePath -match [regex]::Escape($keyword)) {
            $found += $keyword
        }
    }
    $cbmkeys = @('s2s', 'bewind')
    $inskeys = @('curatoren','wsnp')
    foreach ($cbmkey in $cbmkeys) {
        if ($found -contains $cbmkey) {
            if ($found -notcontains 'cbm') {
                $found += 'cbm'
            }
        }
    }
    foreach ($inskey in $inskeys) {
        if ($found -contains $inskey) {
            if ($found -notcontains 'insolventie') {
                $found += 'insolventie'
            }
        }
    }


    # Prioriteer cbm, insolventie, lkb als eerste indien aanwezig
    $priority = @('cbm', 'insolventie', 'lkb')
    $ordered = @()
    foreach ($p in $priority) {
        if ($found -contains $p) {
            $ordered += $p
        }
    }
    $ordered += ($found | Where-Object { $priority -notcontains $_ })

    return $ordered
}



# Zet het pad naar de root van je repo
if (Test-Path "P:\") {
    $repoRoot = 'P:\Repos\toezicht'
    $outputPath = 'L:\OntwikkelShare\Projecten\Toezicht\Architectuur'
    #    $analyserepo = 'P:\Repos\analyse'
}
else {
    $repoRoot = 'C:\beheer\vibe\toezicht2'
    $outputPath = 'output'
    #    $analyserepo = 'C:\beheer\vibe\dynamicsinv'
}
$TestOverviewFile = Resolve-fileName -fileName "TestOverview" -outputPath $outputPath

$results = @()

# Haal alle bestanden in één keer op
Write-Progress -Activity "verzamel alle files"
$allFiles = Get-ChildItem -Path $repoRoot -Recurse -File


# Cypress: filter op extensie
$cypressFiles = $allFiles | Where-Object {
    $_.Name -match '\.(cy|spec)\.(ts|js)$'
}

# Protractor: filter op extensie
$protractorFiles = $allFiles | Where-Object {
    $_.Name -match '\.(e2e-spec|protractor)\.(ts|js)$'
}

# Robot Framework: filter op extensie
$robotFiles = $allFiles | Where-Object {
    $_.Extension -eq '.robot'
}

# ReadyAPI: filter op extensie
$readyApiFiles = $allFiles | Where-Object {
    $_.Extension -eq '.xml'
}

# Cypress: zoek naar .cy.ts, .cy.js, .spec.ts, .spec.js
$i = 1
foreach ($file in $cypressFiles) {
    $describeLines = Select-String -Path $file.FullName -Pattern '^\s*(x?describe)\s*\('
    foreach ($line in $describeLines) {
        $match = [regex]::Match($line.Line, '^\s*(x?describe)\s*\(\s*["'']([^"'']+)["'']')
        if ($match.Success) {
            $results += [PSCustomObject]@{
                Type     = "Cypress"
                Keywords = (Get-KeywordsFromPath -FilePath $file.FullName) -join ', '
                File     = Get-RelativePath -FullPath $file.FullName -RepoRoot $repoRoot
                TestCase = $match.Groups[2].Value
            }
        }
    }
    Write-Progress -Activity "zoeken door de Cypress files" -Status "$($file.Name) ($i/$($cypressFiles.Count))" -PercentComplete ((($i++) / $($cypressFiles.Count)) * 100)  
}

# Protractor: zoek naar .e2e-spec.ts, .e2e-spec.js, .protractor.js, .protractor.ts
$i = 1
foreach ($file in $protractorFiles) {
    $describeLines = Select-String -Path $file.FullName -Pattern '^\s*(x?describe)\s*\('
    foreach ($line in $describeLines) {
        $match = [regex]::Match($line.Line, '^\s*(x?describe)\s*\(\s*["'']([^"'']+)["'']')
        if ($match.Success) {
            $results += [PSCustomObject]@{
                Type     = "Protractor"
                Keywords = (Get-KeywordsFromPath -FilePath $file.FullName) -join ', '
                File     = Get-RelativePath -FullPath $file.FullName -RepoRoot $repoRoot
                TestCase = $match.Groups[2].Value
            }
        }
    }
    write-Progress -Activity "zoeken door de Protractor files" -Status "$($file.Name) ($i/$($protractorFiles.Count))" -PercentComplete ((($i++) / $($protractorFiles.Count)) * 100)
}

# Robot Framework: zoek naar .robot files en haal *** Test Cases *** secties
$i = 1
foreach ($file in $robotFiles) {
    $lines = Get-Content $file.FullName
    $inTestCases = $false
    foreach ($line in $lines) {
        if ($line -match '^\*\*\*\s*Test Cases\s*\*\*\*') {
            $inTestCases = $true
            continue
        }
        if ($inTestCases -and $line -match '^\*\*\*') {
            $inTestCases = $false
        }
        if ($inTestCases -and $line.Trim() -ne "" -and $line -notmatch '^\s') {
            $results += [PSCustomObject]@{
                Type     = "Robot"
                Keywords = (Get-KeywordsFromPath -FilePath $file.FullName) -join ', '
                File     = Get-RelativePath -FullPath $file.FullName -RepoRoot $repoRoot
                TestCase = $line.Trim()
            }
        }
    }
    write-Progress -Activity "zoeken door de Robot Framework files" -Status "$($file.Name) ($i/$($robotFiles.Count))" -PercentComplete ((($i++) / $($robotFiles.Count)) * 100)
}

# ReadyAPI: zoek naar .xml files met <testCase name="...">
$i = 1
foreach ($file in $readyApiFiles) {
    $testCaseLines = Select-String -Path $file.FullName -Pattern '<(con:)?testCase\b[^>]*\bname="([^"]+)"'
    foreach ($line in $testCaseLines) {
        $match = [regex]::Match($line.Line, '<(con:)?testCase\b[^>]*\bname="([^"]+)"')
        if ($match.Success) {
            $results += [PSCustomObject]@{
                Type     = "ReadyAPI"
                Keywords = (Get-KeywordsFromPath -FilePath $file.FullName) -join ', '
                File     = Get-RelativePath -FullPath $file.FullName -RepoRoot $repoRoot
                TestCase = $match.Groups[2].Value
            }
        }
    }
    write-Progress -Activity "zoeken door de ReadyAPI files" -Status "$($file.Name) ($i/$($readyApiFiles.Count))" -PercentComplete ((($i++) / $($readyApiFiles.Count)) * 100)   
}

# exporteer naar CSV
$results | Export-Csv -Path $TestOverviewFile -NoTypeInformation -Delimiter ";"
Write-Output "Testoverview geexporteerd"

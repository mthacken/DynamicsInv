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
    } else {
        return $FullPath
    }
}


# Zet het pad naar de root van je repo
$repoRoot = "c:\beheer\Vibe\toezicht2"
$TestOverviewFile = Resolve-fileName -fileName "TestOverview"

$results = @()

# Cypress: zoek naar .cy.ts, .cy.js, .spec.ts, .spec.js
$i=1
$cypressFiles = Get-ChildItem -Path $repoRoot -Recurse -Include *.cy.ts,*.cy.js,*.spec.ts,*.spec.js
foreach ($file in $cypressFiles) {
    $describeLines = Select-String -Path $file.FullName -Pattern '^\s*(x?describe)\s*\('
    foreach ($line in $describeLines) {
        $match = [regex]::Match($line.Line, '^\s*(x?describe)\s*\(\s*["'']([^"'']+)["'']')
        if ($match.Success) {
            $results += [PSCustomObject]@{
                Type = "Cypress"
                File = Get-RelativePath -FullPath $file.FullName -RepoRoot $repoRoot
                TestCase = $match.Groups[2].Value
            }
        }
    }
    Write-Progress -Activity "zoeken door de Cypress files" -Status "$($file.Name) ($i/$($cypressFiles.Count))" -PercentComplete ((($i++) / $($cypressFiles.Count)) * 100)  
}

# Protractor: zoek naar .e2e-spec.ts, .e2e-spec.js, .protractor.js, .protractor.ts
$i=1
$protractorFiles = Get-ChildItem -Path $repoRoot -Recurse -Include *.e2e-spec.ts,*.e2e-spec.js,*.protractor.js,*.protractor.ts
foreach ($file in $protractorFiles) {
    $describeLines = Select-String -Path $file.FullName -Pattern '^\s*(x?describe)\s*\('
    foreach ($line in $describeLines) {
        $match = [regex]::Match($line.Line, '^\s*(x?describe)\s*\(\s*["'']([^"'']+)["'']')
        if ($match.Success) {
            $results += [PSCustomObject]@{
                Type = "Protractor"
                File = Get-RelativePath -FullPath $file.FullName -RepoRoot $repoRoot
                TestCase = $match.Groups[2].Value
            }
        }
    }
    write-Progress -Activity "zoeken door de Protractor files" -Status "$($file.Name) ($i/$($protractorFiles.Count))" -PercentComplete ((($i++) / $($protractorFiles.Count)) * 100)
}

# Robot Framework: zoek naar .robot files en haal *** Test Cases *** secties
$i=1
$robotFiles = Get-ChildItem -Path $repoRoot -Recurse -Include *.robot
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
                Type = "Robot"
                File = Get-RelativePath -FullPath $file.FullName -RepoRoot $repoRoot
                TestCase = $line.Trim()
            }
        }
    }
    write-Progress -Activity "zoeken door de Robot Framework files" -Status "$($file.Name) ($i/$($robotFiles.Count))" -PercentComplete ((($i++) / $($robotFiles.Count)) * 100)
}

# ReadyAPI: zoek naar .xml files met <testCase name="...">
$i=1
# ReadyAPI: zoek naar .xml files met <testCase ... name="..."> of <con:testCase ... name="...">
$readyApiFiles = Get-ChildItem -Path $repoRoot -Recurse -Include *.xml
foreach ($file in $readyApiFiles) {
    $testCaseLines = Select-String -Path $file.FullName -Pattern '<(con:)?testCase\b[^>]*\bname="([^"]+)"'
    foreach ($line in $testCaseLines) {
        $match = [regex]::Match($line.Line, '<(con:)?testCase\b[^>]*\bname="([^"]+)"')
        if ($match.Success) {
            $results += [PSCustomObject]@{
                Type = "ReadyAPI"
                File = Get-RelativePath -FullPath $file.FullName -RepoRoot $repoRoot
                TestCase = $match.Groups[2].Value
            }
        }
    }
     write-Progress -Activity "zoeken door de ReadyAPI files" -Status "$($file.Name) ($i/$($readyApiFiles.Count))" -PercentComplete ((($i++) / $($readyApiFiles.Count)) * 100)   
}

# exporteer naar CSV
$results | Export-Csv -Path $TestOverviewFile -NoTypeInformation -Delimiter ";"

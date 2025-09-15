$intervalMinutes = 10

function Run-TestSuite($name, $command) {
    Write-Host "[$(Get-Date -Format 'u')] Start $name tests..."
    try {
        & $command
        if ($LASTEXITCODE -eq 0) {
            Write-Host "[$(Get-Date -Format 'u')] $name tests geslaagd."
        } else {
            Write-Warning "[$(Get-Date -Format 'u')] $name tests gefaald (exitcode $LASTEXITCODE)."
        }
    } catch {
        Write-Error "[$(Get-Date -Format 'u')] Fout bij uitvoeren $name: $_"
    }
}

while ($true) {
    # Robot Framework
    Run-TestSuite "Robot"      "robot .\Testen\Robot"

    # ReadyAPI (testrunner.bat of testrunner.sh afhankelijk van OS)
    Run-TestSuite "ReadyAPI"   "testrunner.bat -sSuiteName -cTestCaseName .\Testen\ReadyAPI\Project.xml"

    # Protractor (zorg dat protractor en node_modules in PATH staan)
    Run-TestSuite "Protractor" "protractor .\Testen\Protractor\protractor.conf.js"

    # Cypress
    Run-TestSuite "Cypress"    "npx cypress run --project .\Testen\Cypress"

    Write-Host "[$(Get-Date -Format 'u')] Wacht $intervalMinutes minuten tot volgende run..."
    Start-Sleep -Seconds ($intervalMinutes * 60)
}
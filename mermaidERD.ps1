# Zet entityrelations_xxx.csv om naar een Mermaid ER-diagram

param (
    [string]$CsvPath = "c:\beheer\Vibe\DynamicsInv\output\entityrelations_20250819_181102.csv",
    [string]$OutPath = "c:\beheer\Vibe\DynamicsInv\mermaid\entityrelations_20250819_181102.md"
)

$lines = Get-Content $CsvPath | Select-Object -Skip 1
$relations = @()
$matchstring = "(?i)CBMzaakid"

foreach ($line in $lines) {
    $cols = $line -replace '"','' -split ','
    if ($cols.Count -eq 2) {
        $primary = $cols[0].Trim()
        $secondary = $cols[1].Trim()
        if (($primary -match $matchstring) -or ($secondary -match $matchstring))
        {
           $relations += "$primary --> $secondary"
        }
    }
}
$diagram = @()
$diagram += '```mermaid'
$diagram += "graph LR"
$diagram += $relations
$diagram += '```'
$diagram | Set-Content $OutPath

Write-Host "Mermaid diagram opgeslagen in $OutPath"
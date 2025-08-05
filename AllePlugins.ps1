Get-ChildItem -Path 'C:\beheer\vibe\toezicht2' -Recurse -Filter *.cs | ForEach-Object {
    $content = Get-Content $_.FullName
    if ($content -match "IPlugin" -or $content -match "CodeActivity") {
        Write-Host "Gevonden: $($_.FullName)"
    }
}

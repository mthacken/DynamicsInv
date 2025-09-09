function Resolve-fileName {
    param(
        [string]$fileName,
        [string]$outputPath = "output",
        [bool]$overwrite = $true
    )
    $OldOutputFile = $null
    for ($i = 1; $i -lt 100; $i++) {
        $NewOutputFile = "{0}/{1}_{2}_{3}.csv" -f $outputPath, $fileName, (Get-Date -Format "yyyyMMdd"), $i
        if (!(Test-Path $NewOutputFile)) {
            if ($overwrite -and ($null -ne $OldOutputFile)) {
                Remove-Item $OldOutputFile -Force
                return $OldOutputFile
            }
            return $NewOutputFile
        }
        $OldOutputFile = $NewOutputFile
    }
}
function Resolve-fileName {
    param(
        [string]$fileName,
        [bool]$overwrite = $true
    )
    $OldOutputFile = $null
    for ($i = 1; $i -lt 100; $i++) {
        $NewOutputFile = "output/{0}_{1}_{2}.csv" -f $fileName, (Get-Date -Format "yyyyMMdd"), $i
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
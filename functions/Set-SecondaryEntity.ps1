function set-SecondaryEntity { 
    param(
        [object]$Relation
    )
    
    $Entity = $entityResults | Where-Object { ($_.PrimaryId -replace ' ', '' -replace '^(spi_|_spir_)', '') -eq ($relation.SecondaryId -replace ' ', '' -replace '^(spi_|_spir_)', '') } | Select-Object -First 1 
    if ($Entity) {
        $Relation.SecondaryEntity = $Entity.EntityName
        $Relation.SecondaryEntityOnderdeel = $Entity.EntityOnderdeel
        $Relation.SecondaryEntityFunctie = $Entity.EntityFunctie
        return [PSCustomObject]@{ Success = $true; Result = $Relation }
    }
    else {
        return [PSCustomObject]@{ Success = $false; Error = "EntityId Not Found!" }
    }
}

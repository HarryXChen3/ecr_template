# Load TOML parsing
function Parse-RucksackToml {
    param([string]$filePath)

    $toml = Get-Content $filePath -Raw
    if ($toml -match 'path\s*=\s*"([^"]+)"') {
        return $matches[1]
    } else {
        return "packages"
    }
}

# Prompt user to select a file
function Prompt-SelectFile {
    param([string[]]$files, [string]$prompt)

    Write-Host "`n$prompt"
    for ($i = 0; $i -lt $files.Length; $i++) {
        Write-Host "[$i] $($files[$i])"
    }

    do {
        $selection = Read-Host "Enter the number of the correct file"
    } while (($null -eq ($selectN = $selection -as [int])) -or $selectN -lt 0 -or $selectN -ge $files.Length)

    return $files[$selection]
}

# Find root .luau file
function Find-RootFile {
    param([string]$packagePath)

    $allLuauFiles = Get-ChildItem -Recurse -Path $packagePath -Filter *.luau | ForEach-Object { $_.FullName }
    if ($allLuauFiles.Count -eq 1) {
        return $allLuauFiles[0]
    }

    $initFiles = $allLuauFiles | Where-Object { $_ -like "*init.luau" }
    if ($initFiles.Count -eq 1) {
        return $initFiles[0]
    }

    $relativeBase = (Get-Item $packagePath).FullName
    if ($initFiles.Count -gt 1) {
        $relativePaths = $initFiles | ForEach-Object { Resolve-Path $_ | ForEach-Object { $_.Path.Replace("$relativeBase\", "") } }
        $chosen = Prompt-SelectFile $relativePaths "Multiple init.luau files found:"
        return Join-Path $packagePath $chosen
    }

    if ($allLuauFiles.Count -gt 1) {
        $relativePaths = $allLuauFiles | ForEach-Object { Resolve-Path $_ | ForEach-Object { $_.Path.Replace("$relativeBase\", "") } }
        $chosen = Prompt-SelectFile $relativePaths "No init.luau found. Select a .luau file:"
        return Join-Path $packagePath $chosen
    }

    Write-Host "No .luau files found in $packagePath. Skipping..."
    return $null
}

# Extract type exports
function Extract-TypeExports {
    param([string]$filePath)

    $content = Get-Content $filePath -Raw
    $pattern = 'export type ([a-zA-Z_][a-zA-Z0-9_]*)(<[^>]+>)?'
    $matches = [regex]::Matches($content, $pattern)
    return $matches | ForEach-Object {
        $typeName = $_.Groups[1].Value
        $generics = $_.Groups[2].Value
        [PSCustomObject]@{
            Name     = $typeName
            Generics = $generics
        }
    }
}

# Main execution
# Run rucksack install
Write-Host "Running 'rucksack install'..."
& rucksack install
if ($LASTEXITCODE -ne 0) {
    Write-Error "rucksack install failed. Exiting script."
    exit 1
}

$cwd = Get-Location
$rucksackToml = Join-Path $cwd "rucksack.toml"
$installPath = Parse-RucksackToml $rucksackToml
$bundlePath = Join-Path $cwd $installPath
$packagesRoot = Split-Path $bundlePath

Get-ChildItem -Directory $bundlePath | ForEach-Object {
    $packageName = $_.Name
    $packagePath = $_.FullName

    Write-Host "`nProcessing package: $packageName"

    $rootFile = Find-RootFile $packagePath
    if (-not $rootFile) { return }

    $typeExports = Extract-TypeExports $rootFile

    $outputFilePath = Join-Path $packagesRoot "$packageName.luau"
    Write-Host "Generating file: $outputFilePath"

    # Check if we should use the short form: `require(script.Parent.bundle.A)`
    $useShortRequire = $false
    $srcPath = Join-Path $packagePath "src"
    $srcInit = Join-Path $srcPath "init.luau"

    if (Test-Path $srcInit) {
        $useShortRequire = $true
    } elseif (Test-Path $srcPath) {
        $luauFilesInSrc = Get-ChildItem -Recurse -Path $srcPath -Filter *.luau | Select-Object -ExpandProperty FullName
        if ($luauFilesInSrc.Count -eq 1 -and ($luauFilesInSrc -eq $rootFile)) {
            $useShortRequire = $true
        }
    }

    if ($useShortRequire) {
        $bundleName = Split-Path $bundlePath -Leaf
        $requireLine = "local module = require(script.Parent.$bundleName.$packageName)"
    } else {
        $relativePath = $rootFile.Replace($packagesRoot + "\", "").Replace(".luau", "").Replace("\", ".")
        $requireLine = "local module = require(script.Parent.$relativePath)"
    }

    # Generate output lines
    $lines = @()
    $lines += $requireLine
    $lines += ""

    foreach ($type in $typeExports) {
        $line = "export type $($type.Name)$($type.Generics) = module.$($type.Name)$($type.Generics)"
        $lines += $line
    }

    $lines += ""
    $lines += "return module"

    Set-Content -Path $outputFilePath -Value $lines -Encoding UTF8
}

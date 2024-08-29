param(
    [string]$version = $null
)

[string]$PROGRAM_NAME="rokit"
[string]$REPOSITORY="rojo-rbx/rokit"

[string[]]$dependencies = "Invoke-RestMethod","Expand-Archive","Get-WMIObject"

function Test-CommandExists {
 param ($command)

 $oldPreference = $ErrorActionPreference
 $ErrorActionPreference = 'stop'

 try {if(Get-Command $command){return $true}}
 catch {return $false}
 finally {$ErrorActionPreference=$oldPreference}
}

foreach ($dep in $dependencies) {
    if (!(Test-CommandExists $dep)) {
        Write-Output "ERROR: '$dep' is not installed or available."
        exit 1
    }
}

if ($GITHUB_PAT) {
    Write-Output "NOTE: Using provided GITHUB_PAT for authentication"
}

[uint16]$ARCH_ID = (Get-WMIObject -Class Win32_Processor).Architecture
[string]$ARCH = $null
if ($ARCH_ID -eq 0 -or $ARCH_ID -eq 9) {
    $ARCH = "x86_64"
} else {
    Write-Output "Unsupported architecture: $ARCH_ID"
    exit 1
}

[string]$VERSION_PATTERN = "[0-9]*\.[0-9]*\.[0-9]*"
[string]$API_URL = "https://api.github.com/repos/$REPOSITORY/releases/latest"
if ($version) {
    $VERSION_PATTERN = $version
    $API_URL="https://api.github.com/repos/$REPOSITORY/releases/tags/v$VERSION_PATTERN"
    Write-Output "[1 / 3] Looking for $PROGRAM_NAME release with tag 'v$VERSION_PATTERN'"
} else {
    Write-Output "[1 / 3] Looking for latest $PROGRAM_NAME release"
}
[regex]$FILE_PATTERN = "$PROGRAM_NAME-$VERSION_PATTERN-windows-$ARCH.zip"

[string]$RELEASE_JSON_DATA = $null
if ($GITHUB_PAT) {
    $headers = @{
        "X-GitHub-Api-Version" = "2022-11-28"
        "Authorization" = "token $GITHUB_PAT"
    }
    $RELEASE_JSON_DATA = Invoke-RestMethod -Method Get -Uri $API_URL -Headers $headers | ConvertTo-Json -Depth 100
} else {
    $headers = @{
        "X-GitHub-Api-Version" = "2022-11-28"
    }
    $RELEASE_JSON_DATA = Invoke-RestMethod -Method Get -Uri $API_URL -Headers $headers | ConvertTo-Json -Depth 100
}

if (!($RELEASE_JSON_DATA) -or ($RELEASE_JSON_DATA -like "*Not Found*")) {
    Write-Output "ERROR: Latest release was not found. Please check your network connection."
    exit 1
}

<#
group 0: entire match
group 1: asset id
group 2: asset name (e.g. rokit-0.2.5-windows-x86_64.zip)
#>
[regex]$REGEX_ASSET_ID = '(?m)^.+api\.github\.com/repos/rojo-rbx/rokit/releases/assets/(\d+)(?s).+?(?=name)name":\s*"([^"]+)"'
$matched_assets = (Select-String $REGEX_ASSET_ID -input $RELEASE_JSON_DATA -AllMatches | ForEach-Object {$_.Matches})
if ($matched_assets.Count -le 0) {
    Write-Output "ERROR: Failed to find any assets in the latest release."
    exit 1
}

[string]$RELEASE_ASSET_ID = $null
[string]$RELEASE_ASSET_NAME = $null
foreach ($asset in $matched_assets) {
    [string]$asset_name = $asset.Groups[2].Value
    if ($asset_name -match $FILE_PATTERN) {
        $RELEASE_ASSET_ID = $asset.Groups[1].Value
        $RELEASE_ASSET_NAME = $asset_name
    }
}

if (!($RELEASE_ASSET_ID) -or !($RELEASE_ASSET_NAME)) {
    Write-Output "ERROR: Failed to find asset that matches the pattern \"$FILE_PATTERN\" in the latest release."
    exit 1
}

Write-Output "[2 / 3] Downloading '$RELEASE_ASSET_NAME'"
$RELEASE_DOWNLOAD_URL = "https://api.github.com/repos/$REPOSITORY/releases/assets/$RELEASE_ASSET_ID"
$RELEASE_NAME = [io.path]::GetFileNameWithoutExtension($RELEASE_ASSET_NAME)
$ZIP_FILE = "$RELEASE_NAME.zip"
if ($GITHUB_PAT) {
    $headers = @{
        "X-GitHub-Api-Version" = "2022-11-28"
        "Accept" = "application/octet-stream"
        "Authorization" = "token $GITHUB_PAT"
    }
    Invoke-RestMethod -Method Get -Uri $RELEASE_DOWNLOAD_URL -OutFile $ZIP_FILE -Headers $headers
} else {
    $headers = @{
        "X-GitHub-Api-Version" = "2022-11-28"
        "Accept" = "application/octet-stream"
    }
    Invoke-RestMethod -Method Get -Uri $RELEASE_DOWNLOAD_URL -OutFile $ZIP_FILE -Headers $headers
}

if (!(Test-Path $ZIP_FILE -PathType Leaf)) {
    Write-Output "ERROR: Failed to download the release archive '$ZIP_FILE'."
    exit 1
}

$BINARY_NAME = "$PROGRAM_NAME.exe"
$UNZIPPED_FOLDER = [io.path]::Combine(".", $RELEASE_NAME)
$PATH_TO_BINARY = [io.path]::Combine($UNZIPPED_FOLDER, $BINARY_NAME)

Expand-Archive $ZIP_FILE
Remove-Item $ZIP_FILE

if (!(Test-Path $PATH_TO_BINARY -PathType Leaf)) {
    Write-Output "ERROR: The file '$BINARY_NAME' does not exist in the downloaded archive."
    exit 1
}

Write-Output "[3 / 3] Running $PROGRAM_NAME installation"
& $PATH_TO_BINARY self-install
Remove-Item $UNZIPPED_FOLDER -Recurse

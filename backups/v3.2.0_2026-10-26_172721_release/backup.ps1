param(
    [Parameter(Mandatory = $true)]
    [string]$Version,
    [string]$Label = ""
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$stamp = Get-Date -Format "yyyy-MM-dd_HHmmss"
$safeVersion = ($Version -replace '[^0-9A-Za-z._-]', '_')
$safeLabel = ($Label -replace '[^0-9A-Za-z._-]', '_')
$folderName = if ($safeLabel) { "${safeVersion}_${stamp}_${safeLabel}" } else { "${safeVersion}_${stamp}" }
$target = Join-Path (Join-Path $root "backups") $folderName

New-Item -ItemType Directory -Path $target -Force | Out-Null

$files = @("index.html", "DEVELOPMENT.md", "react.txt", "backup.ps1")
$manifestFiles = @()

foreach ($file in $files) {
    $source = Join-Path $root $file
    if (Test-Path -LiteralPath $source -PathType Leaf) {
        $destination = Join-Path $target $file
        Copy-Item -LiteralPath $source -Destination $destination -Force
        $item = Get-Item -LiteralPath $destination
        $manifestFiles += [PSCustomObject]@{
            name = $file
            bytes = $item.Length
            sha256 = (Get-FileHash -LiteralPath $destination -Algorithm SHA256).Hash
        }
    }
}

$manifest = [PSCustomObject]@{
    version = $Version
    label = $Label
    created = (Get-Date).ToString("o")
    folder = $folderName
    files = $manifestFiles
}

$manifestPath = Join-Path $target "MANIFEST.json"
$json = $manifest | ConvertTo-Json -Depth 5
[System.IO.File]::WriteAllText($manifestPath, $json, (New-Object System.Text.UTF8Encoding($false)))

Write-Output $target

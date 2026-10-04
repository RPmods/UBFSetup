[CmdletBinding()]
param(
    [ValidatePattern('^\d+\.\d+\.\d+(?:-[0-9A-Za-z.-]+)?$')]
    [string]$Version = '1.0.1'
)

$ErrorActionPreference = 'Stop'
$root = [IO.Path]::GetFullPath($PSScriptRoot)
$staging = Join-Path $root 'staging'
$payload = Join-Path $staging 'launcher'
$archive = Join-Path $staging 'UBFLauncher-update.zip'
$dist = Join-Path $root 'dist'

function Assert-ChildPath([string]$Path, [string]$Root, [string]$Name) {
    $fullPath = [IO.Path]::GetFullPath($Path)
    $fullRoot = [IO.Path]::GetFullPath($Root).TrimEnd([IO.Path]::DirectorySeparatorChar, [IO.Path]::AltDirectorySeparatorChar) + [IO.Path]::DirectorySeparatorChar
    if (-not $fullPath.StartsWith($fullRoot, [StringComparison]::OrdinalIgnoreCase)) {
        throw "$Name must stay inside $Root."
    }
    return $fullPath
}

foreach ($path in @($staging, $dist)) {
    $safePath = Assert-ChildPath $path $root 'Build output'
    if (Test-Path -LiteralPath $safePath) { Remove-Item -LiteralPath $safePath -Recurse -Force }
    New-Item -ItemType Directory -Path $safePath -Force | Out-Null
}

$payloadConfigPath = Join-Path $root 'launcher-payload.json'
$payloadConfig = Get-Content -LiteralPath $payloadConfigPath -Raw | ConvertFrom-Json
if ([string]::IsNullOrWhiteSpace($payloadConfig.launcherVersionMetadataUrl)) {
    throw 'launcher-payload.json does not define launcherVersionMetadataUrl.'
}

$metadataUri = [Uri]$payloadConfig.launcherVersionMetadataUrl
if ($metadataUri.Scheme -ne 'https' -or $metadataUri.Host -ne 'raw.githubusercontent.com') {
    throw 'Launcher metadata must come from the official HTTPS raw.githubusercontent.com endpoint.'
}

$metadata = Invoke-RestMethod -Uri $metadataUri.AbsoluteUri
if ([string]::IsNullOrWhiteSpace($metadata.version) -or [string]::IsNullOrWhiteSpace($metadata.downloadUrl) -or
    [string]::IsNullOrWhiteSpace($metadata.sha256)) {
    throw 'Launcher version metadata is incomplete.'
}

$downloadUri = [Uri]$metadata.downloadUrl
if ($downloadUri.Scheme -ne 'https' -or $downloadUri.Host -ne 'github.com' -or
    $downloadUri.AbsolutePath -notmatch '^/RPmods/ubf-laucher/releases/download/.+/UBFLauncher-update\.zip$') {
    throw 'Launcher package URL is not the official UBFLauncher release asset.'
}
if ($metadata.sha256 -notmatch '^[0-9a-fA-F]{64}$') { throw 'Launcher package SHA-256 is invalid.' }

Invoke-WebRequest -Uri $downloadUri.AbsoluteUri -OutFile $archive
$actualHash = (Get-FileHash -LiteralPath $archive -Algorithm SHA256).Hash.ToLowerInvariant()
if ($actualHash -ne $metadata.sha256.ToLowerInvariant()) {
    throw "Launcher package SHA-256 mismatch. Expected $($metadata.sha256), got $actualHash."
}

Add-Type -AssemblyName System.IO.Compression.FileSystem
$archiveFile = [IO.Compression.ZipFile]::OpenRead($archive)
try {
    $payloadRoot = [IO.Path]::GetFullPath($payload).TrimEnd([IO.Path]::DirectorySeparatorChar, [IO.Path]::AltDirectorySeparatorChar) + [IO.Path]::DirectorySeparatorChar
    foreach ($entry in $archiveFile.Entries) {
        if ([string]::IsNullOrEmpty($entry.Name)) { continue }
        if ($entry.FullName.Contains('\')) { throw "Package entry uses an invalid separator: $($entry.FullName)" }
        $destination = [IO.Path]::GetFullPath((Join-Path $payload $entry.FullName))
        if (-not $destination.StartsWith($payloadRoot, [StringComparison]::OrdinalIgnoreCase)) {
            throw "Package entry escapes the payload directory: $($entry.FullName)"
        }
        New-Item -ItemType Directory -Path ([IO.Path]::GetDirectoryName($destination)) -Force | Out-Null
        $input = $entry.Open()
        try {
            $output = [IO.File]::Open($destination, [IO.FileMode]::CreateNew, [IO.FileAccess]::Write, [IO.FileShare]::None)
            try { $input.CopyTo($output) }
            finally { $output.Dispose() }
        }
        finally { $input.Dispose() }
    }
}
finally { $archiveFile.Dispose() }

foreach ($requiredFile in @('UBFLauncher.exe', 'UBFLauncherUpdater.exe', 'UBFLauncher.files.json', 'launcher.settings.json')) {
    if (-not (Test-Path -LiteralPath (Join-Path $payload $requiredFile) -PathType Leaf)) {
        throw "The launcher payload is missing $requiredFile."
    }
}

$isccCandidates = @(
    (Join-Path ${env:ProgramFiles(x86)} 'Inno Setup 6\ISCC.exe'),
    (Join-Path $env:ProgramFiles 'Inno Setup 6\ISCC.exe'),
    (Join-Path $env:LOCALAPPDATA 'Programs\Inno Setup 6\ISCC.exe')
) | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
$iscc = $isccCandidates | Where-Object { Test-Path -LiteralPath $_ -PathType Leaf } | Select-Object -First 1
if (-not $iscc) { throw 'Inno Setup 6 was not found. Install JRSoftware.InnoSetup first.' }

Push-Location $root
try {
    & $iscc "/DSetupVersion=$Version" 'UBFSetup.iss'
    if ($LASTEXITCODE -ne 0) { throw "Inno Setup compilation failed with exit code $LASTEXITCODE." }
}
finally { Pop-Location }

$setupExe = Join-Path $dist 'UBFSetup.exe'
if (-not (Test-Path -LiteralPath $setupExe -PathType Leaf)) { throw 'Inno Setup did not produce dist\\UBFSetup.exe.' }
Write-Host "UBFSetup: $setupExe"
Write-Host "Launcher payload: $($metadata.version)"
Write-Host "Setup version: $Version"

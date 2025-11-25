param (
    [Parameter(Mandatory)]
    [string]$SourceDir,
    [Parameter(Mandatory)]
    [string]$OutputExe,
    [string]$ProductName = "Smart Gamma",
    [string]$ProductVersion = "0.0.0",
    [string]$InstallSubdir = "smart-gamma"
)

function Resolve-FourPartVersion {
    param([string]$Version)
    if (-not $Version) {
        return "0.0.0.0"
    }
    $parts = $Version.Split('.', [System.StringSplitOptions]::RemoveEmptyEntries)
    if ($parts.Count -eq 0) {
        $parts = @("0")
    }
    while ($parts.Count -lt 4) {
        $parts += "0"
    }
    if ($parts.Count -gt 4) {
        $parts = $parts[0..3]
    }
    return ($parts -join '.')
}

function Find-Makensis {
    $candidates = @(
        $env:MAKENSIS,
        (Join-Path ${env:ProgramFiles(x86)} "NSIS\makensis.exe"),
        (Join-Path ${env:ProgramFiles} "NSIS\makensis.exe"),
        "makensis.exe"
    ) | Where-Object { $_ }

    foreach ($candidate in $candidates) {
        $cmd = Get-Command $candidate -ErrorAction SilentlyContinue
        if ($cmd) {
            return $cmd.Source
        }
    }
    return $null
}

if (-not (Test-Path $SourceDir)) {
    throw "Source directory '$SourceDir' not found."
}

$resolvedSourceDir = (Resolve-Path -Path $SourceDir).ProviderPath
$resolvedOutputExe = if ([System.IO.Path]::IsPathRooted($OutputExe)) {
    [System.IO.Path]::GetFullPath($OutputExe)
} else {
    [System.IO.Path]::GetFullPath((Join-Path (Get-Location) $OutputExe))
}

$outputDir = Split-Path -Parent $resolvedOutputExe
if ($outputDir -and -not (Test-Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
}

$payloadRoot = $resolvedSourceDir
$childDirectories = Get-ChildItem -Path $resolvedSourceDir -Directory -ErrorAction SilentlyContinue
if ($childDirectories.Count -eq 1) {
    $payloadRootCandidate = $childDirectories[0].FullName
    $hasObsBin = Test-Path (Join-Path $payloadRootCandidate "bin")
    $hasObsPlugins = Test-Path (Join-Path $payloadRootCandidate "obs-plugins")
    if ($hasObsBin -or $hasObsPlugins) {
        $payloadRoot = $payloadRootCandidate
    }
}

if (-not (Get-ChildItem -Path $payloadRoot -Recurse -ErrorAction SilentlyContinue | Where-Object { -not $_.PSIsContainer })) {
    throw "Payload directory '$payloadRoot' is empty. Did you run 'cmake --install ... --prefix $SourceDir' first?"
}

$makensis = Find-Makensis
if (-not $makensis) {
    throw "Unable to locate makensis.exe. Please install NSIS and ensure makensis is in PATH or set the MAKENSIS environment variable."
}

$defaultInstallRoot = Join-Path ([Environment]::GetFolderPath("CommonApplicationData")) "obs-studio\plugins"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$nsiPath = Join-Path $scriptDir "create-windows-installer.nsi"
if (-not (Test-Path $nsiPath)) {
    throw "Unable to find installer script at $nsiPath"
}

function New-DefineArgument {
    param(
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][object]$Value
    )
    $valueString = if ($null -eq $Value) { '' } else { [string]$Value }
    $escaped = $valueString.Replace('"', '\"')
    return "/D$Name=$escaped"
}

$defines = @(
    New-DefineArgument -Name "PRODUCT_NAME" -Value $ProductName
    New-DefineArgument -Name "PRODUCT_VERSION" -Value (Resolve-FourPartVersion -Version $ProductVersion)
    New-DefineArgument -Name "SOURCE_ROOT" -Value $payloadRoot
    New-DefineArgument -Name "OUTPUT_EXE" -Value $resolvedOutputExe
    New-DefineArgument -Name "INSTALL_ROOT" -Value $defaultInstallRoot
    New-DefineArgument -Name "INSTALL_SUBDIR" -Value $InstallSubdir
)

Write-Host "Building NSIS wizard installer..."
Write-Host " - Payload: $payloadRoot"
Write-Host " - Output : $resolvedOutputExe"

& $makensis @defines $nsiPath
if ($LASTEXITCODE -ne 0 -or -not (Test-Path $resolvedOutputExe)) {
    throw "makensis failed to create installer (exit code $LASTEXITCODE)."
}

Write-Host "Created installer: $resolvedOutputExe"

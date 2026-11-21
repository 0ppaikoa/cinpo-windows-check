param(
    [string] $Label = 'unknown'
)

$ErrorActionPreference = 'Stop'

Write-Host "===== $Label ====="
Write-Host "PSVersion: $($PSVersionTable.PSVersion)"
Write-Host "OS: $([Environment]::OSVersion.VersionString)"
Write-Host "Culture: $([Globalization.CultureInfo]::CurrentCulture.Name)"
Write-Host "UICulture: $([Globalization.CultureInfo]::CurrentUICulture.Name)"
Write-Host "Console.OutputEncoding: $([Console]::OutputEncoding.WebName)"
Write-Host "Console.InputEncoding: $([Console]::InputEncoding.WebName)"
Write-Host "Text.Encoding.Default: $([Text.Encoding]::Default.WebName)"
if (Get-Variable OutputEncoding -ErrorAction SilentlyContinue) {
    Write-Host "OutputEncoding: $($OutputEncoding.WebName)"
}
Write-Host "chcp: $(& chcp.com)"
Write-Host "tar: $((Get-Command tar.exe).Source)"
& tar.exe --version
if ($LASTEXITCODE -ne 0) {
    throw 'tar.exe --version failed'
}

$root = Join-Path $env:RUNNER_TEMP 'cinpo-diagnostics'
$asciiArchiveDir = Join-Path $root 'ascii-archive'
New-Item -ItemType Directory -Force -Path $asciiArchiveDir | Out-Null
Set-Content -LiteralPath (Join-Path $asciiArchiveDir 'payload.txt') -Value 'hello' -Encoding ascii
$archive = Join-Path $root 'payload.tar.gz'
& tar.exe -czf $archive -C $asciiArchiveDir payload.txt
if ($LASTEXITCODE -ne 0) {
    throw 'failed to create the test archive'
}

function Test-TarDestination {
    param(
        [string] $Name,
        [scriptblock] $Action
    )

    $destination = Join-Path $root $Name
    New-Item -ItemType Directory -Force -Path $destination | Out-Null
    Write-Host "--- $Name ---"
    $output = & $Action $destination 2>&1
    $exitCode = $LASTEXITCODE
    $output | ForEach-Object { Write-Host $_ }
    $files = @(Get-ChildItem -LiteralPath $destination -Force | ForEach-Object Name) -join ', '
    Write-Host "exit=$exitCode files=[$files]"
}

Test-TarDestination '日本語-dash-C' {
    param($destination)
    & tar.exe -xzf $archive -C $destination
}

Test-TarDestination '日本語-push-location' {
    param($destination)
    Push-Location $destination
    try {
        & tar.exe -xzf $archive
    } finally {
        Pop-Location
    }
}

Test-TarDestination '日本語-start-process' {
    param($destination)
    $process = Start-Process -FilePath tar.exe `
        -ArgumentList @('-xzf', $archive, '-C', $destination) `
        -Wait -PassThru -NoNewWindow
    $global:LASTEXITCODE = $process.ExitCode
}

Test-TarDestination 'ascii-dash-C' {
    param($destination)
    & tar.exe -xzf $archive -C $destination
}

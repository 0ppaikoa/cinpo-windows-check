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

$jp = [string]([char] 0x65E5) + [char] 0x672C + [char] 0x8A9E
$root = Join-Path $env:RUNNER_TEMP 'cinpo-diagnostics'
$asciiArchiveDir = Join-Path $root 'ascii-archive'
New-Item -ItemType Directory -Force -Path $asciiArchiveDir | Out-Null
Set-Content -LiteralPath (Join-Path $asciiArchiveDir 'payload.txt') -Value 'hello' -Encoding ascii
$archive = Join-Path $root 'payload.tar.gz'
& tar.exe -czf $archive -C $asciiArchiveDir payload.txt
if ($LASTEXITCODE -ne 0) {
    throw 'failed to create the test archive'
}

function Show-Files {
    param([string] $Path)
    $names = @(Get-ChildItem -LiteralPath $Path -Force | ForEach-Object Name) -join ', '
    Write-Host "files=[$names]"
}

$destination = Join-Path $root "$jp-dash-C"
New-Item -ItemType Directory -Force -Path $destination | Out-Null
Write-Host "--- $jp-dash-C ---"
$output = & tar.exe -xzf $archive -C $destination 2>&1
$exitCode = $LASTEXITCODE
$output | ForEach-Object { Write-Host $_ }
Write-Host "exit=$exitCode"
Show-Files $destination

$destination = Join-Path $root "$jp-push-location"
New-Item -ItemType Directory -Force -Path $destination | Out-Null
Write-Host "--- $jp-push-location ---"
Push-Location $destination
try {
    $output = & tar.exe -xzf $archive 2>&1
    $exitCode = $LASTEXITCODE
} finally {
    Pop-Location
}
$output | ForEach-Object { Write-Host $_ }
Write-Host "exit=$exitCode"
Show-Files $destination

$destination = Join-Path $root "$jp-relative-archive"
New-Item -ItemType Directory -Force -Path $destination | Out-Null
Copy-Item -LiteralPath $archive -Destination (Join-Path $destination 'payload.tar.gz') -Force
Write-Host "--- $jp-relative-archive ---"
Push-Location $destination
try {
    $output = & tar.exe -xzf 'payload.tar.gz' 2>&1
    $exitCode = $LASTEXITCODE
} finally {
    Pop-Location
}
$output | ForEach-Object { Write-Host $_ }
Write-Host "exit=$exitCode"
Show-Files $destination

$destination = Join-Path $root "$jp-start-process"
New-Item -ItemType Directory -Force -Path $destination | Out-Null
Write-Host "--- $jp-start-process ---"
$process = Start-Process -FilePath tar.exe `
    -ArgumentList @('-xzf', $archive, '-C', $destination) `
    -Wait -PassThru -NoNewWindow
Write-Host "exit=$($process.ExitCode)"
Show-Files $destination

$destination = Join-Path $root 'ascii-dash-C'
New-Item -ItemType Directory -Force -Path $destination | Out-Null
Write-Host "--- ascii-dash-C ---"
$output = & tar.exe -xzf $archive -C $destination 2>&1
$exitCode = $LASTEXITCODE
$output | ForEach-Object { Write-Host $_ }
Write-Host "exit=$exitCode"
Show-Files $destination

$japaneseArchive = Join-Path $root "$jp-archive.tar.gz"
Copy-Item -LiteralPath $archive -Destination $japaneseArchive -Force
$destination = Join-Path $root 'ascii-destination-japanese-archive'
New-Item -ItemType Directory -Force -Path $destination | Out-Null
Write-Host "--- $jp archive path with ASCII destination ---"
$output = & tar.exe -xzf $japaneseArchive -C $destination 2>&1
$exitCode = $LASTEXITCODE
$output | ForEach-Object { Write-Host $_ }
Write-Host "exit=$exitCode"
Show-Files $destination

$japaneseCurl = Join-Path $root "$jp-curl.txt"
Write-Host "--- $jp curl output path ---"
$output = & curl.exe -fsSL -o $japaneseCurl https://example.com 2>&1
$exitCode = $LASTEXITCODE
$output | ForEach-Object { Write-Host $_ }
Write-Host "exit=$exitCode exists=$(Test-Path -LiteralPath $japaneseCurl)"

$japaneseGit = Join-Path $root "$jp-git"
New-Item -ItemType Directory -Force -Path $japaneseGit | Out-Null
Write-Host "--- $jp git -C path ---"
$output = & git -C $japaneseGit init -q 2>&1
$exitCode = $LASTEXITCODE
$output | ForEach-Object { Write-Host $_ }
Write-Host "git-init-exit=$exitCode"
$output = & git -C $japaneseGit status --porcelain 2>&1
$exitCode = $LASTEXITCODE
$output | ForEach-Object { Write-Host $_ }
Write-Host "git-status-exit=$exitCode"

param(
	[string] $GodotPath = "",
	[int] $IntegrationPort = 18910
)

$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$godotWrapper = Join-Path $PSScriptRoot "godot.ps1"
$resultsDir = Join-Path $repoRoot "test-results"
$junitPath = Join-Path $resultsDir "gut-junit.xml"

New-Item -ItemType Directory -Force -Path $resultsDir | Out-Null

function Invoke-Godot {
	param([string[]] $Arguments)

	$wrapperArgs = @()
	if (-not [string]::IsNullOrWhiteSpace($GodotPath)) {
		$wrapperArgs += @("-GodotPath", $GodotPath)
	}
	$wrapperArgs += $Arguments

	& $godotWrapper @wrapperArgs
	if ($LASTEXITCODE -ne 0) {
		exit $LASTEXITCODE
	}
}

Write-Output "Importing Godot project resources..."
Invoke-Godot @("--headless", "--import", "--path", $repoRoot)

Write-Output "Running GUT unit regression tests..."
Invoke-Godot @(
	"--headless",
	"--path",
	$repoRoot,
	"-s",
	"res://addons/gut/gut_cmdln.gd",
	"-gconfig=res://.gutconfig.json",
	"-gjunit_xml_file=$junitPath",
	"-gexit"
)

if (-not (Test-Path -LiteralPath $junitPath)) {
	throw "GUT did not write the expected JUnit report at $junitPath."
}

[xml] $gutReport = Get-Content -Raw -LiteralPath $junitPath
$gutTestCount = [int] $gutReport.testsuites.tests
$gutFailureCount = [int] $gutReport.testsuites.failures
if ($gutTestCount -le 0) {
	throw "GUT did not run any tests."
}
if ($gutFailureCount -gt 0) {
	throw "GUT reported $gutFailureCount failing test(s). See $junitPath."
}

Write-Output "Running headless project smoke test..."
Invoke-Godot @(
	"--headless",
	"--path",
	$repoRoot,
	"--scene",
	"res://test/integration/mimic_startup_probe.tscn",
	"--quit-after",
	"60",
	"--no-header"
)

Write-Output "Running two-instance ENet connection smoke test..."
$twoInstanceArgs = @{
	Port = $IntegrationPort
	Transport = "enet"
	ResultsDir = $resultsDir
}
if (-not [string]::IsNullOrWhiteSpace($GodotPath)) {
	$twoInstanceArgs["GodotPath"] = $GodotPath
}
& (Join-Path $PSScriptRoot "run_two_instances.ps1") @twoInstanceArgs
if ($LASTEXITCODE -ne 0) {
	exit $LASTEXITCODE
}

Write-Output "Running two-instance ENet auto-connect smoke test..."
$twoInstanceArgs = @{
	Port = ($IntegrationPort + 1)
	Transport = "enet"
	ConnectMode = "server_if_first_else_client"
	ResultsDir = $resultsDir
}
if (-not [string]::IsNullOrWhiteSpace($GodotPath)) {
	$twoInstanceArgs["GodotPath"] = $GodotPath
}
& (Join-Path $PSScriptRoot "run_two_instances.ps1") @twoInstanceArgs
if ($LASTEXITCODE -ne 0) {
	exit $LASTEXITCODE
}

Write-Output "Running two-instance WebSocket connection smoke test..."
$twoInstanceArgs = @{
	Port = ($IntegrationPort + 2)
	Transport = "websocket"
	ResultsDir = $resultsDir
}
if (-not [string]::IsNullOrWhiteSpace($GodotPath)) {
	$twoInstanceArgs["GodotPath"] = $GodotPath
}
& (Join-Path $PSScriptRoot "run_two_instances.ps1") @twoInstanceArgs
if ($LASTEXITCODE -ne 0) {
	exit $LASTEXITCODE
}

Write-Output "Mimic verification passed."

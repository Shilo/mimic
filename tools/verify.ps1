param(
	[string] $GodotPath = "",
	[int] $IntegrationPort = 18910,
	[switch] $SkipQuality
)

$ErrorActionPreference = "Stop"

$repoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot "..")).Path
$godotWrapper = Join-Path $PSScriptRoot "godot.ps1"
$resultsDir = Join-Path $repoRoot "test/.output"
$junitPath = Join-Path $resultsDir "gut-junit.xml"

New-Item -ItemType Directory -Force -Path $resultsDir | Out-Null

function Invoke-Godot {
	param([string[]] $Arguments)

	$wrapperArgs = @()
	if (-not [string]::IsNullOrWhiteSpace($GodotPath)) {
		$wrapperArgs += @("-GodotPath", $GodotPath)
	}
	$wrapperArgs += $Arguments

	& (Get-PowerShellExecutable) -NoProfile -ExecutionPolicy Bypass -File $godotWrapper @wrapperArgs
	if ($LASTEXITCODE -ne 0) {
		exit $LASTEXITCODE
	}
}

function Invoke-PowerShellScript {
	param(
		[string] $ScriptPath,
		[hashtable] $Parameters = @{}
	)

	$scriptArguments = @(
		"-NoProfile",
		"-ExecutionPolicy",
		"Bypass",
		"-File",
		$ScriptPath
	)
	foreach ($key in $Parameters.Keys) {
		$scriptArguments += "-$key"
		$scriptArguments += [string] $Parameters[$key]
	}

	& (Get-PowerShellExecutable) @scriptArguments
	if ($LASTEXITCODE -ne 0) {
		exit $LASTEXITCODE
	}
}

function Get-PowerShellExecutable {
	$binaryName = "powershell.exe"
	if ($PSVersionTable.PSEdition -eq "Core") {
		$binaryName = "pwsh.exe"
		if (-not ($env:OS -eq "Windows_NT")) {
			$binaryName = "pwsh"
		}
	}

	$hostPath = Join-Path $PSHOME $binaryName
	if (Test-Path -LiteralPath $hostPath) {
		return $hostPath
	}

	if ($PSVersionTable.PSEdition -eq "Core") {
		return "pwsh"
	}
	return "powershell"
}

if (-not $SkipQuality) {
	Write-Output "Running static quality and duplicate-code checks..."
	Invoke-PowerShellScript (Join-Path $PSScriptRoot "quality.ps1")
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
Invoke-PowerShellScript (Join-Path $PSScriptRoot "run_two_instances.ps1") $twoInstanceArgs

Write-Output "Running two-instance ENet auto-connect smoke test..."
$twoInstanceArgs = @{
	Port = ($IntegrationPort + 1)
	Transport = "enet"
	ConnectMode = "server_then_client"
	ResultsDir = $resultsDir
}
if (-not [string]::IsNullOrWhiteSpace($GodotPath)) {
	$twoInstanceArgs["GodotPath"] = $GodotPath
}
Invoke-PowerShellScript (Join-Path $PSScriptRoot "run_two_instances.ps1") $twoInstanceArgs

Write-Output "Running two-instance WebSocket connection smoke test..."
$twoInstanceArgs = @{
	Port = ($IntegrationPort + 2)
	Transport = "websocket"
	ResultsDir = $resultsDir
}
if (-not [string]::IsNullOrWhiteSpace($GodotPath)) {
	$twoInstanceArgs["GodotPath"] = $GodotPath
}
Invoke-PowerShellScript (Join-Path $PSScriptRoot "run_two_instances.ps1") $twoInstanceArgs

Write-Output "Mimic verification passed."

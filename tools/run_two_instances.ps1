param(
	[string] $GodotPath = "",
	[int] $Port = 18910,
	[ValidateSet("enet", "websocket")]
	[string] $Transport = "enet",
	[int] $TimeoutSeconds = 12,
	[string] $ResultsDir = ""
)

$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")

if ([string]::IsNullOrWhiteSpace($ResultsDir)) {
	$ResultsDir = Join-Path $repoRoot "test-results"
}

New-Item -ItemType Directory -Force -Path $ResultsDir | Out-Null

$serverOut = Join-Path $ResultsDir "integration-$Transport-server.out.log"
$serverErr = Join-Path $ResultsDir "integration-$Transport-server.err.log"
$clientOut = Join-Path $ResultsDir "integration-$Transport-client.out.log"
$clientErr = Join-Path $ResultsDir "integration-$Transport-client.err.log"
Remove-Item -LiteralPath $serverOut, $serverErr, $clientOut, $clientErr -ErrorAction SilentlyContinue

function Resolve-GodotPath {
	$defaultGodotPath = "C:\Programming_Files\Godot\Godot_v4.6.3-stable_win64.exe\Godot_v4.6.3-stable_win64.exe"
	if (-not [string]::IsNullOrWhiteSpace($GodotPath)) {
		if (-not (Test-Path -LiteralPath $GodotPath)) {
			throw "Godot executable not found at explicit path '$GodotPath'."
		}
		return $GodotPath
	}

	foreach ($candidatePath in @($env:MIMIC_GODOT_PATH, $env:GODOT_PATH, $defaultGodotPath)) {
		if (-not [string]::IsNullOrWhiteSpace($candidatePath) -and (Test-Path -LiteralPath $candidatePath)) {
			return $candidatePath
		}
	}

	throw "Godot executable not found. Set MIMIC_GODOT_PATH or pass -GodotPath."
}

function New-GodotArgumentList {
	param([string] $Role)

	$arguments = @()
	$arguments += @(
		"--headless",
		"--path",
		$repoRoot,
		"--scene",
		"res://test/integration/mimic_connection_probe.tscn",
		"--no-header",
		"--",
		"--mimic-role=$Role",
		"--mimic-transport=$Transport",
		"--mimic-address=127.0.0.1",
		"--mimic-port=$Port",
		"--mimic-timeout=$TimeoutSeconds"
	)
	return $arguments
}

function Wait-ForLogLine {
	param(
		[string] $Path,
		[string] $Pattern,
		[int] $TimeoutSeconds,
		[System.Diagnostics.Process] $Process
	)

	$deadline = (Get-Date).AddSeconds($TimeoutSeconds)
	while ((Get-Date) -lt $deadline) {
		if ((Test-Path -LiteralPath $Path) -and (Select-String -LiteralPath $Path -Pattern $Pattern -Quiet)) {
			return $true
		}
		if ($Process.HasExited) {
			return $false
		}
		Start-Sleep -Milliseconds 100
	}
	return $false
}

function Stop-IfRunning {
	param([System.Diagnostics.Process] $Process)

	if ($Process -ne $null -and -not $Process.HasExited) {
		Stop-Process -Id $Process.Id -Force
	}
}

$server = $null
$client = $null
$godotExecutable = Resolve-GodotPath

try {
	$server = Start-Process `
		-FilePath $godotExecutable `
		-ArgumentList (New-GodotArgumentList "server") `
		-RedirectStandardOutput $serverOut `
		-RedirectStandardError $serverErr `
		-WindowStyle Hidden `
		-PassThru

	$serverReady = Wait-ForLogLine `
		-Path $serverOut `
		-Pattern "MIMIC_TEST_READY server" `
		-TimeoutSeconds $TimeoutSeconds `
		-Process $server
	if (-not $serverReady) {
		throw "Server probe did not become ready before the client started. See $serverOut and $serverErr."
	}

	$client = Start-Process `
		-FilePath $godotExecutable `
		-ArgumentList (New-GodotArgumentList "client") `
		-RedirectStandardOutput $clientOut `
		-RedirectStandardError $clientErr `
		-WindowStyle Hidden `
		-PassThru

	Wait-Process -Id $server.Id, $client.Id -Timeout $TimeoutSeconds -ErrorAction Stop
	$server.Refresh()
	$client.Refresh()
} catch {
	Stop-IfRunning $client
	Stop-IfRunning $server
	Write-Error $_
	exit 1
}

if (
	($server.ExitCode -ne $null -and $server.ExitCode -ne 0) -or
	($client.ExitCode -ne $null -and $client.ExitCode -ne 0)
) {
	Write-Output "Server exit: $($server.ExitCode)"
	Write-Output "Client exit: $($client.ExitCode)"
	Write-Output "Server stdout:"
	Get-Content -LiteralPath $serverOut -ErrorAction SilentlyContinue
	Write-Output "Server stderr:"
	Get-Content -LiteralPath $serverErr -ErrorAction SilentlyContinue
	Write-Output "Client stdout:"
	Get-Content -LiteralPath $clientOut -ErrorAction SilentlyContinue
	Write-Output "Client stderr:"
	Get-Content -LiteralPath $clientErr -ErrorAction SilentlyContinue
	exit 1
}

$serverConnected = Select-String -LiteralPath $serverOut -Pattern "MIMIC_TEST_CONNECTED server" -Quiet
$clientConnected = Select-String -LiteralPath $clientOut -Pattern "MIMIC_TEST_CONNECTED client" -Quiet

if (-not $serverConnected -or -not $clientConnected) {
	Write-Output "Missing expected connection markers."
	Write-Output "Server stdout:"
	Get-Content -LiteralPath $serverOut -ErrorAction SilentlyContinue
	Write-Output "Client stdout:"
	Get-Content -LiteralPath $clientOut -ErrorAction SilentlyContinue
	exit 1
}

Write-Output "Two-instance Mimic $Transport connection smoke test passed on port $Port."

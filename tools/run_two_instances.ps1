param(
	[string] $GodotPath = "",
	[int] $Port = 18910,
	[ValidateSet("enet", "websocket")]
	[string] $Transport = "enet",
	[ValidateSet("explicit", "server_then_client")]
	[string] $ConnectMode = "explicit",
	[int] $TimeoutSeconds = 12,
	[string] $ResultsDir = ""
)

$ErrorActionPreference = "Stop"

$repoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot "..")).Path

if ([string]::IsNullOrWhiteSpace($ResultsDir)) {
	$ResultsDir = Join-Path $repoRoot "test/.output"
}

New-Item -ItemType Directory -Force -Path $ResultsDir | Out-Null

$logPrefix = "integration-$Transport-$ConnectMode"
$serverOut = Join-Path $ResultsDir "$logPrefix-server.out.log"
$serverErr = Join-Path $ResultsDir "$logPrefix-server.err.log"
$clientOut = Join-Path $ResultsDir "$logPrefix-client.out.log"
$clientErr = Join-Path $ResultsDir "$logPrefix-client.err.log"
Remove-Item -LiteralPath $serverOut, $serverErr, $clientOut, $clientErr -ErrorAction SilentlyContinue

function Resolve-GodotPath {
	$defaultGodotPath = "C:\Programming_Files\Godot\Godot_v4.6.3-stable_win64.exe\Godot_v4.6.3-stable_win64_console.exe"
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

	$pathGodot = Get-Command godot -ErrorAction SilentlyContinue
	if ($null -ne $pathGodot) {
		return $pathGodot.Source
	}

	throw "Godot executable not found. Set MIMIC_GODOT_PATH or pass -GodotPath."
}

function New-GodotArgumentList {
	param([string] $Role)

	$probeRole = $Role
	if ($ConnectMode -eq "server_then_client") {
		$probeRole = "auto"
	}

	$arguments = @()
	$arguments += @(
		"--headless",
		"--path",
		$repoRoot,
		"--scene",
		"res://test/integration/mimic_connection_probe.tscn",
		"--no-header",
		"--",
		"--mimic-role=$probeRole",
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

function Assert-ForbiddenLogLinesAbsent {
	param(
		[string[]] $Paths,
		[string[]] $Patterns
	)

	foreach ($path in $Paths) {
		foreach ($pattern in $Patterns) {
			if ((Test-Path -LiteralPath $path) -and (Select-String -LiteralPath $path -Pattern $pattern -SimpleMatch -Quiet)) {
				Write-Output "Forbidden log pattern '$pattern' found in $path."
				Get-Content -LiteralPath $path -ErrorAction SilentlyContinue
				exit 1
			}
		}
	}
}

function Stop-IfRunning {
	param([System.Diagnostics.Process] $Process)

	if ($Process -ne $null -and -not $Process.HasExited) {
		Stop-Process -Id $Process.Id -Force
	}
}

function Start-GodotProbe {
	param(
		[string[]] $Arguments,
		[string] $StandardOutputPath,
		[string] $StandardErrorPath
	)

	$startParameters = @{
		FilePath = $godotExecutable
		ArgumentList = $Arguments
		RedirectStandardOutput = $StandardOutputPath
		RedirectStandardError = $StandardErrorPath
		PassThru = $true
	}
	if ($env:OS -eq "Windows_NT") {
		$startParameters["WindowStyle"] = "Hidden"
	}

	return Start-Process @startParameters
}

$server = $null
$client = $null
$godotExecutable = Resolve-GodotPath

try {
	$server = Start-GodotProbe `
		-Arguments (New-GodotArgumentList "server") `
		-StandardOutputPath $serverOut `
		-StandardErrorPath $serverErr

	$serverReady = Wait-ForLogLine `
		-Path $serverOut `
		-Pattern "MIMIC_TEST_READY server" `
		-TimeoutSeconds $TimeoutSeconds `
		-Process $server
	if (-not $serverReady) {
		throw "Server probe did not become ready before the client started. See $serverOut and $serverErr."
	}

	$client = Start-GodotProbe `
		-Arguments (New-GodotArgumentList "client") `
		-StandardOutputPath $clientOut `
		-StandardErrorPath $clientErr

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

if ($Transport -eq "enet" -and $ConnectMode -eq "server_then_client") {
	Assert-ForbiddenLogLinesAbsent `
		-Paths @($serverOut, $serverErr, $clientOut, $clientErr) `
		-Patterns @("Couldn't create an ENet host", 'Parameter "host" is null')
}

Write-Output "Two-instance Mimic $Transport $ConnectMode connection smoke test passed on port $Port."

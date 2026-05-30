$ErrorActionPreference = "Stop"

$defaultGodotPath = "C:\Programming_Files\Godot\Godot_v4.6.3-stable_win64.exe\Godot_v4.6.3-stable_win64.exe"
$GodotPath = ""
$GodotArguments = @($args)
$explicitGodotPath = $false

if ($GodotArguments.Count -ge 2 -and $GodotArguments[0] -eq "-GodotPath") {
	$GodotPath = [string] $GodotArguments[1]
	$explicitGodotPath = -not [string]::IsNullOrWhiteSpace($GodotPath)
	if ($GodotArguments.Count -gt 2) {
		$GodotArguments = $GodotArguments[2..($GodotArguments.Count - 1)]
	} else {
		$GodotArguments = @()
	}
}

if ($explicitGodotPath) {
	if (-not (Test-Path -LiteralPath $GodotPath)) {
		throw "Godot executable not found at explicit path '$GodotPath'."
	}
} else {
	$candidatePaths = @($env:MIMIC_GODOT_PATH, $env:GODOT_PATH, $defaultGodotPath)
	$GodotPath = ""
	foreach ($candidatePath in $candidatePaths) {
		if (-not [string]::IsNullOrWhiteSpace($candidatePath) -and (Test-Path -LiteralPath $candidatePath)) {
			$GodotPath = $candidatePath
			break
		}
	}
}

if ([string]::IsNullOrWhiteSpace($GodotPath)) {
	throw "Godot executable not found. Set MIMIC_GODOT_PATH or pass -GodotPath."
}

& $GodotPath @GodotArguments
exit $LASTEXITCODE

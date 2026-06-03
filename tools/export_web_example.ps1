param(
	[string] $GodotPath = "",
	[string] $OutputDir = "build/site/play",
	[string] $SiteDir = "build/site",
	[string] $Preset = "Docs Web Example"
)

$ErrorActionPreference = "Stop"

$repoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot "..")).Path
$buildRoot = Join-Path $repoRoot "build"
$siteRoot = (Join-Path $repoRoot $SiteDir)
$resolvedBuildRoot = [System.IO.Path]::GetFullPath($buildRoot)
$resolvedSiteRoot = [System.IO.Path]::GetFullPath($siteRoot)
$outputPath = [System.IO.Path]::GetFullPath((Join-Path $repoRoot $OutputDir))

function Test-IsWithinDirectory {
	param(
		[string] $ChildPath,
		[string] $ParentPath
	)

	$normalizedParent = $ParentPath.TrimEnd([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar)
	$normalizedChild = $ChildPath.TrimEnd([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar)
	return $normalizedChild.Equals($normalizedParent, [System.StringComparison]::OrdinalIgnoreCase) -or $normalizedChild.StartsWith("$normalizedParent$([System.IO.Path]::DirectorySeparatorChar)", [System.StringComparison]::OrdinalIgnoreCase)
}

New-Item -ItemType Directory -Path $resolvedBuildRoot -Force | Out-Null
New-Item -ItemType File -Path (Join-Path $resolvedBuildRoot ".gdignore") -Force | Out-Null

if (-not (Test-IsWithinDirectory -ChildPath $outputPath -ParentPath $resolvedSiteRoot)) {
	throw "Refusing to export outside the generated site directory: $outputPath"
}

if (Test-Path -LiteralPath $outputPath) {
	$resolvedOutputPath = (Resolve-Path -LiteralPath $outputPath).Path
	if (-not (Test-IsWithinDirectory -ChildPath $resolvedOutputPath -ParentPath $resolvedSiteRoot)) {
		throw "Refusing to remove a path outside the generated site directory: $resolvedOutputPath"
	}
	Remove-Item -LiteralPath $resolvedOutputPath -Recurse -Force
}

New-Item -ItemType Directory -Path $outputPath -Force | Out-Null

$godotScript = Join-Path $PSScriptRoot "godot.ps1"
$arguments = @()
if (-not [string]::IsNullOrWhiteSpace($GodotPath)) {
	$arguments += @("-GodotPath", $GodotPath)
}
$arguments += @(
	"--headless",
	"--path",
	$repoRoot,
	"--export-release",
	$Preset,
	(Join-Path $outputPath "index.html")
)

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

$previousErrorActionPreference = $ErrorActionPreference
$ErrorActionPreference = "Continue"
try {
	$exportOutput = & (Get-PowerShellExecutable) -NoProfile -ExecutionPolicy Bypass -File $godotScript @arguments 2>&1
	$exportExitCode = $LASTEXITCODE
} finally {
	$ErrorActionPreference = $previousErrorActionPreference
}
$exportOutput | ForEach-Object { Write-Output $_ }

if ($exportExitCode -ne 0) {
	exit $exportExitCode
}

if ($exportOutput -match "Cannot export project|Project export .* failed") {
	exit 1
}

$expectedArtifacts = @(
	"index.html",
	"index.js",
	"index.pck",
	"index.wasm"
)

$missingArtifacts = @()
foreach ($artifact in $expectedArtifacts) {
	if (-not (Test-Path -LiteralPath (Join-Path $outputPath $artifact))) {
		$missingArtifacts += $artifact
	}
}

if ($missingArtifacts.Count -gt 0) {
	throw "Godot export did not write expected web artifact(s): $($missingArtifacts -join ', ')."
}

exit 0

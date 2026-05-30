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

& $godotScript @arguments
exit $LASTEXITCODE

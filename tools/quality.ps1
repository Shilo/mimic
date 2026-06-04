param(
	[int] $DuplicateMinLines = 8,
	[int] $DuplicateMinTokens = 70,
	[string] $OutputDir = "test/.output/quality",
	[switch] $BootstrapTools,
	[switch] $SkipDuplicateCheck,
	[switch] $SkipGdstyle,
	[switch] $SkipDependencyCheck,
	[switch] $SkipPowerShellSyntaxCheck,
	[switch] $StrictGdstyle,
	[switch] $SkipPolicyCheck
)

$ErrorActionPreference = "Stop"

$repoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot "..")).Path
$qualityRoot = Join-Path $PSScriptRoot "quality"
$resolvedOutputDir = [System.IO.Path]::GetFullPath((Join-Path $repoRoot $OutputDir))
$gdstyleVersion = "v0.1.5"
$gdcruiserVersion = "1.7.0"
$gdstyleConfig = Join-Path $qualityRoot "gdstyle.toml"
$gdcruiserConfig = Join-Path $qualityRoot "gdcruiser.json"
$jscpdPackageRoot = $qualityRoot
$projectPaths = @("addons/mimic", "examples", "test")
$gdstyleBlockingRules = @(
	"quality/type-hint"
)
$mimicReadableCastTypes = @(
	"Array",
	"Dictionary",
	"Error",
	"Level",
	"Mimic.EditorAutoConnectMode",
	"Mimic.NetworkState",
	"Mimic.PortMappingProtocol",
	"Mimic.TransportType",
	"MimicLog.Level",
	"PackedByteArray",
	"PackedColorArray",
	"PackedFloat32Array",
	"PackedFloat64Array",
	"PackedInt32Array",
	"PackedInt64Array",
	"PackedStringArray",
	"PackedVector2Array",
	"PackedVector3Array",
	"PackedVector4Array",
	"PortMappingProtocol",
	"String",
	"StringName",
	"TransportType",
	"UPNP.UPNPResult",
	"Vector2",
	"Vector2i",
	"Vector3",
	"Vector3i",
	"Vector4",
	"Vector4i"
)
$mimicEnumParameterNames = @(
	"attempted_state",
	"log_level",
	"mapping_protocol",
	"message_level",
	"mode",
	"network_state",
	"port_mapping_protocol",
	"previous_state",
	"state",
	"transport"
)
$mimicEnumDeclarationCastTypes = @(
	"Level",
	"Mimic.EditorAutoConnectMode",
	"Mimic.NetworkState",
	"Mimic.PortMappingProtocol",
	"Mimic.TransportType",
	"MimicLog.Level",
	"NetworkState",
	"PortMappingProtocol",
	"TransportType"
)

New-Item -ItemType Directory -Force -Path $resolvedOutputDir | Out-Null

function Get-RelativePath {
	param([string] $Path)

	$fullPath = [System.IO.Path]::GetFullPath($Path)
	$rootWithSeparator = $repoRoot.TrimEnd(
		[System.IO.Path]::DirectorySeparatorChar,
		[System.IO.Path]::AltDirectorySeparatorChar
	) + [System.IO.Path]::DirectorySeparatorChar
	if ($fullPath.StartsWith($rootWithSeparator, [System.StringComparison]::OrdinalIgnoreCase)) {
		return $fullPath.Substring($rootWithSeparator.Length).Replace("\", "/")
	}
	return $fullPath.Replace("\", "/")
}

function Resolve-ProjectPath {
	param([string] $Path)

	return Join-Path $repoRoot $Path
}

function Invoke-CheckedCommand {
	param(
		[string] $Label,
		[string] $Command,
		[string[]] $Arguments,
		[bool] $AllowFailure = $false
	)

	Write-Host $Label
	Push-Location $repoRoot
	try {
		& $Command @Arguments
		$exitCode = $LASTEXITCODE
	} finally {
		Pop-Location
	}
	if ($exitCode -ne 0 -and -not $AllowFailure) {
		throw "$Label failed with exit code $exitCode."
	}
}

function Get-GdstyleAssetMetadata {
	if ($IsWindows -or $env:OS -eq "Windows_NT") {
		return @{
			Name = "gdstyle-x86_64-pc-windows-msvc.zip"
			Sha256 = "50e5d86ca571d19083f6d9ca4be4b346323dfb56bca7854946937896d87c3b4c"
		}
	}
	if ($IsMacOS) {
		$machine = ""
		$uname = Get-Command uname -ErrorAction SilentlyContinue
		if ($null -ne $uname) {
			$machine = (& $uname.Source "-m")
		}
		if ($machine -eq "arm64" -or $machine -eq "aarch64") {
			return @{
				Name = "gdstyle-aarch64-apple-darwin.tar.gz"
				Sha256 = "57173d1695c99242a1933944017fef6a885c12e8b0bf09faaa7ceb9ec5d71305"
			}
		}
		return @{
			Name = "gdstyle-x86_64-apple-darwin.tar.gz"
			Sha256 = "4b1671dfd49feaa8c6d7632bcacba836ff99b8e788c6a1d68c327757e62331f7"
		}
	}
	return @{
		Name = "gdstyle-x86_64-unknown-linux-gnu.tar.gz"
		Sha256 = "3b6e72c1f4e43e6547c3b520c5d3158d0b0012a7c6ece4bfb2a08e0a3747d138"
	}
}

function Get-LocalGdstylePath {
	$binaryName = "gdstyle"
	if ($IsWindows -or $env:OS -eq "Windows_NT") {
		$binaryName = "gdstyle.exe"
	}

	$localPath = Join-Path $repoRoot "tools/.bin/gdstyle/$gdstyleVersion/$binaryName"
	if (Test-Path -LiteralPath $localPath) {
		return $localPath
	}
	return ""
}

function Get-PythonCommand {
	$candidateNames = @("python", "python3")
	foreach ($candidateName in $candidateNames) {
		$candidate = Get-Command $candidateName -ErrorAction SilentlyContinue
		if ($null -eq $candidate) {
			continue
		}
		$versionOutput = & $candidate.Source "-c" "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')"
		if ($LASTEXITCODE -ne 0) {
			continue
		}
		if ([version] $versionOutput -ge [version] "3.13") {
			return $candidate.Source
		}
	}

	return ""
}

function Get-NpmCommand {
	$candidate = Get-Command npm -ErrorAction SilentlyContinue
	if ($null -eq $candidate) {
		return ""
	}
	return $candidate.Source
}

function Get-LocalJscpdPath {
	$binaryName = "jscpd"
	if ($IsWindows -or $env:OS -eq "Windows_NT") {
		$binaryName = "jscpd.cmd"
	}

	$localPath = Join-Path $jscpdPackageRoot "node_modules/.bin/$binaryName"
	if (Test-Path -LiteralPath $localPath) {
		return $localPath
	}
	return ""
}

function Install-Jscpd {
	$npm = Get-NpmCommand
	if ([string]::IsNullOrWhiteSpace($npm)) {
		throw "npm was not found. Install Node.js to run the duplicate-code gate."
	}

	Write-Host "Installing locked jscpd dependencies from $(Get-RelativePath (Join-Path $jscpdPackageRoot "package-lock.json"))..."
	& $npm `
		ci `
		--ignore-scripts `
		--no-audit `
		--no-fund `
		--prefix `
		$jscpdPackageRoot | Out-Null
	if ($LASTEXITCODE -ne 0) {
		throw "Failed to install locked jscpd dependencies."
	}

	$localPath = Get-LocalJscpdPath
	if ([string]::IsNullOrWhiteSpace($localPath)) {
		throw "Installed jscpd dependencies, but could not find the local jscpd executable."
	}
	return $localPath
}

function Resolve-Jscpd {
	$localPath = Get-LocalJscpdPath
	if (-not [string]::IsNullOrWhiteSpace($localPath)) {
		return $localPath
	}
	return Install-Jscpd
}

function Get-LocalGdcruiserRoot {
	return Join-Path $repoRoot "tools/.bin/gdcruiser/v$gdcruiserVersion"
}

function Get-LocalGdcruiserPath {
	$binaryName = "gdcruiser"
	if ($IsWindows -or $env:OS -eq "Windows_NT") {
		$binaryName = "gdcruiser.exe"
	}

	$localPath = Join-Path (Get-LocalGdcruiserRoot) "bin/$binaryName"
	if (Test-Path -LiteralPath $localPath) {
		return $localPath
	}
	return ""
}

function Install-Gdstyle {
	$existingPath = Get-LocalGdstylePath
	if (-not [string]::IsNullOrWhiteSpace($existingPath)) {
		return $existingPath
	}

	$asset = Get-GdstyleAssetMetadata
	$assetName = [string] $asset.Name
	$installRoot = Join-Path $repoRoot "tools/.bin/gdstyle/$gdstyleVersion"
	$tempRoot = Join-Path $resolvedOutputDir "gdstyle-download"
	$archivePath = Join-Path $tempRoot $assetName
	$url = "https://github.com/atelico/gdstyle/releases/download/$gdstyleVersion/$assetName"

	New-Item -ItemType Directory -Force -Path $installRoot, $tempRoot | Out-Null
	Write-Host "Downloading gdstyle $gdstyleVersion from $url"
	$webRequestArgs = @{
		Uri = $url
		OutFile = $archivePath
	}
	if ($PSVersionTable.PSEdition -eq "Desktop") {
		$webRequestArgs["UseBasicParsing"] = $true
	}
	Invoke-WebRequest @webRequestArgs
	$actualHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $archivePath).Hash.ToLowerInvariant()
	if ($actualHash -ne $asset.Sha256) {
		throw "gdstyle archive checksum mismatch for $assetName. Expected $($asset.Sha256), got $actualHash."
	}

	if ($assetName.EndsWith(".zip")) {
		Expand-Archive -LiteralPath $archivePath -DestinationPath $installRoot -Force
	} else {
		tar -xzf $archivePath -C $installRoot
		if ($LASTEXITCODE -ne 0) {
			throw "Failed to extract $archivePath."
		}
	}

	$installedPath = Get-LocalGdstylePath
	if ([string]::IsNullOrWhiteSpace($installedPath)) {
		$binary = Get-ChildItem -LiteralPath $installRoot -Recurse -File |
			Where-Object { $_.Name -eq "gdstyle" -or $_.Name -eq "gdstyle.exe" } |
			Select-Object -First 1
		if ($null -eq $binary) {
			throw "Downloaded gdstyle, but could not find the executable in $installRoot."
		}
		$installedPath = $binary.FullName
	}
	return $installedPath
}

function Install-Gdcruiser {
	$existingPath = Get-LocalGdcruiserPath
	if (-not [string]::IsNullOrWhiteSpace($existingPath)) {
		return $existingPath
	}

	$python = Get-PythonCommand
	if ([string]::IsNullOrWhiteSpace($python)) {
		throw "Python was not found. Install Python 3.13+ to bootstrap gdcruiser."
	}

	$installRoot = Get-LocalGdcruiserRoot
	New-Item -ItemType Directory -Force -Path $installRoot | Out-Null
	Write-Host "Installing gdcruiser $gdcruiserVersion into $(Get-RelativePath $installRoot)"
	$requirementsPath = Resolve-ProjectPath "tools/quality/requirements_quality.txt"
	& $python `
		-m `
		pip `
		install `
		--quiet `
		--disable-pip-version-check `
		--no-deps `
		--only-binary=:all: `
		--require-hashes `
		--target `
		$installRoot `
		-r `
		$requirementsPath
	if ($LASTEXITCODE -ne 0) {
		throw "Failed to install gdcruiser $gdcruiserVersion."
	}

	$installedPath = Get-LocalGdcruiserPath
	if ([string]::IsNullOrWhiteSpace($installedPath)) {
		throw "Installed gdcruiser, but could not find the executable in $installRoot."
	}
	return $installedPath
}

function Resolve-Gdstyle {
	$localPath = Get-LocalGdstylePath
	if (-not [string]::IsNullOrWhiteSpace($localPath)) {
		return $localPath
	}

	if ($BootstrapTools) {
		return Install-Gdstyle
	}

	$pathCommand = Get-Command gdstyle -ErrorAction SilentlyContinue
	if ($null -ne $pathCommand) {
		return $pathCommand.Source
	}

	return ""
}

function Resolve-Gdcruiser {
	$localPath = Get-LocalGdcruiserPath
	if (-not [string]::IsNullOrWhiteSpace($localPath)) {
		return $localPath
	}

	if ($BootstrapTools) {
		return Install-Gdcruiser
	}

	return ""
}

function Assert-GdstyleVersion {
	param([string] $GdstylePath)

	$versionOutput = & $GdstylePath "--version"
	if ($LASTEXITCODE -ne 0) {
		throw "Failed to read gdstyle version from $GdstylePath."
	}
	if ($versionOutput -notmatch "0\.1\.5") {
		throw "Expected gdstyle $gdstyleVersion, but found '$versionOutput' at $GdstylePath."
	}
}

function Invoke-GdcruiserCommand {
	param(
		[string] $GdcruiserPath,
		[string[]] $Arguments
	)

	$localRoot = Get-LocalGdcruiserRoot
	$previousPythonPath = $env:PYTHONPATH
	if ($GdcruiserPath.StartsWith($localRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
		if ([string]::IsNullOrWhiteSpace($previousPythonPath)) {
			$env:PYTHONPATH = $localRoot
		} else {
			$env:PYTHONPATH = "$localRoot$([System.IO.Path]::PathSeparator)$previousPythonPath"
		}
	}

	Push-Location $repoRoot
	try {
		& $GdcruiserPath @Arguments
		$exitCode = $LASTEXITCODE
	} finally {
		Pop-Location
		$env:PYTHONPATH = $previousPythonPath
	}
	return $exitCode
}

function Add-PolicyIssue {
	param(
		[System.Collections.Generic.List[object]] $Issues,
		[string] $Rule,
		[string] $Message,
		[string] $Path,
		[int] $Line = 1,
		[string] $Severity = "error"
	)

	$Issues.Add([PSCustomObject] @{
		severity = $Severity
		rule = $Rule
		path = $Path
		line = $Line
		message = $Message
	}) | Out-Null
}

function Add-RegexPolicyIssues {
	param(
		[System.Collections.Generic.List[object]] $Issues,
		[string] $Rule,
		[string] $Message,
		[string[]] $Files,
		[string] $Pattern,
		[string[]] $Exclude = @(),
		[string] $Severity = "error"
	)

	foreach ($file in $Files) {
		$relativePath = Get-RelativePath $file
		if ($Exclude -contains $relativePath) {
			continue
		}
		$matches = Select-String -LiteralPath $file -Pattern $Pattern -AllMatches
		foreach ($match in $matches) {
			if ($match.Line.TrimStart().StartsWith("#")) {
				continue
			}
			Add-PolicyIssue `
				-Issues $Issues `
				-Rule $Rule `
				-Message $Message `
				-Path $relativePath `
				-Line $match.LineNumber `
				-Severity $Severity
		}
	}
}

function Add-RawRegexPolicyIssues {
	param(
		[System.Collections.Generic.List[object]] $Issues,
		[string] $Rule,
		[string] $Message,
		[string[]] $Files,
		[string] $Pattern,
		[string[]] $Exclude = @(),
		[string] $Severity = "error"
	)

	$regex = [regex]::new($Pattern, [System.Text.RegularExpressions.RegexOptions]::Singleline)
	foreach ($file in $Files) {
		$relativePath = Get-RelativePath $file
		if ($Exclude -contains $relativePath) {
			continue
		}

		$content = Get-Content -Raw -LiteralPath $file
		foreach ($match in $regex.Matches($content)) {
			$line = ($content.Substring(0, $match.Index) -split "`r?`n").Count
			$lineText = (Get-Content -LiteralPath $file -TotalCount $line | Select-Object -Last 1)
			if ($lineText.TrimStart().StartsWith("#")) {
				continue
			}
			Add-PolicyIssue `
				-Issues $Issues `
				-Rule $Rule `
				-Message $Message `
				-Path $relativePath `
				-Line $line `
				-Severity $Severity
		}
	}
}

function Test-GdscriptDocCommentBefore {
	param(
		[string[]] $Lines,
		[int] $Index
	)

	for ($lineIndex = $Index - 1; $lineIndex -ge 0; $lineIndex--) {
		$trimmedLine = $Lines[$lineIndex].Trim()
		if ($trimmedLine.StartsWith("@") -or (Test-GdscriptAnnotationContinuation -Line $trimmedLine)) {
			continue
		}
		return $trimmedLine.StartsWith("##")
	}
	return $false
}

function Test-GdscriptAnnotationContinuation {
	param([string] $Line)

	if ($Line -eq "") {
		return $false
	}

	return $Line -match '^[\)\]\}]\s*,?$' -or
		$Line -match '^(?:"[^"]*"|''[^'']*''|[A-Za-z_][A-Za-z0-9_\.]*|-?\d+(?:\.\d+)?|true|false|null)\s*,?$'
}

function Test-GdscriptDocCommentAfter {
	param(
		[string[]] $Lines,
		[int] $Index
	)

	if ($Index + 1 -ge $Lines.Count) {
		return $false
	}
	return $Lines[$Index + 1].Trim().StartsWith("##")
}

function Test-GdscriptInlineDocComment {
	param([string] $Line)

	$docIndex = $Line.IndexOf("##", [System.StringComparison]::Ordinal)
	return $docIndex -gt 0 -and -not [string]::IsNullOrWhiteSpace($Line.Substring($docIndex + 2))
}

function Test-GdscriptMemberDocComment {
	param(
		[string[]] $Lines,
		[int] $Index
	)

	return (Test-GdscriptDocCommentBefore -Lines $Lines -Index $Index) -or
		(Test-GdscriptInlineDocComment -Line $Lines[$Index])
}

function Get-BraceDelta {
	param([string] $Line)

	return ([regex]::Matches($Line, "\{").Count - [regex]::Matches($Line, "\}").Count)
}

function Get-ParenthesisDelta {
	param([string] $Line)

	return ([regex]::Matches($Line, "\(").Count - [regex]::Matches($Line, "\)").Count)
}

function New-StringSet {
	$set = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::Ordinal)
	return ,$set
}

function Add-StringSetValue {
	param(
		[System.Collections.Generic.HashSet[string]] $Set,
		[string] $Value
	)

	if (-not [string]::IsNullOrWhiteSpace($Value)) {
		$Set.Add($Value) | Out-Null
	}
}

function Resolve-GodotDocClassesRoot {
	$candidates = @()
	if (-not [string]::IsNullOrWhiteSpace($env:GODOT_SOURCE_PATH)) {
		$candidates += $env:GODOT_SOURCE_PATH
	}
	$candidates += "C:\Programming_Files\Godot\godot-master"

	foreach ($candidate in $candidates) {
		$docClassesRoot = Join-Path $candidate "doc/classes"
		if (Test-Path -LiteralPath $docClassesRoot) {
			return $docClassesRoot
		}
	}

	return ""
}

function Add-FallbackNativeClassMembers {
	param(
		[string] $ClassName,
		[System.Collections.Generic.HashSet[string]] $Members,
		[System.Collections.Generic.HashSet[string]] $Visited
	)

	if ([string]::IsNullOrWhiteSpace($ClassName) -or $Visited.Contains($ClassName)) {
		return
	}
	$Visited.Add($ClassName) | Out-Null

	$fallbackParents = @{
		CanvasItem = "Node"
		CanvasLayer = "Node"
		CharacterBody2D = "PhysicsBody2D"
		CollisionObject2D = "Node2D"
		EditorPlugin = "Node"
		MultiplayerSynchronizer = "Node"
		Node = "Object"
		Node2D = "CanvasItem"
		Object = ""
		PhysicsBody2D = "CollisionObject2D"
		RefCounted = "Object"
	}
	$fallbackMembers = @{
		CanvasItem = @(
			"hide",
			"is_visible_in_tree",
			"material",
			"modulate",
			"self_modulate",
			"show",
			"visibility_changed",
			"visible",
			"z_index"
		)
		CharacterBody2D = @("floor_velocity", "get_floor_normal", "move_and_slide", "velocity")
		EditorPlugin = @("add_autoload_singleton", "get_editor_interface", "remove_autoload_singleton")
		MultiplayerSynchronizer = @(
			"delta_synchronized",
			"public_visibility",
			"replication_config",
			"root_path",
			"set_visibility_for",
			"synchronized"
		)
		Node = @(
			"add_child",
			"get_node",
			"get_parent",
			"get_tree",
			"name",
			"owner",
			"process_mode",
			"process_priority",
			"queue_free",
			"ready",
			"remove_child",
			"tree_entered",
			"tree_exited",
			"tree_exiting"
		)
		Node2D = @("global_position", "global_rotation", "global_scale", "position", "rotation", "scale")
		Object = @(
			"connect",
			"disconnect",
			"emit_signal",
			"free",
			"get",
			"get_class",
			"get_instance_id",
			"get_method_list",
			"get_property_list",
			"has_signal",
			"is_class",
			"notification",
			"property_list_changed",
			"script",
			"script_changed",
			"set"
		)
		RefCounted = @("get_reference_count", "init_ref", "reference", "unreference")
	}

	if ($fallbackMembers.ContainsKey($ClassName)) {
		foreach ($member in $fallbackMembers[$ClassName]) {
			Add-StringSetValue -Set $Members -Value $member
		}
	}

	if ($fallbackParents.ContainsKey($ClassName)) {
		Add-FallbackNativeClassMembers `
			-ClassName $fallbackParents[$ClassName] `
			-Members $Members `
			-Visited $Visited
	}
}

function Add-NativeClassMembersFromDocs {
	param(
		[string] $ClassName,
		[System.Collections.Generic.HashSet[string]] $Members,
		[System.Collections.Generic.HashSet[string]] $Visited,
		[string] $DocClassesRoot
	)

	if ([string]::IsNullOrWhiteSpace($ClassName) -or $Visited.Contains($ClassName)) {
		return
	}
	$Visited.Add($ClassName) | Out-Null

	if ([string]::IsNullOrWhiteSpace($DocClassesRoot)) {
		Add-FallbackNativeClassMembers -ClassName $ClassName -Members $Members -Visited (New-StringSet)
		return
	}

	$classDocPath = Join-Path $DocClassesRoot "$ClassName.xml"
	if (-not (Test-Path -LiteralPath $classDocPath)) {
		Add-FallbackNativeClassMembers -ClassName $ClassName -Members $Members -Visited (New-StringSet)
		return
	}

	[xml] $classDoc = Get-Content -Raw -LiteralPath $classDocPath
	$classNode = $classDoc.class

	foreach ($method in @($classNode.methods.method)) {
		Add-StringSetValue -Set $Members -Value ([string] $method.name)
	}
	foreach ($member in @($classNode.members.member)) {
		Add-StringSetValue -Set $Members -Value ([string] $member.name)
	}
	foreach ($signal in @($classNode.signals.signal)) {
		Add-StringSetValue -Set $Members -Value ([string] $signal.name)
	}
	foreach ($constant in @($classNode.constants.constant)) {
		Add-StringSetValue -Set $Members -Value ([string] $constant.name)
		$enumName = [string] $constant.enum
		if (-not [string]::IsNullOrWhiteSpace($enumName)) {
			Add-StringSetValue -Set $Members -Value (($enumName -split "\.")[-1])
		}
	}

	$parentClassName = [string] $classNode.inherits
	if (-not [string]::IsNullOrWhiteSpace($parentClassName)) {
		Add-NativeClassMembersFromDocs `
			-ClassName $parentClassName `
			-Members $Members `
			-Visited $Visited `
			-DocClassesRoot $DocClassesRoot
	}
}

function Get-GdscriptSymbolLine {
	param([string] $Line)

	return ($Line.Trim() -replace '^(@[A-Za-z_][A-Za-z0-9_]*(?:\([^)]*\))?\s+)+', '')
}

function Get-GdscriptClassMetadata {
	param([string[]] $Files)

	$metadataByFile = @{}
	foreach ($file in $Files) {
		$lines = Get-Content -LiteralPath $file
		$className = ""
		$baseName = ""
		$members = New-StringSet

		foreach ($line in $lines) {
			if ($line -match '^\s') {
				continue
			}

			$symbolLine = Get-GdscriptSymbolLine -Line $line
			if ($symbolLine -match '^class_name\s+([A-Za-z_][A-Za-z0-9_]*)(?:\s+extends\s+([A-Za-z_][A-Za-z0-9_\.]*))?') {
				$className = $Matches[1]
				if (-not [string]::IsNullOrWhiteSpace($Matches[2])) {
					$baseName = $Matches[2]
				}
				continue
			}
			if ($symbolLine -match '^extends\s+([A-Za-z_][A-Za-z0-9_\.]*)') {
				$baseName = $Matches[1]
				continue
			}

			if ($symbolLine -match '^signal\s+([A-Za-z_][A-Za-z0-9_]*)\b') {
				Add-StringSetValue -Set $members -Value $Matches[1]
				continue
			}
			if ($symbolLine -match '^enum\s+([A-Za-z_][A-Za-z0-9_]*)\b') {
				Add-StringSetValue -Set $members -Value $Matches[1]
				continue
			}
			if ($symbolLine -match '^(?:static\s+)?func\s+([A-Za-z_][A-Za-z0-9_]*)\s*\(') {
				Add-StringSetValue -Set $members -Value $Matches[1]
				continue
			}
			if ($symbolLine -match '^(?:static\s+)?var\s+([A-Za-z_][A-Za-z0-9_]*)\b') {
				Add-StringSetValue -Set $members -Value $Matches[1]
				continue
			}
			if ($symbolLine -match '^const\s+([A-Za-z_][A-Za-z0-9_]*)\b') {
				Add-StringSetValue -Set $members -Value $Matches[1]
			}
		}

		$metadataByFile[$file] = [PSCustomObject] @{
			class_name = $className
			base_name = $baseName
			members = $members
		}
	}

	return $metadataByFile
}

function Add-GdscriptBaseClassMembers {
	param(
		[string] $BaseName,
		[hashtable] $MetadataByClassName,
		[System.Collections.Generic.HashSet[string]] $Members,
		[System.Collections.Generic.HashSet[string]] $Visited,
		[string] $DocClassesRoot
	)

	if ([string]::IsNullOrWhiteSpace($BaseName) -or $Visited.Contains($BaseName)) {
		return
	}
	$Visited.Add($BaseName) | Out-Null

	if ($MetadataByClassName.ContainsKey($BaseName)) {
		$metadata = $MetadataByClassName[$BaseName]
		foreach ($member in $metadata.members) {
			Add-StringSetValue -Set $Members -Value $member
		}
		Add-GdscriptBaseClassMembers `
			-BaseName $metadata.base_name `
			-MetadataByClassName $MetadataByClassName `
			-Members $Members `
			-Visited $Visited `
			-DocClassesRoot $DocClassesRoot
		return
	}

	Add-NativeClassMembersFromDocs `
		-ClassName $BaseName `
		-Members $Members `
		-Visited (New-StringSet) `
		-DocClassesRoot $DocClassesRoot
}

function Get-GdscriptFunctionSignature {
	param(
		[string[]] $Lines,
		[int] $StartIndex
	)

	$signature = $Lines[$StartIndex]
	$depth = Get-ParenthesisDelta $signature
	$index = $StartIndex
	while ($depth -gt 0 -and $index + 1 -lt $Lines.Count) {
		$index += 1
		$signature += "`n$($Lines[$index])"
		$depth += Get-ParenthesisDelta $Lines[$index]
	}

	return [PSCustomObject] @{
		text = $signature
		end_index = $index
	}
}

function Get-GdscriptLocalDeclarations {
	param([string[]] $Lines)

	$declarations = [System.Collections.Generic.List[object]]::new()
	for ($index = 0; $index -lt $Lines.Count; $index++) {
		$line = $Lines[$index]
		$codeLine = $line
		$commentIndex = $codeLine.IndexOf("#", [System.StringComparison]::Ordinal)
		if ($commentIndex -ge 0) {
			$codeLine = $codeLine.Substring(0, $commentIndex)
		}
		$trimmedLine = $codeLine.Trim()
		if ($trimmedLine -eq "") {
			continue
		}

		if ($trimmedLine -match '^(?:static\s+)?func\s+[A-Za-z_][A-Za-z0-9_]*\s*\(') {
			$signature = Get-GdscriptFunctionSignature -Lines $Lines -StartIndex $index
			$openIndex = $signature.text.IndexOf("(", [System.StringComparison]::Ordinal)
			$closeIndex = $signature.text.LastIndexOf(")", [System.StringComparison]::Ordinal)
			if ($openIndex -ge 0 -and $closeIndex -gt $openIndex) {
				$parameters = $signature.text.Substring($openIndex + 1, $closeIndex - $openIndex - 1)
				$parameterPattern = [regex]::new('(?:^|,)\s*(?:\.\.\.)?(?<Name>[A-Za-z_][A-Za-z0-9_]*)\s*(?::=|:|=|,|$)')
				foreach ($match in $parameterPattern.Matches($parameters)) {
					$lineOffset = ($parameters.Substring(0, $match.Index) -split "`r?`n").Count - 1
					$declarations.Add([PSCustomObject] @{
						kind = "function parameter"
						line = $index + $lineOffset + 1
						name = [string] $match.Groups["Name"].Value
					}) | Out-Null
				}
			}
			$index = $signature.end_index
			continue
		}

		if ($codeLine -match '^\s+(?:var|const)\s+([A-Za-z_][A-Za-z0-9_]*)\b') {
			$declarations.Add([PSCustomObject] @{
				kind = "local declaration"
				line = $index + 1
				name = $Matches[1]
			}) | Out-Null
			continue
		}
		if ($codeLine -match '^\s*for\s+([A-Za-z_][A-Za-z0-9_]*)\s+in\b') {
			$declarations.Add([PSCustomObject] @{
				kind = "for iterator"
				line = $index + 1
				name = $Matches[1]
			}) | Out-Null
		}
	}

	return $declarations
}

function Add-GdscriptShadowedBaseClassIssues {
	param(
		[System.Collections.Generic.List[object]] $Issues,
		[string[]] $Files
	)

	$metadataByFile = Get-GdscriptClassMetadata -Files $Files
	$metadataByClassName = @{}
	foreach ($file in $metadataByFile.Keys) {
		$metadata = $metadataByFile[$file]
		if (-not [string]::IsNullOrWhiteSpace($metadata.class_name)) {
			$metadataByClassName[$metadata.class_name] = $metadata
		}
	}
	$docClassesRoot = Resolve-GodotDocClassesRoot

	foreach ($file in $Files) {
		$metadata = $metadataByFile[$file]
		if ([string]::IsNullOrWhiteSpace($metadata.base_name)) {
			continue
		}

		$baseMembers = New-StringSet
		Add-GdscriptBaseClassMembers `
			-BaseName $metadata.base_name `
			-MetadataByClassName $metadataByClassName `
			-Members $baseMembers `
			-Visited (New-StringSet) `
			-DocClassesRoot $docClassesRoot
		if ($baseMembers.Count -eq 0) {
			continue
		}

		$relativePath = Get-RelativePath $file
		$lines = Get-Content -LiteralPath $file
		foreach ($declaration in Get-GdscriptLocalDeclarations -Lines $lines) {
			if (-not $baseMembers.Contains($declaration.name)) {
				continue
			}
			Add-PolicyIssue `
				-Issues $Issues `
				-Rule "style/shadowed-variable-base-class" `
				-Message "Rename '$($declaration.name)'; this $($declaration.kind) shadows a base class member and Godot reports that as SHADOWED_VARIABLE_BASE_CLASS." `
				-Path $relativePath `
				-Line $declaration.line
		}
	}
}

function Test-GdscriptReadableCastType {
	param([string] $TypeName)

	if ($mimicReadableCastTypes -contains $TypeName) {
		return $true
	}
	$unqualifiedTypeName = ($TypeName -split "\.")[-1]
	return $mimicReadableCastTypes -contains $unqualifiedTypeName
}

function Add-GdscriptInferredCastDeclarationIssues {
	param(
		[System.Collections.Generic.List[object]] $Issues,
		[string[]] $Files
	)

	$pattern = [regex]::new('^\s*var\s+(?<Name>[A-Za-z_][A-Za-z0-9_]*)\s*:=\s*(?<Expression>.+?)\s+as\s+(?<Type>[A-Za-z_][A-Za-z0-9_\.]*)\s*(?:#.*)?$')
	foreach ($file in $Files) {
		$relativePath = Get-RelativePath $file
		$lines = Get-Content -LiteralPath $file
		for ($index = 0; $index -lt $lines.Count; $index++) {
			$line = $lines[$index]
			if ($line.TrimStart().StartsWith("#")) {
				continue
			}
			$match = $pattern.Match($line)
			if (-not $match.Success) {
				continue
			}

			$typeName = [string] $match.Groups["Type"].Value
			if (-not (Test-GdscriptReadableCastType -TypeName $typeName)) {
				continue
			}

			Add-PolicyIssue `
				-Issues $Issues `
				-Rule "style/no-inferred-as-declaration" `
				-Message "Prefer 'var $($match.Groups["Name"].Value): $typeName = ...' over inferring a declaration through 'as $typeName'." `
				-Path $relativePath `
				-Line ($index + 1)
		}
	}
}

function Test-GdscriptEnumDeclarationCastType {
	param([string] $TypeName)

	if ($mimicEnumDeclarationCastTypes -contains $TypeName) {
		return $true
	}
	$unqualifiedTypeName = ($TypeName -split "\.")[-1]
	return $mimicEnumDeclarationCastTypes -contains $unqualifiedTypeName
}

function Add-GdscriptRedundantEnumCastDeclarationIssues {
	param(
		[System.Collections.Generic.List[object]] $Issues,
		[string[]] $Files
	)

	$pattern = [regex]::new('^\s*var\s+(?<Name>[A-Za-z_][A-Za-z0-9_]*)\s*:\s*(?<DeclaredType>[A-Za-z_][A-Za-z0-9_\.]*)\s*=\s*(?<Expression>.+?)\s+as\s+(?<CastType>[A-Za-z_][A-Za-z0-9_\.]*)\s*(?:#.*)?$')
	foreach ($file in $Files) {
		$relativePath = Get-RelativePath $file
		$lines = Get-Content -LiteralPath $file
		for ($index = 0; $index -lt $lines.Count; $index++) {
			$line = $lines[$index]
			if ($line.TrimStart().StartsWith("#")) {
				continue
			}
			$match = $pattern.Match($line)
			if (-not $match.Success) {
				continue
			}

			$declaredType = [string] $match.Groups["DeclaredType"].Value
			$castType = [string] $match.Groups["CastType"].Value
			if ($declaredType -ne $castType) {
				continue
			}
			if (-not (Test-GdscriptEnumDeclarationCastType -TypeName $declaredType)) {
				continue
			}

			Add-PolicyIssue `
				-Issues $Issues `
				-Rule "style/no-redundant-enum-as-declaration" `
				-Message "Drop redundant 'as $castType'; the '$($match.Groups["Name"].Value)' declaration already has that enum type." `
				-Path $relativePath `
				-Line ($index + 1)
		}
	}
}

function Add-GdscriptEnumIntIssues {
	param(
		[System.Collections.Generic.List[object]] $Issues,
		[string[]] $Files
	)

	$enumValueCastPatterns = @(
		'\b(?:Mimic\.)?(?:EditorAutoConnectMode|NetworkState|PortMappingProtocol|TransportType)\.[A-Z][A-Z0-9_]*\s+as\s+int\b',
		'\b(?:MimicLog\.)?Level\.[A-Z][A-Z0-9_]*\s+as\s+int\b',
		'\bint\s*\(\s*(?:Mimic\.)?(?:EditorAutoConnectMode|NetworkState|PortMappingProtocol|TransportType)\.[A-Z][A-Z0-9_]*\s*\)',
		'\bint\s*\(\s*(?:MimicLog\.)?Level\.[A-Z][A-Z0-9_]*\s*\)'
	)
	$enumParameterPattern = [regex]::new(
		'\b(?<Name>' + (($mimicEnumParameterNames | ForEach-Object { [regex]::Escape($_) }) -join "|") + ')\s*:\s*int\b'
	)

	foreach ($file in $Files) {
		$relativePath = Get-RelativePath $file
		$lines = Get-Content -LiteralPath $file
		for ($index = 0; $index -lt $lines.Count; $index++) {
			$line = $lines[$index]
			if ($line.TrimStart().StartsWith("#")) {
				continue
			}

			foreach ($pattern in $enumValueCastPatterns) {
				if ($line -match $pattern) {
					Add-PolicyIssue `
						-Issues $Issues `
						-Rule "style/no-enum-to-int-cast" `
						-Message "Keep enum values typed as enums instead of casting them to int." `
						-Path $relativePath `
						-Line ($index + 1)
					break
				}
			}

			$trimmedLine = $line.Trim()
			if ($trimmedLine -match '^(?:static\s+)?func\s+[A-Za-z_][A-Za-z0-9_]*\s*\(') {
				$signature = Get-GdscriptFunctionSignature -Lines $lines -StartIndex $index
				foreach ($parameterMatch in $enumParameterPattern.Matches($signature.text)) {
					$lineOffset = ($signature.text.Substring(0, $parameterMatch.Index) -split "`r?`n").Count - 1
					Add-PolicyIssue `
						-Issues $Issues `
						-Rule "style/no-enum-int-parameter" `
						-Message "Use the relevant enum type for '$($parameterMatch.Groups["Name"].Value)' instead of typing the value as int." `
						-Path $relativePath `
						-Line ($index + $lineOffset + 1)
				}
				$index = $signature.end_index
			}
		}
	}
}

function Add-GdscriptPublicDocumentationIssues {
	param(
		[System.Collections.Generic.List[object]] $Issues,
		[string[]] $Files
	)

	foreach ($file in $Files) {
		$relativePath = Get-RelativePath $file
		$lines = Get-Content -LiteralPath $file
		$publicEnumDepth = 0

		for ($index = 0; $index -lt $lines.Count; $index++) {
			$line = $lines[$index]
			$trimmedLine = $line.Trim()
			$lineNumber = $index + 1

			if ($trimmedLine -eq "" -or $trimmedLine.StartsWith("#")) {
				continue
			}

			if ($publicEnumDepth -gt 0) {
				if ($trimmedLine -match '^([A-Z][A-Z0-9_]*)\s*(?:=\s*[^,]+)?\s*,?(?:\s*#.*)?$') {
					$valueName = $Matches[1]
					if (-not (Test-GdscriptMemberDocComment -Lines $lines -Index $index)) {
						Add-PolicyIssue `
							-Issues $Issues `
							-Rule "style/public-enum-value-doc" `
							-Message "Document public enum value '$valueName' with a GDScript ## comment." `
							-Path $relativePath `
							-Line $lineNumber
					}
				}

				$publicEnumDepth += Get-BraceDelta $line
				if ($publicEnumDepth -le 0) {
					$publicEnumDepth = 0
				}
				continue
			}

			$isTopLevel = $line -notmatch '^\s'
			if (-not $isTopLevel) {
				continue
			}

			if ($trimmedLine -match '^(class_name\s+[A-Za-z_][A-Za-z0-9_]*(?:\s+extends\s+[A-Za-z_][A-Za-z0-9_]*)?|extends\s+[A-Za-z_][A-Za-z0-9_]*)\b') {
				if (-not (Test-GdscriptDocCommentAfter -Lines $lines -Index $index)) {
					Add-PolicyIssue `
						-Issues $Issues `
						-Rule "style/public-class-doc" `
						-Message "Document addon script declarations with a GDScript ## class comment immediately after the declaration." `
						-Path $relativePath `
						-Line $lineNumber
				}
				continue
			}

			if ($trimmedLine -match '^signal\s+([A-Za-z_][A-Za-z0-9_]*)\b') {
				$signalName = $Matches[1]
				if (-not $signalName.StartsWith("_") -and -not (Test-GdscriptMemberDocComment -Lines $lines -Index $index)) {
					Add-PolicyIssue `
						-Issues $Issues `
						-Rule "style/public-signal-doc" `
						-Message "Document public signal '$signalName' with a GDScript ## comment." `
						-Path $relativePath `
						-Line $lineNumber
				}
				continue
			}

			if ($trimmedLine -match '^class\s+([A-Za-z_][A-Za-z0-9_]*)\s*:') {
				$innerClassName = $Matches[1]
				if (-not $innerClassName.StartsWith("_") -and -not (Test-GdscriptMemberDocComment -Lines $lines -Index $index)) {
					Add-PolicyIssue `
						-Issues $Issues `
						-Rule "style/public-inner-class-doc" `
						-Message "Document public inner class '$innerClassName' with a GDScript ## comment." `
						-Path $relativePath `
						-Line $lineNumber
				}
				continue
			}

			if ($trimmedLine -match '^enum\s+([A-Za-z_][A-Za-z0-9_]*)\s*\{?') {
				$enumName = $Matches[1]
				$isPublicEnum = -not $enumName.StartsWith("_")
				if ($isPublicEnum -and -not (Test-GdscriptMemberDocComment -Lines $lines -Index $index)) {
					Add-PolicyIssue `
						-Issues $Issues `
						-Rule "style/public-enum-doc" `
						-Message "Document public enum '$enumName' with a GDScript ## comment." `
						-Path $relativePath `
						-Line $lineNumber
				}
				if ($isPublicEnum) {
					$publicEnumDepth = Get-BraceDelta $line
				}
				continue
			}

			$symbolLine = $trimmedLine -replace '^(@[A-Za-z_][A-Za-z0-9_]*(?:\([^)]*\))?\s+)+', ''
			if ($symbolLine -match '^(?:static\s+)?var\s+([A-Za-z_][A-Za-z0-9_]*)\b') {
				$variableName = $Matches[1]
				if (-not $variableName.StartsWith("_") -and -not (Test-GdscriptMemberDocComment -Lines $lines -Index $index)) {
					Add-PolicyIssue `
						-Issues $Issues `
						-Rule "style/public-variable-doc" `
						-Message "Document public variable '$variableName' with a GDScript ## comment." `
						-Path $relativePath `
						-Line $lineNumber
				}
				continue
			}

			if ($symbolLine -match '^const\s+([A-Za-z_][A-Za-z0-9_]*)\b') {
				$constantName = $Matches[1]
				if (-not $constantName.StartsWith("_") -and -not (Test-GdscriptMemberDocComment -Lines $lines -Index $index)) {
					Add-PolicyIssue `
						-Issues $Issues `
						-Rule "style/public-constant-doc" `
						-Message "Document public constant '$constantName' with a GDScript ## comment." `
						-Path $relativePath `
						-Line $lineNumber
				}
				continue
			}

			if ($symbolLine -match '^(?:static\s+)?func\s+([A-Za-z_][A-Za-z0-9_]*)\s*\(') {
				$methodName = $Matches[1]
				if (-not $methodName.StartsWith("_") -and -not (Test-GdscriptMemberDocComment -Lines $lines -Index $index)) {
					Add-PolicyIssue `
						-Issues $Issues `
						-Rule "style/public-method-doc" `
						-Message "Document public method '$methodName' with a GDScript ## comment." `
						-Path $relativePath `
						-Line $lineNumber
				}
			}
		}
	}
}

function Get-DevOnlyReferenceFiles {
	$extensions = @(".cfg", ".gd", ".godot", ".tres", ".tscn")
	$paths = @(
		Resolve-ProjectPath "project.godot",
		Resolve-ProjectPath "export_presets.cfg",
		Resolve-ProjectPath "addons/mimic",
		Resolve-ProjectPath "examples"
	)

	$files = @()
	foreach ($path in $paths) {
		if (-not (Test-Path -LiteralPath $path)) {
			continue
		}

		$item = Get-Item -LiteralPath $path
		if ($item.PSIsContainer) {
			$files += Get-ChildItem -LiteralPath $path -Recurse -File |
				Where-Object { $extensions -contains $_.Extension.ToLowerInvariant() } |
				ForEach-Object { $_.FullName }
		} else {
			$files += $item.FullName
		}
	}

	return [string[]] $files
}

function Get-NormalizedJscpdPath {
	param([string] $Path)

	return $Path.Replace("\", "/")
}

function Assert-JscpdHasNoClones {
	param([string] $ReportPath)

	$report = Get-Content -Raw -LiteralPath $ReportPath | ConvertFrom-Json
	$clones = [System.Collections.Generic.List[string]]::new()
	foreach ($clone in @($report.duplicates)) {
		$firstPath = Get-NormalizedJscpdPath $clone.firstFile.name
		$secondPath = Get-NormalizedJscpdPath $clone.secondFile.name
		$clones.Add(
			"${firstPath}:$($clone.firstFile.start)-$($clone.firstFile.end) ~ " +
			"${secondPath}:$($clone.secondFile.start)-$($clone.secondFile.end)"
		)
	}

	if ($clones.Count -eq 0) {
		Write-Output "jscpd zero-clone gate passed."
		return
	}

	Write-Output "jscpd found $($clones.Count) clone(s):"
	foreach ($clone in $clones) {
		Write-Output $clone
	}
	throw "Duplicate-code gate failed. Refactor clones instead of adding an allowlist."
}

function Invoke-MimicPolicyCheck {
	$issues = [System.Collections.Generic.List[object]]::new()
	$gdFiles = Get-ChildItem `
		-LiteralPath (Resolve-ProjectPath "addons/mimic"), (Resolve-ProjectPath "examples"), (Resolve-ProjectPath "test") `
		-Recurse `
		-File `
		-Filter "*.gd" |
		Where-Object { $_.FullName -notlike "*\addons\gut\*" } |
		ForEach-Object { $_.FullName }
	$addonFiles = $gdFiles | Where-Object { (Get-RelativePath $_).StartsWith("addons/mimic/") }

	Add-RegexPolicyIssues `
		-Issues $issues `
		-Rule "ai/no-string-call-deferred" `
		-Message "Use typed Callable dispatch, such as some_method.call_deferred(args), instead of string-based call_deferred()." `
		-Files $gdFiles `
		-Pattern 'call_deferred\s*\(\s*"'

	Add-RegexPolicyIssues `
		-Issues $issues `
		-Rule "ai/no-direct-gdscript-print" `
		-Message "Remove stray debug print calls; use MimicLog for runtime output and assertions for tests." `
		-Files $gdFiles `
		-Pattern '\b(print|prints|printerr|print_debug|print_rich|print_verbose|printt|printraw)\s*\(' `
		-Exclude @("addons/mimic/debug/mimic_log.gd")

	Add-RawRegexPolicyIssues `
		-Issues $issues `
		-Rule "ai/settings-centralized" `
		-Message "Read and write mimic_multiplayer ProjectSettings through MimicProjectSettings instead of scattering string keys." `
		-Files $addonFiles `
		-Pattern 'ProjectSettings\.(get_setting|set_setting|clear|has_setting)\s*\(\s*"mimic_multiplayer/' `
		-Exclude @("addons/mimic/settings/mimic_project_settings.gd")

	Add-RegexPolicyIssues `
		-Issues $issues `
		-Rule "ai/no-production-preload-addons" `
		-Message "Prefer class_name dependencies in addon code; reserve addon preloads for tests or narrowly justified cases." `
		-Files $addonFiles `
		-Pattern 'preload\s*\(\s*"res://addons/mimic/'

	Add-RegexPolicyIssues `
		-Issues $issues `
		-Rule "ai/no-addon-dev-resource-dependencies" `
		-Message "Addon runtime code must not load docs or tool scripts/resources." `
		-Files $addonFiles `
		-Pattern '\b(load|preload)\s*\(\s*"res://(docs|tools)/'

	Add-RegexPolicyIssues `
		-Issues $issues `
		-Rule "ai/no-custom-spawn-system" `
		-Message "Mimic's current focus excludes custom spawn/despawn behavior; discuss design before adding MultiplayerSpawner logic." `
		-Files $addonFiles `
		-Pattern '\bMultiplayerSpawner\b'

	Add-RegexPolicyIssues `
		-Issues $issues `
		-Rule "ai/no-raw-rpc-layer" `
		-Message "Do not add raw RPC protocols to the addon without an explicit design request; keep the MVP on Godot high-level helpers." `
		-Files $addonFiles `
		-Pattern '(^|\s)@rpc\b|\brpc(_id)?\s*\('

	Add-GdscriptShadowedBaseClassIssues -Issues $issues -Files $gdFiles
	Add-GdscriptInferredCastDeclarationIssues -Issues $issues -Files $gdFiles
	Add-GdscriptRedundantEnumCastDeclarationIssues -Issues $issues -Files $gdFiles
	Add-GdscriptEnumIntIssues -Issues $issues -Files $gdFiles
	Add-GdscriptPublicDocumentationIssues -Issues $issues -Files $addonFiles

	Add-RawRegexPolicyIssues `
		-Issues $issues `
		-Rule "dev/no-quality-runtime-reference" `
		-Message "Quality tooling must not be referenced by project settings, export presets, scenes, resources, or runtime code." `
		-Files (Get-DevOnlyReferenceFiles) `
		-Pattern 'tools/(quality|\.bin)|quality\.ps1|jscpd|gdcruiser|gdstyle|test[/\\]\.output[/\\]quality'

	if (-not (Test-Path -LiteralPath (Join-Path $repoRoot "tools/.gdignore"))) {
		Add-PolicyIssue `
			-Issues $issues `
			-Rule "dev/export-boundary" `
			-Message "tools/.gdignore must exist so quality scripts stay out of Godot's resource scan." `
			-Path "tools/.gdignore"
	}

	$policyJsonPath = Join-Path $resolvedOutputDir "mimic-policy.json"
	[object[]] $policyIssueArray = $issues.ToArray()
	ConvertTo-Json -InputObject $policyIssueArray -Depth 4 |
		Set-Content -LiteralPath $policyJsonPath -Encoding UTF8

	if ($issues.Count -eq 0) {
		Write-Output "Mimic AI policy check passed."
		return
	}

	Write-Output "Mimic AI policy check found $($issues.Count) issue(s):"
	foreach ($issue in $issues) {
		Write-Output "$($issue.path):$($issue.line) [$($issue.severity)] $($issue.rule): $($issue.message)"
	}
	throw "Mimic AI policy check failed. See $(Get-RelativePath $policyJsonPath)."
}

function Invoke-PowerShellSyntaxCheck {
	$issues = [System.Collections.Generic.List[object]]::new()
	$scriptFiles = Get-ChildItem `
		-LiteralPath (Resolve-ProjectPath "tools") `
		-Recurse `
		-File `
		-Filter "*.ps1" |
		Where-Object { $_.FullName -notlike "*\tools\.bin\*" } |
		ForEach-Object { $_.FullName }

	foreach ($scriptFile in $scriptFiles) {
		$tokens = $null
		$parseErrors = $null
		[System.Management.Automation.Language.Parser]::ParseFile(
			$scriptFile,
			[ref] $tokens,
			[ref] $parseErrors
		) | Out-Null

		foreach ($parseError in $parseErrors) {
			Add-PolicyIssue `
				-Issues $issues `
				-Rule "dev/powershell-syntax" `
				-Message $parseError.Message `
				-Path (Get-RelativePath $scriptFile) `
				-Line $parseError.Extent.StartLineNumber
		}
	}

	$syntaxJsonPath = Join-Path $resolvedOutputDir "powershell-syntax.json"
	[object[]] $syntaxIssueArray = $issues.ToArray()
	ConvertTo-Json -InputObject $syntaxIssueArray -Depth 4 |
		Set-Content -LiteralPath $syntaxJsonPath -Encoding UTF8

	if ($issues.Count -eq 0) {
		Write-Output "PowerShell syntax check passed for $($scriptFiles.Count) script(s)."
		return
	}

	Write-Output "PowerShell syntax check found $($issues.Count) issue(s):"
	foreach ($issue in $issues) {
		Write-Output "$($issue.path):$($issue.line) [$($issue.severity)] $($issue.rule): $($issue.message)"
	}
	throw "PowerShell syntax check failed. See $(Get-RelativePath $syntaxJsonPath)."
}

if (-not $SkipPolicyCheck) {
	Invoke-MimicPolicyCheck
} else {
	Write-Output "Skipping Mimic AI policy check."
}

if (-not $SkipPowerShellSyntaxCheck) {
	Invoke-PowerShellSyntaxCheck
} else {
	Write-Output "Skipping PowerShell syntax check."
}

if (-not $SkipDuplicateCheck) {
	$jscpd = Resolve-Jscpd

	$jscpdOutput = Join-Path $resolvedOutputDir "jscpd"
	New-Item -ItemType Directory -Force -Path $jscpdOutput | Out-Null
	$jscpdReportPath = Join-Path $jscpdOutput "jscpd-report.json"
	# jscpd's threshold controls its own exit code; Mimic enforces clone policy from JSON.
	$jscpdArgs = @(
		"--reporters",
		"console,ai,json",
		"--output",
		$jscpdOutput,
		"--min-lines",
		[string] $DuplicateMinLines,
		"--min-tokens",
		[string] $DuplicateMinTokens,
		"--threshold",
		"100",
		"--formats-exts",
		"gdscript:gd",
		"--ignore",
		"**/addons/gut/**,**/.godot/**,**/build/**,**/docs/api/**,**/test/.output/**,**/tools/.bin/**",
		"--noTips"
	) + $projectPaths

	Invoke-CheckedCommand `
		-Label "Running jscpd duplicate-code check with zero-clone policy..." `
		-Command $jscpd `
		-Arguments $jscpdArgs
	Assert-JscpdHasNoClones -ReportPath $jscpdReportPath
} else {
	Write-Output "Skipping duplicate-code check."
}

if (-not $SkipDependencyCheck) {
	$gdcruiser = Resolve-Gdcruiser
	if ([string]::IsNullOrWhiteSpace($gdcruiser)) {
		Write-Output "gdcruiser was not found. Run tools/quality.ps1 -BootstrapTools to enable the dependency architecture check locally."
	} else {
		$gdcruiserJsonPath = Join-Path $resolvedOutputDir "gdcruiser.json"
		$gdcruiserArgs = @(
			".",
			"--config",
			$gdcruiserConfig,
			"-f",
			"json",
			"-o",
			$gdcruiserJsonPath
		)

		Write-Output "Running gdcruiser dependency architecture check with $(Get-RelativePath $gdcruiserConfig)..."
		$gdcruiserExit = Invoke-GdcruiserCommand -GdcruiserPath $gdcruiser -Arguments $gdcruiserArgs
		if ($gdcruiserExit -ne 0) {
			throw "gdcruiser dependency check failed with exit code $gdcruiserExit. See $(Get-RelativePath $gdcruiserJsonPath)."
		}

		$dependencyReport = Get-Content -Raw -LiteralPath $gdcruiserJsonPath | ConvertFrom-Json
		$cycleCount = @($dependencyReport.cycles).Count
		$errorCount = @($dependencyReport.errors).Count
		Write-Output "gdcruiser checked $($dependencyReport.graph.stats.module_count) module(s), $($dependencyReport.graph.stats.dependency_count) dependency edge(s), $cycleCount cycle(s), and $errorCount parser error(s)."
		if ($errorCount -gt 0) {
			Write-Output "gdcruiser parser errors:"
			@($dependencyReport.errors) |
				Select-Object -First 5 |
				ForEach-Object {
					Write-Output ($_ | ConvertTo-Json -Compress -Depth 6)
				}
			throw "gdcruiser reported $errorCount parser error(s). See $(Get-RelativePath $gdcruiserJsonPath)."
		}
	}
} else {
	Write-Output "Skipping dependency architecture check."
}

if (-not $SkipGdstyle) {
	$gdstyle = Resolve-Gdstyle
	if ([string]::IsNullOrWhiteSpace($gdstyle)) {
		Write-Output "gdstyle was not found. Run tools/quality.ps1 -BootstrapTools to enable the GDScript style gate locally."
	} else {
		Assert-GdstyleVersion $gdstyle
		$gdstyleJsonPath = Join-Path $resolvedOutputDir "gdstyle.json"
		$gdstyleArgs = @(
			"check",
			"--config",
			$gdstyleConfig,
			"--format",
			"json",
			"--no-color"
		) + $projectPaths

		Write-Output "Running gdstyle check with $(Get-RelativePath $gdstyleConfig)..."
		Push-Location $repoRoot
		try {
			$gdstyleOutput = & $gdstyle @gdstyleArgs
			$gdstyleExit = $LASTEXITCODE
		} finally {
			Pop-Location
		}
		$gdstyleText = ($gdstyleOutput -join "`n")
		Set-Content -LiteralPath $gdstyleJsonPath -Value $gdstyleText -Encoding UTF8
		if ($gdstyleExit -ne 0) {
			throw "gdstyle check failed with exit code $gdstyleExit. See $(Get-RelativePath $gdstyleJsonPath)."
		}
		$gdstyleDiagnostics = @()
		if (-not [string]::IsNullOrWhiteSpace($gdstyleText)) {
			$convertedDiagnostics = $gdstyleText | ConvertFrom-Json
			if ($convertedDiagnostics -is [System.Array]) {
				$gdstyleDiagnostics = $convertedDiagnostics
			} else {
				$gdstyleDiagnostics = @($convertedDiagnostics)
			}
		}
		$blockingGdstyleDiagnostics = @(
			$gdstyleDiagnostics | Where-Object {
				($gdstyleBlockingRules -contains [string]$_.rule) -or
				([string]$_.severity -eq "error")
			}
		)
		if ($blockingGdstyleDiagnostics.Count -gt 0) {
			Write-Output "gdstyle reported $($blockingGdstyleDiagnostics.Count) blocking diagnostic(s). Full report: $(Get-RelativePath $gdstyleJsonPath)."
			$blockingGdstyleDiagnostics |
				Select-Object -First 8 |
				ForEach-Object {
					Write-Output "$($_.file):$($_.span.line) [$($_.rule)] $($_.message)"
				}
			if ($blockingGdstyleDiagnostics.Count -gt 8) {
				Write-Output "...and $($blockingGdstyleDiagnostics.Count - 8) more blocking diagnostic(s)."
			}
			throw "gdstyle blocking diagnostics found. See $(Get-RelativePath $gdstyleJsonPath)."
		}
		if ($gdstyleDiagnostics.Count -gt 0) {
			Write-Output "gdstyle reported $($gdstyleDiagnostics.Count) advisory diagnostic(s). Full report: $(Get-RelativePath $gdstyleJsonPath)."
			$gdstyleDiagnostics |
				Select-Object -First 8 |
				ForEach-Object {
					Write-Output "$($_.file):$($_.span.line) [$($_.rule)] $($_.message)"
				}
			if ($gdstyleDiagnostics.Count -gt 8) {
				Write-Output "...and $($gdstyleDiagnostics.Count - 8) more advisory diagnostic(s)."
			}
		} else {
			Write-Output "gdstyle reported no diagnostics."
		}

		if ($StrictGdstyle) {
			$gdstyleFmtArgs = @(
				"fmt",
				"--check",
				"--config",
				$gdstyleConfig,
				"--no-color"
			) + $projectPaths
			Invoke-CheckedCommand `
				-Label "Running strict gdstyle formatting check..." `
				-Command $gdstyle `
				-Arguments $gdstyleFmtArgs
		}
	}
} else {
	Write-Output "Skipping gdstyle check."
}

Write-Output "Mimic quality checks completed."

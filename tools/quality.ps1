param(
	[double] $DuplicateThreshold = 2.0,
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
$gdstyleVersion = "v0.1.4"
$gdcruiserVersion = "1.7.0"
$gdstyleConfig = Join-Path $qualityRoot "gdstyle.toml"
$gdcruiserConfig = Join-Path $qualityRoot "gdcruiser.json"
$jscpdBaselinePath = Join-Path $qualityRoot "jscpd_baseline.json"
$jscpdPackageRoot = $qualityRoot
$projectPaths = @("addons/mimic", "examples", "test")
$gdstyleBlockingRules = @(
	"quality/type-hint"
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
			Sha256 = "9cf3e7bf5ab56ac0e2a568c11f1184dfed87450e0069a053d73f78538a7fb05f"
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
				Sha256 = "6c46b740ffee6224fa299c3fc9d9e2e643ca58135f30e7aefbd68a44e14e8634"
			}
		}
		return @{
			Name = "gdstyle-x86_64-apple-darwin.tar.gz"
			Sha256 = "cb470f366334301821573a5e1517927a4780d268a45f4785483474f247ef8e9e"
		}
	}
	return @{
		Name = "gdstyle-x86_64-unknown-linux-gnu.tar.gz"
		Sha256 = "84c518c023d797e82cf6fc21ba9deb1a6abdf74cd7016cba9421efc420f0a299"
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
	if ($versionOutput -notmatch "0\.1\.4") {
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

function Get-Sha256Text {
	param([string] $Text)

	$bytes = [System.Text.Encoding]::UTF8.GetBytes($Text)
	$sha256 = [System.Security.Cryptography.SHA256]::Create()
	try {
		$hashBytes = $sha256.ComputeHash($bytes)
		return [System.BitConverter]::ToString($hashBytes).Replace("-", "").ToLowerInvariant()
	} finally {
		$sha256.Dispose()
	}
}

function Get-NormalizedJscpdPath {
	param([string] $Path)

	return $Path.Replace("\", "/")
}

function Get-JscpdCloneFingerprint {
	param([object] $Clone)

	$paths = @(
		(Get-NormalizedJscpdPath $Clone.firstFile.name),
		(Get-NormalizedJscpdPath $Clone.secondFile.name)
	) | Sort-Object
	$fragmentHash = Get-Sha256Text ([string] $Clone.fragment)
	return "$($paths[0])|$($paths[1])|$fragmentHash"
}

function Assert-JscpdBaseline {
	param([string] $ReportPath)

	if (-not (Test-Path -LiteralPath $jscpdBaselinePath)) {
		throw "jscpd baseline file is missing at $(Get-RelativePath $jscpdBaselinePath)."
	}

	$baseline = Get-Content -Raw -LiteralPath $jscpdBaselinePath | ConvertFrom-Json
	$allowedFingerprints = [System.Collections.Generic.HashSet[string]]::new()
	foreach ($allowedClone in @($baseline.allowedClones)) {
		$paths = @(
			(Get-NormalizedJscpdPath $allowedClone.firstFile),
			(Get-NormalizedJscpdPath $allowedClone.secondFile)
		) | Sort-Object
		[void] $allowedFingerprints.Add("$($paths[0])|$($paths[1])|$($allowedClone.fragmentSha256)")
	}

	$report = Get-Content -Raw -LiteralPath $ReportPath | ConvertFrom-Json
	$unexpectedClones = [System.Collections.Generic.List[string]]::new()
	foreach ($clone in @($report.duplicates)) {
		$fingerprint = Get-JscpdCloneFingerprint $clone
		if (-not $allowedFingerprints.Contains($fingerprint)) {
			$firstPath = Get-NormalizedJscpdPath $clone.firstFile.name
			$secondPath = Get-NormalizedJscpdPath $clone.secondFile.name
			$unexpectedClones.Add(
				"${firstPath}:$($clone.firstFile.start)-$($clone.firstFile.end) ~ " +
				"${secondPath}:$($clone.secondFile.start)-$($clone.secondFile.end)"
			)
		}
	}

	if ($unexpectedClones.Count -eq 0) {
		Write-Output "jscpd baseline ratchet passed with $(@($report.duplicates).Count) known clone(s)."
		return
	}

	Write-Output "jscpd found $($unexpectedClones.Count) unapproved clone(s):"
	foreach ($unexpectedClone in $unexpectedClones) {
		Write-Output $unexpectedClone
	}
	throw "Duplicate-code ratchet failed. Refactor new clones or update $(Get-RelativePath $jscpdBaselinePath) with an intentional baseline change."
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
		-Rule "ai/no-direct-addon-print" `
		-Message "Remove stray debug print calls; use MimicLog for addon runtime output." `
		-Files $gdFiles `
		-Pattern '\b(print|prints|printerr|print_rich|print_verbose|printt|printraw)\s*\(' `
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
		[string] $DuplicateThreshold,
		"--formats-exts",
		"gdscript:gd",
		"--ignore",
		"**/addons/gut/**,**/.godot/**,**/build/**,**/docs/api/**,**/test/.output/**,**/tools/.bin/**",
		"--noTips"
	) + $projectPaths

	Invoke-CheckedCommand `
		-Label "Running jscpd duplicate-code check at <= $DuplicateThreshold% duplication..." `
		-Command $jscpd `
		-Arguments $jscpdArgs
	Assert-JscpdBaseline -ReportPath $jscpdReportPath
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

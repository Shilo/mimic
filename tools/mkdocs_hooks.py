"""MkDocs hooks for generated Mimic documentation."""

from __future__ import annotations

import os
import platform
import shutil
import shlex
import subprocess
import sys
import time
from pathlib import Path


def on_pre_build(config, **kwargs):
	root = Path(config.config_file_path).resolve().parent
	build_dir = root / "build"
	build_dir.mkdir(parents=True, exist_ok=True)
	(build_dir / ".gdignore").write_text("", encoding="utf-8")
	xml_dir = build_dir / "api_xml"
	api_dir = root / "docs" / "api"

	if xml_dir.exists():
		shutil.rmtree(xml_dir)
	xml_dir.mkdir(parents=True, exist_ok=True)

	godot_command = _get_godot_command(root)
	subprocess.run(
		[
			*godot_command,
			"--headless",
			"--path",
			str(root),
			"--doctool",
			str(xml_dir),
			"--no-docbase",
			"--gdscript-docs",
			"res://addons/mimic",
		],
		cwd=root,
		check=True,
	)
	_wait_for_expected_xml(xml_dir)

	subprocess.run(
		[
			sys.executable,
			str(root / "tools" / "generate_api_docs.py"),
			"--xml-dir",
			str(xml_dir),
			"--output-dir",
			str(api_dir),
		],
		cwd=root,
		check=True,
	)


def on_post_build(config, **kwargs):
	root = Path(config.config_file_path).resolve().parent
	site_dir = Path(config["site_dir"]).resolve()
	_copy_brand_assets(root, site_dir)


def _copy_brand_assets(root: Path, site_dir: Path) -> None:
	source_dir = root / "brand"
	target_dir = site_dir / "brand"

	if target_dir.exists():
		shutil.rmtree(target_dir)

	for source_path in source_dir.rglob("*"):
		if not source_path.is_file() or source_path.suffix.lower() not in {".svg", ".png"}:
			continue
		relative_path = source_path.relative_to(source_dir)
		target_path = target_dir / relative_path
		target_path.parent.mkdir(parents=True, exist_ok=True)
		shutil.copy2(source_path, target_path)


def _get_godot_command(root: Path) -> list[str]:
	command_override = os.environ.get("MIMIC_GODOT_COMMAND", "").strip()
	if command_override:
		return shlex.split(command_override, posix=platform.system() != "Windows")

	env_path = os.environ.get("MIMIC_GODOT_PATH") or os.environ.get("GODOT_PATH")
	if env_path:
		resolved_env_path = _resolve_executable(env_path)
		if resolved_env_path:
			return [resolved_env_path]

	if platform.system() == "Windows":
		powershell = (
			shutil.which("powershell.exe")
			or shutil.which("powershell")
			or shutil.which("pwsh.exe")
			or shutil.which("pwsh")
		)
		if not powershell:
			raise RuntimeError("PowerShell was not found on PATH, so tools/godot.ps1 cannot run.")
		return [
			powershell,
			"-NoProfile",
			"-ExecutionPolicy",
			"Bypass",
			"-File",
			str(root / "tools" / "godot.ps1"),
		]

	return ["godot"]


def _resolve_executable(candidate: str) -> str:
	candidate_path = Path(candidate)
	if candidate_path.exists():
		return str(candidate_path)
	found_path = shutil.which(candidate)
	return found_path or ""


def _wait_for_expected_xml(xml_dir: Path) -> None:
	expected_paths = [xml_dir / f"{class_name}.xml" for class_name in ("Mimic", "MimicConnector", "MimicSync", "MimicProjectSettings")]
	for _ in range(50):
		if all(path.exists() for path in expected_paths):
			return
		time.sleep(0.1)

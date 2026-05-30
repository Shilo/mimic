#!/usr/bin/env python3
"""Generate Markdown API pages from Godot doctool XML."""

from __future__ import annotations

import argparse
import html
import re
import sys
import textwrap
import xml.etree.ElementTree as ET
from dataclasses import dataclass
from pathlib import Path


CLASS_PAGES = {
	"Mimic": "mimic.md",
	"MimicConnector": "mimic_connector.md",
	"MimicSync": "mimic_sync.md",
	"MimicProjectSettings": "mimic_project_settings.md",
}

SECTION_ORDER = ["Methods", "Signals", "Properties", "Enumerations", "Constants"]


@dataclass(frozen=True)
class ApiClass:
	name: str
	inherits: str
	brief: str
	description: str
	methods: list[ET.Element]
	signals: list[ET.Element]
	members: list[ET.Element]
	constants: list[ET.Element]


def main() -> int:
	parser = argparse.ArgumentParser(description=__doc__)
	parser.add_argument("--xml-dir", required=True, type=Path)
	parser.add_argument("--output-dir", required=True, type=Path)
	args = parser.parse_args()

	classes = []
	for class_name in CLASS_PAGES:
		xml_path = args.xml_dir / f"{class_name}.xml"
		if not xml_path.exists():
			raise FileNotFoundError(f"Expected Godot API XML at {xml_path}")
		classes.append(_read_class(xml_path))

	args.output_dir.mkdir(parents=True, exist_ok=True)
	for stale_page in args.output_dir.glob("*.md"):
		stale_page.unlink()

	for api_class in classes:
		page_path = args.output_dir / CLASS_PAGES[api_class.name]
		page_path.write_text(_render_class_page(api_class), encoding="utf-8")

	index_path = args.output_dir / "index.md"
	index_path.write_text(_render_index(classes), encoding="utf-8")
	return 0


def _read_class(xml_path: Path) -> ApiClass:
	root = ET.parse(xml_path).getroot()
	return ApiClass(
		name=root.attrib["name"],
		inherits=root.attrib.get("inherits", ""),
		brief=_clean_text(root.findtext("brief_description", "")),
		description=_clean_text(root.findtext("description", "")),
		methods=_public_children(root, "methods", "method"),
		signals=_public_children(root, "signals", "signal"),
		members=_public_children(root, "members", "member"),
		constants=_public_children(root, "constants", "constant"),
	)


def _public_children(root: ET.Element, section: str, tag: str) -> list[ET.Element]:
	parent = root.find(section)
	if parent is None:
		return []

	children = []
	for child in parent.findall(tag):
		name = child.attrib.get("name", "")
		enum_name = child.attrib.get("enum", "")
		if name.startswith("_") or enum_name.startswith("_") or "._" in enum_name:
			continue
		if tag in {"method", "member"} and not _clean_text(child.findtext("description", child.text or "")):
			if tag == "method":
				continue
		children.append(child)
	return children


def _render_index(classes: list[ApiClass]) -> str:
	lines = [
		"# API Reference",
		"",
		"Auto-generated from Godot `##` documentation comments. Do not edit these files by hand.",
		"",
		"The pages in this section are rebuilt from the GDScript classes in `addons/mimic/` during every documentation build.",
		"",
		"| Class | Summary |",
		"| --- | --- |",
	]
	for api_class in classes:
		page_name = CLASS_PAGES[api_class.name]
		summary = api_class.brief.split("\n\n", 1)[0] if api_class.brief else ""
		lines.append(f"| [{api_class.name}]({page_name}) | {summary} |")
	lines.append("")
	return "\n".join(lines)


def _render_class_page(api_class: ApiClass) -> str:
	lines = [
		f"# {api_class.name}",
		"",
		"Auto-generated from Godot `##` documentation comments. Do not edit by hand.",
		"",
	]

	if api_class.inherits:
		lines.extend([f"**Inherits:** `{api_class.inherits}`", ""])

	if api_class.brief:
		lines.extend([api_class.brief, ""])
	if api_class.description:
		lines.extend([api_class.description, ""])

	overview = _render_overview(api_class)
	if overview:
		lines.extend(overview)

	sections = {
		"Methods": _render_methods(api_class.methods),
		"Signals": _render_signals(api_class.signals),
		"Properties": _render_members(api_class.members),
		"Enumerations": _render_enums(api_class.constants),
		"Constants": _render_constants(api_class.constants),
	}

	for section_name in SECTION_ORDER:
		section_lines = sections[section_name]
		if section_lines:
			lines.extend(["", f"## {section_name}", "", *section_lines])

	lines.append("")
	return "\n".join(lines)


def _render_overview(api_class: ApiClass) -> list[str]:
	rows = []
	if api_class.methods:
		rows.append(("Methods", len(api_class.methods)))
	if api_class.signals:
		rows.append(("Signals", len(api_class.signals)))
	if api_class.members:
		rows.append(("Properties", len(api_class.members)))
	public_enums = _group_enum_constants(api_class.constants)
	if public_enums:
		rows.append(("Enumerations", len(public_enums)))
	plain_constants = [constant for constant in api_class.constants if not constant.attrib.get("enum")]
	if plain_constants:
		rows.append(("Constants", len(plain_constants)))
	if not rows:
		return []

	lines = ["| Section | Count |", "| --- | ---: |"]
	for label, count in rows:
		lines.append(f"| {label} | {count} |")
	lines.append("")
	return lines


def _render_methods(methods: list[ET.Element]) -> list[str]:
	lines = []
	for method in methods:
		lines.extend([f"### `{_method_signature(method)}`", ""])
		description = _clean_text(method.findtext("description", ""))
		if description:
			lines.extend([description, ""])
	return lines


def _render_signals(signals: list[ET.Element]) -> list[str]:
	lines = []
	for signal in signals:
		lines.extend([f"### `{_signal_signature(signal)}`", ""])
		description = _clean_text(signal.findtext("description", ""))
		if description:
			lines.extend([description, ""])
	return lines


def _render_members(members: list[ET.Element]) -> list[str]:
	lines = []
	for member in members:
		lines.extend([f"### `{_member_signature(member)}`", ""])
		description = _clean_text(member.text or "")
		if description:
			lines.extend([description, ""])
	return lines


def _render_enums(constants: list[ET.Element]) -> list[str]:
	lines = []
	for enum_name, enum_constants in _group_enum_constants(constants).items():
		lines.extend([f"### `{enum_name}`", "", "| Value | Description |", "| --- | --- |"])
		for constant in enum_constants:
			value = constant.attrib.get("value", "")
			description = _clean_text(constant.text or "")
			lines.append(f"| `{constant.attrib['name']} = {value}` | {description} |")
		lines.append("")
	return lines


def _render_constants(constants: list[ET.Element]) -> list[str]:
	lines = []
	for constant in constants:
		if constant.attrib.get("enum"):
			continue
		lines.extend([f"### `{constant.attrib['name']}`", ""])
		value = constant.attrib.get("value", "")
		if value:
			lines.extend([f"Value: `{html.unescape(value)}`", ""])
		description = _clean_text(constant.text or "")
		if description:
			lines.extend([description, ""])
	return lines


def _group_enum_constants(constants: list[ET.Element]) -> dict[str, list[ET.Element]]:
	grouped: dict[str, list[ET.Element]] = {}
	for constant in constants:
		enum_name = constant.attrib.get("enum", "")
		if not enum_name or enum_name.startswith("_") or "._" in enum_name:
			continue
		if "." in enum_name:
			enum_name = enum_name.rsplit(".", 1)[-1]
		grouped.setdefault(enum_name, []).append(constant)
	return grouped


def _method_signature(method: ET.Element) -> str:
	prefix = "static func" if "static" in method.attrib.get("qualifiers", "") else "func"
	params = ", ".join(_param_signature(param) for param in method.findall("param"))
	return_type = _typed_name(method.find("return"))
	if return_type and return_type != "void":
		return f"{prefix} {method.attrib['name']}({params}) -> {return_type}"
	return f"{prefix} {method.attrib['name']}({params})"


def _signal_signature(signal: ET.Element) -> str:
	params = ", ".join(_param_signature(param, include_defaults=False) for param in signal.findall("param"))
	return f"signal {signal.attrib['name']}({params})"


def _member_signature(member: ET.Element) -> str:
	name = member.attrib["name"]
	member_type = _typed_name(member)
	default = html.unescape(member.attrib.get("default", ""))
	signature = f"var {name}"
	if member_type:
		signature += f": {member_type}"
	if default:
		signature += f" = {default}"
	return signature


def _param_signature(param: ET.Element, include_defaults: bool = True) -> str:
	signature = param.attrib["name"]
	param_type = _typed_name(param)
	if param_type:
		signature += f": {param_type}"
	if include_defaults and "default" in param.attrib:
		signature += f" = {html.unescape(param.attrib['default'])}"
	return signature


def _typed_name(element: ET.Element | None) -> str:
	if element is None:
		return ""
	return html.unescape(element.attrib.get("enum") or element.attrib.get("type") or "")


def _clean_text(raw_text: str) -> str:
	text = html.unescape(raw_text or "")
	text = textwrap.dedent(text)
	text = "\n".join(line.strip() for line in text.splitlines()).strip()
	if not text:
		return ""

	text = re.sub(r"\[br\s*/?\]\s*\[br\s*/?\]", "\n\n", text)
	text = re.sub(r"\[br\s*/?\]", "\n", text)
	text = re.sub(r"\[code\](.*?)\[/code\]", lambda match: f"`{match.group(1)}`", text, flags=re.DOTALL)
	text = re.sub(r"\[(param|member|signal|enum|constant)\s+([^\]]+)\]", _code_ref, text)
	text = re.sub(r"\[method\s+([^\]]+)\]", lambda match: f"`{match.group(1)}()`", text)
	text = re.sub(r"\[([A-Za-z_][A-Za-z0-9_.]*)\]", lambda match: f"`{match.group(1)}`", text)
	text = re.sub(r"\[/?[a-zA-Z0-9_ =\".,:-]+\]", "", text)
	text = re.sub(r"[ \t]+\n", "\n", text)
	text = re.sub(r"\n{3,}", "\n\n", text)
	return text.strip()


def _code_ref(match: re.Match[str]) -> str:
	kind = match.group(1)
	name = match.group(2)
	if kind == "signal":
		return f"`{name}`"
	return f"`{name}`"


if __name__ == "__main__":
	try:
		raise SystemExit(main())
	except Exception as error:
		print(f"API documentation generation failed: {error}", file=sys.stderr)
		raise

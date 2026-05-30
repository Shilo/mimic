#!/usr/bin/env python3
"""Audit Mimic documentation color contrast pairs."""

from __future__ import annotations

from dataclasses import dataclass


AA_NORMAL = 4.5
AA_UI = 3.0


COLORS = {
	"mint": "#65E6B8",
	"mint_hover": "#4FD9A8",
	"mint_text": "#167E62",
	"mint_text_hover": "#007F60",
	"link_light": "#005F73",
	"link_light_hover": "#004D5C",
	"ink": "#10212B",
	"ink_deep": "#08141B",
	"ink_lifted": "#18313F",
	"muted": "#49616B",
	"page": "#FAFCFB",
	"soft_mint": "#E9FFF7",
	"border": "#DDE8E5",
	"border_strong": "#167E62",
	"dark_page": "#0E1B22",
	"dark_code": "#142933",
	"dark_callout": "#112A24",
	"dark_border": "#245647",
	"white_mint": "#F5FFFB",
	"dark_text": "#EAF8F3",
	"dark_muted": "#B8CCC5",
	"light_code": "#EEF7F4",
}
COLORS["search_idle"] = "#5CD2AA"
COLORS["search_idle_hover"] = "#59CAA4"
COLORS["dark_mint_hover"] = "#1E4142"


@dataclass(frozen=True)
class Pair:
	name: str
	foreground: str
	background: str
	minimum: float = AA_NORMAL


PAIRS = [
	Pair("light body text", "ink", "page"),
	Pair("light muted text", "muted", "page"),
	Pair("light heading text", "ink", "page"),
	Pair("light content links", "link_light", "page"),
	Pair("light content link hover", "link_light_hover", "page"),
	Pair("light inline code", "ink", "light_code"),
	Pair("light header title/icons/source", "ink", "mint"),
	Pair("light header bottom border", "ink", "mint", AA_UI),
	Pair("light search idle text/icons", "ink", "search_idle"),
	Pair("light search idle hover text/icons", "ink", "search_idle_hover"),
	Pair("light search idle border", "ink", "search_idle", AA_UI),
	Pair("light search focus text/icons", "ink", "white_mint"),
	Pair("light search focus border", "ink", "white_mint", AA_UI),
	Pair("light search results meta", "ink", "soft_mint"),
	Pair("light search result title/body", "ink", "white_mint"),
	Pair("light search result teaser", "muted", "white_mint"),
	Pair("light search result mark", "mint_text_hover", "white_mint"),
	Pair("light search result hover text", "ink", "soft_mint"),
	Pair("light primary button text", "ink", "mint"),
	Pair("light primary button hover text", "ink", "mint_hover"),
	Pair("light top button text", "ink", "mint"),
	Pair("light top button hover text", "mint", "ink"),
	Pair("light secondary button text", "ink", "page"),
	Pair("light secondary button border", "ink", "page", AA_UI),
	Pair("light secondary button hover text", "ink", "soft_mint"),
	Pair("light secondary button hover border", "ink", "soft_mint", AA_UI),
	Pair("light nav section text", "ink", "page"),
	Pair("light primary nav title text", "ink", "mint"),
	Pair("light nav section border", "border_strong", "page", AA_UI),
	Pair("light nav active/hover text", "mint_text_hover", "page"),
	Pair("light callout text", "ink", "soft_mint"),
	Pair("light callout border", "border_strong", "soft_mint", AA_UI),
	Pair("light footer text", "ink", "page"),
	Pair("light footer link", "link_light", "page"),
	Pair("dark body text", "dark_text", "dark_page"),
	Pair("dark muted text", "dark_muted", "dark_page"),
	Pair("dark heading text", "dark_text", "dark_page"),
	Pair("dark content links", "mint", "dark_page"),
	Pair("dark content link hover", "mint_hover", "dark_page"),
	Pair("dark inline code", "dark_text", "dark_code"),
	Pair("dark header title/icons/source", "ink", "mint"),
	Pair("dark header bottom border", "ink", "mint", AA_UI),
	Pair("dark search idle text/icons", "ink", "search_idle"),
	Pair("dark search idle hover text/icons", "ink", "search_idle_hover"),
	Pair("dark search idle border", "ink", "search_idle", AA_UI),
	Pair("dark search focus text/icons", "white_mint", "ink"),
	Pair("dark search focus border", "mint", "ink", AA_UI),
	Pair("dark search results meta", "white_mint", "ink_lifted"),
	Pair("dark search result title/body", "white_mint", "ink"),
	Pair("dark search result teaser", "dark_muted", "ink"),
	Pair("dark search result mark", "mint", "ink"),
	Pair("dark search result hover body", "white_mint", "dark_mint_hover"),
	Pair("dark primary button text", "ink", "mint"),
	Pair("dark primary button hover text", "ink", "mint_hover"),
	Pair("dark top button text", "ink", "mint"),
	Pair("dark top button hover text", "mint", "ink"),
	Pair("dark secondary button text", "mint", "dark_page"),
	Pair("dark secondary button border", "mint", "dark_page", AA_UI),
	Pair("dark secondary button hover text", "mint", "dark_mint_hover"),
	Pair("dark secondary button hover border", "mint", "dark_mint_hover", AA_UI),
	Pair("dark nav section text", "mint", "dark_page"),
	Pair("dark primary nav title text", "ink", "mint"),
	Pair("dark nav section border", "mint", "dark_page", AA_UI),
	Pair("dark nav active/hover text", "mint", "dark_page"),
	Pair("dark callout text", "dark_text", "dark_callout"),
	Pair("dark callout border", "mint", "dark_callout", AA_UI),
	Pair("dark footer text", "dark_text", "dark_page"),
	Pair("dark footer link", "mint", "dark_page"),
]


def main() -> int:
	failures = []
	for pair in PAIRS:
		ratio = contrast(COLORS[pair.foreground], COLORS[pair.background])
		status = "PASS" if ratio >= pair.minimum else "FAIL"
		print(f"{status} {ratio:5.2f}:1 >= {pair.minimum:3.1f}:1  {pair.name}")
		if status == "FAIL":
			failures.append(pair)

	if failures:
		print(f"\n{len(failures)} contrast pair(s) failed.")
		return 1

	print(f"\nAll {len(PAIRS)} contrast pairs pass.")
	return 0


def contrast(foreground: str, background: str) -> float:
	foreground_luminance = luminance(foreground)
	background_luminance = luminance(background)
	lighter = max(foreground_luminance, background_luminance)
	darker = min(foreground_luminance, background_luminance)
	return (lighter + 0.05) / (darker + 0.05)


def luminance(hex_color: str) -> float:
	red, green, blue = _rgb(hex_color)
	red, green, blue = _channel(red), _channel(green), _channel(blue)
	return 0.2126 * red + 0.7152 * green + 0.0722 * blue


def _rgb(hex_color: str) -> tuple[float, float, float]:
	hex_color = hex_color.removeprefix("#")
	return (
		int(hex_color[0:2], 16) / 255.0,
		int(hex_color[2:4], 16) / 255.0,
		int(hex_color[4:6], 16) / 255.0,
	)


def _channel(value: float) -> float:
	if value <= 0.03928:
		return value / 12.92
	return ((value + 0.055) / 1.055) ** 2.4


if __name__ == "__main__":
	raise SystemExit(main())

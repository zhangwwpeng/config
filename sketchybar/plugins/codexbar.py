#!/usr/bin/env python3
"""sketchybar plugin: show CodexBar token-plan usage in the bar.

It reads a cached snapshot of `codexbar usage --format json` and, when the
snapshot is stale, kicks off a background refresh that re-triggers sketchybar
once fresh data is available. `codexbar usage` can take ~10s (it hits the web /
CLI / API), so the heavy call is kept out of the hot path.
"""

import json
import os
import re
import shlex
import shutil
import subprocess
import tempfile
import time

NAME = os.environ.get("NAME", "codexbar")
ICON = "\U000f06a9"  # nf-md-robot (verified present in Hack Nerd Font)

TMP = tempfile.gettempdir()
CACHE = os.path.join(TMP, "codexbar_sketchybar.json")
LOCK = os.path.join(TMP, "codexbar_sketchybar.lock")

REFRESH_INTERVAL = 300   # refresh cached data at most every N seconds
LOCK_STALE_AFTER = 600   # treat a lock older than this as dead

CODEXBAR = shutil.which("codexbar") or "/opt/homebrew/bin/codexbar"

# How to render the per-provider number.
#   "left"     -> show remaining (100 - usedPercent) / "… left" amount
#   "used"     -> show usedPercent directly
MODE = "left"

# Compact display names for providers (<= 3 chars). Unknowns truncate to 3.
SHORT = {
    "antigravity": "AG",
    "deepseek": "DS",
    "claude": "Cla",
    "mistral": "Mst",
    "openai": "OAI",
    "codex": "Cdx",
    "gemini": "Gem",
    "copilot": "Cop",
    "cursor": "Cur",
    "grok": "Grk",
    "groq": "Grq",
}

_CURRENCY_RE = re.compile(r"([$¥€£])\s?([\d,]+(?:\.\d+)?)")
_LEFT_RE = re.compile(r"([$¥€£])\s?([\d,]+(?:\.\d+)?)\s*left", re.IGNORECASE)


def _fmt_amount(sym: str, value: float) -> str:
    if value >= 100:
        return f"{sym}{value:.0f}"
    return f"{sym}{value:.2f}".rstrip("0").rstrip(".")


def _currency_amounts(usage: dict) -> list[tuple[str, float]]:
    """Collect remaining amounts across every rate window (primary/secondary/
    tertiary/extra), preferring the explicit '… left' figure."""
    windows = []
    for key in ("primary", "secondary", "tertiary"):
        w = usage.get(key)
        if isinstance(w, dict) and w:
            windows.append(w)
    for e in usage.get("extraRateWindows") or []:
        w = e.get("window") if isinstance(e, dict) else None
        if isinstance(w, dict) and w:
            windows.append(w)

    amounts = []
    for w in windows:
        rd = w.get("resetDescription") or ""
        m = _LEFT_RE.search(rd) or _CURRENCY_RE.search(rd)
        if not m:
            continue
        try:
            value = float(m.group(2).replace(",", ""))
        except ValueError:
            continue
        amounts.append((m.group(1), value))
    return amounts


def _provider_label(entry: dict) -> str:
    provider = entry.get("provider", "?")
    name = SHORT.get(provider, provider[:3].capitalize())
    usage = entry.get("usage") or {}

    # Currency-style plan (balance / spend): sum the remaining amounts of every
    # window, e.g. Mistral's Included API + Monthly Plan.
    amounts = _currency_amounts(usage)
    if amounts:
        symbol = amounts[0][0]
        total = sum(v for _, v in amounts)
        return f"{name} {_fmt_amount(symbol, total)}"

    primary = usage.get("primary") or {}
    used = primary.get("usedPercent")
    if isinstance(used, (int, float)):
        pct = max(0.0, 100.0 - float(used)) if MODE == "left" else float(used)
        return f"{name} {round(pct)}%"

    # No live quota (e.g. Antigravity "offline" source) -> make it visible.
    return f"{name} ?"


def _render() -> tuple[str, bool]:
    """Return (label, has_data)."""
    if not os.path.exists(CACHE):
        return "loading…", False
    try:
        with open(CACHE, "r", encoding="utf-8") as f:
            data = json.load(f)
    except (OSError, ValueError):
        return "codexbar?", False

    if not isinstance(data, list) or not data:
        return "", False

    parts = [_provider_label(e) for e in data if isinstance(e, dict)]
    return " · ".join(p for p in parts if p), bool(parts)


def _proxy_env() -> dict:
    """sketchybar (launchd) doesn't inherit shell proxy vars, so `agy` can't
    reach Google and codexbar falls back to offline Antigravity data. Fill
    them in from the macOS system proxy settings when missing."""
    env = dict(os.environ)
    if env.get("https_proxy") or env.get("HTTPS_PROXY"):
        return env
    try:
        out = subprocess.run(["scutil", "--proxy"], capture_output=True,
                             text=True, timeout=3).stdout
    except (OSError, subprocess.SubprocessError):
        return env
    kv = dict(re.findall(r"^\s*(\w+)\s*:\s*(\S+)", out, re.MULTILINE))
    for scheme in ("HTTPS", "HTTP"):
        if kv.get(f"{scheme}Enable") == "1" and kv.get(f"{scheme}Proxy"):
            url = f"http://{kv[f'{scheme}Proxy']}:{kv.get(f'{scheme}Port', '80')}"
            for k in ("https_proxy", "http_proxy", "HTTPS_PROXY", "HTTP_PROXY"):
                env.setdefault(k, url)
            break
    return env


def _maybe_refresh() -> None:
    if os.path.exists(LOCK):
        # Drop dead locks (e.g. a previous fetch was killed).
        try:
            if time.time() - os.path.getmtime(LOCK) < LOCK_STALE_AFTER:
                return
            os.remove(LOCK)
        except OSError:
            return

    try:
        if time.time() - os.path.getmtime(CACHE) < REFRESH_INTERVAL:
            return
    except OSError:
        pass  # no cache yet -> fetch

    try:
        fd = os.open(LOCK, os.O_CREAT | os.O_EXCL | os.O_WRONLY)
        os.close(fd)
    except FileExistsError:
        return

    cache = shlex.quote(CACHE)
    lock = shlex.quote(LOCK)
    script = (
        f'trap "rm -f {lock}" EXIT; '
        f'{shlex.quote(CODEXBAR)} usage --format json > "{cache}.tmp" 2>/dev/null '
        f'&& mv "{cache}.tmp" "{cache}"; '
        f"sketchybar --trigger codexbar_update"
    )
    subprocess.Popen(
        ["bash", "-c", script],
        start_new_session=True,
        env=_proxy_env(),
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )


def main() -> None:
    label, has_data = _render()
    args = ["sketchybar", "--set", NAME, f"icon={ICON}", f"label={label}"]
    args.append("drawing=on" if (has_data or label) else "drawing=off")
    subprocess.run(args, check=False)

    _maybe_refresh()


if __name__ == "__main__":
    main()

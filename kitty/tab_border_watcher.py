# pyright: reportMissingImports=false
"""Show the window border only while the OS window has more than one tab.

kitty draws window borders per split and has no condition on the tab count, so
this watcher switches the border color to the terminal background while a
single tab is open and back to the accent color once a second tab appears.

`on_tab_bar_dirty` fires for far more than tab creation: every tab title
change counts too. And `set-colors` itself marks the tab bar dirty
(kitty/colors.py: patch_colors -> mark_tab_bar_dirty -> watcher), so calling it
unconditionally turns each title update into a full color patch plus a deep
recursion. Only call it when the colour actually has to change.
"""

from typing import Any

from kitty.boss import Boss
from kitty.window import Window

BORDER_ON = "#6c6180"
BORDER_OFF = "#232922"


_applied: dict[int, str] = {}


def _apply(boss: Boss, window: Window, tab_manager: Any) -> None:
    color = BORDER_ON if len(tab_manager.tabs) > 1 else BORDER_OFF
    key = id(tab_manager)
    if _applied.get(key) == color:
        return
    _applied[key] = color
    try:
        boss.call_remote_control(
            window,
            ("set-colors", "--all", f"active_border_color={color}", f"inactive_border_color={color}"),
        )
    except Exception:
        # A failed color change must never take the tab bar down with it.
        _applied.pop(key, None)


def on_tab_bar_dirty(boss: Boss, window: Window, data: dict[str, Any]) -> None:
    tab_manager = data.get("tab_manager")
    if tab_manager is None:
        return
    _apply(boss, window, tab_manager)

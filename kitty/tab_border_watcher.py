# pyright: reportMissingImports=false
"""Show the window border only while the OS window has more than one tab.

kitty draws window borders per split and has no condition on the tab count, so
this watcher switches the border color to the terminal background while a
single tab is open and back to the accent color once a second tab appears.
`on_tab_bar_dirty` fires for new tabs, closed tabs and reordering, which is
every case that changes the count.
"""

from typing import Any

from kitty.boss import Boss
from kitty.window import Window

BORDER_ON = "#6c6180"
BORDER_OFF = "#232922"


def _apply(boss: Boss, window: Window, count: int) -> None:
    color = BORDER_ON if count > 1 else BORDER_OFF
    try:
        boss.call_remote_control(
            window,
            ("set-colors", "--all", f"active_border_color={color}", f"inactive_border_color={color}"),
        )
    except Exception:
        # A failed color change must never take the tab bar down with it.
        pass


def on_tab_bar_dirty(boss: Boss, window: Window, data: dict[str, Any]) -> None:
    tab_manager = data.get("tab_manager")
    if tab_manager is None:
        return
    _apply(boss, window, len(tab_manager.tabs))

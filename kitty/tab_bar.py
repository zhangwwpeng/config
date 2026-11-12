"""Custom tab renderer based on kitty's native separator renderer.

The native renderer owns the sizing, title truncation and tab colors.  This
only replaces the plain tab shape with rounded powerline caps.
"""

from kitty.fast_data_types import Screen
from kitty.rgb import color_as_int
from kitty.tab_bar import DrawData, ExtraData, TabBarData, as_rgb, draw_title


LEFT_CAP = ''
RIGHT_CAP = ''

# omp sets the terminal title to "π <state> <session>"; the π is its logo.
OMP_MARK = 'π '


def _strip_omp_mark(title: str) -> str:
    if title.startswith(OMP_MARK):
        return title[len(OMP_MARK):]
    return '' if title == 'π' else title


# Claude Code cycles these asterisks as its working spinner; draw a plain dot.
CLAUDE_SPIN = set('✢✳✶✻✽◐◑')


def _claude_mark(title: str) -> str:
    if title and title[0] in CLAUDE_SPIN:
        return '●' + title[1:]
    return title


def draw_tab(
    draw_data: DrawData,
    screen: Screen,
    tab: TabBarData,
    before: int,
    max_tab_length: int,
    index: int,
    is_last: bool,
    extra_data: ExtraData,
) -> int:
    # This is intentionally structured like kitty's draw_tab_with_separator.
    # In particular, use tab_bg/tab_fg from DrawData and the same title
    # drawing path, rather than calculating colors from screen.cursor.
    tab_bg = as_rgb(draw_data.tab_bg(tab))
    tab_fg = as_rgb(draw_data.tab_fg(tab))
    default_bg = as_rgb(color_as_int(draw_data.default_bg))

    # Hide omp's leading "π " mark in the tab label.
    tab = tab._replace(title=_claude_mark(_strip_omp_mark(tab.title)))

    # A cap on each side needs two cells.  Fall back to the native-looking
    # ellipsis for very narrow tab bars.
    if max_tab_length < 4:
        screen.cursor.fg = tab_fg
        screen.cursor.bg = tab_bg
        if max_tab_length <= 1:
            screen.draw('…')
        elif max_tab_length == 2:
            screen.draw('…|')
        else:
            screen.draw('…  '[:max_tab_length])
        return screen.cursor.x

    # Left rounded cap: tab color in the glyph, terminal background outside.
    screen.cursor.bg = default_bg
    screen.cursor.fg = tab_bg
    screen.draw(LEFT_CAP)

    # Keep kitty's native title renderer and clipping behavior.  The two caps
    # consume two cells from the native tab width.
    screen.cursor.bg = tab_bg
    screen.cursor.fg = tab_fg
    title_start = screen.cursor.x
    title_width = max_tab_length - 2
    draw_title(draw_data, screen, tab, index, title_width)

    # If a custom title template still overhangs, clip it just like the native
    # separator renderer does.
    extra = screen.cursor.x - title_start - title_width
    if extra > 0:
        screen.cursor.x -= extra + 1
        screen.draw('…')

    # Fill up to the right cap. The caller has already laid out this tab's
    # exact width, including in kitty's vertical tab-bar mode.
    right_cap_x = before + max_tab_length - 1
    if screen.cursor.x < right_cap_x:
        screen.cursor.bg = tab_bg
        screen.cursor.fg = tab_fg
        screen.draw(' ' * (right_cap_x - screen.cursor.x))
    screen.cursor.x = right_cap_x

    # Right rounded cap, then restore the terminal background for the gap
    # before the next tab/row.
    screen.cursor.bg = default_bg
    screen.cursor.fg = tab_bg
    screen.draw(RIGHT_CAP)
    screen.cursor.bg = default_bg
    screen.cursor.fg = tab_fg
    # kitty reserves one final column in vertical mode. Clear it with the
    # tab-bar background so no square of the tab color remains after the cap.
    if draw_data.tab_bar_edge in ('left', 'right'):
        screen.cursor.bg = default_bg
        screen.cursor.fg = tab_fg
        screen.draw(' ')
    screen.cursor.bold = screen.cursor.italic = False
    return screen.cursor.x

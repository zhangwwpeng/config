from kitty.fast_data_types import Screen
from kitty.tab_bar import DrawData, ExtraData, TabBarData, draw_title

def draw_tab(
    draw_data: DrawData, screen: Screen, tab: TabBarData,
    before: int, max_title_length: int, index: int, is_last: bool,
    extra_data: ExtraData
) -> int:
    orig_fg = screen.cursor.fg
    orig_bg = screen.cursor.bg
    left_sep, right_sep = ('', '')

    def draw_sep(which: str) -> None:
        screen.cursor.bg = int(draw_data.default_bg)
        screen.cursor.fg = int(orig_bg)
        screen.draw(which)
        screen.cursor.bg = int(orig_bg)
        screen.cursor.fg = int(orig_fg)

    if max_title_length <= 1:
        screen.draw('…')
    elif max_title_length == 2:
        screen.draw('…|')
    elif max_title_length < 6:
        draw_sep(left_sep)
        screen.draw((' ' if max_title_length == 5 else '') + '…' + (' ' if max_title_length >= 4 else ''))
        draw_sep(right_sep)
    else:
        # Fixed total width per tab: max_title_length cells
        # Layout: left_sep | space | title/… | space | right_sep | padding
        title_area = max_title_length - 5  # cells available for the title portion

        draw_sep(left_sep)
        screen.draw(' ')
        start = screen.cursor.x
        draw_title(draw_data, screen, tab, index)
        drawn = screen.cursor.x - start

        if drawn > title_area:
            screen.cursor.x = start + max(0, title_area - 1)
            screen.draw('…')
        elif drawn < title_area:
            screen.draw(' ' * (title_area - drawn))

        screen.draw(' ')
        draw_sep(right_sep)
        draw_sep(' ')

    return int(screen.cursor.x)

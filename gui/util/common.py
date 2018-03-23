'''
@Summary: Contains common methods and globals shared between util modules
@Author: `devopsec <https://github.com/devopsec>`_
'''

import sys

BLACK, RED, GREEN, YELLOW, BLUE, MAGENTA, CYAN, WHITE = range(8)


def has_colors(stream):
    """ From Python cookbook, #475186 """

    if not hasattr(stream, "isatty"):
        return False
    if not stream.isatty():
        return False # auto color only on TTYs
    try:
        import curses
        curses.setupterm()
        return curses.tigetnum("colors") > 2
    except:
        # guess false in case of error
        return False


def strfc(text, color=WHITE):
    """ Formats string with terminal codes for color """

    return "\x1b[1;{}m".format(30 + color) + str(text).strip() + "\x1b[0m"

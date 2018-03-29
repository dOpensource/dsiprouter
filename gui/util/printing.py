'''
@Summary: Contains methods for various printing capabilities
@Author: `devopsec <https://github.com/devopsec>`_
'''

import json, traceback
from util.common import *

def printc(text, color=WHITE, out=sys.stdout):
    """
    Print text with color, if available, to out
    :param text:    str
    :param color:   int
    :param out:     File
    :return:        None
    """

    if has_colors(sys.stdout):
        string = strfc(text, color)
        print(string, file=out, flush=True)
    else:
        string = str(text).strip()
        print(string, file=out, flush=True)

# some common use cases
def printerror(message):
    printc(message, RED)

def printwarn(message):
    printc(message, YELLOW)

def printinfo(message):
    printc(message, CYAN)

def printdebug(message):
    printc(message, GREEN)

def printpretty(message):
    printc(message, MAGENTA)
    
def printbold(message):
    printc(message, WHITE)


def pprint_json(data, **kwargs):
    """ works on lists or dicts """

    if isinstance(data, list):
        data = dict(data=data)
    if len(kwargs) > 0:
        print(json.dumps(data, sort_keys=True, indent=4, **kwargs))
    else:
        print(json.dumps(data, sort_keys=True, indent=4))

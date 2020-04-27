#
# TODO: this module shadows globals() builtin, which is a bad practice
# and may have unintended consequences elsewhere, we need to find a better implementation
#
# Also, we lose the state of global required if dsiprouter restarts
# which means kamailio may not have reloaded memory at all
# We should track the state of reloads in a file or database (the latter preferably)
#

def initialize():
    global reload_required
    global licensed
    globals()['licensed'] = False
    globals()['reload_required'] = False

# allow references in code before initialize is called
reload_required = globals()['reload_required'] if 'reload_required' in globals() else False
licensed =  globals()['licensed'] if 'licensed' in globals() else False

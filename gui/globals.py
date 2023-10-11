#
# TODO: this module shadows globals() builtin, which is a bad practice
# and may have unintended consequences elsewhere, we need to find a better implementation
#
# Also, we lose the state of global required if dsiprouter restarts
# which means kamailio may not have reloaded memory at all
# We should track the state of reloads in a file or database (the latter preferably)
#

def initialize(state):
    globals()['kam_reload_required'] = state.get('kam_reload_required', False)
    globals()['dsip_reload_required'] = state.get('dsip_reload_required', False)
    globals()['dsip_reload_ongoing'] = state.get('dsip_reload_ongoing', False)

# allow references in code before initialize is called
kam_reload_required = globals()['kam_reload_required'] if 'kam_reload_required' in globals() else False
dsip_reload_required = globals()['dsip_reload_required'] if 'dsip_reload_required' in globals() else False
dsip_reload_ongoing = globals()['dsip_reload_ongoing'] if 'dsip_reload_ongoing' in globals() else False

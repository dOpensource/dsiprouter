import json, os


# TODO: not thread/process safe, move to shared memory manager


def getPersistentState():
    if not os.path.exists('/run/dsiprouter/state.json'):
        return {}

    with open('/run/dsiprouter/state.json', 'r') as f:
        return json.load(f)

def setPersistentState(state):
    with open('/run/dsiprouter/state.json', 'w') as f:
        json.dump(state, f)

def updatePersistentState(updates):
    if not os.path.exists('/run/dsiprouter/state.json'):
        with open('/run/dsiprouter/state.json', 'w') as f:
            json.dump(updates, f)
        return updates

    with open('/run/dsiprouter/state.json', 'r+') as f:
        state = json.load(f)
        state.update(updates)
        f.seek(0)
        f.truncate(0)
        json.dump(state, f)
    return state
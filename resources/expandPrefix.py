# set per your own configs
prefixs = [
'011XXXXX.',
]
prefixs_mid_process = []
prefixs_post_process = []

# process ASTERISK-like regex pattern for a prefix
# we are not expanding 'X' or '.'
# this is because we don't support length based prefix matching
# instead we utilize dr_rules longest-to-shortest prefix matching
def process_prefix(prefix):
    for i in range(len(prefix)):
        if prefix[i] == 'N':
            tmp = list(prefix)
            for j in range(2,9+1):
                tmp[i] = str(j)
                prefixs_mid_process.append(''.join(tmp))
            return None
        elif prefix[i] == 'Z':
            tmp = list(prefix)
            for j in range(1,9+1):
                tmp[i] = str(j)
                prefixs_mid_process.append(''.join(tmp))
            return None
        elif prefix[i] == '[':
            tmp = list(prefix[i+1:])
            for j in range(len(tmp)):
                if tmp[j] == ']':
                    break
                prefixs_mid_process.append(prefix[:i] + tmp[j] + prefix[prefix.index(']')+1:])
            return None
    prefixs_post_process.append(prefix)
    return None

# first run
for p in prefixs:
    process_prefix(p)

# recursive runs
while(len(prefixs_mid_process) != 0):
    for i in reversed(range(len(prefixs_mid_process))):
        if not any((c in set('NZ[')) for c in prefixs_mid_process[i]):
            prefixs_post_process.append(prefixs_mid_process.pop(i))
        else:
            process_prefix(prefixs_mid_process[i])
            prefixs_mid_process.pop(i)

# print them to console
for p in prefixs_post_process:
    print("'" + p.replace('X','').replace('.','') + "',")

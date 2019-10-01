number_alphabet = '0123456789'
lc_letter_alphabet = 'abcdefghijklmnopqrstuvwxyz'
uc_letter_alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'

# process ASTERISK-like regex pattern for a prefix
# we are not expanding '!' or '.'
# this is because we don't support length based prefix matching
# instead we utilize dr_rules longest-to-shortest prefix matching
def expand_prefix(prefix, suffix_check=None):
    finished = False
    for i in range(len(prefix)):
        if prefix[i] == 'X' and suffix_check is None:
            for j in range(0,9+1):
                yield from expand_prefix(prefix[:i] + str(j) + prefix[i+1:])
        elif prefix[i] == 'Z' and suffix_check is None:
            for j in range(1,9+1):
                yield from expand_prefix(prefix[:i] + str(j) + prefix[i+1:])
            finished = True
        elif prefix[i] == 'N' and suffix_check is None:
            for j in range(2,9+1):
                yield from expand_prefix(prefix[:i] + str(j) + prefix[i+1:])
            finished = True
        elif prefix[i] == '[':
            tmp = prefix[i+1:]
            try:
                dash_idx = tmp.index('-')
                try:
                    start,end = number_alphabet.index(tmp[dash_idx-1]),number_alphabet.index(tmp[dash_idx+1])
                    for j in number_alphabet[start:end+1]:
                        yield from expand_prefix(prefix[:i] + j + prefix[prefix.index(']')+1:])
                    finished = True
                except ValueError:
                    pass
                try:
                    start,end = lc_letter_alphabet.index(tmp[dash_idx-1]),lc_letter_alphabet.index(tmp[dash_idx+1])
                    for j in lc_letter_alphabet[start:end+1]:
                        yield from expand_prefix(prefix[:i] + j + prefix[prefix.index(']')+1:])
                    finished = True
                except ValueError:
                    pass
                try:
                    start,end = uc_letter_alphabet.index(tmp[dash_idx-1]),uc_letter_alphabet.index(tmp[dash_idx+1])
                    for j in uc_letter_alphabet[start:end+1]:
                        yield from expand_prefix(prefix[:i] + j + prefix[prefix.index(']')+1:], suffix_check=prefix[prefix.index(']')+1:])
                    finished = True
                except ValueError:
                    pass
            except ValueError:
                for j in tmp[:tmp.index(']')]:
                    yield from expand_prefix(prefix[:i] + j + prefix[prefix.index(']')+1:])
        else:
            if finished:
                break
            if suffix_check is None:
                if not any(c in set('XZN[]') for c in prefix):
                    yield prefix.replace('.', '').replace('!', '')
                    break
            else:
                if not any(c in set('[]') for c in prefix) and not any(c in set('XZN[]') for c in suffix_check):
                    yield prefix.replace('.', '').replace('!', '')
                    break


def expand_prefixs(prefixs):
    for p in prefixs:
        yield sorted(list(expand_prefix(p)))

#### Example Usage:
#example_prefixs = ['[0-9]', '[a-z]', '[A-Z]', '[01]N']
#for p in expand_prefixs(example_prefixs):
#    print(p)

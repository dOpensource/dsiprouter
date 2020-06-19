#!/usr/bin/env python3

import os, sys, re, subprocess, shutil

dsip_project_dir = subprocess.Popen(['git', 'rev-parse', '--show-toplevel'], universal_newlines=True,
                                    stdout=subprocess.PIPE, stderr=subprocess.DEVNULL).communicate()[0].strip()
if len(dsip_project_dir) == 0:
    dsip_project_dir = os.path.dirname(os.path.dirname(os.path.abspath(sys.argv[0])))

kamcfg_file = os.path.join(dsip_project_dir, 'kamailio', 'kamailio_dsiprouter.cfg')
unmatched_ifdefs = []
unmatched_endifs = []

with open(kamcfg_file, 'rb') as kamcfg:
    i = 1
    for line in kamcfg:
        if re.match(rb'^\#\!ifn?def', line):
            unmatched_ifdefs.append(i)
        elif re.match(rb'^\#\!endif', line):
            try:
                unmatched_ifdefs.pop()
            except IndexError:
                unmatched_endifs.append(i)
        i += 1

term_width = shutil.get_terminal_size((80, 24))[0]

print('|', '='*(term_width-2), '|', sep='')
if len(unmatched_ifdefs) != 0 or len(unmatched_endifs) != 0:
    errors_found = True
    print('Errors Found')
else:
    errors_found = False
    print('No Errors Found')
print('|', '='*(term_width-2), '|', sep='')
if len(unmatched_ifdefs) != 0:
    header = 'unmatched ifdefs'
    header_len = len(header)
    avail_space = term_width - 4 - header_len
    header_fill = '=' * (int(avail_space / 2))
    header_pad = '=' * (avail_space % 2)
    print('|', header_fill, ' '+header+' ', header_fill, header_pad, '|', sep='')
    for i in unmatched_ifdefs:
        print('{}: line {}'.format(kamcfg_file, str(i)), file=sys.stderr)
    print('|', '='*(term_width-2), '|', sep='', file=sys.stderr)
if len(unmatched_endifs) != 0:
    header = 'unmatched endifs'
    header_len = len(header)
    avail_space = term_width - 4 - header_len
    header_fill = '=' * (int(avail_space / 2))
    header_pad = '=' * (avail_space % 2)
    print('|', header_fill, ' '+header+' ', header_fill, header_pad, '|', sep='')
    for i in unmatched_endifs:
        print('{}: line {}'.format(kamcfg_file, str(i)), file=sys.stderr)
    print('|', '='*(term_width-2), '|', sep='', file=sys.stderr)

sys.exit(int(errors_found))



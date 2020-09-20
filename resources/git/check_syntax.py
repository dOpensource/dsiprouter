#!/usr/bin/env python3

import os, sys, re, subprocess, shutil


# TODO: add support for other basic preprocessor checks (c/kamcfg)
# TODO: add support for missing semi-colon / dangling curly brace (c/kamcfg)
# TODO: add support for recursing through kamcfg include files (kamcfg)


# global config variables
project_root = subprocess.Popen(['git', 'rev-parse', '--show-toplevel'], universal_newlines=True,
                                    stdout=subprocess.PIPE, stderr=subprocess.DEVNULL).communicate()[0].strip()
if len(project_root) == 0:
    project_root = os.path.dirname(os.path.dirname(os.path.abspath(sys.argv[0])))

# find C src files in project
matched_csrc_files = subprocess.Popen(['find', project_root, '-type', 'f', '-regextype', 'posix-extended', '-regex', '.*\.(cpp|hpp|c|h)$'],
                                    universal_newlines=True, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL).communicate()[0].strip().split()
# find kamailio .cfg files in project
shell_pipe = subprocess.Popen(['find', project_root, '-type', 'f', '-name', '*.cfg', '-print0'],
                                    stdout=subprocess.PIPE, stderr=subprocess.DEVNULL).stdout
matched_kamcfg_files = subprocess.Popen(['xargs', '-0', 'sh', '-c', 'for arg do sed -n "/^\#\!KAMAILIO/q 0;q 1" ${arg} && echo "${arg}"; done', '_'],
                                    universal_newlines=True, stdin=shell_pipe, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL
                                    ).communicate()[0].strip().split()
files_found = len(matched_csrc_files) + len(matched_kamcfg_files)

term_width = shutil.get_terminal_size((80, 24))[0]

# global constants
CSRC_STYLE_IFDEF_REGEX = re.compile(rb'^\#if(?:n?def)?')
CSRC_STYLE_ENDIF_REGEX = re.compile(rb'^\#endif')
KAMCFG_STYLE_IFDEF_REGEX = re.compile(rb'^\#if(?:n?def)?')
KAMCFG_STYLE_ENDIF_REGEX = re.compile(rb'^\#endif')

# holds state for entire test
test_succeeded = True
files_checked = 0

# holds state for current file check
current_file = '<no file selected>'
unmatched_ifdefs = []
unmatched_endifs = []


# check for common syntax errors, currently supported checks:
#   + preprocessor statement closure
def haveValidSyntax(test_files, syntax='c-src'):
    global files_checked, current_file, unmatched_ifdefs, unmatched_endifs
    
    if syntax == 'c-src':
        ifdef_regex = CSRC_STYLE_IFDEF_REGEX
        endif_regex = CSRC_STYLE_ENDIF_REGEX
    elif syntax == 'kam-cfg':
        ifdef_regex = KAMCFG_STYLE_IFDEF_REGEX
        endif_regex = KAMCFG_STYLE_ENDIF_REGEX
    else:
        return False
    
    for test_file in test_files:
        current_file = test_file
        
        with open(test_file, 'rb') as fp:
            i = 1
            for line in fp:
                if ifdef_regex.match(line):
                    unmatched_ifdefs.append(i)
                elif endif_regex.match(line):
                    try:
                        unmatched_ifdefs.pop()
                    except IndexError:
                        unmatched_endifs.append(i)
                i += 1
        
        files_checked += 1
                
        if len(unmatched_ifdefs) != 0 or len(unmatched_endifs) != 0:
            return False
        
    return True

# print summary of test results
def printSummary():
    print('|', '='*(term_width-2), '|', sep='')
    if test_succeeded:
        print('Test Result: PASSED')
    else:
        print('Test Result: FAILED')
    print('Number Of Files Tested: {}'.format(str(files_checked)))
    print('Number Of Files Matched: {}'.format(str(files_found)))
    print('|', '='*(term_width-2), '|', sep='')


# print detailed failure info
def printErrorInfo():
    if not test_succeeded:
        if len(unmatched_ifdefs) != 0:
            header = 'unmatched ifdefs'
            header_len = len(header)
            avail_space = term_width - 4 - header_len
            header_fill = '=' * (int(avail_space / 2))
            header_pad = '=' * (avail_space % 2)
            print('|', header_fill, ' '+header+' ', header_fill, header_pad, '|', sep='')
            for i in unmatched_ifdefs:
                print('{}: line {}'.format(current_file, str(i)), file=sys.stderr)
            print('|', '='*(term_width-2), '|', sep='', file=sys.stderr)
        
        if len(unmatched_endifs) != 0:
            header = 'unmatched endifs'
            header_len = len(header)
            avail_space = term_width - 4 - header_len
            header_fill = '=' * (int(avail_space / 2))
            header_pad = '=' * (avail_space % 2)
            print('|', header_fill, ' '+header+' ', header_fill, header_pad, '|', sep='')
            for i in unmatched_endifs:
                print('{}: line {}'.format(current_file, str(i)), file=sys.stderr)
            print('|', '='*(term_width-2), '|', sep='', file=sys.stderr)

# wrapper for the final cleanup 
def printResultsAndExit():
    printSummary()
    printErrorInfo()
    sys.exit(int(test_succeeded == False))


# main testing logic
if not haveValidSyntax(matched_csrc_files, syntax='c-src'):
    test_succeeded = False
elif not haveValidSyntax(matched_kamcfg_files, syntax='kam-cfg'):
    test_succeeded = False
printResultsAndExit()


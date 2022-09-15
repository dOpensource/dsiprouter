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
CSRC_STYLE_IFDEF_REGEX = re.compile(rb'^[ \t]*#(?:ifdef|ifndef).*')
CSRC_STYLE_ELSE_REGEX = re.compile(rb'^[ \t]*#else.*')
CSRC_STYLE_ENDIF_REGEX = re.compile(rb'^[ \t]*#endif.*')
CSRC_CURLYBRACE_OPEN_REGEX = re.compile(rb'^[ \t]*(?!//|/\*).*\{[ \t]*')
CSRC_CURLYBRACE_CLOSE_REGEX = re.compile(rb'^[ \t]*(?!//|/\*)\}[ \t]*')
KAMCFG_STYLE_IFDEF_REGEX = re.compile(rb'^[ \t]*#\!(?:ifdef|ifndef).*')
KAMCFG_STYLE_ELSE_REGEX = re.compile(rb'^[ \t]*#\!else.*')
KAMCFG_STYLE_ENDIF_REGEX = re.compile(rb'^[ \t]*#\!endif.*')
KAMCFG_CURLYBRACE_OPEN_REGEX = re.compile(rb'^[ \t]*(?!//|#|/\*).*\{[ \t]*')
KAMCFG_CURLYBRACE_CLOSE_REGEX = re.compile(rb'^[ \t]*(?!//|#|/\*)\}[ \t]*')

# holds state for entire test
test_succeeded = True
files_checked = 0

# holds state for current file check
unmatched_ifdefs = []
unmatched_elses = []
outoforder_elses = []
unmatched_endifs = []
unmatched_lcurly_braces = []
unmatched_rcurly_braces = []

# check for common syntax errors, currently supported checks:
#   + preprocessor statement closure
def haveValidSyntax(test_files, syntax='c-src'):
    global files_checked
    global unmatched_ifdefs, unmatched_elses, outoforder_elses, unmatched_endifs
    global unmatched_lcurly_braces, unmatched_rcurly_braces

    if syntax == 'c-src':
        ifdef_regex = CSRC_STYLE_IFDEF_REGEX
        else_regex = CSRC_STYLE_ELSE_REGEX
        endif_regex = CSRC_STYLE_ENDIF_REGEX
        lcurly_regex = CSRC_CURLYBRACE_OPEN_REGEX
        rcurly_regex = CSRC_CURLYBRACE_CLOSE_REGEX
    elif syntax == 'kam-cfg':
        ifdef_regex = KAMCFG_STYLE_IFDEF_REGEX
        else_regex = KAMCFG_STYLE_ELSE_REGEX
        endif_regex = KAMCFG_STYLE_ENDIF_REGEX
        lcurly_regex = KAMCFG_CURLYBRACE_OPEN_REGEX
        rcurly_regex = KAMCFG_CURLYBRACE_CLOSE_REGEX
    else:
        return False

    for test_file in test_files:
        with open(test_file, 'rb') as fp:
            i = 1
            for line in fp:
                if ifdef_regex.match(line):
                    unmatched_ifdefs.append([test_file,i,line])
                elif else_regex.match(line):
                    if len(unmatched_ifdefs) == 0:
                        outoforder_elses.append([test_file,i,line])
                    else:
                        unmatched_elses.append([test_file,i,line])
                elif endif_regex.match(line):
                    try:
                        unmatched_elses.pop()
                    except IndexError:
                        pass
                    try:
                        unmatched_ifdefs.pop()
                    except IndexError:
                        unmatched_endifs.append([test_file,i,line])
                elif lcurly_regex.match(line):
                    unmatched_lcurly_braces.append([test_file,i,line])
                elif rcurly_regex.match(line):
                    unmatched_rcurly_braces.append([test_file,i,line])
                i += 1

        files_checked += 1

        if len(unmatched_ifdefs) + len(outoforder_elses) + len(unmatched_elses) + len(unmatched_endifs) + \
        len(unmatched_lcurly_braces) + len(unmatched_rcurly_braces) != 0:
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

# print error results for a single test
def printErrorBlock(header, test_results):
    header_len = len(header)
    avail_space = term_width - 4 - header_len
    header_fill = '=' * (int(avail_space / 2))
    header_pad = '=' * (avail_space % 2)
    print('|', header_fill, ' ' + header + ' ', header_fill, header_pad, '|', sep='')
    for result in test_results:
        print('[{}] line {}: {}'.format(result[0], str(result[1]), result[2]), file=sys.stderr)
    print('|', '=' * (term_width - 2), '|', sep='', file=sys.stderr)

# print detailed failure info
def printErrorInfo():
    if len(unmatched_ifdefs) != 0:
        printErrorBlock('unmatched preprocessor ifdef statements', unmatched_ifdefs)
    if len(outoforder_elses) != 0:
        printErrorBlock('out of order preprocessor else statements', outoforder_elses)
    if len(unmatched_elses) != 0:
        printErrorBlock('unmatched preprocessor else statements', unmatched_elses)
    if len(unmatched_endifs) != 0:
        printErrorBlock('unmatched preprocessor endif statements', unmatched_endifs)
    if len(unmatched_lcurly_braces) != 0:
        printErrorBlock('unmatched left curly braces', unmatched_lcurly_braces)
    if len(unmatched_rcurly_braces) != 0:
        printErrorBlock('unmatched right curly braces', unmatched_rcurly_braces)

# wrapper for the final cleanup
def printResultsAndExit():
    printSummary()
    if not test_succeeded:
        printErrorInfo()
    sys.exit(int(test_succeeded == False))

# main testing logic
if __name__ == "__main__":
    if not haveValidSyntax(matched_csrc_files, syntax='c-src'):
        test_succeeded = False
    elif not haveValidSyntax(matched_kamcfg_files, syntax='kam-cfg'):
        test_succeeded = False
    printResultsAndExit()


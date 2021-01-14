# Makefile for running test unit
#

# Our own sorting function
sort-files = $(shell echo -e $1 | tr ' ' '\n' | sort -V)


TESTS_FILES ?= $(wildcard *.sh)
TESTS_EXCLUDE ?=
TESTS ?= $(call sort-files,$(filter-out $(patsubst %,%.sh,$(TESTS_EXCLUDE)), $(TESTS_FILES)))
DSIP_CONFIG_FILE ?= $(shell grep -oP '^DSIP_CONFIG_FILE[ \t]*=[ \t]*"\K(.*)(?=")' include/common 2>/dev/null)
DEBUG ?= $(shell grep -oP '^DEBUG\s?\=\s?\K(.*)' $(DSIP_CONFIG_FILE) 2>/dev/null)

_setdebug:
		@if [ "$(DEBUG)" = "False" ]; then \
				sed -i -r 's|^DEBUG\s?\=\s?.*|DEBUG = True|g' $(DSIP_CONFIG_FILE) ; \
				systemctl restart dsiprouter ; \
		fi ;

_resetdebug:
		@if [ "$(DEBUG)" = "False" ]; then \
				sed -i -r 's|^DEBUG\s?\=\s?.*|DEBUG = False|g' $(DSIP_CONFIG_FILE) ; \
				systemctl restart dsiprouter ; \
		fi ;

_all:
		@for FILE in $(TESTS) ; do \
				if [ -f $$FILE ] ; then \
						if [ -x $$FILE ] ; then \
								echo "Run test `basename $$FILE .sh`:" `head -n 2 "$$FILE" | tail -n 1 | cut -c 3-` ; \
								./$$FILE ; \
								ret=$$? ; \
								if [ ! "$$ret" -eq 0 ] ; then \
										echo "Test unit file $$FILE: failed" ; \
								else \
										echo "Test unit file $$FILE: ok" ; \
								fi ; \
						fi ; \
				fi ; \
		done ; \
		exit $$RES;

_run:
		-@if [ -f $(UNIT) ] ; then \
				if [ -x $(UNIT) ] ; then \
						echo "Run test `basename $(UNIT) .sh`:" `head -n 2 "$(UNIT)" | tail -n 1 | cut -c 3-` ; \
						./$(UNIT) ; \
						ret=$$? ; \
						if [ ! "$$ret" -eq 0 ] ; then \
								echo "Test unit file $(UNIT): failed" ; \
						else \
								echo "Test unit file $(UNIT): ok" ; \
						fi ; \
				fi ; \
		else \
				echo "Test unit file $(UNIT): not found" ; \
		fi ;

# run all tests
all: _setdebug _all _resetdebug

# run one test specified in variable UNIT
# # example: make UNIT=1.sh run
run: _setdebug _run _resetdebug

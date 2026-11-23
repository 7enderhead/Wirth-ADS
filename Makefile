# Free Pascal procedure/test workspace.
#
#   make                build and run the unit tests (default)
#   make test           same, extra options via ARGS='...'
#   make lazbuild       build the test project the Lazarus way
#   make clean          remove build/
#   make doctor         show which compiler/toolchain will be used
#   make debug-check    verify the test binary has usable debug info
#   make help           show this summary
#
# Documentation lives in README.md and docs/.

FPC ?= fpc
LAZBUILD ?= lazbuild

.PHONY: all test lazbuild clean doctor debug-check help

all: test

test:
	@FPC="$(FPC)" scripts/run-tests.sh $(ARGS)

lazbuild:
	@mkdir -p build/tests
	@$(LAZBUILD) tests/tests.lpi

clean:
	@rm -rf build

doctor:
	@echo "fpc:      $$(command -v $(FPC) || echo 'NOT FOUND')"
	@$(FPC) -iV 2>/dev/null | sed 's/^/          version /'
	@echo "lazbuild: $$(command -v $(LAZBUILD) || echo 'NOT FOUND')"
	@$(LAZBUILD) --version 2>/dev/null | head -n1 | sed 's/^/          version /'

debug-check:
	@FPC="$(FPC)" scripts/check-debug.sh

help:
	@printf '%s\n' \
	  'Usage: make [target] [ARGS="<FPCUnit options>"]' \
	  '' \
	  'Targets:' \
	  '  all, test   Build and run all unit tests (default)' \
	  '  lazbuild    Build tests/tests.lpi with lazbuild (does not run tests)' \
	  '  doctor      Show compiler and Lazarus paths/versions' \
	  '  debug-check Verify the test binary contains usable debug info' \
	  '  clean       Remove build/' \
	  '  help        Show this help' \
	  '' \
	  'Examples:' \
	  "  make test ARGS='--suite=TTextUtilsTest'" \
	  "  make test ARGS='--format=xml --file=build/report.xml'" \
	  '  make lazbuild LAZBUILD=/path/to/lazbuild' \
	  '' \
	  'The test binary itself accepts options too:' \
	  '  build/tests/tests --help' \
	  '  build/tests/tests --list' \
	  '' \
	  'See docs/usage.md and docs/troubleshooting.md for details.'

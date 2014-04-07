NPM_EXECUTABLE_HOME := node_modules/.bin

PATH := ${NPM_EXECUTABLE_HOME}:${PATH}

test: deps
	@find test -name '*_test.coffee' | xargs -n 1 -t coffee

dev: generate-js
	@coffee -wc --bare -o lib src/*.coffee

generate-js:
	@find src -name '*.coffee' | xargs coffee -c -o lib

package:
	@chmod 0755 bin/qqcli

remove-js:
	@rm -fr lib/

deps:

.PHONY: all


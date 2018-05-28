SHELL := /bin/bash

test:
	swift test

run-rest:
	swift build
	./.build/debug/SgBaseRest

ptest: 
	( \
		source ./py-test/venv/bin/activate; \
    	pytest ./py-test; \
	)

	
	
	
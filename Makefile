SHELL := /bin/bash

test:
	swift test

run-rest:
	swift run SeagullRestDemo

run-perf-test:
	swift run SeagullPerfTest

ptest: 
	( \
		source ./py-test/venv/bin/activate; \
    	pytest ./py-test; \
	)

	
	
	
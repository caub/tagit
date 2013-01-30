#!/bin/sh
erl -sname tagit -pa ebin -pa deps/*/ebin -s tagit \
	-eval "io:format(\"* see: http://localhost:8080~n\")."

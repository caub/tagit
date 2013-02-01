#!/bin/sh
erl -pa ebin deps/*/ebin -s tagit \
	-eval "io:format(\"* see: http://localhost:8080~n\")."

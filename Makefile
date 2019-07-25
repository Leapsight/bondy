
REBAR            = $(shell pwd)/rebar3

.PHONY: compile test xref dialyzer

compile-no-deps:
	${REBAR} compile

test: compile
	${REBAR} ct

xref: compile
	${REBAR} xref skip_deps=true

dialyzer: compile
	${REBAR} dialyzer

devrun:
	${REBAR} as dev release
	/bin/cp config/dev/bondy.conf _build/dev/rel/bondy/etc/bondy.conf
	_build/dev/rel/bondy/bin/bondy console
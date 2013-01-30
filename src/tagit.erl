%%#!/usr/bin/env escript
%%! -smp disable +A1 +K true -pa ebin deps/cowboy/ebin -input

-module(tagit).
-behaviour(application).
-export([start/0, start/2, stop/1]).

start() ->
	application:start(crypto),
	application:start(public_key),
	application:start(ssl),
	application:start(cowboy),
	application:start(tagit).


start(_Type, _Args) ->
	Dispatch = [
		{'_', [
			{[<<"favicon.ico">>], favicon_handler, []},
			{[<<"websocket">>], websocket_handler, []},
			% {[<<"eventsource">>], eventsource_handler, []},
			% {[<<"eventsource">>, <<"live">>], eventsource_emitter, []},
			{[<<"pub">>], publish_handler, []},
			{[<<"sub">>], subscribe_handler, []},
			{[], tag_handler, []},
			{'_', default_handler, []}
		]}
	],
	{ok, _} = cowboy:start_listener(my_http_listener, 100,
		cowboy_tcp_transport, [{port, 8080}],
		cowboy_http_protocol, [{dispatch, Dispatch}]
	),
 %  {ok, _} = cowboy:start_listener(my_https_listener, 100,
	% 	cowboy_ssl_transport, [
	% 		{port, 8443}, {certfile, "priv/ssl/cert.pem"},
	% 		{keyfile, "priv/ssl/key.pem"}, {password, "cowboy"}],
	% 	cowboy_http_protocol, [{dispatch, Dispatch}]
	% ),

	%% init a session table
	%ets:new(session,[public,named_table,bag]),
	%% init fake database
	ets:new(posts,[public, named_table]),
	ets:insert(posts, {1, <<"chrisr">>, <<"2013-01-16T12:09:01">>, <<"Erlang conference @Barcelona">>}),
	ets:insert(posts, {2, <<"fabian veel">>, <<"2013-01-16T12:09:12">>, <<"Follow nba news on <a href='http://www.basketusa.com/'>www.basketusa.com</a>">>}),
	ets:insert(posts, {3, <<"fabian veel">>, <<"2013-01-16T12:09:14">>, <<"miami nba news">>}),
	ets:insert(posts, {4, <<"fabian veel">>, <<"2013-01-17T15:54:55">>, <<"LAL: kobe nba news">>}),
	ets:insert(posts, {5, <<"fabian veel">>, <<"2013-01-18T14:19:01">>, <<"@Lakers bryant 50pts vs okc nba news">>}),
	ets:insert(posts, {6, <<"fabian veel">>, <<"2013-01-18T16:02:34">>, <<"kobe injured @lakers nba">>}),

	ets:new(posts_tags, [public, named_table, bag]),
	ets:insert(posts_tags, {1,<<"erlang">>}),
	ets:insert(posts_tags, [{2, <<"nba">>}]),
	ets:insert(posts_tags, [{3, <<"nba">>}]),
	ets:insert(posts_tags, [{4, <<"nba">>},{4, <<"lakers">>}]),
	ets:insert(posts_tags, [{5, <<"nba">>},{5, <<"lakers">>},{5, <<"kobebryant">>}]),
	ets:insert(posts_tags, [{6, <<"nba">>},{6, <<"lakers">>},{6, <<"kobebryant">>}]),

	ets:new(tags, [public, named_table]),
	ets:insert(tags, {<<"erlang">>, <<"(?i)erlang">>, <<"2013-01-10">>}),
	ets:insert(tags, {<<"nba">>, <<"(?i)nba|basket">>, <<"2013-01-10">>}),
	ets:insert(tags, {<<"on">>, <<"(?i)on">>, <<"2013-01-28">>}),
	ets:insert(tags, {<<"news">>, <<"(?i)news">>, <<"2013-01-28">>}),
	ets:insert(tags, {<<"lakers">>, <<"(?i)lakers|lal|(los angeles lakers)">>, <<"2013-01-10">>}),
	ets:insert(tags, {<<"kobebryant">>, <<"(?i)kb|kobe|bryant">>, <<"2013-01-10">>}),
	

	ets:new(websockets, [public, named_table]),
	%see ws_handler ,, bind websocket with Current Tags

	tagit_listener:start_link(),
	
	tagit_sup:start_link().



stop(_State) ->
	ok.

%% Feel free to use, reuse and abuse the code in this file.

%% @private
-module(tagit_app).
-behaviour(application).

%% API.
-export([start/2]).
-export([stop/1]).

%% API.
start(_Type, _Args) ->
	Dispatch = cowboy_router:compile([
		{'_', [
			{"/static/[...]", cowboy_static, [
				{directory, {priv_dir, tagit, []}},
				{mimetypes, {fun mimetypes:path_to_mimes/2, default}}
			]},
			{"/pub", publish_handler, []},
			{"/sub", subscribe_handler, []},
			{"/websocket", ws_handler, []},
			{'_', default_handler, []}
		]}
	]),
	{ok, _} = cowboy:start_http(http, 100, [{port, 8080}],
		[{env, [{dispatch, Dispatch}]}]),

	%% init a session table
	%ets:new(session,[public,named_table]),
	%% init fake database

	%% should have dets replicas, and save it in dets when there'a save action or at each insert
	ets:new(posts,[public, named_table]),
	%                 Id      Author      Time                   Text
	ets:insert(posts, {1, <<"chrisr">>, <<"2013-01-16T12:09:01">>, <<"Erlang conference @Barcelona">>}),
	ets:insert(posts, {2, <<"fabian">>, <<"2013-01-16T12:09:12">>, <<"Follow nba news on <a href='http://www.basketusa.com/'>www.basketusa.com</a>">>}),
	ets:insert(posts, {3, <<"fabian">>, <<"2013-01-16T12:09:14">>, <<"miami nba news">>}),
	ets:insert(posts, {4, <<"fabian">>, <<"2013-01-17T15:54:55">>, <<"LAL: kobe nba news">>}),
	ets:insert(posts, {5, <<"fabian">>, <<"2013-01-18T14:19:01">>, <<"@Lakers bryant 50pts vs okc nba news">>}),
	ets:insert(posts, {6, <<"fabian">>, <<"2013-01-18T16:02:34">>, <<"kobe injured @lakers nba">>}),

	ets:new(posts_tags, [public, named_table, bag]),
	ets:insert(posts_tags, {1,<<"erlang">>}),
	ets:insert(posts_tags, [{2, <<"nba">>}]),
	ets:insert(posts_tags, [{3, <<"nba">>}]),
	ets:insert(posts_tags, [{4, <<"nba">>},{4, <<"lakers">>}]),
	ets:insert(posts_tags, [{5, <<"nba">>},{5, <<"lakers">>},{5, <<"kobebryant">>}]),
	ets:insert(posts_tags, [{6, <<"nba">>},{6, <<"lakers">>},{6, <<"kobebryant">>}]),

	ets:new(tags, [public, named_table]),
	%                   Id           Expression matched   Time (of creation)
	ets:insert(tags, {<<"erlang">>, <<"(?i)erlang">>, <<"2013-01-10">>}),
	ets:insert(tags, {<<"nba">>, <<"(?i)nba|basket">>, <<"2013-01-10">>}),
	ets:insert(tags, {<<"on">>, <<"(?i)on">>, <<"2013-01-28">>}),
	ets:insert(tags, {<<"foobar">>, <<"foo|bar">>, <<"2013-01-10">>}),
	ets:insert(tags, {<<"news">>, <<"(?i)news">>, <<"2013-01-28">>}),
	ets:insert(tags, {<<"lakers">>, <<"(?i)lakers|lal|(los angeles lakers)">>, <<"2013-01-10">>}),
	ets:insert(tags, {<<"kobebryant">>, <<"(?i)kb|kobe|bryant">>, <<"2013-01-10">>}),
	

	ets:new(websockets, [public, named_table]),
	%                    Pid       Tag path
	%see websocket_handler


	tagit_listener:start_link(),
	
	tagit_sup:start_link().

stop(_State) ->
	ok.
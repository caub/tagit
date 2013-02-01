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

	init_db(),
	tagit_listener:start_link(),
	tagit_sup:start_link().

stop(_State) ->
	dets:close(dposts),
	dets:close(dposts_tags),
	dets:close(dtags),
	ok.

init_db() ->
	%% init a session table
	%ets:new(session,[public,named_table]),

	% ------------ posts    {post_id, author, time, text} -----------------
	ets:new(posts,[public, named_table]),
	dets:open_file(dposts, [{file, "./db/posts"}, {type, set}]),
	dets:to_ets(dposts, posts),
	%ets:insert(posts, {1, <<"chrisr">>, <<"2013-01-16T12:09:01">>, <<"Erlang conference @Barcelona">>}),

	%------------- posts_tags  {post_id, tag_id} --------------------------
	ets:new(posts_tags, [public, named_table, bag]),
	dets:open_file(dposts_tags, [{file, "./db/posts_tags"}, {type, bag}]),
	dets:to_ets(dposts_tags, posts_tags),
	%ets:insert(posts_tags, [{1,<<"erlang">>}]),

	%------------- tags  {tag_id, expression matched, time (of creation)} --
	ets:new(tags, [public, named_table]),
	dets:open_file(dtags, [{file, "./db/tags"}, {type, set}]),
	dets:to_ets(dtags, tags),
	%ets:insert(tags, {<<"erlang">>, <<"(?i)erlang">>, <<"2013-01-10">>}),

	%------------- websockets  {ws_pid, tag_path} --------------------------
	ets:new(websockets, [public, named_table]).

%% Feel free to use, reuse and abuse the code in this file.

-module(subscribe_handler).
-behaviour(cowboy_http_handler).
-export([init/3, handle/2, terminate/2]).
-include_lib("stdlib/include/ms_transform.hrl").

init({_Any, http}, Req, []) ->
	{ok, Req, undefined}.

handle(Req, State) ->
	%reply with active subscriptions from session
	{Action, _} = cowboy_http_req:qs_val(<<"action">>, Req, <<"update">>),
	{Tag, _} = cowboy_http_req:qs_val(<<"tag">>, Req),
	io:format("o20 ~p ~n", [ Tag]),
	case Action of 
		<<"delete">> -> 
			ets:match_delete(tags, Tag),
			ets:match_delete(posts_tags, {'_', Tag});
		_ -> 
			% from time
			{From, _} = cowboy_http_req:qs_val(<<"from">>, Req, <<"2013">>),
			{Arg, _} = cowboy_http_req:qs_val(<<"arg">>, Req),

			case ets:lookup(tags, Tag) of 
				[] -> 
					update_tag(Tag, Arg, From);
				[{_,OldArg,OldFrom}|T] when OldArg/=Arg; From<OldFrom ->
					update_tag(Tag, Arg, From); % could add , OldFrom to avoid redoing already parsed msgs
				_ -> ok
			end,
			ets:insert(tags, {Tag, Arg, From})

	end,
	{ok, Req2} = cowboy_http_req:reply(200, [], <<"done">>, Req),
	{ok, Req2, State}.


terminate(_Req, _State) ->
	ok.

update_tag(Tag, Arg, From) -> 
	% possibly long
	Posts = ets:select(posts, ets:fun2ms(fun({I,A,T,C}) when From < T -> {I,A,T,C} end)),
	lists:foldl(fun({I,A,T,C}, _) ->
		case re_match(C, Arg) of 
			nomatch -> ok;
			_ -> ets:insert(posts_tags, {I, Tag})
		end 
	end, [], Posts).

re_match(Data, Re) ->
	try
		re:run(Data, Re)
	catch 
		_:_Reason ->
			nomatch
	end.
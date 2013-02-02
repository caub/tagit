%% Feel free to use, reuse and abuse the code in this file.

-module(subscribe_handler).

-export([init/3, handle/2, terminate/3, update_tag/3]).

-include_lib("stdlib/include/ms_transform.hrl").

init(_Transport, Req, []) ->
	{ok, Req, undefined}.

handle(Req, State) ->
	%reply with active subscriptions from session
	{Action, _} = cowboy_req:qs_val(<<"action">>, Req, <<"update">>),
	{Tag, _} = cowboy_req:qs_val(<<"tag">>, Req),
	io:format("o20 ~p ~n", [ Tag]),
	case Action of 
		<<"delete">> -> 
			ets:match_delete(tags, Tag),
			ets:match_delete(posts_tags, {'_', Tag}),
			dets:match_delete(dtags, Tag),
			dets:match_delete(dposts_tags, {'_', Tag});
		_ -> 
			% from time
			{From, _} = cowboy_req:qs_val(<<"from">>, Req, <<"2013">>),
			{Arg, _} = cowboy_req:qs_val(<<"arg">>, Req),

			case ets:lookup(tags, Tag) of 
				[] -> 
					spawn(?MODULE, update_tag, [Tag, Arg, From]);
				[{_,OldArg,OldFrom}|_T] when OldArg/=Arg; From<OldFrom ->
					spawn(?MODULE, update_tag, [Tag, Arg, From]); % should add OldFrom to parse msgs between From and OldFrom, but for the moment OldFrom is current time
				_ -> ok
			end,
			ets:insert(tags, {Tag, Arg, From}),
			dets:insert(dtags, {Tag, Arg, From})

	end,
	{ok, Req2} = cowboy_req:reply(200, [], <<"done">>, Req),
	{ok, Req2, State}.


terminate(_Reason, _Req, _State) ->
	ok.

update_tag(Tag, Arg, From) -> 
	% possibly long
	Posts = ets:select(posts, ets:fun2ms(fun({I,A,T,C}) when From < T -> {I,A,T,C} end)),
	Data = lists:foldl(fun({I,_A,_T,C}, Acc) ->
		case re_match(C, Arg) of 
			nomatch -> Acc;
			_ -> [{I, Tag}|Acc]
		end 
	end, [], Posts),
	ets:insert(posts_tags, Data),
	dets:insert(dposts_tags, Data).

re_match(Data, Re) ->
	try
		re:run(Data, Re)
	catch 
		_:_Reason ->
			nomatch
	end.
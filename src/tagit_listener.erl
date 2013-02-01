
%% our central broker
%%  gets messages from any source, browse all active subscriptions and dispatch message to matching ones

-module(tagit_listener).
-behaviour(gen_server).

-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

-export([start_link/0, process/1]).

% These are all wrappers for calls to the server
start_link() ->
	gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

process(Message) ->
	gen_server:call(?MODULE, Message).


init([]) ->
	%timer:send_interval(1000, {tick, '_'}), %% starts a timer service
	{ok, []}.

handle_call({_Id, _Author, _Time, _Text}, _From, State) ->
	% can put handle_info code here
	{reply, put, State};

handle_call(_Message, _From, State) ->
	{reply, error, State}.

handle_cast(_Message, State) ->
	{noreply, State}.

handle_info({Id, Author, Time, Text}, State) ->

	% process the message through all tags
	TagsMatched = ets:foldl(fun({T,R,_}, Acc)-> 
		case re_match(Text, R) of 
			nomatch -> Acc;
			_ -> ets:insert(posts_tags, {Id, T}), [T|Acc]
		end
	end, [], tags),
	
	{ok, Msg} = json:encode([Id, Author, Time, Text]++[TagsMatched]),

	ets:foldl(fun({Pid, Path}, _)-> 
		io:format("o33 ~p ~p ~n", [Path, TagsMatched]),
		case path_match(Path, TagsMatched) of 
			true -> Pid ! Msg;
			_ -> ok
		end
	end, [], websockets),
	io:format("o33 ~p ~p ~n", [self(), Msg]),
	{noreply, State}.

terminate(_Reason, _State) ->
	ok.

code_change(_OldVersion, State, _Extra) ->
	{ok, State}.


re_match(Data, Re) ->
	try
		re:run(Data, Re)
	catch 
		_:_Reason ->
			nomatch
	end.


path_match(_, []) -> false;
path_match([], _Tags) -> true;
path_match([<<"">>], _Tags) -> true;
path_match([Tag|Rest],Tags) ->
	path_match(Rest, [T || T <- re:split(Tag, " |\\+", [{return,binary}]), lists:member(T, Tags)]).



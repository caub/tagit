%% Feel free to use, reuse and abuse the code in this file.

-module(websocket_handler).
-behaviour(cowboy_http_handler).
-behaviour(cowboy_http_websocket_handler).
-export([init/3, handle/2, terminate/2]).
-export([websocket_init/3, websocket_handle/3,
	websocket_info/3, websocket_terminate/3]).

init({_Any, http}, Req, []) ->
	case cowboy_http_req:header('Upgrade', Req) of
		{undefined, Req2} -> {ok, Req2, undefined};
		{<<"websocket">>, _Req2} -> {upgrade, protocol, cowboy_http_websocket};
		{<<"WebSocket">>, _Req2} -> {upgrade, protocol, cowboy_http_websocket}
	end.

handle(Req, State) ->
	{ok, Req, State}.

terminate(_Req, _State) ->
	ets:delete(websockets, self()),
	ok.

websocket_init(_Any, Req, []) ->
	%gproc:reg({p, l, ?WSKey}),
	{PeerAddr, _} = cowboy_http_req:peer_addr(Req),
	{Path, _} = cowboy_http_req:qs_val(<<"path">>, Req, <<"">>),

	io:format("o0 ~p ~n", [[self(), Path]]),
	%keep subscriptions in session for each peer
	ets:insert(websockets, {self(), re:split(Path, "&", [{return,binary}])}),

	Req2 = cowboy_http_req:compact(Req),
	{ok, Req2, undefined, hibernate}.

websocket_handle({text, Msg}, Req, State) ->
	%gproc:send({p, l, ?WSKey}, {self(), ?WSKey, Msg}),
	io:format("o20 incoming ~p ~n", [Msg]),
	% update listening path
	ets:insert(websockets, {self(), re:split(Msg, "&", [{return,binary}])}),
	{ok, Req, State};

websocket_handle(_Any, Req, State) ->
	io:format(",,,,,,,~p  ~n", [test]),
	{ok, Req, State}.

websocket_info(Info, Req, State) ->
	%io:format("o23 ~p  ~n", [self() ]),
	{reply, {text, Info}, Req, State, hibernate}.

websocket_terminate(_Reason, _Req, _State) ->
	ok.

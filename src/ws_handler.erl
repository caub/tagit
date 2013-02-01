%% Feel free to use, reuse and abuse the code in this file.

-module(ws_handler).
-behaviour(cowboy_websocket_handler).

-export([init/3]).
-export([websocket_init/3, websocket_handle/3,
	websocket_info/3, websocket_terminate/3]).

init({tcp, http}, _Req, _Opts) ->
	{upgrade, protocol, cowboy_websocket}.

websocket_init(_TransportName, Req, _Opts) ->
	%gproc:reg({p, l, ?WSKey}),
	{Path, _} = cowboy_req:qs_val(<<"path">>, Req, <<"">>),

	io:format("o0 ~p ~n", [[self(), Path]]),
	%keep subscriptions in session for each peer
	ets:insert(websockets, {self(), re:split(Path, "&", [{return,binary}])}),

	{ok, Req, undefined_state}.

websocket_handle({text, Msg}, Req, State) ->
	%gproc:send({p, l, ?WSKey}, {self(), ?WSKey, Msg}),
	io:format("o20 incoming ~p ~n", [Msg]),
	% update listening path
	ets:insert(websockets, {self(), re:split(Msg, "&", [{return,binary}])}),
	{ok, Req, State};
websocket_handle(_Data, Req, State) ->
	{ok, Req, State}.

websocket_info(Info, Req, State) ->
	{reply, {text, Info}, Req, State, hibernate}.%hib

websocket_terminate(_Reason, _Req, _State) ->
	ok.

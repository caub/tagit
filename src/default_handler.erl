%% Feel free to use, reuse and abuse the code in this file.

-module(default_handler).

-export([init/3, handle/2, terminate/3]).

init(_Transport, Req, []) ->
	{ok, Req, undefined}.

handle(Req, State) ->
	{Path, _} = cowboy_req:path(Req),
	io:format("o21 ~p ~n", [Path]),
	Tags = ets:match(tags, {'$1','$2','$3'}),
	Tagscount = [[length(ets:match(posts_tags, {'_',T})),T,A,Ti] || [T,A,Ti] <- Tags],
	{ok, Tagsj} = json:encode(Tagscount),
	{ok, Req2} = cowboy_req:reply(200, [],
[<<"<html>
<head>
<meta charset='utf-8'>
<meta name='viewport' content='width=device-width'>
<title>Tagit</title>
<link rel='shortcut icon' href='/static/favicon.ico'>
<link rel=stylesheet type=text/css href='/static/app.css'>
<script type='text/javascript'>
	var ws, tags=">>, Tagsj, <<";
</script>
<script src='//ajax.googleapis.com/ajax/libs/jquery/1.9.0/jquery.min.js'></script>
<script src='/static/app.js'></script>
</head>
<body>

<div id='home'>

<div id='header'>
	<a id='home__s' onclick='location.hash=\"\"'>Tagit</a>
	<div id='post__s'><a onclick='$(\"#tags\").fadeToggle();'>Tags</a><a onclick='$(\"#post_\").fadeToggle();'>Write</a></div>
	<input id='browse_tag' type='text' style='width: 320px;' title='put tags separated with & for AND and + for OR (they are grouped by OR)'>
	<button onclick='location.hash=document.getElementById(\"browse_tag\").value'>Browse</button>
</div>

<div id='posts'>
	<dl></dl>
</div>

<div id='tags'>
	<input placeholder='Tag name' id='add_tag' type='text' style='max-width: 100px;'>
	<input placeholder='Tag expression pattern matching' id='add_tag_arg' type='text' style='min-width: 240px;'>
	<button id='add_tag_b' onclick='sub(document.getElementById(\"add_tag\").value,document.getElementById(\"add_tag_arg\").value)'>Add</button>
</div>
<div id='post_'>
	<input placeholder='author' id='post_author' type='text' value='jack'><br>
	<textarea id='post_text'>Hello!, send something</textarea><br>
	<button onclick='Post()' style='float: right;'>Send</button>
</div>

</div>

</body>
</html>">>], Req),
		
	{ok, Req2, State}.


terminate(_Reason, _Req, _State) ->
	ok.

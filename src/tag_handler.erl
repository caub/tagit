%% Feel free to use, reuse and abuse the code in this file.

-module(tag_handler).
-behaviour(cowboy_http_handler).
-export([init/3, handle/2, terminate/2]).

init({_Any, http}, Req, []) ->
	{ok, Req, undefined}.

handle(Req, State) ->
	{PeerAddr, _} = cowboy_http_req:peer_addr(Req),
	io:format("o21 ~p ~n", [PeerAddr]),
	Tags = ets:match(tags, {'$1','$2','$3'}),
	{ok, Tagsj} = json:encode(Tags),
	{ok, Countsj} = json:encode([ [length(ets:match(posts_tags, {'_',T})),T,A] || [T,A,_] <- Tags]),
	{Host, _} = cowboy_http_req:raw_host(Req),
	{Port, _} = cowboy_http_req:port(Req),
	{ok, Req2} = cowboy_http_req:reply(200, [{'Content-Type', <<"text/html">>}],
[<<"<html>
<head>
<meta charset='utf-8'>
<meta name='viewport' content='width=device-width'>
<title>Tagit</title>
<style>
body {
	margin: 0;
	font-size: 18px;
	line-height: 1.5em;
	background: #f5f5f5;
}
dt, dd{
	margin-top: 4px;
	margin-bottom: 4px;
}
input[type=text]{
	font-size: 18px;
	line-height: 24px;
	margin: 10px 0;
}
button {
	font-size: 16px;
	line-height: 22px;
}
input[placeholder]{
	font-size: 16px;
}
#home {
	display: -webkit-box; display: -moz-box; display: box;
	-webkit-box-orient: vertical;-moz-box-orient: vertical;box-orient: vertical;
	-webkit-box-align: center;-moz-box-align: center;flex-align: center;
	width: 100%;
}
#tags {
	display: -webkit-box; display: -moz-box; display: box;
	-webkit-box-orient: vertical;-moz-box-orient: vertical;box-orient: vertical;
	-webkit-box-align: start;-moz-box-align: start;flex-align: start;
	margin-top: 1em;
}
#tags > span {
	position: absolute;
	margin-top: -1.5em;
}
.tag {
	color: #ffffff;
	background-color: #5bc0de;
	cursor: pointer;
	padding: 0 5px;
	text-decoration: none;
	line-height: 1em;
}
.big{
	-webkit-border-radius: 2px;
	border-radius: 2px;
	display: block;
	font-size: 36px;
	margin: 5px .5em;
}
.title {
	-webkit-border-radius: 4px;
	border-radius: 4px;
	font-size: 64px;
	margin: 5px 8px;
}
.notif_{
	color: #0f0;
	position: absolute;
	margin-top: 12px;
	margin-left: 12px;
}
</style>
<script src='//ajax.googleapis.com/ajax/libs/jquery/1.9.0/jquery.min.js'></script>
<script type='text/javascript'>
window.onload = ready;
var tags=">>, Tagsj, <<", counts=">>, Countsj, <<";

function ready(){
	counts.sort().reverse();
	for (var i=0; i<tags.length; i++){
		$('#tags').append('<a class=\"tag big\" href=\"'+counts[i][1]+'\" title=\"'+counts[i][2]+'\">'+counts[i][1]+'</a><span>'+counts[i][0]+'</span>');
	}
}

function sub(tag, arg){
	$.get('/sub', {
			tag: tag,
			arg: arg
		}, function(res){
			$('<span class=\"notif_\">'+res+'</span>').insertAfter($('#add_tag_b')).fadeOut(5000);
		}
	);
}

function unsub(tag){
	$.get('/sub',{
			tag: JSON.stringify(tag),
			action: 'delete'
		}, function(res){
			alert(res);
		}
	);
}

</script>
</head>
<body>

<div id='home'>


<div style='margin: 5em 0;'>
	<a href='/' class='tag title'>Tag</a><a href='/' class='tag title'>it</a>
	<span style='font-size: 16px;color: #888;'>Create and Follow your Tags</span>
</div>


<div id='browse'>
	<input value='nba+basket+kobebryant/lakers' title='put tags separated with / for AND and + for OR (they are grouped by OR)' id='browse_tag' type='text' style='width: 320px;'>
	<button onclick='location.href=document.getElementById(\"browse_tag\").value'>Browse</button>
</div>
<div>
	<input placeholder='Tag name' id='add_tag' type='text' style='max-width: 100px;'>
	<input placeholder='Tag expression pattern matching' id='add_tag_arg' type='text' style='min-width: 240px;'>
	<button id='add_tag_b' onclick='sub(document.getElementById(\"add_tag\").value,document.getElementById(\"add_tag_arg\").value)'>Add</button>
</div>
<div id='tags'>
</div>

</div>

</body>
</html>">>], Req),
		
	{ok, Req2, State}.


terminate(_Req, _State) ->
	ok.

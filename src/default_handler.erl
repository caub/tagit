%% Feel free to use, reuse and abuse the code in this file.

-module(default_handler).
-behaviour(cowboy_http_handler).
-export([init/3, handle/2, terminate/2]).

init({_Any, http}, Req, []) ->
	{ok, Req, undefined}.

handle(Req, State) ->
	{PeerAddr, _} = cowboy_http_req:peer_addr(Req),
	{Path, _} = cowboy_http_req:path(Req),
	io:format("o21 ~p ~n", [Path]),
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
}
input[placeholder]{
	font-size: 14px;
}
button {
	font-size: 16px;
}
#home {
	display: -webkit-box; display: -moz-box; display: box;
	-webkit-box-orient: vertical;-moz-box-orient: vertical;box-orient: vertical;
	-webkit-box-align: center;-moz-box-align: center;flex-align: center;
	width: 100%;
}

#posts{
	-webkit-box-flex: 1;-moz-box-flex: 1;box-flex: 1;
	display: -webkit-box; display: -moz-box; display: box;
	-webkit-box-orient: vertical;-moz-box-orient: vertical;box-orient: vertical;
	margin-top: 2em;
}
#posts dt{
	margin-top: 1em;
}
#posts dt > time {
	color: #666;
	margin-left: 10px;
	font-size: 14px;
	float:right;
}
#tags {
	padding: 5px;
	display: none;
	background: #e5e5e5;
	right: 1em;
	position: absolute;
	top: 70px;
	line-height: 2em;
}
#tags > span {
	margin: 0 10px;
}
.tag {
	color: #ffffff;
	background-color: #5bc0de;
	-webkit-border-radius: 2px;
	border-radius: 2px;
	cursor: pointer;
	margin: 0 5px;
	padding: 1px 5px;
	text-decoration: none;
	font-size: 16px;
}
.big{
	font-size: 24px;
}
#post_{
	display: none;
	background: #d5d5d5;
	padding: 5px;
	right: 1em;
	position: absolute;
	top: 70px;
}
#header a{
	margin: 0 5px;
	cursor: pointer;
}
#post__s {
	float: right;
}
#home__s {
	float: left;
	font-weight: bold;
}
#header{
	background: #eaeaea;
	width: 100%;
	text-align: center;
	line-height: 2em;
}

</style>
<script src='//ajax.googleapis.com/ajax/libs/jquery/1.9.0/jquery.min.js'></script>
<script type='text/javascript'>
window.onload = ready;
window.onhashchange = change;
var ws, tags=">>, Tagsj, <<", counts=">>, Countsj, <<";

function ready(){
	change();
	if ('MozWebSocket' in window) {
		WebSocket = MozWebSocket;
	}
	if ('WebSocket' in window) {
		// browser supports websockets
		ws = new WebSocket('ws://">>, Host, <<":">>, list_to_binary(integer_to_list(Port)), <<"/websocket?path='+location.hash.substr(1));
		ws.onopen = function(evt) {
			console.log('websocket connected!');
		};
		ws.onmessage = function (evt) {
			var data = JSON.parse(evt.data);
			addMsg(data);
		};
		ws.onclose = function(evt) {
			console.log('websocket was closed');
			//unsub!
		};
	} else {
		// browser does not support websockets
		alert('sorry, your browser does not support websockets.');
	}

	counts.sort().reverse();
	for (var i=0; i<tags.length; i++){
		$('#tags').append('<br><span>'+counts[i][0]+'</span><a class=\"tag big\" onclick=\"location.hash=\\\''+counts[i][1]+'\\\'\">'+counts[i][1]+'</a><span>'+counts[i][2]+'</span>');
	}

	$('#browse_tag').val(location.hash.substr(1)||'nba+basket+kobebryant&lakers');
}

function change(evt){
	$('#posts > dl').empty();
	getPosts(location.hash.substr(1), 10);
	console.log(location.hash.substr(1));
	if (!!evt){
		ws.send(location.hash.substr(1));
	}
}

function addMsg(t){
	var msg = $('<dt id=\"'+t[0]+'\"><span class=\"message\">'+t[1]+'</span><time datetime=\"'+t[2]+'\">'+parseDate(t[2])+'</time></dt><dd>'+t[3]+'</dd>');
	for (var i=0; i<t[4].length; i++){
		msg.first().prepend('<a class=\"tag\" onclick=\"location.hash=\\\''+t[4][i]+'\\\'\">'+t[4][i]+'</a>');
	}
	msg.hide().prependTo('#posts > dl').fadeIn();
}

function parseDate(d){
	var x;
	if ((x = new Date(d)) != 'Invalid Date'){
		return x.toGMTString().split(/ ?gmt/i)[0];
	}else{
		return d.replace('T', ' ');
	}
}

function Post(){
	$.post('/pub',
		{
			author: $('#post_author').val(),
			text: $('#post_text').val()
		},
		function(res){
			//$('#post_').fadeOut();
		}
	);
}

function getPosts(path, count){
	$.getJSON('/pub', {path: path, count: count},
		function(res){
			for (var i=0; i<res.length; i++){
				addMsg(res[i]);
			}
			//$('<a onclick>load more</a>').appendTo('#posts > dl').fadeIn();
		}
	);
}
function sub(tag, arg){
	$.get('/sub', {
			tag: tag.trim().split(' ')[0],
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


terminate(_Req, _State) ->
	ok.

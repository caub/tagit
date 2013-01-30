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
	{ok, Pathj} = json:encode(Path),
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
	max-width: 100px;
}
input[placeholder]{
	font-size: 14px;
}
#home {
	display: -webkit-box; display: -moz-box; display: box;
	-webkit-box-orient: vertical;-moz-box-orient: vertical;box-orient: vertical;
	-webkit-box-align: center;-moz-box-align: center;flex-align: center;
	width: 100%;
}

#subs{
	display: -webkit-box; display: -moz-box; display: box;
	-webkit-box-pack: center;-moz-box-pack: center;flex-pack: center;
	-webkit-box-align: center;-moz-box-align: center;flex-align: center;
	width: 100%;
	background: #e5e5e5;
	margin-bottom: 3em;
	min-height: 60px;
}
#posts{
	-webkit-box-flex: 1;-moz-box-flex: 1;box-flex: 1;
	display: -webkit-box; display: -moz-box; display: box;
	-webkit-box-orient: vertical;-moz-box-orient: vertical;box-orient: vertical;
	margin-top: 5em;
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
	background: #e5e5e5;
	padding: 5px;
	right: 1em;
	position: absolute;
	top: 70px;
}
#post__s {
	float: right;
	cursor: pointer;
}
#home__s {
	float: left; 
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
var ws, path=">>, Pathj, <<";

function ready(){
	getPosts();
	if ('MozWebSocket' in window) {
		WebSocket = MozWebSocket;
	}
	if ('WebSocket' in window) {
		// browser supports websockets
		ws = new WebSocket('ws://">>, Host, <<":">>, list_to_binary(integer_to_list(Port)), <<"/websocket?path='+JSON.stringify(path));
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
	var s='';
	for (var i=0; i<path.length; i++){
		var parts = path[i].split(' ');s+='& (';
		for (var j=0; j<parts.length; j++){
			s += '<a class=\"tag big\" href=\"'+('/'+parts[j])+'\">'+parts[j]+'</a>'
		}
		s+=') ';
	}
	$('#header').append(s.substr(1));
}

function addMsg(t){
	var msg = $('<dt id=\"'+t[0]+'\"><span class=\"message\">'+t[1]+'</span><time datetime=\"'+t[2]+'\">'+parseDate(t[2])+'</time></dt><dd>'+t[3]+'</dd>');
	for (var i=0; i<t[4].length; i++){
		msg.first().prepend('<a class=\"tag\" href=\"'+(location.href+'/'+t[4][i])+'\">'+t[4][i]+'</a>');
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
			$('#post_').fadeOut();
		}
	);
}

function getPosts(){
	$.getJSON('/pub', {path: JSON.stringify(path)},
		function(res){
			for (var i=0; i<res.length; i++){
				addMsg(res[i]);
			}
		}
	);
}

</script>
</head>
<body>

<div id='home'>

<div id='header'>
	<a id='home__s' href='/'>&larr; Home</a>
	<a id='post__s' onclick='$(\"#post_\").fadeToggle();'>Write</a>
</div>



<div id='post_'>
	<input placeholder='author' id='post_author' type='text' value='jack'><br>
	<textarea id='post_text'>Hello!, send something</textarea><br>
	<button onclick='Post()' style='float: right;'>Send</button>
</div>

<div id='posts'>
	<dl></dl>
</div>

</div>

</body>
</html>">>], Req),
		
	{ok, Req2, State}.


terminate(_Req, _State) ->
	ok.

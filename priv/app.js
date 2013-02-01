
window.onload = ready;
window.onhashchange = change;


function ready(){
	change();
	if ('MozWebSocket' in window) {
		WebSocket = MozWebSocket;
	}
	if ('WebSocket' in window) {
		// browser supports websockets
		ws = new WebSocket('ws://'+location.host+'/websocket?path='+location.hash.substr(1));
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

	tags.sort(function(a,b){return b[0]-a[0];});
	for (var i=0; i<tags.length; i++){
		$('#tags').append('<br><span>'+tags[i][0]+'</span><a class="tag big" onclick="location.hash=\''+tags[i][1]+'\'">'+tags[i][1]+'</a><span>'+tags[i][2]+'</span>');
	}

	$('#browse_tag').val(location.hash.substr(1)||'fubar+any+tag&erlang');
}

function change(evt){
	$('#posts > dl').empty();
	getPosts(location.hash.substr(1), 10);
	if (!!evt){
		ws.send(location.hash.substr(1));
	}
}

function addMsg(t){
	var msg = $('<dt id="'+t[0]+'"><span class="message">'+t[1]+'</span><time datetime="'+t[2]+'">'+parseDate(t[2])+'</time></dt><dd>'+t[3]+'</dd>');
	for (var i=0; i<t[4].length; i++){
		msg.first().prepend('<a class="tag" onclick="location.hash=\''+t[4][i]+'\'">'+t[4][i]+'</a>');
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
			res.sort();
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
			$('<span class="notif_">'+res+'</span>').insertAfter($('#add_tag_b')).fadeOut(5000);
		}
	);
}

function unsub(tag){
	$.get('/sub',{
			tag: tag,
			action: 'delete'
		}, function(res){
			alert(res);
		}
	);
}
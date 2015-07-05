// Your websocket URI should be an absolute path. The following sets the base URI.
var ws_uri = 'ws://' + window.location.hostname + (window.location.port == '' ? '' : (':' + window.location.port) );
// remember to add the specific controller's path to your websocket URI.
ws_uri += "/";
// websocket variable.
var websocket = NaN

function init_websocket()
{
	websocket = new WebSocket(ws_uri);
	websocket.onopen = function(e) {
		// what do you want to do now?
	};

	websocket.onclose = function(e) {
		// you probably want to reopen the websocket if it closes.
		init_websocket()
	};
	websocket.onerror = function(e) {
		// what do you want to do now?
	};
	websocket.onmessage = function(e) {
		// what do you want to do now?
		console.log(e.data);
		// to use JSON, use:
		// msg = JSON.parse(e.data); // remember to use JSON also in your Plezi controller.
	};
}
window.addEventListener("load", init_websocket, false); 

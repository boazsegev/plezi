
// remember to set your websocket uri as an absolute path!
var ws_uri = "ws://echo.websocket.org/";
var websocket = NaN

function init_websocket()
{
	websocket = new WebSocket(ws_uri);
	websocket.onopen = function(e) { on_open(e) };
	websocket.onclose = function(e) { on_close(e) };
	websocket.onmessage = function(e) { on_message(e) };
	websocket.onerror = function(e) { on_error(e) }; }

	function on_open(e) {
		// what do you want to do now?
	}
	function on_close(e) {
		// you probably want to reopen the websocket if it closes.
		init_websocket()
	}
	function on_message(e) {
		// what do you want to do now?
	} 
	function on_error(e) {
		// what do you want to do now?
	}
}
window.addEventListener("load", init, false); 
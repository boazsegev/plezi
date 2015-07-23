// Add this file to your html to add websocket support

// Your websocket URI should be an absolute path. The following sets the base URI.
// remember to update to the specific controller's path to your websocket URI.
var ws_controller_path = window.location.pathname; // change to '/controller/path'
var ws_uri = (window.location.protocol.match(/https/) ? 'wss' : 'ws') + '://' + window.location.hostname + (window.location.port == '' ? '' : (':' + window.location.port) ) + ws_controller_path
// websocket variable.
var websocket = NaN
// count failed attempts
var websocket_fail_count = 0
// to limit failed reconnection attempts, set this to a number.
var websocket_fail_limit = NaN


function init_websocket()
{
	websocket = new WebSocket(ws_uri);
	websocket.onopen = function(e) {
		// reset the count.
		websocket_fail_count = 0
		// what do you want to do now?
	};

	websocket.onclose = function(e) {
        // If the websocket repeatedly you probably want to reopen the websocket if it closes
        if(!isNaN(websocket_fail_limit) && websocket_fail_count >= websocket_fail_limit) {
        	// What to do if we can't reconnect so many times?
        	return
        };
		// you probably want to reopen the websocket if it closes.
		if(isNaN(websocket_fail_limit) || (websocket_fail_count <= websocket_fail_limit) ) {
			// update the count
			websocket_fail_count += 1;
			// try to reconect
			init_websocket();
		};
	};
	websocket.onerror = function(e) {
		// update the count.
		websocket_fail_limit += 1
		// what do you want to do now?
	};
	websocket.onmessage = function(e) {
		// what do you want to do now?
		console.log(e.data);
		// to use JSON, use:
		// msg = JSON.parse(e.data); // remember to use JSON also in your Plezi controller.
	};
}
// setup the websocket connection once the page is done loading
window.addEventListener("load", init_websocket, false); 

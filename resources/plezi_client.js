// This is a commonly used structure for WebSocket messanging.
// The documentation is available on the www.plezi.io website:
// http://www.plezi.io/docs/websockets#websocket-json-auto-dispatch
//
// Basics:
// To open a websocket connection to the current location:
//
//      var client = new PleziClient()
//
// To open a connection to a different path for the original server (SSL will be preserved when in use), use:
//
//      var client = new PleziClient(PleziClient.origin + "/path")
//
// To automatically renew the connection when disconnections are reported by the browser, use:
//
//      client.reconnect = true
//      client.reconnect_interval = 250 // sets how long to wait before reconnection attempts. default is 50 ms.
//
// To set up event handling, directly set an `<event name>` callback. i.e., for an event called `chat`:
//
//      client.chat = function(event) { "..." }
//
// To sent / emit event in JSON format, use the `emit` method:
//
//      client.emit({event: "chat", data: "the message"})
//
function PleziClient(url, reconnect) {
    // Set connected ststus (none).
    this.connected = NaN;
    // Set URL
    if(url) {
        this.url = url
    } else {
        this.url = PleziClient.origin + window.location.pathname
    }
    // Connect Websocket
    this.ws = new WebSocket(this.url);
    // needed to access this object from the websocket callback.
    this.ws.owner = this
    // auto-reconnection
    this.reconnect = false;
    this.reconnect_interval = 50
    // the timeout for a message ack receipt
    this.emit_timeout = false
    // Set the reconnect property
    if(reconnect) {this.reconnect = true;}
    // The Websocket onopen callback
    this.ws.on_open = this.___on_open
    // The Websocket onclose callback
    this.ws.onclose = this.___on_close
    // The Websocket onerror callback
    this.ws.onerror = this.___on_error
    // The Websocket onmessage callback
    this.ws.onmessage = this.___on_message
}
// The Websocket onopen callback
PleziClient.prototype.___on_open = function(e) {
    this.owner.connected = true;
    if (this.owner.onopen) { this.owner.onopen(e) }
}
// The Websocket onclose callback
PleziClient.prototype.___on_close = function(e) {
    this.connected = false;
    if (this.owner.onclose) { this.owner.onclose(e) }
    if(this.owner.reconnect) {
        setTimeout( function(obj) {
            obj.connected = NaN;
            obj.ws = new Websocket(obj.url);
            obj.ws.owner = obj
        }, this.reconnect_interval, this.owner);
    }
}
// The Websocket onerror callback
PleziClient.prototype.___on_error = function(e) {
    if (this.owner.onerror) {this.owner.onerror(e)}
}
// The Websocket onmessage callback
PleziClient.prototype.___on_message = function(e) {
    try {
        var msg = JSON.parse(e.data);
        if ( msg.event == '_ack_') { clearTimeout(msg._EID_) }
        if ( (msg.event) && (this.owner[msg.event])) {
            this.owner[msg.event](msg);
        } else if ( (msg.event) && (this.owner['on' + msg.event])) {
            console.warn('PleziClient: use a callback called "' + msg.event +
                '" instead of of "on' + msg.event + '"');
            this.owner['on' + msg.event](msg);
        } else
        {
            if (this.owner['unknown'] && (msg.event != '_ack_') ) {this.owner['unknown'](msg)};
        }
    } catch(err) {
        console.error("PleziClient experienced an error while responding to the following onmessage event",
            err, e)
    }
}
// Sets a timeout for the websocket message
PleziClient.prototype.___set_failed_timeout = function(event, callback, timeout) {
    if(event._EID_) {return event;};
    if(!timeout) { timeout = this.emit_timeout; };
    if(!callback) { callback = this.___on_timeout; };
    if(!timeout) { return event; };
    event._EID_ = setTimeout(callback, timeout, event, this);
    return event;
}
// Removes the _client_ property from the event and calls
// the ontimeout callback within the correct scope
PleziClient.prototype.___on_timeout = function(event, client) {
    client.ontimeout(event)
}
// The timeout callback
PleziClient.prototype.ontimeout = function(event) {
    console.warn("Timeout reached - it's assumed the connection was lost " +
        "and the following event was ignored by the server:", event);
    console.log(this);
}

PleziClient.prototype.close = function() {
    this.reconnect = false;
    this.ws.close();
}

PleziClient.origin = (window.location.protocol.match(/https/) ? 'wws' : 'ws') + '://' + window.location.hostname + (window.location.port == '' ? '' : (':' + window.location.port) );

PleziClient.prototype.sendraw = function(data) {
    if (this.ws.readyState != 1) { return false; }
    this.ws.send(data);
    if (this.ws.readyState != 1) { return false; }
    return true
}

PleziClient.prototype.emit = function(event, callback, timeout) {
    this.___set_failed_timeout(event, callback, timeout)
    return this.sendraw( JSON.stringify(event) );
}

PleziClient.prototype.readyState = function() { return this.ws.readyState; }

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
//      client.autoreconnect = true
//      client.reconnect_interval = 250 // sets how long to wait before reconnection attempts. default is 250 ms.
//
// To set up event handling, directly set an `<event name>` callback. i.e., for an event called `chat`:
//
//      client.chat = function(event) { "..." }
//
// To sent / emit event in JSON format, use the `emit` method:
//
//      client.emit({event: "chat", data: "the message"})
//
function PleziClient(url, autoreconnect) {
    // Set URL
    if(url) {
        this.url = url
    } else {
        this.url = PleziClient.origin + self.location.pathname
    }
    // Connect Websocket
    this.reconnect();
    // Setup AJAJ
    this.ajaj = {};
    this.ajaj.client = this
    this.ajaj.url = this.url.replace(/^ws:\/\//i, "http://").replace(/^wss:\/\//i, "https://");
    this.ajaj.add = {};
    this.ajaj.emit = this.___ajaj__emit;
    this.ajaj.auto = false
    // auto-reconnection
    this.autoreconnect = false;
    this.reconnect_interval = 200
    // dump data to console?
    this.log_events = false
    // the timeout for a message ack receipt
    this.emit_timeout = false
    // Set the autoreconnect property
    if(autoreconnect) {this.autoreconnect = true;}
}
// The Websocket onopen callback
PleziClient.prototype.___on_open = function(e) {
    this.owner.connected = true;
    if (this.owner.onopen) { this.owner.onopen(e) }
}
// The Websocket onclose callback
PleziClient.prototype.___on_close = function(e) {
    this.owner.connected = false;
    if (this.owner.onclose) { this.owner.onclose(e) }
    if(this.owner.autoreconnect) {
        setTimeout( function(obj) {
            obj.reconnect();
        }, this.owner.reconnect_interval, this.owner);
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
        this.owner.___dispatch(msg);
    } catch(err) {
        console.error("PleziClient experienced an error parsing the following data (not JSON):",
            err, e.data)
    }
}
PleziClient.prototype.___dispatch = function(msg) {
    try {
        if (this.log_events) {console.log(msg)}
        if ( msg.event == '_ack_') { clearTimeout(msg._EID_) }
        if ( (msg.event) && (this[msg.event])) {
            this[msg.event](msg);
        } else if ( (msg.event) && (this['on' + msg.event])) {
            console.warn('PleziClient: use a callback called "' + msg.event +
                '" instead of of "on' + msg.event + '"');
            this['on' + msg.event](msg);
        } else
        {
            if (this['unknown'] && (msg.event != '_ack_') ) {this['unknown'](msg)};
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
    if (client.ajaj.auto) {
        if (client.log_events) {console.log("falling back on AJAJ for the event:", event)}
        client.ajaj.emit(event, client.ontimeout);
    } else {
        client.ontimeout(event);
    }
}
// The timeout callback
PleziClient.prototype.ontimeout = function(event) {
    console.warn("Timeout reached - it's assumed the connection was lost " +
        "and the following event was ignored by the server:", event);
    console.log(this);
}

PleziClient.prototype.reconnect = function() {
    this.connected = NaN;
    this.ws = new WebSocket(this.url);
    // lets us access the client from the callbacks
    this.ws.owner = this
    // The Websocket onopen callback
    this.ws.onopen = this.___on_open
    // The Websocket onclose callback
    this.ws.onclose = this.___on_close
    // The Websocket onerror callback
    this.ws.onerror = this.___on_error
    // The Websocket onmessage callback
    this.ws.onmessage = this.___on_message
}

PleziClient.prototype.close = function() {
    this.autoreconnect = false;
    this.ws.close();
}

PleziClient.origin = (self.location.protocol.match(/https/) ? 'wws' : 'ws') + '://' + self.location.hostname + (self.location.port == '' ? '' : (':' + self.location.port) );

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

PleziClient.prototype.___ajaj__emit = function(event, callback) {
    var combined = {}
    for (var k in this.add) {combined[k] = this.add[k];};
    for (var k in event) {combined[k] = event[k];};
    if(!combined.id) {combined.id = event.event;};
    var req = new XMLHttpRequest();
    req.client = this.client;
    req.json = combined;
    req.callback = callback
    // if(!req.callback) req.callback = this.failed
    req.onreadystatechange = function() {
        if (this.readyState != 4) { return }
        if (this.status == 200) {
            try {
                var res = JSON.parse(this.responseText);
                this.client.___dispatch(res);
            } catch(err) {
                console.error("PleziClient experienced an error parsing the following data (not JSON):",
            err, this.responseText)
            }

        } else {
            if(this.callback) {
                this.callback(this.json);
            }
        }
    }
    req.open("POST", this.url ,true);
    req.setRequestHeader("Content-type", "application/json");
    try {
        req.send(JSON.stringify(combined));
    } catch(err) {
        callback(event)
    }
}

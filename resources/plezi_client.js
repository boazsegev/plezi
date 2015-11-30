// This is a commonly used structure for WebSocket messanging.
//
// To open a websocket connection to the current location
// (i.e, "https://example.com/path" => "wss://example.com/path"), use:
//
//      var client = new PleziClient()
//
// To open a connection to a different path for the original server (SSL will be preserved when in use), use:
//
//      var client = new PleziClient(PleziClient.origin + "/path")
//
// i.e., to open a connection to the root ("/"), use:
//
//      var client = new PleziClient(PleziClient.origin + "/")
//
// To open a connection to a different URL or path, use:
//
//      var client = new PleziClient("ws://full.url.com/path")
//
// To automatically renew the connection when disconnections are reported by the browser, use:
//
//      client.reconnect = true
//      client.reconnect_interval = 250 // sets how long to wait before reconnection attempts. default is 50 ms.
//
// The automatic renew flag can be used when creating the client, using:
//
//      var client = new PleziClient(PleziClient.origin + "/path", true)
//      client.reconnect_interval = 250 // Or use the default 50 ms.
//
// To set up event handling, directly set an `on<event name>` callback. i.e., for an event called `chat`:
//
//      client.onchat = function(event) { "..." }
//
// To sent / emit event in JSON format, use the `emit` method:
//
//      client.emit({event: "chat", data: "the message"})
//
// To sent raw websocket data, use the `send` method.
// This might cause disconnetions if Plezi's controller uses `auto_dispatch`.
// i.e. sending a string:
//
//      client.send("string")
//
// Manually closing the connection will prevent automatic reconnection:
//
//      client.close()
//
function PleziClient(url, reconnect) {
    this.connected = NaN;
    if(url) {
        this.url = url
    } else {
        this.url = PleziClient.origin + window.location.pathname
    }
    
    this.ws = new WebSocket(this.url);
    this.ws.owner = this
    this.reconnect = false;
    this.reconnect_interval = 50
    if(reconnect) {this.reconnect = true;}
    this.ws.onopen = function(e) {
        this.owner.connected = true;
        if (this.owner.onopen) { this.owner.onopen(e) }
    }
    this.ws.onclose = function(e) {
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
    this.ws.onerror = function(e) { if (this.owner.onerror) {this.owner.onerror(e)} }
    this.ws.onmessage = this.___on_message
}

PleziClient.prototype.___on_message = function(e) {
    try {
        var msg = JSON.parse(e.data);
        if ( (msg.event) && (this.owner['on' + msg.event])) {
            this.owner['on' + msg.event](msg);
        } else
        {
            if (this.owner['unknown']) {this.owner['unknown'](msg)};
        }
    } catch(err) {
        console.error(err)
    }
}

PleziClient.prototype.close = function() {
    this.reconnect = false;
    this.ws.close();
}

PleziClient.origin = (window.location.protocol.match(/https/) ? 'wws' : 'ws') + '://' + window.location.hostname + (window.location.port == '' ? '' : (':' + window.location.port) );

PleziClient.prototype.send = function(data) {
    if (this.ws.readyState != 1) { return false; }
    this.ws.send(data);
    if (this.ws.readyState != 1) { return false; }
    return true
}

PleziClient.prototype.emit = function(data) {
    return this.send( JSON.stringify(data) );
}

PleziClient.prototype.readyState = function() { return this.ws.readyState; }

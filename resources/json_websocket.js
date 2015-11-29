function PleziClient(url, reconnect) {
    this.connected = NaN;
    this.url = url
    this.ws = new WebSocket(url);
    this.reconnect = false;
    this.reconnect_interval = 50
    if(reconnect) {this.reconnect = true;}
    this.ws.onopen = function(e) {
        this.connected = true;
        if (this.onopen) { this.onopen(e) }
    }
    this.ws.onclose = function(e) {
        this.connected = false;
        if(this.reconnect) {
            setTimeout( function() {
                this.connected = NaN;
                this.ws = new Websocket(url);
            }, this.reconnect_interval);
        }
        if (this.onclose) { this.onclose(e) }
    }
    this.ws.onerror = function(e) { if (this.onerror) {this.onerror(e)} }
    this.ws.onmessage = this.___on_message
}

PleziClient.prototype.___on_message = function(e) {
    try {
        var msg = JSON.parse(e.data);
        if ( (msg.event) && (this['on' + msg.event])) {
            this['on' + msg.event](msg);
        }
    } catch(err) {
        console.error(err)
    }
}

PleziClient.prototype.close = function() {
    this.reconnect = false;
    this.ws.close();
}

PleziClient.prototype.send = function(data) {
    this.ws.send(data);
}

PleziClient.prototype.emit = function(data) {
    this.ws.send(JSON.stringify(data));
}
# Plezi Websockets

Inside Plezi's core code is a pure Ruby HTTP and Websocket Server (and client) called [GRHttp](https://github.com/boazsegev/GRHttp) (Generic HTTP), a wonderful server that supports an effective websocket fanctionality both as a server and as a client.

Plezi augmentes GRHttp by adding auto-Redis support for scaling and automatically mapping each Contoller as a broadcast channel and each server instance to it's own unique channel (allowing unicasting to direct it's message at the target connection's server).



(todo: write documentation)






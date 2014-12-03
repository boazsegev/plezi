# server object\file structure

- services

this folder holds the modules and classes regarding the core-services classes (normal TCP/IP service and SSL service should be here).

services have one protocol that parses incoming requests and one handler that takes the parsed request and responds to it.

both protocols and handlers can be changed mid-stream, allowing a service to switch protocols (such as from HTTP to WebSockets, HTTP/1.1 to SPDY etc') or a handler.

- protocols

this folder holds the different protocols that could be run over the each socket-service (HTTP / WebSockets etc' should be here).

the protocols are devided into two different classes/object types:

1. parsing input.
2. formatting output.

- handlers

this folder holds the classes and modules used to actually handle the requests parsed by the protocol layer.

these are the classes and modules the Anorexic framework users (developers) connect with when writing their web apps.

## servers, services and protocols ... what?

services are the part of the server that recieves and sends data - services run specific protocols that together make up the whole of a server.

this division allows the user to change protocols mid-stream when allowed (such as switching from HTTP to WebSockets).

this abstraction to the sockets layer allows support for future or custom protocols without any changes to the abstraction layer.


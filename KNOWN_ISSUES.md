# Known Issues

Here we will list known issues and weather or not a solution is being persued.

## Haml

Haml doesn't play well with multiple concurrent requests... looking into that. caching templates did not solve the issue (not file access).

## Benchmarks hang for chuncked data and missing mimetypes?

the Apache benchmark hangs some requests, when chuncked data and missing mimetypes are introduced...

is this a server or benchmark error?

## Assetes

non-cachable assests (images etc') fail with 404 instead of being rendered from the file itself.

## Assetes/WSProtocol (WebSockets)

frame parsing for large frames is unreasonably slow... benchmark show that some frames take seconds(!) to parse (a 0.25MB frame takes about 15 seconds to process...)

If anyone finds the cause and comes up with a solution... I'd be happy to merge it into the project. 


# Known Issues

Here we will list known issues and weather or not a solution is being persued.

## Assetes/Sass
Anorexic/server/http_host ::

Sass assets refresh takes more resources then expected. the memory usage is unexplained.
Maybe the Assets system should be revisited, maybe a bug with the Sass Engine...?

at the moment, Sass refresh will only observe the root Sass file and ignore any included files.

observing the root file (without the included files) is done using mtime with Anorexic and doesn't cause noticable delays.

## Assetes/WSProtocol (WebSockets)

frame parsing for large frames is unreasonably slow... benchmark show that some frames take seconds(!) to parse (a 0.25MB frame takes about 15 seconds to process...)

If anyone finds the cause and comes up with a solution... I'd be happy to merge it into the project. 


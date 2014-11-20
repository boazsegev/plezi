# Known Issues

Here we will list known issues and weather or not a solution is being persued.

## Haml

Haml doesn't play well with multiple concurrent requests... looking into that. caching Haml Engine objects mitigated the issue, but there is still more to solve. maybe an HTTPResponse issue?

## Benchmarks hang for chuncked data and missing mimetypes?

the Apache benchmark hangs some requests, when chuncked data and missing mimetypes are introduced...

is this a server or benchmark error?

## Assetes

non-cachable assests (images etc') fail with 404 instead of being rendered from the file itself.

## Idle CPU usage

Anorexic never really sleeps... idling uses some CPU (more on MRI, less on JRuby)... looking for solutions that don't block.
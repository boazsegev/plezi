# Known Issues

Here we will list known issues and weather or not a solution is being persued.

## Caching?

seems caching sometimes fails ( data isn't cached / cache keeps reloading)...?

## Haml

Haml doesn't play well with multiple concurrent requests... looking into that. caching Haml Engine objects mitigated the issue, but there is still more to solve. maybe an HTTPResponse issue?

## Chuncked data issues? or Apache benchmarks bug?

the Apache benchmark hangs some requests, when chuncked data and missing mimetypes are introduced...

is this a server or benchmark error?

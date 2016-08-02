#!/usr/bin/env bash

# Edit these parameters if you wish to leverage multi-process concurrency. i.e.:
#       bundle exec iodine -t 16 -w 4 -www ./public # => 4 processes
bundle exec iodine -t 16 -w 1 -www ./public -p $PORT

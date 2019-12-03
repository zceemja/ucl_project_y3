#!/bin/bash

h1=`sha1sum $1 | cut -d " " -f1`
h2=`echo -n $2 | sha1sum | cut -d " " -f1`

[[ "$h1" == "$h2" ]] && echo "OK" || echo "FAIL"

#!/bin/bash
echo -n `grep -o '^[^//]*' "$1" | tr [:lower:] [:upper:] | tr -d '\n '`


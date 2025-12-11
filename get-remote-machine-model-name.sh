#!/bin/sh
set -eu
IFS=$(printf "\n\t")
# scratch=$(mktemp -d -t tmp.XXXXXXXXXX)
# atexit() {
#   rm -rf "$scratch"
# }
# trap atexit EXIT

ssh "$@" sh -c 'echo | gcc -march=native -Q --help=target | grep march | head -n 1 | sed "s/^.*-march=[[:space:]]*//"'

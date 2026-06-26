#!/bin/sh
printf '\033c\033]0;%s\a' Fight I
base_path="$(dirname "$(realpath "$0")")"
"$base_path/Fight I.x86_64" "$@"

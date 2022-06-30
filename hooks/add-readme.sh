#!/bin/bash
FILE=README.md
if  test -f "$FILE"; then
    git add README.md
    exit 0
else
    echo "$FILE does not exist. Add the README.MD file to your repo before commiting."
    exit 1
fi
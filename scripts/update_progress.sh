#!/bin/bash

PARENT_COMMAND="$(ps -o comm= $PPID)"

echo "[ "$PARENT_COMMAND" ]: " $1

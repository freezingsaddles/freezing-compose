#!/usr/bin/env bash
# recover-container-name-conflict.sh
#
# Recover from the Docker error where existing docker-compose containers
# have the same names as new incoming ones.
# Blast the old ones until they are gone.
#
# This is kind of a hack because when it is done it will emit this error:
#
#   "docker rm" requires at least 1 argument.
#   See 'docker rm --help'.
#
#   Usage:  docker rm [OPTIONS] CONTAINER [CONTAINER...]
#
#   Remove one or more containers
#
# MIT Licensed
#
# Copyright 2024 Richard Bullington-McGuire
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject
# to the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
# BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
# ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
# CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

while docker compose up -d 2>&1 \
	| awk '/Error response from daemon: Conflict. The container name/{print $16}' \
	| cut -d\" -f 2 \
	| xargs docker rm; do
	echo "conflicting container removed"
done

#!/usr/bin/env bash
# Remove old docker images

HOURS=${1:-168} # Default 168 hours (7 days)
# Thanks https://forums.docker.com/t/simple-script-needed-to-delete-all-docker-images-over-4-weeks-old/28558/7
docker image prune --all --filter until="$HOURS" --force

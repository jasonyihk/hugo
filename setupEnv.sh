#!/bin/sh
set -ex

$(cat deploy/config/process.json | jq -r 'to_entries | map("export \(.key)=\(.value)") | .[] ')

#!/bin/sh
# Stable LaunchAgent entry point. Homebrew's node binary is replaced on
# upgrades; pointing the plist at this script keeps the launch constraint
# valid so provision can still run.
exec /opt/homebrew/bin/node "$HOME/.hindsight/local-tools/knowledge-pages.mjs" provision

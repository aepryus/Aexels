#!/bin/sh
# Aexels's AI prompt (AI/prompt.py), published to Pequod, which adds it to the tray's requests and keeps it warm
# on Opus. Run it whenever the instructions, the reference, an article or a paper changes; with --to <file> it
# writes the prompt there instead, to look at.
set -e
cd "$(dirname "$0")/.."
python3 -I AI/prompt.py | python3 -I ../Pequod/Tools/publish.py aexels.tray opus "$@"

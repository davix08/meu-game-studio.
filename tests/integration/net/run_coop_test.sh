#!/usr/bin/env bash
# Two-process coop test: a host and a client Godot on 127.0.0.1 (design/gdd/coop-lan.md).
# Exit 0 only when BOTH sides pass. Run from the project root.
set -u
GODOT="${GODOT:-godot}"
"$GODOT" --headless --path . -s res://tests/integration/net/coop_peer.gd -- host > /tmp/coop_host.log 2>&1 &
HOST=$!
sleep 1
"$GODOT" --headless --path . -s res://tests/integration/net/coop_peer.gd -- client > /tmp/coop_client.log 2>&1
CLIENT_RC=$?
wait $HOST
HOST_RC=$?
grep -E "^(PASS|FAIL)" /tmp/coop_host.log /tmp/coop_client.log
if [ $HOST_RC -eq 0 ] && [ $CLIENT_RC -eq 0 ]; then echo "coop integration: PASS"; exit 0; fi
echo "coop integration: FAIL (host=$HOST_RC client=$CLIENT_RC)"; exit 1

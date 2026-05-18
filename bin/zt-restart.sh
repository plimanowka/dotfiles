#!/usr/bin/env bash
# Restart the ZeroTier background daemon on macOS.
# Fixes the GUI hanging on "waiting for service to start" when the
# com.zerotier.one launchd daemon has died or never loaded.
set -euo pipefail

DAEMON="system/com.zerotier.one"
PLIST="/Library/LaunchDaemons/com.zerotier.one.plist"

if [[ "$(uname)" != "Darwin" ]]; then
	echo "zt-restart: macOS only (this manages a launchd daemon)" >&2
	exit 1
fi

if [[ ! -f "$PLIST" ]]; then
	echo "zt-restart: $PLIST not found — is ZeroTier installed?" >&2
	exit 1
fi

echo "zt-restart: kickstarting $DAEMON ..."
if ! sudo launchctl kickstart -k "$DAEMON" 2>/dev/null; then
	# Daemon not bootstrapped at all — load it, then start it.
	echo "zt-restart: not loaded, bootstrapping from $PLIST ..."
	sudo launchctl bootstrap system "$PLIST"
	sudo launchctl kickstart -k "$DAEMON"
fi

# Give the daemon a moment to open its control socket.
for _ in 1 2 3 4 5 6 7 8 9 10; do
	pgrep -f zerotier-one >/dev/null 2>&1 && break
	sleep 0.5
done

if ! pgrep -f zerotier-one >/dev/null 2>&1; then
	echo "zt-restart: daemon process still not running — check Console.app for com.zerotier.one" >&2
	exit 1
fi

echo "zt-restart: daemon up — status:"
zerotier-cli info

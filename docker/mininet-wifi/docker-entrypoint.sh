#!/bin/bash
set -e

# bring up OVS if available
if command -v ovs-vswitchd >/dev/null 2>&1; then
  echo "Starting OVS (if not running) ..."
  # Note: on some setups you must run 'ovsdb-server' then 'ovs-vswitchd'
  ovsdb-server --remote=punix:/var/run/openvswitch/db.sock --detach || true
  ovs-vsctl --no-wait init || true
  ovs-vswitchd --pidfile --detach || true
fi

# try to enable mac80211_hwsim if possible
if modprobe -n mac80211_hwsim >/dev/null 2>&1; then
  modprobe mac80211_hwsim || true
fi

exec "$@"
#!/usr/bin/env bash
# Launch an agentless, disposable k3s API and run the discovery integration test.
set -euo pipefail

k3s_binary=${K3S_BINARY:-k3s}
port=${K3S_TEST_PORT:-16443}
tmp=$(mktemp -d)
pid=
cleanup() {
  if [[ -n $pid ]]; then
    kill "$pid" 2>/dev/null || true
    wait "$pid" 2>/dev/null || true
  fi
  rm -rf "$tmp"
}
trap cleanup EXIT

"$k3s_binary" server \
  --cluster-init --disable-agent --node-ip=127.0.0.1 --advertise-address=127.0.0.1 \
  --disable-network-policy --flannel-backend=none \
  --disable=traefik --disable=servicelb --disable=local-storage --disable=metrics-server \
  --data-dir="$tmp/data" --write-kubeconfig="$tmp/kubeconfig" \
  --https-listen-port="$port" --bind-address=127.0.0.1 \
  >"$tmp/server.log" 2>&1 &
pid=$!

ready=false
for _ in {1..120}; do
  if [[ -f $tmp/kubeconfig ]] && "$k3s_binary" kubectl \
    --kubeconfig "$tmp/kubeconfig" get --raw=/readyz >/dev/null 2>&1; then
    ready=true
    break
  fi
  if ! kill -0 "$pid" 2>/dev/null; then break; fi
  sleep 1
done
if [[ $ready != true ]]; then
  cat "$tmp/server.log" >&2
  echo "k3s API did not become ready" >&2
  exit 1
fi

export LUAKUBE_TEST_KUBECONFIG="$tmp/kubeconfig"
busted --lua="$(command -v lua)" spec/system/discovery_spec.lua

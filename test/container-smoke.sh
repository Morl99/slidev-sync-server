#!/usr/bin/env sh
set -eu
image=${1:?Usage: container-smoke.sh IMAGE}
container=''
cleanup() { if [ -n "$container" ]; then docker rm -f "$container" >/dev/null; fi; }
trap cleanup EXIT INT TERM
for mode in sse ws; do
  websocket=''
  if [ "$mode" = ws ]; then websocket=true; fi
  if [ -n "${SMOKE_USER:-}" ]; then
    set -- --user "$SMOKE_USER"
  else
    set --
  fi
  container=$(docker run -d --read-only --cap-drop=ALL \
    --security-opt=no-new-privileges "$@" -e "WS=$websocket" "$image")
  for attempt in $(seq 1 30); do
    if docker exec "$container" node -e '
      const net = require("node:net");
      const socket = net.connect(8080, "127.0.0.1", () => socket.end());
      socket.on("error", () => process.exit(1));
    ' >/dev/null 2>&1; then break; fi
    sleep 1
  done
  if [ "$mode" = sse ]; then
    docker exec "$container" node --input-type=module -e '
      import assert from "node:assert/strict";
      const response = await fetch("http://127.0.0.1:8080/event?uid=smoke", {
        headers: {accept: "text/event-stream"}, signal: AbortSignal.timeout(5000)
      });
      assert.equal(response.status, 200);
      assert.match(response.headers.get("content-type"), /text\/event-stream/);
      await response.body.cancel();
    '
  else
    docker exec "$container" node --input-type=module -e '
      import assert from "node:assert/strict";
      const timer = setTimeout(() => process.exit(1), 5000);
      const ws = new WebSocket("ws://127.0.0.1:8080");
      ws.onerror = () => process.exit(1);
      ws.onopen = () => {
        ws.send(JSON.stringify({type:"connect", id:"smoke", uid:"a", states:{slide:{page:1}}}));
        ws.send(JSON.stringify({type:"connect", id:"smoke", uid:"a"}));
      };
      ws.onmessage = event => {
        assert.equal(JSON.parse(event.data).states.slide.page, 1);
        clearTimeout(timer);
        ws.close();
      };
    '
  fi
  cleanup
  container=''
  echo "$mode container smoke test passed"
done

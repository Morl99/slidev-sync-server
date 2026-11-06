import assert from 'node:assert/strict';
import { spawn } from 'node:child_process';
import { once } from 'node:events';
import { createServer, connect } from 'node:net';
import { setTimeout as delay } from 'node:timers/promises';
import test from 'node:test';
import { WebSocket } from 'ws';

async function startServer(t, websocket) {
  const reservation = createServer();
  reservation.listen(0, '127.0.0.1');
  await once(reservation, 'listening');
  const { port } = reservation.address();
  await new Promise(resolve => reservation.close(resolve));
  const child = spawn(process.execPath, ['dist/index.js'], {
    cwd: new URL('../', import.meta.url),
    env: { ...process.env, PORT: String(port), WS: websocket ? 'true' : '' },
    stdio: ['ignore', 'pipe', 'pipe'],
  });
  let logs = '';
  child.stdout.on('data', chunk => { logs += chunk; });
  child.stderr.on('data', chunk => { logs += chunk; });
  t.after(async () => {
    if (child.exitCode === null && child.signalCode === null) {
      const exit = once(child, 'exit');
      child.kill();
      await exit;
    }
  });
  for (let attempt = 0; attempt < 100; attempt++) {
    assert.equal(child.exitCode, null, logs);
    const ready = await new Promise(resolve => {
      const socket = connect(port, '127.0.0.1');
      socket.once('connect', () => { socket.destroy(); resolve(true); });
      socket.once('error', () => { socket.destroy(); resolve(false); });
    });
    if (ready) return `127.0.0.1:${port}`;
    await delay(50);
  }
  throw new Error(`Server did not start: ${logs}`);
}

// Both tests exercise the compiled server over real network connections.
test('WebSocket: connect, receive initial state and broadcast patch', { timeout: 10000 }, async t => {
  const host = await startServer(t, true);
  const a = new WebSocket(`ws://${host}`);
  const b = new WebSocket(`ws://${host}`);
  t.after(() => { a.terminate(); b.terminate(); });
  await Promise.all([once(a, 'open'), once(b, 'open')]);
  a.send(JSON.stringify({
    type: 'connect', id: 'smoke', uid: 'a', states: { slide: { page: 1 } },
  }));
  // A second connect on the same socket acknowledges that the group exists.
  const ready = once(a, 'message');
  a.send(JSON.stringify({ type: 'connect', id: 'smoke', uid: 'a' }));
  await ready;
  const initial = once(b, 'message');
  b.send(JSON.stringify({ type: 'connect', id: 'smoke', uid: 'b' }));
  assert.equal(JSON.parse((await initial)[0]).states.slide.page, 1);
  const patched = once(b, 'message');
  a.send(JSON.stringify({ type: 'patch', id: 'smoke', uid: 'a', states: { slide: { page: 2 } } }));
  const message = JSON.parse((await patched)[0]);
  assert.equal(message.type, 'patch');
  assert.equal(message.states.slide.page, 2);
});

test('SSE: open stream, connect and receive patch', { timeout: 10000 }, async t => {
  const host = await startServer(t, false);
  const abort = new AbortController();
  t.after(() => abort.abort());
  const response = await fetch(`http://${host}/event?uid=smoke`, {
    headers: { accept: 'text/event-stream' }, signal: abort.signal,
  });
  assert.equal(response.status, 200);
  assert.match(response.headers.get('content-type'), /text\/event-stream/);
  const reader = response.body.getReader();
  await reader.read();
  for (const [route, data] of [
    ['connect', { id: 'smoke', states: { slide: { page: 1 } } }],
    ['patch', { id: 'smoke', states: { slide: { page: 2 } } }],
  ]) {
    const result = await fetch(`http://${host}/${route}?uid=smoke`, {
      method: 'POST', body: JSON.stringify(data), signal: abort.signal,
    });
    assert.equal(result.status, 200);
    await result.arrayBuffer();
  }
  let received = '';
  const decoder = new TextDecoder();
  while (!received.includes('\n\n')) {
    const chunk = await reader.read();
    assert.equal(chunk.done, false);
    received += decoder.decode(chunk.value, { stream: true });
  }
  assert.match(received, /event: patch/);
  const data = received.split('\n').find(line => line.startsWith('data: '));
  assert.equal(JSON.parse(data.slice(6)).states.slide.page, 2);
});

# Deployment

Mimic's current deployment story is intentionally small: configure a transport, run a Godot server somewhere appropriate for that transport, and point clients at it.

## Default Port

Mimic defaults to port `15490`.

The number is configurable. Local availability is never guaranteed, so change the port if another service is already bound on the machine or server.

`15490` was chosen as a stable project default in the user-port range. It avoids the previous `8910` collision with an assigned IANA service and still leaves room for hosts to pick their own public ports.

ENet uses UDP. WebSocket uses TCP. TCP and UDP have separate port namespaces, but production documentation should still say which protocol a server expects.

## ENet

Use ENet for native desktop or mobile clients when browser support is not required.

Expose the configured UDP port intentionally. If the server is behind a router, UPnP may help local testing, but production hosting should use explicit firewall and network configuration.

## WebSocket

Use WebSocket when browser clients need to connect.

For staging and production, prefer a public `wss://` endpoint on TCP `443` and proxy to the private Godot WebSocket server.

## GitHub Pages Demo

The documentation site can host a Godot Web export under the same GitHub Pages domain. That export is a static browser client, not a multiplayer server.

The public page path should be:

```text
/play/
```

In the build artifact, that lives under `build/site/play/`.

Use a single-threaded Godot Web export for GitHub Pages unless the project deliberately enables Godot's PWA cross-origin isolation workaround.

GitHub Pages is a good place for a playable browser client, a local-only demo, or an example that connects to an external `wss://` server. It is not a place to run an authoritative Godot server.

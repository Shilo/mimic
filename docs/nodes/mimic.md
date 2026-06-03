# Mimic

`Mimic` is the runtime singleton installed by the editor plugin. It owns the active `MultiplayerPeer`, starts and stops server/client connections, and emits connection lifecycle signals for scripts and UI.

## Start A Server

```gdscript
var error := Mimic.start_server()
if error != OK:
	push_error("Failed to start server: %s" % error_string(error))
```

Pass a port or bind address to override Project Settings for one call:

```gdscript
Mimic.start_server(9000, "0.0.0.0")
```

## Start A Client

```gdscript
var error := Mimic.start_client()
if error != OK:
	push_error("Failed to start client: %s" % error_string(error))
```

Override address and port for one call:

```gdscript
Mimic.start_client("192.168.1.25", 9000)
```

## Stop Or Cancel

```gdscript
Mimic.stop()
Mimic.cancel_connection()
```

`stop()` closes the active peer, returns Mimic to `OFFLINE`, and requests deletion of owned UPnP mappings when that setting is enabled. `cancel_connection()` only stops an in-progress client connection.

## Server Or Client Helper

```gdscript
var error := Mimic.start_server_or_client()
if error != OK:
	push_error("Unable to auto-connect: %s" % error_string(error))
```

This helper is meant for local multi-instance testing. With ENet, Mimic first performs a best-effort local bind preflight so later instances can fall back to client mode without noisy ENet bind errors. The fallback is skipped on dedicated/server exports.

## Auto-Connect

Set `mimic_multiplayer/connection/editor_auto_connect` in Project Settings when you want the `Mimic` autoload to start networking during editor-launched local testing:

```text
Disabled
Server Then Client
Client
Server
```

`Server Then Client` uses the same behavior as `Mimic.start_server_or_client()`.

Auto-connect only runs when Godot has the `editor` feature tag. Exported builds should start connections from game code or UI.

## State Helpers

```gdscript
Mimic.is_offline()
Mimic.is_connecting()
Mimic.is_server()
Mimic.is_client()
Mimic.get_state()
Mimic.get_local_peer_id()
Mimic.get_peer_ids()
Mimic.get_external_address()
```

`get_local_peer_id()` returns `0` while offline or connecting. `get_external_address()` returns the last address reported by UPnP port forwarding.

## Signals

```gdscript
Mimic.state_changed.connect(_on_state_changed)
Mimic.start_failed.connect(_on_start_failed)
Mimic.server_started.connect(_on_server_started)
Mimic.client_started.connect(_on_client_started)
Mimic.client_connected.connect(_on_client_connected)
Mimic.client_connection_failed.connect(_on_client_connection_failed)
Mimic.server_disconnected.connect(_on_server_disconnected)
Mimic.peer_connected.connect(_on_peer_connected)
Mimic.peer_disconnected.connect(_on_peer_disconnected)
Mimic.stopped.connect(_on_stopped)
Mimic.port_mapping_finished.connect(_on_port_mapping_finished)
```

`stopped` is emitted for explicit `stop()` calls. Use `server_disconnected`, `client_connection_failed`, or `state_changed` for involuntary disconnects and failed attempts.

## Transport Scope

ENet and WebSocket are the implemented network transports. Offline is an explicit non-network state, and WebRTC is reserved for future signaling support but currently returns an unavailable error when used for server or client startup.

## API

See the generated [`Mimic` API reference](../api/mimic.md).

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

## API

See the generated [`Mimic` API reference](../api/mimic.md).

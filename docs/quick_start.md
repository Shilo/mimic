# Quick Start

This path gets two local editor-launched Godot instances talking to each other with the current connection MVP.

## Configure Defaults

Open **Project > Project Settings** and search for **Mimic Multiplayer**.

Use these values:

```text
mimic_multiplayer/connection/transport = ENet
mimic_multiplayer/connection/editor_auto_connect = Server Then Client
mimic_multiplayer/connection/address = 127.0.0.1
mimic_multiplayer/connection/port = 15490
```

## Run Two Instances

Run two game instances. The first instance should bind the port and become the server. The second instance should fail the local server bind preflight and connect as a client.

Project Settings auto-connect only runs when Godot has the `editor` feature tag. Exported builds should start connections from game code or UI.

## Start From Code Instead

Host:

```gdscript
var error := Mimic.start_server()
if error != OK:
	MimicLog.error("Failed to start server: %s" % error_string(error))
```

Join:

```gdscript
var error := Mimic.start_client()
if error != OK:
	MimicLog.error("Failed to start client: %s" % error_string(error))
```

Stop:

```gdscript
Mimic.stop()
```

Use the same quick local auto-connect behavior from code:

```gdscript
Mimic.start_server_or_client()
```

Cancel a client while it is still connecting:

```gdscript
Mimic.cancel_connection()
```

## Listen For Events

```gdscript
func _ready() -> void:
	Mimic.start_failed.connect(_on_start_failed)
	Mimic.server_started.connect(_on_server_started)
	Mimic.client_started.connect(_on_client_started)
	Mimic.client_connected.connect(_on_client_connected)
	Mimic.client_connection_failed.connect(_on_client_connection_failed)
	Mimic.server_disconnected.connect(_on_server_disconnected)
	Mimic.peer_connected.connect(_on_peer_connected)
	Mimic.peer_disconnected.connect(_on_peer_disconnected)
	Mimic.stopped.connect(_on_stopped)


func _on_start_failed(_attempted_state: Mimic.NetworkState, error: Error, message: String) -> void:
	MimicLog.warning("%s (%s)" % [message, error_string(error)])


func _on_server_started(port: int) -> void:
	MimicLog.log("Server listening on", port)


func _on_client_started(address: String, port: int) -> void:
	MimicLog.log("Connecting to %s:%d" % [address, port])


func _on_client_connected() -> void:
	MimicLog.log("Connected")


func _on_client_connection_failed(message: String) -> void:
	MimicLog.warning(message)


func _on_server_disconnected() -> void:
	MimicLog.log("Disconnected from server")


func _on_peer_connected(peer_id: int) -> void:
	MimicLog.log("Peer connected:", peer_id)


func _on_peer_disconnected(peer_id: int) -> void:
	MimicLog.log("Peer disconnected:", peer_id)


func _on_stopped() -> void:
	MimicLog.log("Networking stopped")
```

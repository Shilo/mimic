# MimicConnector

`MimicConnector` is a scene component that starts and stops Mimic connections. Add it to a startup scene when you want inspector-driven auto-connect or a simple script target for host, join, and stop buttons.

## Auto-Connect Modes

```text
Disabled: Do nothing on ready.
Server: Start a server on ready.
Client: Start a client on ready.
Server If First Else Client: Try server first, then fall back to client.
```

## Button UI Example

```gdscript
@onready var connector: MimicConnector = $MimicConnector


func _on_host_pressed() -> void:
	connector.host()


func _on_join_pressed() -> void:
	connector.join()


func _on_stop_pressed() -> void:
	connector.stop()
```

Pass explicit connection values when the UI has address or port fields:

```gdscript
connector.host(15490)
connector.join("127.0.0.1", 15490)
```

## API

See the generated [`MimicConnector` API reference](../api/mimic_connector.md).

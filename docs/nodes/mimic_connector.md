# MimicConnector

`MimicConnector` is reserved for future built-in connection UI. It is the intended home for a drag-and-drop form with address, port, Host, Join, and Stop controls.

It does not start networking automatically. Configure editor-only startup behavior with Project Settings instead:

```text
mimic_multiplayer/connection/editor_auto_connect = Disabled
mimic_multiplayer/connection/editor_auto_connect = Server Then Client
mimic_multiplayer/connection/editor_auto_connect = Client
mimic_multiplayer/connection/editor_auto_connect = Server
```

Exported builds should start connections from game code or UI.

## Button UI

Until MimicConnector renders controls, wire your own buttons directly to the `Mimic` singleton:

```gdscript

func _on_host_pressed() -> void:
	Mimic.start_server()


func _on_join_pressed() -> void:
	Mimic.start_client()


func _on_stop_pressed() -> void:
	Mimic.stop()
```

## API

See the generated [`MimicConnector` API reference](../api/mimic_connector.md).

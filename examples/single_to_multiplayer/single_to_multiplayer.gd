extends Node2D


func _ready() -> void:
	Mimic.server_started.connect(_on_server_started)
	Mimic.client_connected.connect(_on_client_connected)
	Mimic.client_connection_failed.connect(_on_client_connection_failed)
	Mimic.peer_connected.connect(_on_peer_connected)
	Mimic.peer_disconnected.connect(_on_peer_disconnected)
	Mimic.stopped.connect(_on_stopped)


func _on_server_started(port: int) -> void:
	print("Mimic server listening on port ", port)


func _on_client_connected() -> void:
	print("Mimic client connected.")


func _on_client_connection_failed(message: String) -> void:
	print("Mimic client connection failed: ", message)


func _on_peer_connected(peer_id: int) -> void:
	print("Mimic peer connected: ", peer_id)


func _on_peer_disconnected(peer_id: int) -> void:
	print("Mimic peer disconnected: ", peer_id)


func _on_stopped() -> void:
	print("Mimic network stopped.")

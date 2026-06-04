class_name MimicTransport extends Object
## Internal transport startup helpers used by the Mimic autoload.
## [br][br]
## This class is globally named only so Mimic can avoid script preloads. Gameplay
## code should use the public methods and signals on the [code]Mimic[/code]
## singleton instead.

## Creates an unassigned server [MultiplayerPeer] for the selected Mimic transport.
## [br][br]
## Returns a typed [class PeerResult].
static func create_server_peer(
	transport: Mimic.TransportType,
	port: int,
	bind_address: String
) -> PeerResult:
	var error: Error = OK
	var peer: MultiplayerPeer = null

	match transport:
		Mimic.TransportType.ENET:
			var enet_peer := ENetMultiplayerPeer.new()
			if not bind_address.is_empty() and bind_address != "*":
				enet_peer.set_bind_ip(bind_address)
			error = enet_peer.create_server(
				port,
				MimicProjectSettings.max_clients,
				MimicProjectSettings.enet_channel_count,
				MimicProjectSettings.enet_in_bandwidth,
				MimicProjectSettings.enet_out_bandwidth
			)
			peer = enet_peer
		Mimic.TransportType.WEBSOCKET:
			var websocket_peer := WebSocketMultiplayerPeer.new()
			websocket_peer.handshake_timeout = MimicProjectSettings.websocket_handshake_timeout
			error = websocket_peer.create_server(port, bind_address)
			peer = websocket_peer
		_:
			error = ERR_UNAVAILABLE

	return PeerResult.new(error, peer)


## Creates an unassigned client [MultiplayerPeer] for the selected Mimic transport.
## [br][br]
## Returns a typed [class PeerResult].
static func create_client_peer(
	transport: Mimic.TransportType,
	address: String,
	port: int
) -> PeerResult:
	var error: Error = OK
	var peer: MultiplayerPeer = null

	match transport:
		Mimic.TransportType.ENET:
			var enet_peer := ENetMultiplayerPeer.new()
			var bind_address := MimicProjectSettings.bind_address
			if not bind_address.is_empty() and bind_address != "*":
				enet_peer.set_bind_ip(bind_address)
			error = enet_peer.create_client(
				address,
				port,
				MimicProjectSettings.enet_channel_count,
				MimicProjectSettings.enet_in_bandwidth,
				MimicProjectSettings.enet_out_bandwidth,
				MimicProjectSettings.enet_client_local_port
			)
			peer = enet_peer
		Mimic.TransportType.WEBSOCKET:
			var websocket_peer := WebSocketMultiplayerPeer.new()
			websocket_peer.handshake_timeout = MimicProjectSettings.websocket_handshake_timeout
			error = websocket_peer.create_client(get_websocket_url(address, port))
			peer = websocket_peer
		_:
			error = ERR_UNAVAILABLE

	return PeerResult.new(error, peer)


## Returns the user-facing display name for a Mimic transport value.
static func get_display_name(transport: Mimic.TransportType) -> String:
	match transport:
		Mimic.TransportType.OFFLINE:
			return "Offline"
		Mimic.TransportType.ENET:
			return "ENet"
		Mimic.TransportType.WEBSOCKET:
			return "WebSocket"
		Mimic.TransportType.WEBRTC:
			return "WebRTC"
	return "Unknown"


## Returns the effective bind address after applying a one-call override.
static func get_bind_address(bind_address_override: String = "") -> String:
	if not bind_address_override.is_empty():
		return bind_address_override
	var bind_address := MimicProjectSettings.bind_address
	return "*" if bind_address.is_empty() else bind_address


## Returns a WebSocket URL for the configured WebSocket client options.
static func get_websocket_url(address: String, port: int) -> String:
	if address.begins_with("ws://") or address.begins_with("wss://"):
		return address

	var formatted_address := address
	if formatted_address.split(":").size() > 2 and not formatted_address.begins_with("["):
		formatted_address = "[%s]" % formatted_address

	var path := MimicProjectSettings.websocket_path.strip_edges()
	if not path.is_empty() and not path.begins_with("/"):
		path = "/" + path

	var scheme := "wss" if MimicProjectSettings.websocket_client_use_tls else "ws"
	return "%s://%s:%d%s" % [scheme, formatted_address, port, path]


## Typed result from a transport peer creation attempt.
class PeerResult extends RefCounted:
	var error: Error ## Error returned by the selected transport startup call.
	## Created peer, or [code]null[/code] when the selected transport cannot create one.
	var peer: MultiplayerPeer


	## Creates a peer creation result.
	func _init(result_error: Error, result_peer: MultiplayerPeer) -> void:
		error = result_error
		peer = result_peer

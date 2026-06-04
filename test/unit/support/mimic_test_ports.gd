extends RefCounted

const MIN_PORT := 20_000
const PORT_RANGE := 30_000
const MAX_ATTEMPTS := 512

static var _next_port := _initial_port()


static func next_port() -> int:
	for _attempt in MAX_ATTEMPTS:
		_next_port = _wrap_port(_next_port + 1)
		if _can_bind_tcp(_next_port) and _can_bind_udp(_next_port):
			return _next_port

	push_error("Could not find an available local test port.")
	_next_port = _wrap_port(_next_port + 1)
	return _next_port


static func _initial_port() -> int:
	return MIN_PORT + (OS.get_process_id() % PORT_RANGE)


static func _wrap_port(port: int) -> int:
	if port < MIN_PORT + PORT_RANGE:
		return port
	return MIN_PORT + ((port - MIN_PORT) % PORT_RANGE)


static func _can_bind_tcp(port: int) -> bool:
	var server := TCPServer.new()
	return server.listen(port, "*") == OK


static func _can_bind_udp(port: int) -> bool:
	var peer := PacketPeerUDP.new()
	var error := peer.bind(port, "*")
	peer.close()
	return error == OK

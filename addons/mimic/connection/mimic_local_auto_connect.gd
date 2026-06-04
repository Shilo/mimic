class_name MimicLocalAutoConnect extends Object
## Internal local auto-connect fallback helpers used by the Mimic autoload.
## [br][br]
## This class owns the best-effort host preflight and fallback rules behind
## [method Mimic.start_server_or_client]. Gameplay code should call the
## [code]Mimic[/code] singleton instead.


## Returns a best-effort local host preflight error, or [constant OK].
## [br][br]
## ENet bind failures can be noisy in Godot output, so local auto-connect probes
## obvious occupied-port cases before attempting the authoritative server start.
static func get_host_preflight_error(
	transport: Mimic.TransportType,
	port: int,
	bind_address: String,
	has_active_peer: bool
) -> Error:
	if transport != Mimic.TransportType.ENET:
		return OK
	if has_active_peer or OS.has_feature("web"):
		return OK
	if port < 1 or port > 65_535:
		return OK
	if bind_address != "*" and not bind_address.is_valid_ip_address():
		# PacketPeerUDP can only probe literal bind addresses; let ENet validate other values.
		return OK

	return _get_enet_bind_preflight_error(port, bind_address)


## Returns [code]true[/code] for expected local host startup failures.
static func is_expected_host_failure(error: Error) -> bool:
	return error == ERR_ALREADY_IN_USE or error == ERR_CANT_CREATE or error == ERR_CANT_OPEN


## Returns [code]true[/code] when a failed host attempt may continue as a client.
static func can_fallback_to_client(error: Error, has_active_peer: bool) -> bool:
	if not is_expected_host_failure(error):
		return false
	if has_active_peer:
		return false
	if OS.has_feature("dedicated_server") or OS.has_feature("server"):
		return false
	return true


static func _get_enet_bind_preflight_error(port: int, bind_address: String) -> Error:
	var udp_probe := PacketPeerUDP.new()
	var error: Error = udp_probe.bind(port, bind_address)
	udp_probe.close()
	if error == OK:
		return OK

	# PacketPeerUDP is a heuristic probe; ENet's create_server remains the authoritative bind.
	# Match ENet's create_server bind-failure error so fallback policy stays centralized.
	return ERR_CANT_CREATE

class_name MimicAutoConnect extends Object
## Internal auto-connect policy helpers used by the Mimic autoload.
## [br][br]
## These pure checks gate editor startup auto-connect and steer the host-or-client
## fallback behind [method Mimic.start_server_or_client]. Gameplay code should call
## the [code]Mimic[/code] singleton instead.

const _TOOLING_ARGS := ["--doctool", "--import", "-s", "--script"]


## Returns [code]true[/code] when Mimic runs under a non-gameplay tooling command.
## [br][br]
## Editor auto-connect is skipped for tooling runs such as [code]--doctool[/code],
## [code]--import[/code], [code]-s[/code], and [code]--script[/code]. Pass
## [param cmdline_args] to override the live [method OS.get_cmdline_args] values.
static func is_tooling_run(cmdline_args: PackedStringArray = PackedStringArray()) -> bool:
	if cmdline_args.is_empty():
		cmdline_args = OS.get_cmdline_args()

	for argument in cmdline_args:
		if argument in _TOOLING_ARGS:
			return true

	return false


## Returns a best-effort local host preflight error, or [constant OK].
## [br][br]
## ENet bind failures can be noisy in Godot output, so local auto-connect probes
## obvious occupied-port cases before attempting the authoritative server start.
## [br][br]
## [param transport] is the transport to probe; only ENet is checked, and other
## transports return [constant OK].
## [br][br]
## [param port] is the host port to probe.
## [br][br]
## [param bind_address] is the local bind address to probe.
## [br][br]
## [param has_active_peer] skips the probe when [code]true[/code] so an existing peer is
## left untouched.
## [br][br]
## Returns [constant OK] when no obvious local bind problem is detected, or
## [constant ERR_CANT_CREATE] when the port appears unavailable.
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
## [br][br]
## [param error] is the host start [enum Error] to classify; in-use, create, and open
## failures are treated as expected.
static func is_expected_host_failure(error: Error) -> bool:
	return error == ERR_ALREADY_IN_USE or error == ERR_CANT_CREATE or error == ERR_CANT_OPEN


## Returns [code]true[/code] when a failed host attempt may continue as a client.
## [br][br]
## [param error] is the host start [enum Error] that triggered the fallback check.
## [br][br]
## [param has_active_peer] blocks fallback when [code]true[/code] so an existing peer is
## not replaced.
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

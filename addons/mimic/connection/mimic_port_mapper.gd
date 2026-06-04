class_name MimicPortMapper extends RefCounted
## Internal UPnP port mapping worker used by the Mimic autoload.
## [br][br]
## This class is globally named only so Mimic can avoid script preloads. Gameplay
## code should use the public methods and signals on the [code]Mimic[/code]
## singleton instead.

## Emitted after a background UPnP add-mapping attempt succeeds or fails.
signal finished(error: UPNP.UPNPResult, external_address: String)

var _external_address := ""
var _mapped_port := 0
var _mapped_protocols := PackedStringArray()
var _thread: Thread
var _request_id := 0
var _delete_after_thread := false
var _queued_request := {}


## Starts a background UPnP add-mapping request.
## [br][br]
## Does nothing when [member MimicProjectSettings.port_forwarding_enabled] is [code]false[/code].
func add_mapping(port: int, protocols: PackedStringArray, description: String) -> void:
	if not MimicProjectSettings.port_forwarding_enabled:
		return

	_external_address = ""
	_mapped_port = 0
	_mapped_protocols.clear()

	_start_thread({
		"operation": "add",
		"port": port,
		"protocols": protocols,
		"description": description,
		"duration": MimicProjectSettings.port_mapping_duration,
		"query_external_address": MimicProjectSettings.port_mapping_query_external_address,
		"discover_timeout_ms": MimicProjectSettings.upnp_discover_timeout_ms,
		"discover_ttl": MimicProjectSettings.upnp_discover_ttl,
	})


## Requests deletion of the owned UPnP mapping when deletion is enabled.
func delete_mapping() -> void:
	if not MimicProjectSettings.port_mapping_delete_on_stop:
		return

	if _thread != null:
		_delete_after_thread = true
		_queued_request = {}
		return

	if _mapped_port <= 0 or _mapped_protocols.is_empty():
		return

	var mapped_port := _mapped_port
	var mapped_protocols := _mapped_protocols.duplicate()

	_mapped_port = 0
	_mapped_protocols.clear()
	_external_address = ""

	_start_thread({
		"operation": "delete",
		"port": mapped_port,
		"protocols": mapped_protocols,
		"discover_timeout_ms": MimicProjectSettings.upnp_discover_timeout_ms,
		"discover_ttl": MimicProjectSettings.upnp_discover_ttl,
	})


## Waits for the active UPnP worker thread and any queued cleanup work to finish.
func wait_to_finish() -> void:
	while _thread != null:
		_finish_completed_request()


## Returns the last external address reported by UPnP.
func get_external_address() -> String:
	return _external_address


func _start_thread(request: Dictionary) -> void:
	if _thread != null:
		if String(request["operation"]) == "delete":
			_delete_after_thread = true
		else:
			_queued_request = request
		return

	_request_id += 1
	request["id"] = _request_id

	_thread = Thread.new()
	var error := _thread.start(_run_request.bind(request))
	if error != OK:
		_thread = null
		if String(request["operation"]) == "add":
			finished.emit(UPNP.UPNP_RESULT_UNKNOWN_ERROR, "")


func _run_request(request: Dictionary) -> Dictionary:
	var request_id := int(request["id"])
	var result := _execute_request(request)
	_finish_deferred_request.call_deferred(request_id)
	return {
		"id": request_id,
		"result": result,
	}


func _execute_request(request: Dictionary) -> Dictionary:
	var upnp := UPNP.new()
	var discover_error: UPNP.UPNPResult = upnp.discover(
		int(request["discover_timeout_ms"]),
		int(request["discover_ttl"])
	)
	if discover_error != UPNP.UPNP_RESULT_SUCCESS:
		return _result(request, discover_error)

	var gateway := upnp.get_gateway()
	if gateway == null or not gateway.is_valid_gateway():
		return _result(request, UPNP.UPNP_RESULT_NO_GATEWAY)

	var port := int(request["port"])
	var protocols: PackedStringArray = request["protocols"]
	if String(request["operation"]) == "delete":
		for protocol in protocols:
			upnp.delete_port_mapping(port, protocol)
		return _result(request, UPNP.UPNP_RESULT_SUCCESS)

	var mapped_protocols := PackedStringArray()
	for protocol in protocols:
		var mapping_error: UPNP.UPNPResult = upnp.add_port_mapping(
			port,
			port,
			String(request["description"]),
			protocol,
			int(request["duration"])
		)
		if mapping_error != UPNP.UPNP_RESULT_SUCCESS:
			for mapped_protocol in mapped_protocols:
				upnp.delete_port_mapping(port, mapped_protocol)
			return _result(request, mapping_error)

		mapped_protocols.append(protocol)

	var mapped_address := ""
	if bool(request["query_external_address"]):
		mapped_address = upnp.query_external_address()

	return _result(request, UPNP.UPNP_RESULT_SUCCESS, mapped_address, port, mapped_protocols)


func _finish_deferred_request(request_id: int) -> void:
	if request_id != _request_id:
		return

	_finish_completed_request()


func _finish_completed_request() -> void:
	if _thread == null:
		return

	var thread_result: Dictionary = _thread.wait_to_finish()
	_thread = null

	# Worker threads only compute results; tracked port-mapping state mutates here.
	var request_id := int(thread_result["id"])
	var result: Dictionary = thread_result["result"]

	if request_id != _request_id:
		return

	if String(result["operation"]) == "delete":
		_mapped_port = 0
		_mapped_protocols.clear()
		_external_address = ""
		if _delete_after_thread:
			_delete_after_thread = false
			_queued_request = {}
			return
		_start_queued_request()
		return

	var error: UPNP.UPNPResult = result["error"]
	if error == UPNP.UPNP_RESULT_SUCCESS:
		_mapped_port = int(result["mapped_port"])
		_mapped_protocols = result["mapped_protocols"]
		_external_address = String(result["external_address"])

	if _delete_after_thread:
		_delete_after_thread = false
		if error == UPNP.UPNP_RESULT_SUCCESS:
			delete_mapping()
			return

	finished.emit(error, _external_address)
	_start_queued_request()


func _start_queued_request() -> void:
	if _queued_request.is_empty():
		return

	var request := _queued_request
	_queued_request = {}
	_start_thread(request)


func _result(
	request: Dictionary,
	error: UPNP.UPNPResult,
	mapped_address: String = "",
	mapped_port: int = 0,
	mapped_protocols: PackedStringArray = PackedStringArray()
) -> Dictionary:
	return {
		"operation": request["operation"],
		"error": error,
		"external_address": mapped_address,
		"mapped_port": mapped_port,
		"mapped_protocols": mapped_protocols,
	}

class_name MimicPeerResult extends RefCounted
## Pairs a created [MultiplayerPeer] with the [enum Error] from its startup call.
## [br][br]
## [member peer] is [code]null[/code] when the selected transport cannot create one.

## Error returned by the selected transport startup call.
var error: Error
## Created peer, or [code]null[/code] when the selected transport cannot create one.
var peer: MultiplayerPeer


## Creates a [MimicPeerResult].
func _init(result_error: Error, result_peer: MultiplayerPeer = null) -> void:
	error = result_error
	peer = result_peer

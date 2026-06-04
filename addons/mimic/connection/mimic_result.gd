class_name MimicResult extends RefCounted
## Pairs a Godot [Error] with a human-readable message.
## [br][br]
## [member error] is [constant OK] with an empty [member message] on success.

## Error code, or [constant OK] on success.
var error: Error
## Human-readable explanation, or empty on success.
var message: String


## Creates a [MimicResult].
func _init(result_error: Error, result_message: String = "") -> void:
	error = result_error
	message = result_message

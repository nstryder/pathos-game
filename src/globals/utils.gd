extends Node


func sleep(time_sec: float) -> void:
	await get_tree().create_timer(time_sec).timeout

## Checks if any variables given are null.
## Useful for making sure we don't forget to set 
## certain variables at a certain time. i.e. before ready.
func validate_vars(caller: Node, ...vars: Array) -> void:
	if OS.is_debug_build():
		for variable: Variant in vars:
			assert(variable != null, str("A required variable was not set in", caller))

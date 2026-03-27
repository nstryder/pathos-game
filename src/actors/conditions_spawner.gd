@tool
extends MultiplayerSpawner

@export_dir var conditions_path: String
@export_tool_button("Populate Spawn List", "MemberMethod") var button_populate_spawn_list: Callable = _populate_spawn_list
# Called when the node enters the scene tree for the first time.
func _populate_spawn_list() -> void:
	clear_spawnable_scenes()
	
	var raw_list: Array[String]
	raw_list.assign(Array(ResourceLoader.list_directory(conditions_path)))
	var scene_list: Array[String]
	scene_list.assign(raw_list.filter(func(x: String) -> bool: return x.get_extension() == "tscn"))

	for filename in scene_list:
		var path: String = conditions_path.path_join(filename)
		print("Adding path: ", path)
		add_spawnable_scene(path)
		
	notify_property_list_changed()

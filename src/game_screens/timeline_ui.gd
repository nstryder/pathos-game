extends HBoxContainer

const timeline_entry_scene: PackedScene = preload("uid://bnk7wg11y5700")
const UsageType = EffectCardData.UsageType

@onready var timeline: Timeline = %Timeline


func _on_timeline_timeline_modified() -> void:
	for child in get_children(): child.queue_free()
	for action: Timeline.Action in timeline.main_timeline_queue:
		var timeline_entry: Label = timeline_entry_scene.instantiate()
		if action.type == UsageType.ATTACH:
			timeline_entry.text = "Attach\nFX"
		else:
			timeline_entry.text = "Use FX"
		add_child(timeline_entry)

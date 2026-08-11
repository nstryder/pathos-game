extends Node2D
class_name SynergyNode

signal activated
signal deactivated


@export var synergy_name: String
@export var is_active: bool:
	set(value):
		if value != is_active:
			if value:
				activated.emit()
			else:
				deactivated.emit()
		is_active = value
@export var player_nodepath: NodePath
var player: Player
var data: SynergyData
var behavior: SynergyBehavior


func _ready() -> void:
	data = CardDb.synergies[synergy_name]

	var synergy_path: String = CardDb.get_synergy_behavior_path(synergy_name)
	behavior = (load(synergy_path) as GDScript).new()

	player = get_tree().root.get_node(player_nodepath)
	activated.connect(behavior.on_activate)
	behavior.player = player
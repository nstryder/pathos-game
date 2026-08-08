extends Node2D
class_name SynergyNode


@export var synergy_name: String
@export var is_active: bool
var data: SynergyData
var behavior: SynergyBehavior


func _ready() -> void:
	data = CardDb.synergies[synergy_name]

	var synergy_path: String = CardDb.get_synergy_behavior_path(synergy_name)
	behavior = (load(synergy_path) as GDScript).new()
